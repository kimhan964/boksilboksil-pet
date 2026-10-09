# 0.33.3 구매 다운로드 인수인계

- 사용자 승인: “GitHub·홈페이지에 반영”. 게임 배포와 사이트 서버·다운로드 링크 교체 승인.
- 소형판 기준은 검증된 builds/purchase-small-20261008/0.33.2 PCK. 현재 구매 권한·계정 UI 스크립트를 명시적으로 덮어 담으며 기존 동물 원본과 저장 호환 유지.
- 빌드: tools/build_purchase_fix.py. 출력 builds/purchase-small-20261009. 공개 도구 tools/publish_purchase_fix.py. 새 태그 v0.33.3-purchase.20261009. 이전 릴리스 덮어쓰기 없음.
- 계정 창: force_native=true, transient=false, 480×260, 기본 앱 테마, 중앙 배치. 실제 최종 EXE에서 안내문과 세 버튼 잘림 없음 확인. 검수 실행시 보이는 창으로 실행할 것. 숨김 시작 옵션으로 UI 검수를 하지 말 것.
- 공식 추가팩 경로: authorize_pack → /api/game/pet-pack → /api/game/pet-pack/file. 서버/클라이언트 모두 종별 권한 재확인, 클라이언트 크기·SHA256 대조, 다운로드중 권한회수 차단. 저장된 파일만으로 이용권 부여하지 않음.
- 사이트 체크아웃: C:/Users/rlagk/Documents/Codex/2026-09-23/mbti/purchase-download-0332. 운영 소스 b0cb4a7dd0023c1d9b1ee21fd5d20a7451cbb7ac에서 변경. 예전 다른 체크아웃 배포 금지.
- 검사: 서버 68개 PASS; Worker 빌드 PASS; candidate PCK purchase_pack_access_test PASS, 원본 프로젝트 밖 candidate 폴더에서 실행. 네이티브 테스트 480×260 창 및 실제 EXE 화면 확인. 실제 결제/실사용자 정보 변경 없음.
- 제한: 역사적 GitHub 공개 pack 자체는 기존 직접 주소로 접근 가능. 엄격한 원본 파일 접근 차단에는 private storage 이전과 과거 공개 자산 처리가 별도 필요.
- 다른 진행중 변경: MENU-ORGANIZATION-HANDOFF-2026-10-08.md 및 함께하기 아이콘 등 별도 로컬 변경을 이 배포에 섞지 않음. 기존 16종 설명 download-link-033-local 작업도 보존.
