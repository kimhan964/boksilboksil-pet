# Local keyboard and click activity bridge

This Windows helper is original project code. BongoCat's installed files were
inspected for application structure and interface names only; no assets or code
were copied.

`TypingInput.exe` is built from `TypingInput.cs` with the Windows .NET Framework
C# compiler. Run from the project directory in PowerShell:

```powershell
& "$env:WINDIR\Microsoft.NET\Framework64\v4.0.30319\csc.exe" /nologo /target:winexe /optimize+ '/out:addons\typing_input\TypingInput.exe' /reference:System.Windows.Forms.dll 'addons\typing_input\TypingInput.cs'
```

- Starts only in the standalone typing game; pausing or closing stops it.
- A Windows low-level keyboard hook counts distinct down/up pairs. Standalone
  modifiers and held-key auto-repeat do not generate extra animation pulses.
- A low-level mouse hook counts left/right/middle/side button-down events. Releases,
  movement and wheel scrolling are excluded. No mouse coordinates are read.
- Always calls `CallNextHookEx`; never suppresses or replaces keyboard/mouse input.
- Key identity is used transiently in a 256-element held-key array. No text,
  keystroke log, active-window information, or file output is produced.
- Only an aggregate counter plus a per-launch random token is sent to a UDP
  socket bound to `127.0.0.1`. No external network endpoint is used.
- A 16 ms message-loop timer sends counts outside the hook callback. A heartbeat
  lets the game show connection errors. Parent exit closes the helper.
- No service, startup registration, administrator privilege, or driver install.
- Protected desktops and elevated apps may restrict observation. The feature
  does not attempt to bypass Windows restrictions.

APM now uses the APMAlert exponential estimator; see ../../README.md for the exact formula, input mapping and validation. Activity/reward statistics belong only to BoksilTypingFriends, independently of DesktopFriends.

Windows API reference: https://learn.microsoft.com/en-us/windows/win32/winmsg/lowlevelkeyboardproc

Packaging must copy TypingInput.exe outside the PCK to addons/typing_input/TypingInput.exe beside TypingFriends.exe.
