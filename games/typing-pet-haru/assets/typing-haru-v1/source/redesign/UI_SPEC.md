# 단짝 타자친구 UI 간격 규격

기준: scripts/cozy_ui.gd 상수. 단위는 논리 px. 8px 기본 그리드, 요청된 12/20px는 4px 보조 간격이며 모서리 14px는 예외다. 글씨 배율은 글꼴에만 적용하고 간격은 유지한다.

| 항목 | 규격 |
|---|---|
| 창 바깥 | OUTER 20 (상하좌우) |
| 헤더→프로필→탭→콘텐츠→하단 줄 | MAJOR_GAP 16 |
| 탭 | TAB_HEIGHT 40, 좌우 TAB_PAD 16, 사이 TAB_GAP 8, 가운데 정렬 |
| 카드 | CARD_X 20 / CARD_Y 16, CARD_GAP 16, CARD_RADIUS 16, BORDER 2 |
| 카드 제목·내용 / 요소 사이 | INNER_GAP 12 |
| 드롭다운·입력 | FIELD_HEIGHT 44, CONTROL_RADIUS 14 |
| 버튼 | BUTTON_HEIGHT 40, FOOTER_HEIGHT 44, CONTROL_RADIUS 14, BUTTON_GAP 12, 같은 줄 균등 폭 |
| 스크롤 | SCROLL_WIDTH 8, SCROLL_GAP 8, SCROLL_Y 8 |
| 안내문 | HELP_PAD 상하 8, MIN_FONT 12 |
| 슬라이더 라벨 | GRID 8 |
| 프로필 | PROFILE_PAD 16, PROFILE_THUMB 96, PROFILE_GAP 16 |
| 하단 버튼 | 3개 균등 폭, 사이 12, 창 가장자리 20 |

설정 기본 크기 640×860. 글씨 1.3배에서는 가로를 늘리며 화면 사용 영역에 맞춰 제한한다. 콘텐츠는 세로 스크롤하고 가로 스크롤을 사용하지 않는다. 버튼 높이는 최소 높이이며 큰 글씨·여러 줄은 필요한 만큼 늘어난다.
기본 TabContainer의 붙은 탭 대신 8px 간격의 별도 버튼 줄을 사용하고 기존 탭 선택 상태와 동기화한다.
튜토리얼과 도움말은 같은 창이며 같은 여백·버튼 규격을 사용한다.

## 탭 아이콘·상태

아이콘은 기존 발바닥/선물/컵을 20px로 표시하고 글자와 6px 간격을 둔다. 리포트는 기존에 아이콘이 없어 텍스트 탭을 유지한다.
선택 탭: #F3C2BE 채움, #6B4A35 2px 외곽선, 기존 Jua 기반 굵기 보강(embolden 0.7).
비선택 탭: #FFFDF8 채움, 같은 2px 외곽선. 호버만 #FBE0DC. 탭 높이 40, 좌우 패딩 16, 탭 사이 8은 유지한다.
