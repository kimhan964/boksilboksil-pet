"""Verify the executable's embedded RT_ICON bytes against the shipping ICO."""
import ctypes as c
import struct
import sys
from pathlib import Path

root = Path(__file__).resolve().parents[1]
exe = Path(sys.argv[1]) if len(sys.argv)>1 else root.parent/'복슬복슬타자친구/TypingFriends.exe'
ico = (root/'games/typing-pet/assets/icon/typing-friends.ico').read_bytes()
expected = {}
for i in range(struct.unpack_from('<H', ico, 4)[0]):
    w,h,_,_,_,_,size,offset = struct.unpack_from('<BBBBHHII', ico, 6+i*16)
    expected[(w or 256,h or 256)] = ico[offset:offset+size]
k = c.WinDLL('kernel32', use_last_error=True)
k.LoadLibraryExW.argtypes=[c.c_wchar_p,c.c_void_p,c.c_uint32]
k.LoadLibraryExW.restype=c.c_void_p
k.FindResourceW.argtypes=[c.c_void_p,c.c_void_p,c.c_void_p]
k.FindResourceW.restype=c.c_void_p
k.LoadResource.argtypes=[c.c_void_p,c.c_void_p]
k.LoadResource.restype=c.c_void_p
k.LockResource.argtypes=[c.c_void_p]
k.LockResource.restype=c.c_void_p
k.SizeofResource.argtypes=[c.c_void_p,c.c_void_p]
k.SizeofResource.restype=c.c_uint32
k.FreeLibrary.argtypes=[c.c_void_p]
module=k.LoadLibraryExW(str(exe),None,0x22)
assert module, c.get_last_error()
def resource(kind, name):
    r=k.FindResourceW(module,name,kind)
    assert r, (kind,name,c.get_last_error())
    data=k.LockResource(k.LoadResource(module,r))
    return c.string_at(data,k.SizeofResource(module,r))
groups=[]
CALLBACK=c.WINFUNCTYPE(c.c_int,c.c_void_p,c.c_void_p,c.c_void_p,c.c_ssize_t)
@CALLBACK
def collect(module_,type_,name,param):
    groups.append(resource(14,name))
    return 1
k.EnumResourceNamesW.argtypes=[c.c_void_p,c.c_void_p,CALLBACK,c.c_ssize_t]
try:
    assert k.EnumResourceNamesW(module,14,collect,0)
    matched=False
    for group in groups:
        found={}
        for i in range(struct.unpack_from('<H',group,4)[0]):
            w,h,_,_,_,_,size,id_=struct.unpack_from('<BBBBHHIH',group,6+i*14)
            found[(w or 256,h or 256)]=resource(3,id_)
        if found==expected: matched=True
    assert matched, 'Executable icon does not match all seven ICO representations'
    print('EXE_ICON_VERIFIED:', sorted(expected), exe)
finally:
    k.FreeLibrary(module)
