"""Remove retired walking resource names from the active PCK directory.
Retains the original bytes and a rollback journal; never copies the large pack.
"""
import struct, json, os, re
from pathlib import Path

pack=Path('C:/Users/rlagk/Documents/복슬복슬펫/0.30.3/DesktopFriends.pck')
journal=pack.with_name(pack.name+'.retired-walks-20261007-journal.json')
if journal.exists(): raise RuntimeError('Already pruned; inspect journal')
with pack.open('r+b') as stream:
    header=stream.read(128)
    if struct.unpack_from('<6I',header)!=(0x43504447,4,4,7,2,2): raise RuntimeError('Unsupported PCK')
    base,directory=struct.unpack_from('<QQ',header,24)
    original_size=stream.seek(0,2)
    stream.seek(directory)
    count=struct.unpack('<I',stream.read(4))[0]
    entries={}; retired=[]
    for _ in range(count):
        length=struct.unpack('<I',stream.read(4))[0]
        name=stream.read(length).rstrip(b'\0').decode('utf-8')
        entry=struct.unpack('<QQ16sI',stream.read(36))
        if entry[3] or base+entry[0]+entry[1]>directory: raise RuntimeError('Invalid entry')
        match=re.match(r'assets/(walk-v\d+|rabbit-frame-pilot-v\d+)/',name)
        if match and match.group(1) not in ['walk-v14','rabbit-frame-pilot-v9']:
            retired.append(name)
        else: entries[name]=entry
    journal.write_text(json.dumps({'pack':str(pack),'size':original_size,'header':header.hex(),'removed':retired},indent=2),encoding='utf-8')
    try:
        stream.seek(0,2)
        stream.write(b'\0'*((-stream.tell())%32))
        updated_directory=stream.tell()
        stream.write(struct.pack('<I',len(entries)))
        for name,entry in sorted(entries.items()):
            encoded=name.encode('utf-8'); encoded+=b'\0'*((-len(encoded))%4)
            stream.write(struct.pack('<I',len(encoded))+encoded+struct.pack('<QQ16sI',*entry))
        stream.flush();os.fsync(stream.fileno())
        stream.seek(32);stream.write(struct.pack('<Q',updated_directory))
        stream.flush();os.fsync(stream.fileno())
    except BaseException:
        stream.seek(0);stream.write(header);stream.truncate(original_size)
        raise
print('Removed retired walking resources:',len(retired))
