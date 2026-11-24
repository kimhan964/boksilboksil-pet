# 타자 모드 동물 원화 — 2026-10-06

내장 `image_gen`으로 15종 × 3장 = 45장 제작. 토끼의 기존 3장을 합해 게임에서 16종/48장을 사용합니다. 각 이미지는 1254×1254 RGBA 완전한 동물+키보드 그림이며 별도 발 파츠를 합성하지 않습니다.

## 파일

각 종 폴더의 `idle.png`, `left.png`, `right.png`. left/right는 **화면에서 눌리는 쪽**입니다. `generation-records.json`에 최종 요청문, 생성 원본 경로, 사용 경로와 다람쥐 재생성 이력을 보존했습니다. 잘못된 다람쥐 오른쪽 프레임은 설치하지 않습니다.

## 생성 순서

1. 기존 토끼 타자 그림과 이전 16종의 색/장식 참고표로 종별 대기 그림 생성.
2. 대기 그림 검수 후 해당 그림만 참조하여 왼쪽/오른쪽 누름 프레임 각각 생성.
3. 모든 캔버스 크기/투명도 확인, 게임 창에서 48장 캡처, 좌우 누름 방향 및 외곽 비교.
4. 표시 배율과 위치 고정. 입력 0.22초 주기, 타건 자세 0.17초, 나머지 대기 자세.

## 공통 편집 지시

Use case: precise-object-edit. Edit this production game sprite into exactly ONE alternate typing animation frame. Preserve the original square canvas dimensions and genuine transparent background, and preserve the entire round face, eyes, smile, blush, ears/head, accessory, torso, colors, outlines and keyboard silhouette/layout/perspective/position almost pixel-for-pixel. Only change the TWO short connected forelimbs in the small area directly above the keyboard. Keep the head, body, keyboard and camera completely stationary; no resizing, reframing or changing proportions.

원본 유지 대상: 얼굴, 눈, 볼, 귀, 목 장식, 몸통, 꼬리, 키보드, 구도, 투명 배경. 양은 발굽, 부엉이는 깃털 날개, 펭귄은 짧은 날개를 사용하며 이 세 종에는 분홍 발바닥을 만들지 않습니다.

## 검수

- 16종/48장 모두 1254×1254, 알파 0~255.
- 16종의 4,800개 입력 샘플: 위치/배율/회전 고정, 세 자세 재생, 입력 종료 후 대기 복귀 통과.
- 불투명 외곽 경계의 대기 대비 최대 차이: 원본 2px (게임의 200px 캔버스에서 약 0.32px).
- 상단 절반을 200px로 표시했을 때 RGB 평균 차이: 0.67~1.66/255. 이미지가 완전히 동일한 픽셀인 것은 아닙니다.
- Godot D3D12 렌더 캡처: `builds/typing-review/all-art/poses-{1,2}.jpg` 및 `all-16.jpg`.
- 이 검사는 타자 모드 전용입니다. 생활 모드의 기존 걷기/상호작용 원화를 교체하지 않습니다.
