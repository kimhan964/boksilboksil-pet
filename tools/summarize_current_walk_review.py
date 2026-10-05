"""Consolidate measured native captures and explicitly recorded visual findings."""
import json
from pathlib import Path
ROOT=Path(__file__).resolve().parents[1]
OUT=ROOT/'design/walk-v12/live-swing-audit-2026-10-04'
TITLE=ROOT/'docs/MOTION-DETAIL-REVIEW-2026-10-04.md'
names={'bear':'곰','fox':'여우','otter':'수달','owl':'부엉이','penguin':'펭귄','raccoon':'너구리','squirrel':'다람쥐'}
findings={
('bear','adult'):(1,'0~15 / 45~59','양쪽 발 회수 속도가 크게 다르고 몸 기울기·발 들림도 비대칭. 발0 전반 진행 88%, 발1 -14%로 한쪽은 뒤로 갔다 급히 따라오는 경로.','두 passing 전신 원화의 들린 발 위치·기울기·체중 이동을 함께 수정.'),
('owl','adult'):(1,'30~45 / 45~59','한쪽 발의 전반 진행이 13%에 머물러 후반에 몰린다. 작은 발의 이동보다 몸 흔들림이 두드러진다.','발을 앞으로 통과시키는 중간 전신 자세를 보완하고 몸 기울기와 착지 시점을 맞춤.'),
('fox','baby'):(1,'전체 주기, 특히 보폭 전환','현재 적용본은 머리 상대 변동 2.39px, 심한 느림 구간 약 1.06%. 양발 보폭 차이와 주황색 변화도 남음.','별도 새 후보의 짧은 보폭·머리 변동 개선을 유지하면서 양쪽 중간 자세의 색을 맞춘 뒤 재검수.'),
('otter','adult'):(2,'4~5, 20~28, 52 전후','성체 발끝에 작은 색 잔상이 있고 발 모양이 착지까지 납작하게 바뀐다. 둥근 몸은 유지되지만 몸·꼬리 반응은 단순하다.','발끝 윤곽과 착지 전 중간 자세 보완. 지지 발 고정과 전신 체중 이동을 함께 검수.'),
('otter','baby'):(2,'15 전후 / 45 전후','양쪽 발 들림이 약 3.60/1.96px로 다르다. 지지 발의 세로 변동 약 0.98px가 남는다.','한쪽 낮은 발 들림과 접지 높이를 수정하고 성체와 털색 비교.'),
('raccoon','adult'):(2,'11~15, 37~53','발 회수 중 짧은 역행 경고. 다른 발은 37~53에서 검은 발바닥이 정면으로 크게 드러나며 발 회전이 과장되어 보인다.','원근에 맞는 발바닥 각도와 전신 중간 자세를 다시 생성.'),
('squirrel','adult'):(2,'19~27, 51~57','큰 멈칫함은 줄었으나 착지 과정에서 발끝 폭과 둥근 모양이 변한다. 꼬리와 상체의 후속 반응은 약하다.','착지 직전 발 윤곽과 몸통·꼬리 반응을 보완.'),
('squirrel','baby'):(2,'30~45 / 45~59, 19~26, 51~57','한 발이 전반에 80%를 이동한 뒤 후반에 느려진다. 착지 중 발끝 형태 변화도 남는다.','통통한 체형·색을 유지하면서 발 회수 중간 위치와 착지 전 자세 수정.'),
('fox','adult'):(2,'15 전후 / 45 전후','발 회수 진행은 상대적으로 균형 있으나 들림 약 4.09/2.56px로 비대칭. 상체와 꼬리 반응·털색 일치 보완 필요.','전신 체중 이동과 양발 들림 균형, 원화 간 색 일치 검수.'),
('penguin','adult'):(3,'전체 주기','발 회수 진행과 들림은 비교적 고르다. 날개·몸통 반응이 작고 목도리 톤 확인이 남는다.','작은 뒤뚱거림의 체중 이동과 장식 색을 보완한 뒤 최종 시각 재검수.')
}
audit=json.loads((OUT/'live-swing-timing.json').read_text('utf8'))
native={};total=0
for direction in ['right','left']:
    validation=json.loads((OUT/direction/'validation.json').read_text('utf8'))
    assert validation['banks']==10 and not validation['failures']
    total+=validation['captures']
    native[direction]={(b['species'],b['stage']):b for b in json.loads((OUT/direction/'head-motion-review.json').read_text('utf8'))}
