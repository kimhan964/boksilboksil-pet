"""Clone a verified Godot 4.7 PCK, changing only its preview configuration.

The assets and scripts stay byte-identical; the Godot package verifier must still
be run on the result. Refuses encrypted/embedded/unrecognized pack formats.
"""
import argparse
import hashlib
import shutil
import struct
from pathlib import Path


def clone(source: Path, destination: Path):
    if source.resolve() == destination.resolve() or destination.exists():
        raise ValueError("Destination must be a new file distinct from the source")
    with source.open("rb") as stream:
        header = bytearray(stream.read(128))
        magic, version, major, minor, patch, flags = struct.unpack_from("<6I", header)
        if (magic, version, major, minor, flags) != (0x43504447, 4, 4, 7, 2):
            raise ValueError("Unsupported PCK header")
        base, directory = struct.unpack_from("<QQ", header, 24)
        if base != 128 or not base < directory < source.stat().st_size:
            raise ValueError("Invalid pack bounds")
        stream.seek(directory)
        table = bytearray(stream.read())
        count = struct.unpack_from("<I", table)[0]
        cursor = 4
        project_entry = None
        for _ in range(count):
            length = struct.unpack_from("<I", table, cursor)[0]
            cursor += 4
            name = bytes(table[cursor:cursor + length]).rstrip(b"\0").decode("utf-8")
            cursor += length
            offset, size = struct.unpack_from("<QQ", table, cursor)
            digest = bytes(table[cursor + 16:cursor + 32])
            entry_flags = struct.unpack_from("<I", table, cursor + 32)[0]
            if entry_flags != 0 or offset + base + size > directory:
                raise ValueError("Unsupported or invalid entry: " + name)
            if name == "project.godot":
                if project_entry is not None:
                    raise ValueError("Duplicate project configuration")
                project_entry = (cursor, offset, size, digest)
            cursor += 36
        if cursor != len(table) or project_entry is None:
            raise ValueError("Unexpected directory trailer or missing configuration")
        entry, offset, size, digest = project_entry
        stream.seek(base + offset)
        old = stream.read(size)
        if hashlib.md5(old).digest() != digest:
            raise ValueError("Source project checksum mismatch")
    config = old.decode("utf-8")
    if 'run/main_scene="res://scenes/main.tscn"' not in config:
        raise ValueError("Source must be the regular edition")
    config = config.replace('run/main_scene="res://scenes/main.tscn"', 'run/main_scene="res://scenes/species_walk_preview.tscn"')
    config = config.replace('config/custom_user_dir_name="DesktopFriends"', 'config/custom_user_dir_name="DesktopFriendsWalkPreview"')
    config = config.replace("[testing]", "[testing]\nwalk_trial_version=14")
    new = config.encode("utf-8")
    destination.parent.mkdir(parents=True, exist_ok=True)
    shutil.copyfile(source, destination)
    with destination.open("r+b") as stream:
        stream.seek(directory)
        stream.write(new)
        padding = (32 - stream.tell() % 32) % 32
        stream.write(b"\0" * padding)
        new_directory = stream.tell()
        struct.pack_into("<QQ", table, entry, directory - base, len(new))
        table[entry + 16:entry + 32] = hashlib.md5(new).digest()
        stream.write(table)
        stream.truncate()
        stream.seek(32)
        stream.write(struct.pack("<Q", new_directory))
    print("PREVIEW_CLONED: configuration changed;", count - 1, "entries preserved")


if __name__ == "__main__":
    parser = argparse.ArgumentParser()
    parser.add_argument("source", type=Path)
    parser.add_argument("destination", type=Path)
    args = parser.parse_args()
    clone(args.source, args.destination)
