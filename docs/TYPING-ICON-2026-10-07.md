# Typing Friends 실행 아이콘

- imagegen으로 기존 토끼를 참조해 새 앱 아이콘 제작: 크림 토끼, 세이지 바탕, 다섯 개의 키.
- 원본: `games/typing-pet/assets/icon/typing-friends-source.png`.
- 게임 창: 같은 폴더의 `pet-icon.png`, 기존 project.godot 및 DisplayServer.set_icon 경로를 그대로 사용.
- Windows EXE: `typing-friends.ico`의 16/24/32/48/64/128/256픽셀 일곱 표현을 rcedit으로 내장.
- `python tools/make_typing_icon.py`로 원본 PNG에서 ICO 재패키징.
- `builds/icon-tools/rcedit-x64.exe <TypingFriends.exe> --set-icon games/typing-pet/assets/icon/typing-friends.ico`로 실행 파일 리소스 적용.
- `python tools/verify_typing_icon.py <TypingFriends.exe>`로 PE 내부 아이콘 리소스가 ICO의 일곱 이미지와 바이트 단위로 일치하는지 검사.
- 기존 EXE는 `builds/typing-icon-backup/TypingFriends-before-icon.exe`에 보존. 데스크톱 펫 실행 파일은 수정하지 않음.
