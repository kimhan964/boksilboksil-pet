# 선물 이용권 연결 · 2026-09-11

사이트는 `C:/Users/User/OneDrive/Documents/심야식당/your-mbti`다. 결제·운영 절차는 해당 프로젝트의 OPERATIONS.md에 기록했다.

scripts/commerce_access.gd가 기기 코드 로그인과 서버 이용권을 확인하고, main.gd는 commerce/enabled 설정이 켜진 패키지에서만 받은 동물 선택을 허용한다. 기본 project.godot과 개발용 빌드는 기존대로 유지했다.

tools/package_commerce.gd는 지정 사이트를 사용하는 별도 DesktopFriends-Commerce-0.11 폴더에 PCK를 작성한다. 기존 실행 파일을 함께 복사했다. 이름의 0.11은 최초 연결 시점이며 현재 작업 트리의 게임 자료를 포함한다. 현재 게임 개발 작업과 병행하므로 고객 출시 전 게임 담당자의 플레이 검증이 필요하다.

서버는 live/active/paid 이용권만 내려준다. 45초 재확인·최대 60초 유효 시간이며 온라인 사용이 필요하다. 연결 해제·환불·네트워크 오류 시 동물을 숨기되 친밀도를 지우지 않는다. 오프라인 방식은 아직 확정하지 않았다.

컴파일 검사, tests/commerce_access_test.gd, tests/commerce_package_test.gd를 통과했다. 외부 결제·배포 서버·실제 게임 플레이는 검증 전이다. 이 패키지는 검토용이며 판매 시작을 의미하지 않는다.
