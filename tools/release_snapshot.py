"""Package installed, verified builds; publish a draft only after verified uploads.

Authentication stays in memory via Git Credential Manager. Never serialize credentials.
"""
import argparse
import hashlib
import http.client
import json
import subprocess
import time
import urllib.error
import urllib.parse
import urllib.request
import zipfile
from pathlib import Path

REPO = "kimhan964/boksilboksil-pet"
TAG = "v0.31.0-preview.20261005"
SOURCE = Path(__file__).resolve().parents[1]
OUTPUT = SOURCE / "builds" / "release-20261005"
INSTALL = SOURCE.parent / "복슬복슬펫"


def sha(path):
    with path.open("rb") as stream:
        return hashlib.file_digest(stream, "sha256").hexdigest()


def package(commit):
    OUTPUT.mkdir(parents=True, exist_ok=True)
    for preview in (False, True):
        origin = INSTALL / "전체동물-움직임점검-v12" if preview else INSTALL
        suffix = "AllPets-Preview-Windows" if preview else "Windows"
        filename = f"BoksilboksilPet-0.31.0-{suffix}.zip"
        output = OUTPUT / filename
        entries = [(origin / n, n) for n in ("DesktopFriends.exe", "DesktopFriends.pck", "GODOT-LICENSE.txt", "GODOT-THIRD-PARTY.json")]
        for file in (SOURCE / "addons/windows_mouse_passthrough").rglob("*"):
            if file.is_file() and not file.name.endswith(".uid"):
                entries.append((file, file.relative_to(SOURCE).as_posix()))
        for name in ("RELEASE-2026-10-05.md", "UI-UNLOCKS-2026-10-05.md", "OUTFIT-CURRENT-CHARACTERS-2026-10-05.md"):
            entries.append((SOURCE / "docs" / name, "docs/" + name))
        print("PACKING", filename, flush=True)
        file_hashes = []
        with zipfile.ZipFile(output, "w", compression=zipfile.ZIP_DEFLATED, compresslevel=1, allowZip64=True) as archive:
            for path, name in entries:
                archive.write(path, name)
                file_hashes.append(f"{sha(path)}  {name}")
            archive.writestr("SOURCE_COMMIT.txt", commit + "\n")
            archive.writestr("FILE-SHA256SUMS.txt", "\n".join(file_hashes) + "\n")
            if preview:
                archive.writestr("Start-Preview.cmd", '@echo off\r\ncd /d "%~dp0"\r\nstart "" "%~dp0DesktopFriends.exe" -- --species=0 --free-play\r\n')
            archive.writestr("START-HERE.txt", "Unzip the complete folder.\nRun " + ("Start-Preview.cmd" if preview else "DesktopFriends.exe") + ".\nKeep DesktopFriends.pck and addons beside the executable.\nDevelopment snapshot: see docs/RELEASE-2026-10-05.md for known limitations.\n")
        with zipfile.ZipFile(output) as archive:
            bad = archive.testzip()
            if bad:
                raise RuntimeError("ZIP CRC mismatch: " + bad)
            assert len([n for n in archive.namelist() if n.endswith(".pck")]) == 1
            assert "DesktopFriends.exe" in archive.namelist()
        print("ZIP_VERIFIED", filename, output.stat().st_size, flush=True)
    sums = [f"{sha(p)}  {p.name}" for p in sorted(OUTPUT.glob("*.zip"))]
    (OUTPUT / "SHA256SUMS.txt").write_text("\n".join(sums) + "\n", encoding="utf-8")


def credentials():
    result = subprocess.run(["git", "credential", "fill"], input="protocol=https\nhost=github.com\n\n", text=True, capture_output=True, check=True, cwd=SOURCE)
    fields = dict(line.split("=", 1) for line in result.stdout.splitlines() if "=" in line)
    return {"Authorization": "Bearer " + fields["password"], "Accept": "application/vnd.github+json", "User-Agent": "Boksil-Snapshot-Publisher"}


def api(path, headers, method="GET", payload=None):
    data = json.dumps(payload).encode() if payload is not None else None
    request = urllib.request.Request("https://api.github.com/repos/" + REPO + path, data=data, headers=headers, method=method)
    with urllib.request.urlopen(request, timeout=60) as response:
        return json.load(response)


def upload(url, path, headers):
    parsed = urllib.parse.urlsplit(url.split("{")[0])
    endpoint = parsed.path + "?" + urllib.parse.urlencode({"name": path.name})
    connection = http.client.HTTPSConnection(parsed.netloc, timeout=300)
    connection.putrequest("POST", endpoint)
    for key, value in headers.items():
        connection.putheader(key, value)
    connection.putheader("Content-Type", "application/zip" if path.suffix == ".zip" else ("application/octet-stream" if path.suffix == ".pck" else "text/plain"))
    connection.putheader("Content-Length", str(path.stat().st_size))
    connection.endheaders()
    total = path.stat().st_size
    sent = 0
    last = time.monotonic()
    with path.open("rb") as stream:
        while block := stream.read(1024 * 1024):
            connection.send(block)
            sent += len(block)
            if time.monotonic() - last > 15:
                print("UPLOAD", path.name, f"{sent / total:.0%}", flush=True)
                last = time.monotonic()
    response = connection.getresponse()
    body = response.read()
    if response.status != 201:
        raise RuntimeError(f"Asset upload failed: HTTP {response.status}")
    connection.close()
    return json.loads(body)


def publish(commit):
    headers = credentials()
    releases = api("/releases?per_page=100", headers)
    release = next((r for r in releases if r["tag_name"] == TAG), None)
    if release is None:
        release = api("/releases", headers, "POST", {"tag_name": TAG, "target_commitish": commit, "name": "복슬복슬펫 0.31.0 · 2026-10-05 개발 스냅샷", "body": (SOURCE / "docs/RELEASE-2026-10-05.md").read_text(encoding="utf-8"), "draft": True, "prerelease": True})
        print("DRAFT_CREATED", release["id"], flush=True)
    assets = release["assets"]
    expected = sorted(OUTPUT.glob("*.zip")) + [OUTPUT / "SHA256SUMS.txt"]
    if len(expected) != 3 or not all(p.is_file() for p in expected):
        raise RuntimeError("Both archives and checksum file are required")
    for path in expected:
        digest = "sha256:" + sha(path)
        asset = next((a for a in assets if a["name"] == path.name), None)
        if asset is None:
            asset = upload(release["upload_url"], path, headers)
        if asset["size"] != path.stat().st_size or asset.get("state") != "uploaded":
            raise RuntimeError("Remote asset size/state mismatch")
        if asset.get("digest") != digest:
            raise RuntimeError("Remote SHA-256 mismatch or unavailable")
        print("REMOTE_VERIFIED", path.name, digest, flush=True)
    release = api("/releases/" + str(release["id"]), headers, "PATCH", {"draft": False, "prerelease": True})
    result = {"release": release["html_url"], "tag": TAG, "commit": commit, "assets": [{"name": a["name"], "size": a["size"], "digest": a.get("digest"), "url": a["browser_download_url"]} for a in release["assets"]]}
    (OUTPUT / "published.json").write_text(json.dumps(result, ensure_ascii=False, indent=2), encoding="utf-8")
    print(json.dumps(result, ensure_ascii=False), flush=True)


if __name__ == "__main__":
    parser = argparse.ArgumentParser()
    parser.add_argument("command", choices=["package", "publish"])
    parser.add_argument("--commit", required=True)
    args = parser.parse_args()
    (package if args.command == "package" else publish)(args.commit)
