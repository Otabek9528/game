#!/usr/bin/env python3
"""
Makes small WebP copies of the place photos and writes Photos/manifest.json,
so the place pages know which photos exist without guessing filenames.

Run it from the repository root whenever photos are added, changed or removed,
then commit Photos/ together:

    python3 tools/build-photos.py          convert what changed, rewrite the manifest
    python3 tools/build-photos.py --check  only report what is out of date (exit 1 if anything)

Needs Pillow:  pip install Pillow

A place's photo folder (Photo_path in the database, e.g. Photos/117) holds
1.jpg, 2.png, ... numbered from 1 without gaps; jpg is preferred over jpeg over
png when a number exists twice, as the pages always did. For each photo this
writes, next to the original (which stays, as the fallback):

    <n>.webp        at most 1080 x 1440, for cards, the place page and the viewer
    <n>.thumb.webp  at most 320 x 320, for the small pictures on the notifications page

The manifest lists every folder that has photos, in order, as "<ext>:<hash>"
(the original's extension and a hash of its bytes). The pages add the hash to
the URL, so a replaced photo is never served from an old cache.

    {"version": 1, "folders": {"Photos/117": ["png:3f1c9a0b", "jpg:9e2d41c7"]}}

A folder the manifest does not list is treated as "not converted yet": the
pages look for its 1.jpg / 1.jpeg / 1.png and, if one is there, find the rest
the old way. So photos uploaded without running this still show, only slower.
"""
import hashlib
import json
import os
import re
import sys

ROOT = 'Photos'
MANIFEST = os.path.join(ROOT, 'manifest.json')
EXTS = ['jpg', 'jpeg', 'png']          # preference order
FULL = (1080, 1440)
THUMB = (320, 320)
FULL_Q = 75
THUMB_Q = 70
MAX_PHOTOS = 10                         # the pages never show more


def source_photos(folder):
    """[(n, path, ext)] numbered 1..k without gaps."""
    by_n = {}
    for name in os.listdir(folder):
        m = re.fullmatch(r'(\d+)\.(jpg|jpeg|png)', name, re.IGNORECASE)
        if not m:
            continue
        n, ext = int(m.group(1)), m.group(2)
        rank = EXTS.index(ext.lower())
        if n not in by_n or rank < by_n[n][0]:
            by_n[n] = (rank, os.path.join(folder, name), ext)
    out = []
    n = 1
    while n in by_n and n <= MAX_PHOTOS:
        out.append((n, by_n[n][1], by_n[n][2]))
        n += 1
    return out


def digest(path):
    h = hashlib.sha256()
    with open(path, 'rb') as f:
        for chunk in iter(lambda: f.read(1 << 16), b''):
            h.update(chunk)
    return h.hexdigest()[:8]


def convert(src, dst, box, quality):
    from PIL import Image, ImageOps
    with Image.open(src) as im:
        im = ImageOps.exif_transpose(im)      # phone photos stored sideways
        if im.mode not in ('RGB', 'RGBA'):
            im = im.convert('RGBA' if 'A' in im.getbands() or im.mode == 'P' else 'RGB')
        im.thumbnail(box, Image.LANCZOS)
        tmp = dst + '.tmp'
        im.save(tmp, 'WEBP', quality=quality, method=6)
    os.replace(tmp, dst)


def main():
    check = '--check' in sys.argv[1:]
    if not os.path.isdir(ROOT):
        print(f'No {ROOT}/ folder here. Run this from the repository root.')
        return 1
    try:
        with open(MANIFEST, encoding='utf-8') as f:
            old = json.load(f).get('folders', {})
    except (FileNotFoundError, ValueError):
        old = {}

    folders = {}
    todo = []
    orphans = []
    for name in sorted(os.listdir(ROOT), key=lambda s: (len(s), s)):
        folder = os.path.join(ROOT, name)
        if not os.path.isdir(folder):
            continue
        photos = source_photos(folder)
        # Copies of photos that were removed or renumbered.
        for f in os.listdir(folder):
            m = re.fullmatch(r'(\d+)(\.thumb)?\.webp', f)
            if m and int(m.group(1)) > len(photos):
                orphans.append(os.path.join(folder, f))
        if not photos:
            continue
        key = f'{ROOT}/{name}'
        entries = []
        for n, path, ext in photos:
            entry = f'{ext.lower()}:{digest(path)}'
            entries.append(entry)
            full = os.path.join(folder, f'{n}.webp')
            thumb = os.path.join(folder, f'{n}.thumb.webp')
            prev = old.get(key, [])
            same = len(prev) >= n and prev[n - 1] == entry
            if not (same and os.path.isfile(full) and os.path.isfile(thumb)):
                todo.append((path, full, thumb))
        folders[key] = entries

    manifest = {'version': 1, 'folders': folders}
    stale_manifest = old != folders
    if check:
        for path, _, _ in todo:
            print(f'  needs converting  {path}')
        for path in orphans:
            print(f'  no longer needed  {path}')
        if stale_manifest:
            print(f'  out of date       {MANIFEST}')
        if todo or orphans or stale_manifest:
            return 1
        print('Everything is up to date.')
        return 0

    try:
        import PIL  # noqa: F401
    except ImportError:
        print('Pillow is needed:  pip install Pillow')
        return 1

    before = after = 0
    for path, full, thumb in todo:
        convert(path, full, FULL, FULL_Q)
        convert(path, thumb, THUMB, THUMB_Q)
        before += os.path.getsize(path)
        after += os.path.getsize(full)
        print(f'  {path}  {os.path.getsize(path) // 1024} KB -> {os.path.getsize(full) // 1024} KB')

    for path in orphans:
        os.remove(path)
        print(f'  removed {path}')

    with open(MANIFEST + '.tmp', 'w', encoding='utf-8') as f:
        json.dump(manifest, f, separators=(',', ':'), sort_keys=True)
        f.write('\n')
    os.replace(MANIFEST + '.tmp', MANIFEST)

    print(f'\n{len(todo)} photo(s) converted', end='')
    if todo:
        print(f', {before // 1024} KB -> {after // 1024} KB', end='')
    print(f'. {len(folders)} folder(s) in {MANIFEST}.')
    print('Commit the Photos/ folder (the .webp files and manifest.json) with the photos.')
    return 0


if __name__ == '__main__':
    sys.exit(main())
