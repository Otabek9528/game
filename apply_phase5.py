#!/usr/bin/env python3
"""
Phase 5 (frontend): reviews sent with signed Telegram data; placeholder pictures for places without photos.

Run from the root of the `game` repository (the folder with index.html):

    python apply_phase5.py            apply the changes to your working tree
    python apply_phase5.py --check    only test whether they apply cleanly
    python apply_phase5.py --show     print the changes (a git diff) without applying
    python apply_phase5.py --revert   undo them again

It only edits files. Nothing is committed or pushed — review with
`git status` / `git diff`, then commit and push yourself.

Built against commit dc2ced4 ('notifications_feature' = Phase 4). If your copy has moved on since, the script
falls back to a 3-way merge and tells you about any file it could not
merge cleanly.
"""
import base64, os, subprocess, sys, zlib

PATCH = zlib.decompress(base64.b64decode("""
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
"""))


def git(args, data=None):
    return subprocess.run(["git"] + args, input=data, capture_output=True)


def main():
    mode = sys.argv[1] if len(sys.argv) > 1 else ""
    if mode == "--show":
        sys.stdout.write(PATCH.decode("utf-8"))
        return 0
    if not (os.path.isfile("index.html") and os.path.isdir(os.path.join("pages", "places"))):
        print("Run this from the root of the game repository (where index.html is).")
        return 1
    if git(["rev-parse", "--is-inside-work-tree"]).returncode != 0:
        print("git was not found, or this folder is not a git repository.")
        return 1

    reverse = ["-R"] if mode == "--revert" else []
    check = git(["apply", "--check", "--whitespace=nowarn"] + reverse + ["-"], PATCH)
    if mode == "--check":
        print("Applies cleanly." if check.returncode == 0 else check.stderr.decode())
        return check.returncode

    if check.returncode == 0:
        res = git(["apply", "--whitespace=nowarn"] + reverse + ["-"], PATCH)
    else:
        print("Does not apply directly; trying a 3-way merge...")
        res = git(["apply", "--3way", "--whitespace=nowarn"] + reverse + ["-"], PATCH)
    out = (res.stdout + res.stderr).decode().strip()
    if out:
        print(out)
    if res.returncode != 0:
        print("\nNot applied. Nothing was changed unless a file is listed above as merged with conflicts.")
        return res.returncode

    print("Done:", "reverted." if reverse else "changes applied.")
    print(git(["status", "--short"]).stdout.decode())
    print("Review with `git diff`, then commit and push yourself.")
    return 0


if __name__ == "__main__":
    sys.exit(main())
