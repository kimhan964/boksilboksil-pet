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

## 구체적인 구매용 후보
- builds/purchase-small-20261008/BoksilboksilPet-0.33.2-Windows-Purchase.zip
- ZIP SHA256 7df02b94d4430b24dba6e358dbf27bc26c871e350390a448a2b5b0bb0426aefa
- 원본은 검증된 0.33.1 PCK이며 현재 main/pack manager/구매 검사와 구매 설정만 덮어써 compact 패키징. 의상 숨김·도토리·놀이 해금은 보존.
- 구매권한 0개/토끼1개/토끼+수달2개, 기본 토끼 차단, 미구매 다운로드·마운트·선택 거부, 만료, 다운로드 중 권한 회수, 만료 후 retry: PURCHASE_PACK_ACCESS PASS.
- 기존 COMMERCE_ACCESS_TESTS PASS, MENU_ORGANIZATION_FAILURES=0. MemoryState 및 mocked entitlements, 실제 결제/사용자 저장 초기화 없음.
- 실제 구매 계정 로그인과 실제 회수 서버응답의 end-to-end 검사는 미실시.

## 공개 전 남은 단계
- 아직 GitHub 공개 또는 홈페이지 구매 다운로드 URL 교체 없음. 기존 공개 0.33.1은 전체 동물 개발판이므로 구매용으로 안내하지 말 것.
- 구매용 ZIP의 업로드와 홈페이지 판매 다운로드 URL 교체를 현재 변경분에 대해 승인받아야 함 (게임/홈페이지 AGENTS.md의 배포 규칙).
- 공개 animal-packs URL은 아직 그대로 공개되어 있음. 현재 수정은 정식 게임의 다운로드·선택·실행 경로를 제한함. 파일 자체의 HTTP 접근제어가 필요하면 공개 자산 대신 서버 entitlement 검사 후 제공하는 private storage URL로 이전해야 함.
