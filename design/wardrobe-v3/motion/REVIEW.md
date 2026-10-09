# 의상 동작 인수인계 · 2026-10-09

## 최신 상태 · 16종 성체 미리보기

- 16종 × 3벌을 별도 네이티브 검수 실행에 연결했다. 지원 목록은 `scripts/wardrobe_motion_art.gd`, 실제 자산은 `assets/wardrobe-motion-v3/*/adult/manifest.json`.
- 공통: 걷기 60셀, 버둥거림 60셀, 대기, 들기/놓기 8구간 × 17셀, 해롱 4셀, 감정 4셀. 토끼의 대기와 원본 먹기/마시기는 기존 추가 은행 유지.
- 총 13,257셀. 네이티브 변환/누락 검사 172,560개, 실패 0. 상세 기록 `verified-preview.json`. 구조 검사 `tools/check_wardrobe_assets.py` 통과.
- 토끼 걷기 앞발 오류: 15/16개 밀도 높은 전신 원화로 60셀 교체. 앞발 부착 위치가 배 아래로 이동하는 원화는 제외. `docs/WARDROBE-PAW-CONTINUITY-2026-10-09.md` 참조.
- 너구리 니트가 표정에서 파란 조끼로 바뀌던 오류와 양 앞치마의 파란 주머니 누락은 재생성 후 적용.
- 각 종 원화와 걷기/버둥거림/들기 연결 접촉표를 확인했다. 수치 검사는 미학적 완성도를 보증하지 않는다. 빠른 팔다리 전환의 보간 윤곽은 정식 적용 전 추가 다듬기 대상이다.
- 검수 실행기는 완성된 manifest가 있는 모든 종을 표시한다. `-- --rabbit --style=apron`으로 수정된 토끼 앞치마부터 볼 수 있다.
- 공개 구매판은 업데이트하지 않았다. 새끼·가구·수면·일반 넘어짐 의상 및 공개 장착/해금은 미완료다. `preview_only=true` 유지.
- 웹 미리보기 소스: `C:/Users/rlagk/Documents/Codex/2026-10-09/wardrobe-site`. 게임 원본을 160px WebP로 내보내며 내용 해시로 캐시를 갱신한다. GitHub 소스 업로드와 웹 공개 여부는 최종 배포 기록을 확인한다.

## 아래는 토끼·고양이 단계의 이전 기록

## 현재 실행 범위

토끼·고양이 **성체 각 3벌**(조끼·니트·카페 앞치마)을 실제 Godot Pet/Motion/View로 연결한 별도 검수 실행. 공개 게임 설정과 사용자 세이브는 불변. 전체 적용/출시 완료가 아니다.

|동작|토끼|고양이|
|---|---|---|
|걷기|60셀, 기존 깡총걸음·착지|60셀, 현재 walk-v14 주기|
|대기|60셀|현재 게임처럼 1셀|
|버둥거림|60셀|60셀|
|들기·놓기·복귀|8구간 × 17셀|8구간 × 17셀|
|해롱 / 감정 표정|4 + 4셀|4 + 4셀|
|기본 당근 / 원본 물 마시기|각 60셀 후보|미제작|

토끼 1,332셀 + 고양이 795셀 = 2,127셀. VARCO로 만든 전신 키 그림을 오프라인 RIFE로 연결했다. 60장 독립 생성이 아니다. 런타임 파츠 분리/팔 덮개/크로스페이드 없음.

## 검증과 수정

- tests/wardrobe_motion_native.gd: 좌우 60셀, 대기, 들기, 버둥거림, 낙하/해롱/복귀, 네 표정을 실제 게임 렌더러로 검사.
- 실제 Pet.begin_pointer/move_pointer/release_pointer/advance_frame으로 4초 들기 및 7초 복귀 연속 재생. 실제 데스크톱 x 이동도 검사.
- 원본 보정 데이터, 변환행렬(캔버스 여백 보정 포함), 배율·루트 일치, 지원 동작의 의상 누락 없음, frame_mix=0 검사.
- 결과: builds/wardrobe-v3-native/{rabbit,cat}/report.json 및 *.png. *-pointer.png는 실제 포인터 연속 재생 캡처. 토끼 12,135개 / 고양이 10,695개 조건 검사 실패 0.
- 키 시트, 60셀 접촉표, 네이티브 캡처에서 짧고 둥근 앞발이 옷 앞에 보임을 확인했다. 자연스러움은 계속 시각 검수할 대상.
- 최초 물 마시기 3키 보간은 고개 겹침으로 교체. 현재 eat/drink는 *-meals-generated.png의 8키 수정본.
- 고양이 hold 꼬리 잘림 수정: 320px 셀에 32px 여백 추가, 표시 원점에서 같은 양 보정. 몸을 작게 줄이지 않음.
- .godot/extension_list.cfg에서 이전 빌드 폴더의 MousePassthrough 중복 등록 2개만 제외. 실제 플러그인/배포 폴더 불변. 캐시 재생성 시 재확인.

## 미완료 범위

다른 14종, 모든 새끼, 가구, 수면, 일반 넘어짐(slapstick), 고양이 식사 의상은 미제작. 공개 옷장/저장/해금과 새 의상 연결도 미완료. manifest preview_only=true 유지.

토끼 먹기/마시기는 원본 해당 파일을 사용하는 경로만 매칭한다. 식탁·컵·다른 음식의 다른 원화를 대체하지 않는다. 검수 런처는 산책/마우스 상호작용 중심이며 가구를 생성하지 않는다.

## 구현과 실행

- scripts/wardrobe_motion_art.gd: 현재 선택 종/한 의상만 캐시하고 prewarm. 지원 종 0/8 성체.
- desktop_pet_view.gd: 원본 CharacterSize/동작/루트 계산 후 마지막에 전신 의상 셀로 표시만 교체.
- testing/wardrobe_v3=true + motion metadata wardrobe_v3_style로만 활성화. 옛 outfit_style 저장 ID와 별개.
- outfit_layer.gd: 새 의상 셀이 표시되면 구 옷 레이어 생략. 구 v1/v2 자산으로 누락을 메우지 않음.
- assets/wardrobe-motion-v3/{rabbit,cat}/adult/manifest.json: 런타임 자산.
- 생성 기록: varco-apply-jobs.json, varco-meals-jobs.json, varco-cat-jobs.json.
- design/wardrobe-v3/motion/launch.gd: 별도 네이티브 검수 런처. 기본 고양이, 패널에서 토끼·고양이/3벌 선택. 실제 마우스 들기/놓기. MemoryState로 세이브 불변.
- 실행: Godot --path <프로젝트> --rendering-method gl_compatibility --script res://design/wardrobe-v3/motion/launch.gd
- 검사: Godot --script res://tests/wardrobe_motion_native.gd (고양이는 -- --cat 추가)

## 다음 작업

1. catalog-plan.json의 승인된 짧은 앞발 파일 사용. 긴 팔 v2 및 반려된 중간안 금지.
2. 현재 종의 원본 atlas/시계/루트 보정을 읽고 동작별 전신 키 생성.
3. 앞발이 의상 앞에 유지되도록 검수. 보간 후 팔·꼬리·얼굴·색·경계 모두 확인.
4. 위 loader의 종 목록을 확대하고 동일한 네이티브 이동/포인터 검사 통과.
5. 모든 행동·성장 단계가 준비된 뒤 공개 옷장/해금 연결. 행동마다 벗겨지는 상태를 출시하지 않는다.
