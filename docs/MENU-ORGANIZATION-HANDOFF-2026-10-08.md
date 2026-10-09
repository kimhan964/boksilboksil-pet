# 메뉴 정리 인수인계 · 2026-10-08

- 함께하기: 놀이감 꺼내기(38), 마우스 따라오기(23), 함께 놀기 안내(39). 실뜨개 공과 리넨 생쥐를 꺼내 실제 클릭/드래그/동물 놓기로 상호작용.
- 집 꾸미기: 가구 배치(32), 활동 공간(33). 가구 목록에는 놀이감 2종 제외. 식탁·놀이 러그·자명종은 가구로 유지.
- 식탁 준비: 음식 선택. 생활 기록: 목표·성장·취향·해금 카드. 공통 가구 버튼과 다른 탭의 해금 카드 제거.
- 의상/옷 색상 선택은 화면에서 숨김. 집 꾸미기에 “의상은 추후 업데이트 예정이에요.” 안내. 저장된 의상·가구·성장·구매권한 유지.
- main.activity의 구 행동 차단 목록에서 23 제거: 버튼이 표시되어도 마우스 따라오기 시작이 차단되던 문제 해결.
- 놀이감/가구는 같은 furniture_room 데이터와 배치 로직을 공유하며 open("toys")/open()으로 목록만 분리. 분류 변경 시 저장 데이터 삭제 금지.
- 실제 수정 설치: C:/Users/rlagk/Documents/복슬복슬펫/0.33.0-small-preview/DesktopFriends.pck. 같은 폴더 EXE 사용. LATEST-RUNTIME.json의 새 해시 확인.
- installed PCK에서 tests/menu_organization_test.gd headless 및 native GL PASS(0 failures). MemoryState로 사용자 저장에 쓰지 않음. 4개 탭 및 두 배치 창 렌더 PNG는 builds/menu-organization-review-20261008. 물리 마우스 수동 조작 전체 검사는 미실시.
- hotpatch journal 4개: menu-organization, menu-follow, menu-toy-panel-20261008, menu-layout-20261008. 기존 스냅샷 build_small_packs build 시 scripts 전부 overlay되므로 현재 소스 포함. 공개 GitHub ZIP에는 아직 미반영, 로컬 최신만 수정.

- 놀이감 창 440px, 지연 컨테이너 크기 갱신으로 닫기 버튼 잘림 수정. 테스트에 닫기 버튼 창 내부 경계 검사 추가 PASS.

## 도토리 오뚝이·놀이 해금 추가
- 생성 원본 assets/decor-cozy-v2/acorn-wobble-v2.png, 프롬프트는 같은 폴더 acorn-wobble-v2-PROMPT.md. builtin image_gen, 실뜨개 공/장난감 바구니 참조. 런타임 decor_art는 v2만 읽고 알파 영역으로 crop 후 기존 고정 배율/전체 흔들림 마스크 유지.
- 함께하기에 기본 도토리 오뚝이·마우스 산책·러그 놀이, 교감4 실뜨개 공, 교감10 생쥐 따라잡기의 그림/놀이 방법/해금 상태/현재 및 남은 교감 추가. play_catalog.gd의 표시 내용은 실제 State.unlocked 판정과 공유.
- 함께하기 놀이감 창에서 도토리 꺼내기/치우기. 기존 props.acorn 하나 사용, 별도 가구 복제 생성하지 않음. state.hidden 저장 유지, 꺼내기 시 기본바닥 접지 및 기존 도토리 방문 상호작용 유지. 러그 배치는 집 꾸미기에 유지.
- 기존 해금 요구값 변경 없음, 진행 점수 차감 없음. 새 의상 기능 추가 없음.
- installed PCK native GL 테스트 PASS: 도토리 보이기/치우기/방문, 공4/생쥐10 경계 판정,181각도 도토리 alpha hull 전체 고정native마스크 안에 포함, UI 렌더/닫기버튼 범위. 별도 MemoryState, 사용자 저장 미초기화.
- screenshots builds/acorn-play-review-20261008. 빌드 스냅샷에 새 PNG가 없으므로 build_small_packs.py common overlay에 새 자산 명시적으로 추가; 다음 패키징 누락 방지. 빌더 Python compile PASS, 전체 재패키징은 미실시.
- 추가 hotpatch journals acorn-play-unlocks-20261008, acorn-review-20261008. 로컬 최신 PCK 반영, GitHub 미업로드.

