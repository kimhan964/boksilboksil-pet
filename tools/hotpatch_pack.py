"""Append a small set of project resources to an unencrypted Godot 4.7 PCK.

Old file contents and directory remain in the pack. The journal preserves the
original header/length so this update can be rolled back without a full copy.
Stop the game's process before running; verify the result with Godot afterwards.
"""
import argparse
import hashlib
import json
import os
import struct
from pathlib import Path

SOURCE=Path(__file__).resolve().parents[1]


def patch(pack, paths, journal_tag="typing-art"):
    if not journal_tag or any(c not in "abcdefghijklmnopqrstuvwxyz0123456789-" for c in journal_tag):
        raise ValueError("Journal tag must contain lowercase letters, digits or hyphens")
    replacements={}
    for name in paths:
        source=(SOURCE/name).resolve()
        source.relative_to(SOURCE)
        if not source.is_file(): raise ValueError("Missing source: "+name)
        replacements[source.relative_to(SOURCE).as_posix()]=source.read_bytes()
    journal=pack.with_name(pack.name+"."+journal_tag+"-journal.json")
    if journal.exists(): raise ValueError("A journal already exists; inspect it before another update")
    with pack.open("r+b") as stream:
        header=stream.read(128)
        if struct.unpack_from("<6I",header)!=(0x43504447,4,4,7,2,2):
            raise ValueError("Unsupported pack format")
        base,directory=struct.unpack_from("<QQ",header,24)
        original_size=stream.seek(0,2)
        if base!=128 or not base<directory<original_size: raise ValueError("Invalid directory")
        stream.seek(directory)
        table=stream.read()
        count=struct.unpack_from("<I",table)[0]
        cursor=4
        entries={}
        for _ in range(count):
            length=struct.unpack_from("<I",table,cursor)[0]
            cursor+=4
            name=table[cursor:cursor+length].rstrip(b"\0").decode("utf-8")
            cursor+=length
            offset,size,digest,flags=struct.unpack_from("<QQ16sI",table,cursor)
            cursor+=36
            if name in entries or flags or base+offset+size>directory: raise ValueError("Invalid entry")
            entries[name]=(offset,size,digest,flags)
        if cursor!=len(table): raise ValueError("Unexpected directory trailer")
        journal.write_text(json.dumps({"pack":str(pack.resolve()),"size":original_size,"header":header.hex(),"changed":list(replacements)},indent=2),encoding="utf-8")
        try:
            stream.seek(0,2)
            for name,data in replacements.items():
                stream.write(b"\0"*((32-stream.tell()%32)%32))
                offset=stream.tell()-base
                stream.write(data)
                entries[name]=(offset,len(data),hashlib.md5(data).digest(),0)
            stream.write(b"\0"*((32-stream.tell()%32)%32))
            updated_directory=stream.tell()
            stream.write(struct.pack("<I",len(entries)))
            for name,entry in sorted(entries.items()):
                encoded=name.encode("utf-8")
                encoded+=b"\0"*((4-len(encoded)%4)%4)
                stream.write(struct.pack("<I",len(encoded))+encoded+struct.pack("<QQ16sI",*entry))
            stream.flush()
            os.fsync(stream.fileno())
            stream.seek(32)
            stream.write(struct.pack("<Q",updated_directory))
            stream.flush()
            os.fsync(stream.fileno())
        except BaseException:
            stream.seek(0)
            stream.write(header)
            stream.truncate(original_size)
            raise
    print("PATCHED",pack,"resources",list(replacements),"journal",journal)


if __name__=="__main__":
    parser=argparse.ArgumentParser()
    parser.add_argument("pack",type=Path)
    parser.add_argument("files",nargs="+")
    parser.add_argument("--journal-tag",default="typing-art")
    args=parser.parse_args()
    patch(args.pack,args.files,args.journal_tag)
