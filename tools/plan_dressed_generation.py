"""Inventory the full-body outfit generation work without replacing any image."""

from pathlib import Path
import json


ROOT = Path(__file__).resolve().parents[1]
SPECIES = ("rabbit", "otter", "squirrel", "hedgehog", "raccoon", "fox", "bear", "owl",
           "cat", "puppy", "hamster", "panda", "red_panda", "lamb", "koala", "penguin")
STAGES = ("baby", "adult")
STYLES = ("cape", "vest", "sweater")
ACTIONS = ("idle", "walk", "pet", "eat", "drink", "sleep", "carry", "jump", "look", "sniff",
           "wave", "groom", "stretch", "rub", "toy", "rest")
ACTION_DETAIL = {
    "idle": "sixteen gentle idle changes in head, eyes and body",
    "walk": "sixteen distinct walking steps with alternating planted and lifted feet",
    "pet": "sixteen natural petting reactions",
    "eat": "sixteen approach, bite, chew and swallow poses",
    "drink": "sixteen bending, sipping and raising-head poses",
    "sleep": "sixteen lying down, breathing and waking poses",
    "carry": "sixteen held and released whole-body poses",
    "jump": "sixteen crouch, takeoff, airborne and landing poses",
    "look": "sixteen curious looking poses",
    "sniff": "sixteen natural sniffing poses",
    "wave": "sixteen friendly waving poses",
    "groom": "sixteen self-grooming poses",
    "stretch": "sixteen connected full-body stretching poses",
    "rub": "sixteen gentle rubbing poses",
    "toy": "sixteen playful toy interaction poses",
    "rest": "sixteen settled resting poses",
}


def relative(path: Path) -> str:
    return path.relative_to(ROOT).as_posix()


def main() -> None:
    tasks = []
    for species in SPECIES:
        for stage in STAGES:
            for style in STYLES:
                reference = ROOT / "design/outfits-varco-v1" / species / f"{stage}-{style}-source.png"
                for action in ACTIONS:
                    source = ROOT / "design/all-species-v3/production-sources" / species / stage / f"{action}.png"
                    local = ROOT / "design/outfits-dressed-v2/local-sources" / species / stage / style / f"{action}.png"
                    varco = ROOT / "design/outfits-dressed-v2/production-sources" / species / stage / style / f"{action}.png"
                    pilot = ROOT / "design/outfits-dressed-v2/pilot" / species / stage / style / f"{action}.png"
                    output = ROOT / "assets/outfits-dressed-v2" / species / stage / style / f"{action}.png"
                    origin = "local" if local.is_file() else ("varco" if varco.is_file() or pilot.is_file() else None)
                    prompt = (f"Edit source image 1, the {stage} {species} 4x4 sprite sheet, preserving "
                              f"all 16 original {action} poses, face, eyes, fur and markings, stage proportions, "
                              f"palette, outline and foot positions. Reference image 2 defines the {style} design. "
                              f"Draw the whole animal wearing the {style} in every complete 2D cel; garment "
                              f"attached to shoulders and moving with {ACTION_DETAIL[action]}. "
                              "Exactly four columns and four rows, one complete character with clear padding "
                              "inside each cell, transparent background, no separated parts, missing anatomy, "
                              "text, extra animals or 3D. Match the approved baby/adult color and tone.")
                    tasks.append({"species": species, "stage": stage, "style": style, "action": action,
                                  "status": "built" if output.is_file() else "todo",
                                  "origin": origin, "source": relative(source),
                                  "outfit_reference": relative(reference),
                                  "local_source": relative(local), "game_asset": relative(output),
                                  "prompt": prompt})
    done = sum(task["status"] == "built" for task in tasks)
    data = {"workflow": "representative idle -> walk/sleep pilot -> remaining 13 actions -> review -> package",
            "generation_tool": "built-in image_gen for new project images",
            "total": len(tasks), "built_assets": done, "remaining_to_generate": len(tasks) - done,
            "tasks": tasks}
    target = ROOT / "design/outfits-dressed-v2/generation-plan.json"
    target.parent.mkdir(parents=True, exist_ok=True)
    target.write_text(json.dumps(data, ensure_ascii=False, indent=2), encoding="utf-8")
    print(f"DRESSED_PLAN built={done} remaining={len(tasks)-done} total={len(tasks)} -> {target}")


if __name__ == "__main__":
    main()