## GitHub 공개 완료 · 2026-10-08
위의 미업로드 설명은 개발 중 기록입니다. 이번 요청으로 메뉴 정리·도토리·놀이 해금 안내가 0.33.1 새 미리보기 릴리스에 공개되었습니다.
- 릴리스: https://github.com/kimhan964/boksilboksil-pet/releases/tag/v0.33.1-preview.20261008
- 다운로드: https://github.com/kimhan964/boksilboksil-pet/releases/download/v0.33.1-preview.20261008/BoksilboksilPet-0.33.1-Windows-Small.zip
- 소스 커밋: 827545fc8b260d7c3cd299990438e77448ba5dab
- ZIP: 189977243 bytes, SHA256 409bafa9461fb260e0e3b7b5d9ecba0125f989767e9199c95e54c1f44ddce107
- 공개 PCK SHA256: 14be51bbad3293646acf1f0f74d727fa72edb456d028f7d3033230defe224f4a
- 최신 설치 PCK를 압축 정리한 파일: 모든 리소스 MD5 검증 및 변경 스크립트/신규 PNG의 원본 바이트 일치 확인. 현재 설치와 공개 PCK의 리소스 내용은 같고 PCK 구조/해시는 다름.
- ZIP CRC/포함 PCK 해시/소스커밋 검증, 공개용 PCK에서 native menu_organization_test 및 headless toy_play_test PASS. GitHub 업로드 크기·SHA256 검증, 공개 태그 커밋 검증, 익명 실제 다운로드 ZIP 헤더 확인.
- 기본 토끼 소형판만 새 업로드. 기존 15종 추가 팩 URL·해시 유지; 이전 공개 자산 덮어쓰기 없음.


## 함께하기 아이콘·넘어지기 확인 · 2026-10-09
- 버튼 38/23/39 아이콘을 각각 장난감 상자, 커서와 발자국, 펼친 안내책으로 분리. assets/ui-cozy-v1/play-toys.png, cursor-follow.png, play-guide.png. 생성 프롬프트는 play-actions-prompts.json.
- 탭 가로 여백을 줄여 아이콘이 점처럼 축소되던 현상 수정. 세 행동의 아이콘은 같은 크기로 정규화. 글꼴·중앙 정렬·기존 버튼 ID 유지. build_small_packs.py에 새 PNG 3개 포함.
- 설치 실행 경로 재확인: 현재 사용자가 실행 중이던 것은 Downloads/BoksilboksilPet-0.33.2-Windows-Purchase/DesktopFriends.exe. 과거 0.33.0 개발 설치를 최신으로 실행하지 말 것. 이 구매용 PCK에 위 UI 리소스 6개만 추가. 구매 권한 검사·저장·동물 동작 코드 변경 없음. 같은 폴더 LATEST-RUNTIME.json 해시와 hotpatch journal 참조. GitHub 미업로드.
- 설치 PCK native GL menu_organization_test PASS, exit 0. 실제 440px 메뉴 렌더에서 서로 다른 아이콘, 글씨 정렬, 탭 표시 확인. builds/ui-play-review-20261009/menu-together.png.
- 넘어지기 자료는 누락 아님. 소스 16종 × 새끼/성체에서 자동 trigger와 60프레임 로딩 PASS(tests/slapstick_auto_test.gd). 실제 원래 수달 native 화면에서 5개 구간 캡처 및 걷기 복귀 PASS(tests/slapstick_auto_native.gd). 이 검사는 대기시간을 0으로 줄여 자동 발생 조건을 확인한 검사이며 일반 플레이 빈도를 검증한 것은 아님.
- 런타임 초기 대기 50초, 이후 재채기/넘어지기 공통 90~150초. 자유 걷기 1.2초 이상, 목표까지24px 초과, 발 접지, 욕구30 이상 필요. 가구 이용·쉬기·잡힘·추가 의상 중 발생하지 않음. 현재 저장 의상은 전종0. 구매용 slapstick.gd와 소스 동일 확인.
- 앞서 띄운 otter-cute-master-v1/motion_pilot.tscn은 autonomy=false/resting=true로 걷기만 검수하므로 넘어지기가 안 나옴. 일반 게임 실행으로 대체할 것. 사용자 보고 당시 모든 실행 상황의 유일한 원인이라고 단정하지 말 것.
- 소스 테스트는 기존 MousePassthrough 중복 등록 오류와 exit1이 동반되지만 테스트 assertions PASS. 구매용 설치 UI 검사는 오류 없이 exit0. 전체 16종의 넘어지기를 눈으로 모두 검수했다는 의미는 아님.

## 사용자 검수 실행 기본값 변경 · 2026-10-09
- 사용자는 구매 계정 연결 화면이 아니라 전체 동물을 확인할 수 있는 실행을 요청함. 이후 사용자 검수용 실행 요청에는 design/local-full-review/launch.gd를 실행할 것.
- 이 로컬 전용 진입점은 commerce=false/testing.unlock_all=true, 정상 자동 행동 활성 상태. 16종 선택 및 가구·놀이 해금 확인용. friends-local-full-review.json 별도 저장을 사용하며 최초 실행에만 기존 저장을 복사.
- 실행 바로가기: C:/Users/rlagk/Documents/복슬복슬펫/전체 동물 검수용.lnk. 원래 구매용 배포 코드·계정 권한은 유지. 이 개발 진입점을 구매 배포에 포함하지 말 것.
- 실행 로그 확인: LOCAL_FULL_REVIEW species=16 commerce=false unlocks=true autonomy=true. 기존 소스의 MousePassthrough 중복 등록 로그는 남아 있음.

