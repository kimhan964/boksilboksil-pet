# Native furniture layer order

Game runtime component for Windows 10/11 (.NET Framework 4.x).
Build in this directory with the installed Framework compiler:

`csc.exe /nologo /optimize+ /target:exe /platform:x64 /out:NativeLayerOrder.exe NativeLayerOrder.cs`

`scripts/native_layer_order.gd` starts one persistent process with redirected
stdin. Each line lists this game's native handles, back to front. The component
verifies every handle belongs to the parent PID. It uses SetWindowPos with
SWP_NOACTIVATE, SWP_NOSIZE, SWP_NOMOVE, and SWP_NOOWNERZORDER. It never changes
window styles or sends input. It exits when stdin closes or the game exits.
The package includes source and executable; no Python or Godot .NET is required.

2026-10-07 flicker correction: the sequential SetWindowPos loop was replaced.
Check actual relative order first, skip requests whose order is already correct,
and relocate only a window whose nearest game window above it is incorrect.
Use the expected preceding handle, not HWND_TOPMOST for every furniture item.
The batch experiment failed the post-drag audit and is discarded. Briefly
recheck after native drag completion; an already correct order performs no writes.
Never raise all transparent furniture surfaces sequentially on every movement.

Godot's Windows `window_move_to_foreground` skips `no_focus` windows:
https://github.com/godotengine/godot/blob/master/platform/windows/display_server_windows.cpp
The pet and furniture intentionally remain unfocusable.

Changing ALWAYS_ON_TOP on the pet is forbidden: it previously erased the
transparent OpenGL surface. Do not replace this implementation with that toggle.
