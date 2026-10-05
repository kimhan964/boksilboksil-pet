"""Measure contact drift in authored colored guide cels. No art generation."""
import argparse, json
from pathlib import Path
from PIL import Image


def audit(source, columns, rows, stride, display_scale):
    image = Image.open(source).convert('RGB')
    width, height = image.width // columns, image.height // rows
    count = columns * rows
    if count % 2 or width * columns != image.width or height * rows != image.height:
        raise ValueError('Expected an even number of complete equal cells')
    measurements = []
    for index in range(count):
        cel = image.crop((index % columns * width, index // columns * height,
                          (index % columns + 1) * width, (index // columns + 1) * height))
        red_support = index < count // 2
        points = []
        for y in range(height // 2, height):
            for x in range(width):
                r, g, b = cel.getpixel((x, y))
                selected = (r > g * 1.6 and r > b * 1.5 and r > 140) if red_support else (b > r * 1.4 and b > g * 1.15 and b > 140)
                if selected:
                    points.append((x, y))
        if not points:
            raise ValueError(f'No support-color pixels in cel {index}')
        floor = max(y for x, y in points)
        sole = [x for x, y in points if y >= floor - 3]
        contact_x = sum(sole) / len(sole)
        measurements.append(dict(index=index, support='red' if red_support else 'blue',
                                 sole_x=contact_x, sole_y=floor,
                                 screen_x=(contact_x + index / count * stride) * display_scale))
    halves = []
    for start in (0, count // 2):
        group = measurements[start:start + count // 2]
        changes = [group[i + 1]['sole_x'] - group[i]['sole_x'] for i in range(len(group) - 1)]
        screens = [item['screen_x'] for item in group]
        halves.append(dict(support=group[0]['support'], source_foot_steps=changes,
                           uniform_travel_contact_drift=max(screens)-min(screens),
                           backwards_only=all(change <= 0 for change in changes)))
    return dict(source=str(source), stride_source_pixels=stride, display_scale=display_scale,
                assumptions='First half red support, second half blue. Color-sole estimate requires visual review; not an anatomy or naturalness pass.',
                frames=measurements, halves=halves)


if __name__ == '__main__':
    parser=argparse.ArgumentParser()
    parser.add_argument('source', type=Path)
    parser.add_argument('--columns', type=int, default=4)
    parser.add_argument('--rows', type=int, default=2)
    parser.add_argument('--stride', type=float, required=True)
    parser.add_argument('--display-scale', type=float, required=True)
    parser.add_argument('--output', type=Path, required=True)
    args=parser.parse_args()
    result=audit(args.source,args.columns,args.rows,args.stride,args.display_scale)
    args.output.parent.mkdir(parents=True,exist_ok=True)
    args.output.write_text(json.dumps(result,ensure_ascii=False,indent=2),encoding='utf8')
    print(json.dumps(result['halves'],indent=2))
