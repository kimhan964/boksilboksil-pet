# 구매 동물 제한 수정 · 2026-10-08

## 확인한 원인
- 공개 0.33.0/0.33.1 소형판 project.godot에는 [commerce]가 없어서 main._ready가 개발용 전체 동물 흐름으로 실행됨.
- 기존 서버 server/game-access.js는 live paid active sale_entitlements의 animalIds만 반환함. 클라이언트 commerce_access는 이 목록과 60초 검증 유효기간을 검사하지만 공개 소형판에서 해당 기능이 켜지지 않았음.
- animal_pack_manager는 구매권한 자체를 검사하지 않아 호출자 실수 또는 캐시/기본 토끼 경로로 권한 확인을 건너뛸 수 있었음.

## 수정
- 구매용 project.godot commerce/enabled=true, site_url=https://boksilboksil.kr. 다운로드를 받았다고 동물 이용권을 주지 않음.
- main이 pack manager에 실시간 permits 콜백 전달. 구매 빌드에서 콜백이 없으면 모든 종 차단.
- available/ensure/local cached mount/start/retry/completion 단계 권한 검사. 기본 포함 토끼도 구매하지 않았으면 차단. 이미 mounted된 다른 종도 이용 불가.
- 권한 변경시 진행 중 다운로드 취소, pet/props/furniture 숨김, 장난감 상호작용 일시 중단. 재확인 후 허용된 동물만 선택 목록으로 복원.
- 다운로드 창의 인터넷 없이 이용 가능하다는 설명을 파일 캐시와 계정 이용권 확인으로 바로잡음.
- build_small_packs.py도 향후 기본 판매 빌드에 commerce 설정을 넣도록 변경. 원본 개발 project.godot는 유지.

## 공개한 구매 전용판
- builds/purchase-small-20261008/BoksilboksilPet-0.33.2-Windows-Purchase.zip
- ZIP SHA256 8c355f6072acc85399d28efa7a51947425d2c34029389c2c404c676dae9c8614
- 원본은 검증된 0.33.1 PCK이며 현재 main/pack manager/구매 검사와 구매 설정만 덮어써 compact 패키징. 의상 숨김·도토리·놀이 해금은 보존.
- 구매권한 0개/토끼1개/토끼+수달2개, 기본 토끼 차단, 미구매 다운로드·마운트·선택 거부, 만료, 다운로드 중 권한 회수, 만료 후 retry: PURCHASE_PACK_ACCESS PASS.
- 기존 COMMERCE_ACCESS_TESTS PASS, MENU_ORGANIZATION_FAILURES=0. MemoryState 및 mocked entitlements, 실제 결제/사용자 저장 초기화 없음.
- 실제 구매 계정 로그인과 실제 회수 서버응답의 end-to-end 검사는 미실시.

## 배포 완료 · 사용자 승인 후 진행
- GitHub: https://github.com/kimhan964/boksilboksil-pet/releases/tag/v0.33.2-purchase.20261008
- 다운로드: https://github.com/kimhan964/boksilboksil-pet/releases/download/v0.33.2-purchase.20261008/BoksilboksilPet-0.33.2-Windows-Purchase.zip
- 게임 릴리스 소스: 2e9a1d789f127f4c6c9727afc5c7687ceb5c4295. 원격 ZIP 크기/해시와 공개 다운로드 응답 검증 완료.
- 홈페이지 83번: b0cb4a7dd0023c1d9b1ee21fd5d20a7451cbb7ac, 환경 revision 6. Sites 배포 succeeded (2026-10-08 18:36 KST).
- 홈페이지 현재 소스는 C:/Users/rlagk/Documents/Codex/2026-09-23/mbti/purchase-download-0332. 오래된 release-footer-fix를 그대로 재배포하지 않는다.
- GAME_DOWNLOAD_URL은 구매 전용 0.33.2 ZIP. 홈페이지 신규 boksil-pet 전체 프로그램 주문 거부, 상점 펫 버튼은 gifts.html의 동물별 이용권으로 이동.
- 과거 전체 프로그램 결제 주문의 원래 계약/다운로드는 보존했다. 신규 동물별 상품과 다르다.
- 웹 결제/선물/환불 모형 검사 23/23 통과. 운영 브라우저에서 0.33.2 안내와 토끼 이용권 필요 문구, 펫 동물 고르기 링크와 동물 1종 카피 확인.
- 쉘 HTTP 검사는 403 응답으로 확인 불가했으나 실제 운영 브라우저는 정상 표시. 실제 구매 계정 로그인/실결제 검증은 미실시.
- 기존 로컬 실행 폴더 0.33.0-small-preview는 개발판으로 유지되어 있다. 구매권한 검사는 새 0.33.2 ZIP에서 수행할 것.

## 남은 범위
- 공개 animal-packs URL은 아직 그대로 공개되어 있음. 현재 수정은 정식 게임의 다운로드·선택·실행 경로를 제한함. 파일 자체의 HTTP 접근제어가 필요하면 공개 자산 대신 서버 entitlement 검사 후 제공하는 private storage URL로 이전해야 함.
