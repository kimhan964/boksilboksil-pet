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