rows=[]
for b in audit['banks']:
    key=(b['species'],b['stage']);priority,frames,problem,fix=findings[key]
    both=[native[d][key] for d in native]
    rows.append(dict(species=key[0],stage=key[1],priority=priority,frames=frames,problem=problem,next_fix=fix,
        head_range_px=max(v['head_offset_range_px'] for v in both),
        slow_fraction=max(v['slow_window_fraction'] for v in both),
        silhouette_height_px=[min(v['vertical_review']['body_bbox_height_range_px'][0] for v in both),max(v['vertical_review']['body_bbox_height_range_px'][1] for v in both)],
        maximum_support_drift_px=max(s['horizontal_drift_px'] for s in b['supports']),
        maximum_support_vertical_px=max(s['vertical_drift_px'] for s in b['supports']),
        sha256=b['sha256'],swings=b['swings']))
summary=dict(date='2026-10-04',native_captures=total,reviewed_banks=10,reviewed_cels=600,
    naturalness_approved=False,method='600 complete atlas cels and sole crops viewed; 6700 native rendered captures numerically checked; selected native phase/stop boards visually checked; installed bear adult selected and displayed. Continuous normal-speed video viewing is not claimed.',
    rows=rows)
(OUT/'detailed-summary.json').write_text(json.dumps(summary,ensure_ascii=False,indent=2),encoding='utf8')
lines=['# 걷기 모션 상세 점검 — 2026-10-04','',
'## 결론','',
'**현재 걷기는 자연스러움 최종 통과 보류.** 발 회수 경로·발끝 형태 변화·체중 이동의 불균형이 남아 있다. 곰과 부엉이, 여우 새끼부터 수정한다.','',
'## 이번에 실제 확인한 범위','',
f'- 현재 적용된 새 걷기 10개: 수달·다람쥐·여우 새끼/성체, 너구리·곰·부엉이·펭귄 성체.',
f'- 각 60장, 총 600장 전신과 발 확대판을 시각 확인. 현재 자산 해시와 발 추적 자료가 일치하는지 검사.',
f'- 실제 Godot D3D12 게임 재생을 새로 실행: 오른쪽 3,350장 + 왼쪽 3,350장 = **{total:,}장**. 시작→세 걸음→정지.',
'- 두 방향 모두 60개 프레임 관측, 빈 프레임·셀/창 경계 잘림·걷기 중 표시 배율 변화 없음.',
'- 실제 캡처의 대표 자세·정지 전환을 비교했고 설치된 점검판에서 곰 성체를 선택해 걷기 반복과 실제 표시를 확인.',
'- 정상 속도 연속 영상을 끝까지 시청한 검수는 미완료. 이번 판정은 프레임별 시각 비교와 실제 재생 캡처의 위치·시간 분석에 근거한다.','',
'## 동물별 수정 체크리스트','',
'프레임은 게임 재생 순서 0~59. 우선순위 1부터 수정하며, 아래 항목은 모두 미해결 상태다.','',
'| 우선 | 동물 | 다시 볼 구간 | 발견한 문제 | 다음 수정 |',
'|---|---|---|---|---|']
for row in sorted(rows,key=lambda r:r['priority']):
    label=names[row['species']]+' '+('새끼' if row['stage']=='baby' else '성체')
    lines.append(f"| {row['priority']} | {label} | {row['frames']} | {row['problem']} | {row['next_fix']} |")
lines+=['','## 수치 근거','',
'머리 상대 변동은 몸의 이동 기준점에 대한 윤곽 중심 변화다. 의도한 체중 이동·기울기도 포함하므로 떨림의 절대 점수로 해석하지 않는다. 발도 발끝 회전에 따라 윤곽 중심이 달라진다. 원화와 실제 화면을 함께 판단했다.','',
'| 동물 | 머리 상대 변동 px | 지지 발 가로/세로 변동 px | 표시 윤곽 높이 px |',
'|---|---|---|---|']
for row in rows:
    label=names[row['species']]+' '+('새끼' if row['stage']=='baby' else '성체')
    h=row['silhouette_height_px']
    lines.append(f"| {label} | {row['head_range_px']:.2f} | {row['maximum_support_drift_px']:.2f} / {row['maximum_support_vertical_px']:.2f} | {h[0]}~{h[1]} |")
