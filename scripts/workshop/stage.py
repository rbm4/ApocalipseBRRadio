"""Normalize ready/pzstudio projects into a narrow, validated Workshop artifact."""
import json
from pathlib import Path
import re
import shutil
import sys


def contained(root, relative):
    root = Path(root).resolve()
    result = (root / relative).resolve()
    if not result.is_relative_to(root) or not result.is_dir():
        raise ValueError("Project directory must exist inside the checkout")
    return result


def output(root, config):
    title = json.loads(Path(config).read_text(encoding="utf-8-sig"))["title"]
    if not isinstance(title, str) or not title or title in (".", "..") or "/" in title or "\\" in title:
        raise ValueError("Invalid pzstudio output title")
    return contained(root, title)


def workshop_id(path):
    ids = [line.split("=", 1)[1].strip() for line in
           path.read_text(encoding="utf-8-sig").splitlines() if line.startswith("id=")]
    if len(ids) != 1:
        raise ValueError("workshop.txt must contain exactly one id")
    return ids[0]


def stage(source, destination, expected_id):
    source, destination = Path(source).resolve(), Path(destination).resolve()
    if not re.fullmatch(r"[1-9][0-9]{0,19}", expected_id):
        raise ValueError("An existing Workshop ID is required; creating new items is disabled")
    if source == destination or destination.is_relative_to(source) or source.is_relative_to(destination):
        raise ValueError("Source and staging directories must be separate")
    contents, preview, metadata = source / "Contents", source / "preview.png", source / "workshop.txt"
    if not (contents / "mods").is_dir() or not preview.is_file() or not metadata.is_file():
        raise ValueError("Expected Contents/mods, preview.png, and workshop.txt")
    if workshop_id(metadata) != expected_id:
        raise ValueError("Configured Workshop ID differs from workshop.txt")
    paths = [contents, preview, metadata, *contents.rglob("*")]
    if any(p.is_symlink() or not (p.is_file() or p.is_dir()) for p in paths):
        raise ValueError("Workshop packages cannot contain symbolic links or special files")
    mods = list((contents / "mods").iterdir())
    if not mods or any(not mod.is_dir() or not list(mod.rglob("mod.info")) for mod in mods):
        raise ValueError("Every packaged mod must have mod.info")
    if preview.read_bytes()[:8] != b"\x89PNG\r\n\x1a\n":
        raise ValueError("Workshop preview must be a PNG")
    if destination.exists():
        shutil.rmtree(destination)
    destination.mkdir(parents=True)
    shutil.copytree(contents, destination / "Contents")
    shutil.copyfile(preview, destination / "preview.png")
    (destination / "manifest.json").write_text(json.dumps({
        "appid": "108600", "workshop_id": expected_id,
        "mods": sorted(mod.name for mod in mods),
    }) + "\n", encoding="utf-8")
    for path in [destination, *destination.rglob("*")]:
        path.chmod(0o755 if path.is_dir() else 0o644)
    print("Staged " + str(len(mods)) + " mod(s) for existing Workshop item " + expected_id)


if __name__ == "__main__":
    try:
        if len(sys.argv) == 4 and sys.argv[1] == "resolve":
            print(contained(sys.argv[2], sys.argv[3]))
        elif len(sys.argv) == 4 and sys.argv[1] == "output":
            print(output(sys.argv[2], sys.argv[3]))
        elif len(sys.argv) == 5 and sys.argv[1] == "stage":
            stage(*sys.argv[2:])
        else:
            raise ValueError("Unsupported packaging command")
    except (OSError, ValueError, KeyError, TypeError) as error:
        print("Workshop packaging failed: " + str(error), file=sys.stderr)
        sys.exit(1)
