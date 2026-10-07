# 타자친구 액세서리 인수인계 · 2026-10-07

## 최신 교체: 복슬복슬메이트 / GPT Image 2.5 Flare

### 추가 5종 (총 액세서리 14종)

동일 VARCO 워크플로와 GPT Image 2.5 Flare, 토끼 원화 + 승인된 베레모 재질 참조를 사용한다. 새 생성 기록은 `assets/accessories-varco-v2/source/new-five-records.json`.

| ID | 이름 | 누적 입력 | 활동 시간 |
|---|---|---:|---:|
| friedegg | 반숙 프라이 핀 | 2,500 | 14분 |
| mushroom | 말랑 버섯 모자 | 4,500 | 25분 |
| headphones | 나만의 미니 헤드폰 | 6,000 | 35분 |
| teacup | 머리 위 티타임 | 8,500 | 50분 |
| sleepcap | 꾸벅 줄무늬 수면모자 | 9,500 | 55분 |

프라이는 귀 옆 핀, 나머지는 머리 위 미니 소품으로 장착한다. 헤드폰은 펫의 양 귀를 감싸는 장비가 아니라 머리 위에 얹는 작은 헤드폰 형태의 장식이다. 기존 저장·해금 ID를 유지하고, 임계값을 이미 달성한 유저는 신규 선물을 받을 수 있다.

추가 5종 착용 검수: `tests/accessories_review.gd -- --new-five`, 결과 `builds/review/accessories-new-five-0.png`, `accessories-new-five-1.png`.

- 사용자 지시: 납작한 아이콘 느낌을 줄이고, 코믹하면서 실제 소품처럼 보이는 형태·재질로 개선.
- VARCO MCP의 동일 워크플로에서 `gpt-image-2.5-flare`로 9종 재생성. 초안의 GPT Image 2 결과는 채택하지 않았다.
- `assets/accessories-varco-v2/`: 리본, 삐에로 모자, 왕관, 베레모, 마법사 모자, 새싹, 클로버, 데이지, 별. 원본은 `source/`, 생성 노드·프롬프트·URL은 `generation-records.json`.
- 먼저 베레모를 토끼·여우·고양이에 씌워 비교한 뒤, 그 이미지를 다른 8종의 재질 참조로 연결했다.
- 기준: 코코아 윤곽선, 세이지·로즈·크림, 비대칭으로 처진 형태, 봉제선·원단 주름·금속 굴곡. 작은 화면에서는 미세 질감보다 형태와 음영이 먼저 읽혀야 한다.
- VARCO 원본의 흰 배경은 `tests/import_accessories.gd -- --folder=res://assets/accessories-varco-v2/ --ids=...`로 외곽 연결 영역만 투명화했다. 원본은 알파 PNG가 아니다.
- `pin.gd`가 v2 9종을 읽는다. 기존 해금 ID와 저장 데이터는 유지한다. 핀 너비 30px, 모자 최대 너비 50px / 높이 42px로 화면 잘림 방지.
- `tests/accessories_review.gd`: 실제 보정된 펫 색상으로 16종 × 9개 = 144개 착용 조합 렌더 및 캔버스 경계 검사 통과. `tests/check.gd -- --capture` 저장·장착·설정 입력·크기 검사 통과.
- 검수 이미지: `builds/review/accessory-pilot.png`, `accessories-0.png`, `accessories-1.png`. 이전 v1 원본은 비교·복구용이며 런타임은 v2 사용.

사용자 최신 방향: 전신 의상은 제작하지 않는다. 기존 펫 원화를 유지하며 머리·귀 액세서리와 특이한 코스튬을 늘린다.

## 제작

- VARCO MCP의 `타자치는 펫` 워크플로 `44a1d43a-43ca-4d63-93ad-a6b85c3b3f94`에서 직접 생성.
- 모델 `gpt-image-2-medium`, 기존 토끼 idle을 스타일 참조로 사용. 프롬프트·노드 ID·다운로드 URL은 `games/typing-pet/assets/accessories-varco-v1/generation-records.json`.
- 로즈 리본, 삐에로 모자, 작은 왕관, 세이지 베레모, 달빛 마법사 모자, 새싹 핀 총 6종. 기존 리본 벡터를 생성 이미지로 교체했고 나머지 5종을 새 보상으로 추가했다.
- VARCO 원본은 RGB이며 체크무늬가 그려져 있었다. `source/`에 보존하고 `tests/import_accessories.gd`로 외곽에 연결된 중성 밝은 배경만 투명화했다. 원본을 알파 이미지라고 오인하면 안 된다.
- 작은 화면에서 선이 흔들리지 않도록 런타임 mipmap과 선형 필터를 사용한다.

## 적용

- 기존 `pin` 저장 슬롯 재사용. 액세서리 1개와 색상 1개를 동시에 장착한다. 저장 형식과 기존 해금을 유지한다.
- 핀은 기존 `Catalog.PINS`, 모자는 별도 `Catalog.HATS`의 동물별 정수화되지 않은 고정 좌표를 사용한다.
- 프레임 전환 중 얼굴·몸·액세서리 크기를 바꾸지 않는다. 화면 크기 설정만 전체를 함께 확대한다.
- 모자까지 마우스 입력 영역에 포함하여 모자를 잡아도 펫을 이동할 수 있다.
- 꾸미기 썸네일과 선물 상자에도 동일한 생성 이미지를 사용한다.
- 의상 슬롯이나 몸에 걸치는 옷은 추가하지 않았다.

## 해금 (누적 입력과 활동 시간 모두 충족)

| 액세서리 | 입력 | 시간 |
|---|---:|---:|
| 로즈 리본 | 60 | 15초 |
| 새싹 핀 | 500 | 3분 |
| 베레모 | 1,200 | 7분 |
| 삐에로 모자 | 2,000 | 12분 |
| 작은 왕관 | 4,000 | 20분 |
| 마법사 모자 | 7,000 | 40분 |

## 확인

- `tests/check.gd`: 저장·해금·장착·48개 타자 셀·설정 입력·이동·크기 유지 검사.
- `tests/accessories_review.gd`: 6종 × 16마리 = 96개 착용 조합 렌더, 알파 및 화면 잘림 검사. 결과 `builds/review/accessories-0.png`, `accessories-1.png`를 육안 확인.
- 설정 버튼 관련 추가 원인: Main._ready에서 기본 Window에 UI를 붙일 때 부모 초기화 중 add_child 실패. `start_game.call_deferred()`로 시작 순서를 수정했다. 실제 시작 경로 `--startup-check`도 검사한다.
- Windows 실제 마우스 클릭 자동화는 도구 초기화 오류 때문에 검증하지 못했다. Godot 입력 주입 검사를 OS 클릭 검증으로 표기하지 않는다.