lines+=['',
'윤곽 높이 변화는 자세 변화와 픽셀 경계도 포함한다. 표시 배율 자체는 일정하다. 관측된 반복 경계의 머리 가로 변화 최대 약 0.163px, 정지 경계 약 0.174px로, 이번 재생에서 큰 전환 튐은 잡히지 않았다.','',
'## 수정 방법과 통과 기준','',
'- [x] 현재 적용 자산과 검수 자료 일치 확인.',
'- [x] 좌우 시작·걷기·정지의 실제 게임 캡처와 공백·잘림·배율 확인.',
'- [x] 전신 600장과 발 확대판의 형태 변화 확인.',
'- [ ] 전신 원화의 발 들기→앞으로 통과→착지를 먼저 수정. 발별 이동을 한 구간에 몰지 않기.',
'- [ ] 발 위치와 함께 통통한 몸의 체중 이동·귀·꼬리 반응을 그리기.',
'- [ ] 발끝이 납작해지거나 발바닥이 갑자기 뒤집히는 중간 프레임 교체.',
'- [ ] 원화 사이와 새끼/성체 사이 털·배·장식 색 일치.',
'- [ ] 정상 속도 연속 재생으로 최종 체감 확인.',
'- [ ] 다른 행동·의상·상호작용으로 바뀔 때 크기와 체형 일치.',
'',
'한 주기 60장을 유지하되 원화 자세를 고친 뒤 보간한다. 프레임 수만 추가해서 통과 처리하지 않는다. 파츠 분리·몸통 늘이기 없이 완성된 전신 이미지로 제작한다.','',
'## 여우 새끼 미설치 후보','',
'forward-balanced 후보는 좌우 1,340장 별도 검수에서 머리 변동 2.39→1.29px, 심한 느림 1.06→0%, 양발 회수 전반 진행 약 54/51%로 개선됐다. 보폭도 짧아져 이동 속도가 약 7.9→4.7px/s로 달라졌다. 색 차이가 남아 설치하지 않았고 프로젝트 자산은 기존본으로 복원했다.',
'',
'후속 builtin 색 수정 원화는 대표색과 차이가 줄었지만 아직 60장 재제작·게임 검증 전이다. 기존 VARCO 실패 후보와 함께 출처를 보관한다. 계획 파일이 존재하는 것은 승인 의미가 아니다.','',
'## 전체 범위에서 남은 작업','',
'이번 상세 재생은 새 걷기 10개에 한정한다. 토끼 성체 승인본은 유지했고, 나머지 나이/종·다른 행동을 완료로 판정하지 않았다. 고슴도치, 고양이, 강아지, 햄스터, 판다, 레서판다, 양, 코알라와 미제작 새끼 단계는 계속 대기/재제작 상태다.',
'',
'기존 16종×새끼/성체×행동 정적 검사는 누락 확인 자료이며 움직임 승인 자료가 아니다. 물 마시기는 기존 조사에서 토끼 성체 외 31개가 sniff 대체였고, 별도 부엉이 성체 시범을 제외한 나머지 접촉·숙이기 개선도 남는다. 전체 진행표와 인수인계 범위를 유지한다.','',
'## 확인 자료','',
f"- [발 타이밍·전신/발 60장 자료](<{OUT.as_posix()}/README.md>)",
f"- [실제 재생 수치](<{OUT.as_posix()}/detailed-summary.json>)",
f"- [곰 실제 우향 재생 GIF](<{OUT.as_posix()}/right/bear-adult.gif>)",
f"- [부엉이 실제 우향 재생 GIF](<{OUT.as_posix()}/right/owl-adult.gif>)",
f"- [여우 새끼 후보 검수](<{(ROOT/'design/walk-v12/fox/baby/CONTACT-REBUILD-HOLD.md').as_posix()}>)",
'']
TITLE.write_text('\n'.join(lines),encoding='utf8')
status_file=ROOT/'design/all-animal-motion-review/status.json'
status=json.loads(status_file.read_text('utf8'))
status['last_goal_turn']='2026-10-04 detailed review: 10 live v12 banks, 600 complete cels visually inspected, 6700 fresh bidirectional native captures. No blank/clipping/scale errors. Naturalness not approved: bear/owl swing timing, fox baby hesitation, toe morphs and body response remain. Fox candidate1340 extra native captures improved motion but held for palette; original live assets restored. Builtin color candidate retained uninstalled. See docs/MOTION-DETAIL-REVIEW-2026-10-04.md.'
lookup={(r['species'],r['stage']):r for r in rows}
for row in status['rows']:
    key=(row['species'],row['stage'])
    if key in lookup:
        q=lookup[key]
        row['latest_detailed_review']={k:q[k] for k in ['priority','frames','problem','next_fix','head_range_px','sha256']}
        row['latest_detailed_review']['naturalness_approved']=False
        evidence=row.setdefault('evidence',[])
        for path in ['docs/MOTION-DETAIL-REVIEW-2026-10-04.md','design/walk-v12/live-swing-audit-2026-10-04/detailed-summary.json']:
            if path not in evidence:evidence.append(path)
status_file.write_text(json.dumps(status,ensure_ascii=False,indent=2)+'\n',encoding='utf8')
print(json.dumps({'report':str(TITLE),'captures':total,'banks':len(rows)},ensure_ascii=False))