## 넘어짐 시간·목표 해금 메뉴 · 2026-10-09 후속
- 사용자 지정 시간: slapstick INITIAL_COOLDOWN=30초, REPEAT_COOLDOWN=60~90초. 재채기와 공유하는 기존 타이머이며 접지/자유걷기/돌봄 상태 조건 유지. 30초마다 강제로 넘어지는 설정이 아님.
- 네 번째 탭을 목표·해금으로 변경. 다음 목표, 합산 교감, 행동별 적립 방법을 상단에 배치하고 아이템별 이미지/해금 조건/현재 교감/남은 교감/진행바 표시. 성장·기존 상세 안내 버튼은 아이템 목록 뒤로 이동.
- unlock_rows에 earned를 별도 제공: 검수용 open=true여도 실제 조건 달성량과 다음 목표 유지. 이미 소유한 가구는 earned로 유지. 기본 제공과 잠금 아이템을 구분하며 기존 해금 수치와 저장 구조는 유지.
- native menu_organization_test assertions 0 failures: 일반3/4, 정확히4달성, 다음목표이동, 검수용3/4 표기 확인. menu-goals-unlocks.png 실렌더 확인(440x646, 탭/글씨/그림/하단버튼). slapstick_test PASS: 초기30/반복60~90, 행동 복귀, 잡힘/가구 동작 보호. 소스 실행의 기존 MousePassthrough 중복등록 로그/exit1 별개로 남아 있음.
- 최신 반영은 소스 전체동물 검수용 진입점. 구매 ZIP/PCK와 GitHub에는 이번 목표·시간 변경을 아직 반영하지 않음. 검수용 실행에 -- --show-goals를 붙이면 목표 탭이 열림.

## 토끼 착지·접지 시간 수정 · 2026-10-09
- rabbit_hop_motion: 기존 착지 회복(약0.18초)에0.16초 추가, 마지막 접지 자세0.12초 유지 후 다음 준비 동작. 기본 주기1.0→1.28초. 착지부터 다음 이륙까지 약0.30→0.58초(주기 미세 변화 포함). 비행 시간/높이/보폭/60장 원본/채도·크기 유지. 접지 시간을 추가했으므로 평균 이동 속도는 약22% 감소.
- 이미지 재생·루트 수평 이동·높이 모두 같은 시간 매핑 사용. 마지막 도착 때도 회복·접지 구간이 끝나야 idle 전환.
- rabbit_hop_test PASS: 연속2주기 이상 접지0.5초 이상·접지 중 위치고정, 새끼/성체30·60·144fps. rabbit_desktop_travel_test 18cases PASS(160px도착/방향/중단 후 반대방향). 의도한 주기 증가에 맞춰 도착 검사 허용시간9→12초.
- native rabbit_contact_native_review 실제 게임 뷰포트 캡처: 새끼·성체 좌우4경우, builds/rabbit-contact-20261009/에 시간/phase/좌표 JSON과 연속화면. 새끼/성체 오른쪽 시트를 눈으로 확인. 소스의 기존 MousePassthrough 중복등록 오류는 별도 유지.
- 전체동물 검수용 소스 실행에 반영. 구매 패키지/GitHub는 이번 변경 미반영.

## 2026-10-09 · VARCO 의상 대표 원화

- 사용자 승인: 짧은 산책 조끼·니트·카페 앞치마 방향. 이후 VARCO MCP로 이미지 생성 요청.
- `design/wardrobe-v3/index.html`에 16종 × 3벌 = 48개 대표 디자인 정리. 승인 토끼 3벌은 기존 builtin 생성, 나머지 15종 45벌은 VARCO MCP 생성.
- 최종 노드·프롬프트·출력 URL은 `design/wardrobe-v3/varco-jobs-current.json`, 파일 해시 `asset-report.json`, 시각 검수·후속 제작 조건 `REVIEW.md`.
- 현재 정지 컨셉 시트만 생성됨. 투명 스프라이트, 성장별 의상, 애니메이션 피팅, 장착 UI, 구매판 패키징은 적용하지 않음. 게임 적용 완료로 오인하지 말 것.
- 원래 동물 및 움직임 파일은 보존. 구 의상 레이어를 단순 재활성화하지 말 것. 구매/배포 정책 변경 및 GitHub 업로드 없음.
