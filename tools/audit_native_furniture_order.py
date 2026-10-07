"""Read Windows stacking order; never moves/activates windows or sends input."""
import ctypes
import json
import sys
import time
from ctypes import wintypes

user32=ctypes.windll.user32
user32.GetTopWindow.argtypes=[wintypes.HWND]
user32.GetTopWindow.restype=wintypes.HWND
user32.GetWindow.argtypes=[wintypes.HWND,wintypes.UINT]
user32.GetWindow.restype=wintypes.HWND
pid=int(sys.argv[1])
samples=[]
for _ in range(40):
    rows=[]
    handle=user32.GetTopWindow(None)
    while handle:
        owner=wintypes.DWORD()
        user32.GetWindowThreadProcessId(handle,ctypes.byref(owner))
        if owner.value==pid and user32.IsWindowVisible(handle):
            title=ctypes.create_unicode_buffer(512)
            user32.GetWindowTextW(handle,title,512)
            rows.append(title.value)
        handle=user32.GetWindow(handle,2)
    pet=next((i for i,s in enumerate(rows) if ' · 바탕화면 친구' in s),None)
    furniture=[i for i,s in enumerate(rows) if '드래그로 이동' in s]
    samples.append({'pet_in_front':pet is not None and all(pet<i for i in furniture),'order':rows})
    time.sleep(.25)
result={'samples':len(samples),'violations':sum(not s['pet_in_front'] for s in samples),'last_order':samples[-1]['order']}
print(json.dumps(result,ensure_ascii=False))
sys.exit(0 if result['violations']==0 else 1)
