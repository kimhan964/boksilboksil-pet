"""Contact sheets of actual native game-window captures, including repairs."""
from pathlib import Path
from PIL import Image, ImageDraw
ROOT = Path(__file__).resolve().parents[1]
OUT = ROOT / "design/gameplay-audit-2026-10-02"
SPECIES = "rabbit otter squirrel hedgehog raccoon fox bear owl cat puppy hamster panda red_panda lamb koala penguin".split()
ACTIONS = "idle walk pet eat drink sleep carry jump look sniff wave groom stretch rub toy rest surprised happy angry sleepy drop dizzy".split()
for page in range(4):
    sheet = Image.new("RGB", (22*128, 8*132), "#edece6")
    draw = ImageDraw.Draw(sheet)
    for index in range(page*4, page*4+4):
        for si, stage in enumerate(["baby", "adult"]):
            row = (index-page*4)*2+si
            for col, action in enumerate(ACTIONS):
                name = f"{index:02d}-{stage}-{action}.png"
                file = OUT / "repaired" / name
                if not file.exists(): file = OUT / name
                frame = Image.open(file).convert("RGBA")
                background = Image.new("RGBA", frame.size, "#edece6")
                background.alpha_composite(frame)
                sheet.paste(background.convert("RGB").resize((128,112)), (col*128,row*132+20))
                draw.text((col*128+3,row*132+3), f"{SPECIES[index]}/{stage} {action}", fill="#4b443b")
    sheet.save(OUT / f"native-contact-{page+1}.png")
print("NATIVE_REVIEW_PAGES=4")
if (OUT / "outfits").exists():
    for page in range(8):
        if not (OUT / "outfits" / f"{page*2+1:02d}-adult-sleep-3.png").exists(): continue
        sheet = Image.new("RGB", (3*192,12*132), "#edece6")
        draw = ImageDraw.Draw(sheet)
        for index in range(page*2,page*2+2):
            for si, stage in enumerate(["baby","adult"]):
                for style in range(1,4):
                    row=(index-page*2)*6+si*3+style-1
                    for col, action in enumerate(["idle","walk","sleep"]):
                        file=OUT / "outfits" / f"{index:02d}-{stage}-{action}-{style}.png"
                        frame=Image.open(file).convert("RGBA")
                        bg=Image.new("RGBA",frame.size,"#edece6")
                        bg.alpha_composite(frame)
                        sheet.paste(bg.convert("RGB").resize((128,112)),(col*192+32,row*132+20))
                        draw.text((col*192+3,row*132+3),f"{SPECIES[index]}/{stage}/{style} {action}",fill="#4b443b")
        sheet.save(OUT / f"native-outfits-{page+1}.png")
    print("NATIVE_OUTFIT_PAGES=8")
