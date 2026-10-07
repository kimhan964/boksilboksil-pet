"""Publish the independently packaged typing game. Reuse verified GitHub transport."""
import argparse
import json
import zipfile
from pathlib import Path
import release_snapshot as github

ROOT = Path(__file__).resolve().parents[1]
INSTALL = ROOT.parent / "복슬복슬타자친구"
OUT = ROOT / "builds/typing-release-0.1.4"
TAG = "typing-v0.1.4"
NAME = "BoksilBoksilMate-0.1.4-Windows.zip"


def package(commit):
    OUT.mkdir(parents=True, exist_ok=True)
    entries = [(INSTALL / name, name) for name in ["TypingFriends.exe", "TypingFriends.pck", "README.md", "GODOT-LICENSE.txt", "GODOT-THIRD-PARTY.json", "FONTS-LICENSES.txt"]]
    for file in (INSTALL / "addons").rglob("*"):
        if file.is_file() and file.suffix != ".uid":
            entries.append((file, file.relative_to(INSTALL).as_posix()))
    with zipfile.ZipFile(OUT / NAME, "w", zipfile.ZIP_DEFLATED, compresslevel=6) as archive:
        hashes = []
        for file, name in entries:
            archive.write(file, name)
            hashes.append(github.sha(file) + "  " + name)
        archive.writestr("SOURCE_COMMIT.txt", commit + "\n")
        archive.writestr("FILE-SHA256SUMS.txt", "\n".join(hashes) + "\n")
    with zipfile.ZipFile(OUT / NAME) as archive:
        assert archive.testzip() is None
        assert "TypingFriends.exe" in archive.namelist()
        assert "addons/typing_input/TypingInput.exe" in archive.namelist()
        assert all("session.log" not in n and "typing-friends.json" not in n for n in archive.namelist())
    (OUT / "SHA256SUMS.txt").write_text(github.sha(OUT / NAME) + "  " + NAME + "\n", encoding="utf-8")
    print("ZIP_VERIFIED", NAME, (OUT / NAME).stat().st_size, flush=True)


def publish(commit):
    headers = github.credentials()
    releases = github.api("/releases?per_page=100", headers)
    release = next((r for r in releases if r["tag_name"] == TAG), None)
    if release is None:
        release = github.api("/releases", headers, "POST", {
            "tag_name": TAG, "target_commitish": commit,
            "name": "복슬복슬메이트 0.1.4 · 액세서리 14종과 UI 개선",
            "body": (ROOT / "docs/RELEASE-TYPING-0.1.4.md").read_text(encoding="utf-8"),
            "draft": True, "prerelease": True,
        })
    for file in [OUT / NAME, OUT / "SHA256SUMS.txt"]:
        digest = "sha256:" + github.sha(file)
        asset = next((a for a in release["assets"] if a["name"] == file.name), None)
        if asset is None:
            asset = github.upload(release["upload_url"], file, headers)
        if asset["size"] != file.stat().st_size or asset.get("digest") != digest or asset["state"] != "uploaded":
            raise RuntimeError("Remote size, digest or upload state differs: " + file.name)
        print("REMOTE_VERIFIED", file.name, digest, flush=True)
    release = github.api("/releases/" + str(release["id"]), headers, "PATCH", {"draft": False, "prerelease": True})
    result = {"release": release["html_url"], "commit": commit, "assets": [{"name": a["name"], "url": a["browser_download_url"], "digest": a.get("digest")} for a in release["assets"]]}
    (OUT / "published.json").write_text(json.dumps(result, ensure_ascii=False, indent=2), encoding="utf-8")
    print(json.dumps(result, ensure_ascii=False), flush=True)


if __name__ == "__main__":
    parser = argparse.ArgumentParser()
    parser.add_argument("command", choices=["package", "publish"])
    parser.add_argument("--commit", required=True)
    args = parser.parse_args()
    (package if args.command == "package" else publish)(args.commit)
