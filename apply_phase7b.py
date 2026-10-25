#!/usr/bin/env python3
"""
Phase 7b: area radii 1, 3, 5 and 10 km

Run from the root of the `game` repository (the folder with index.html):

    python apply_phase7b.py            apply the changes to your working tree
    python apply_phase7b.py --check    only test whether they apply cleanly
    python apply_phase7b.py --show     print the changes (a git diff) without applying
    python apply_phase7b.py --revert   undo them again

It only edits files. Nothing is committed or pushed — review with
`git status` / `git diff`, then commit and push yourself.

Built against commit bfc4e2c. If your copy has moved on since, the script
falls back to a 3-way merge and tells you about any file it could not
merge cleanly.
"""
import base64, os, subprocess, sys, zlib

PATCH = zlib.decompress(base64.b64decode("""
eNq1VdFu2zYUffdXXAhDJMOWKNlx4sSxl7R1igzdasQJhqEbAlq6llnLpEpSToK2f7ChT3ve+75gL/um7RNGSk5qZ8PmYqlhm7jk
veceHd5jJ2w6Bd9PmQZKcpqiIlxoNmUx1UzwB1Ew04sMJlsm1hhP8Ab2MZx240kQTFp7cTc+gCgM93Z3a77vb92z1mg0tu97fAx+
KwybUQiN1Xp8XIMaVK+jHOKMKtV3uPYzOsHMgYRq6ue671CJdDxD1IGkCSuUMzgi+eC+NGHLtWKFKVSL7+86wBK7e17VgRQZ9h2L
IlIpitwZ1BpwhzMptBYc9G1ucqrA2QT2J5pvgKxIzhd9J7KsqqrHA22vg8IjgXY+B2gUrqP6j4Xa+RyorfAfFDgiZo4GaxO5OVa5
xCXD67uBGq3CQS35NLe+Vlt55rVaObUbYxu7+0HQbh8c7NLwU51qgLb1qUm1Lo0OmvvQKL+tQwGWVMLJ6Az64HnXhpW4Dkx49fTl
N6dnz2FnBz5GwZOT8fDq8vxFHd69A3emda4OCVliWswZ92nOgqSI54npJmRK3HogMc9ojB75njS+IE1w3XqvugTb9uK70XBsGr9y
F0K9KdA1CRKVpoWkXNtIzUTu/tCzs2ELzk+enVmmrzpNo5T5mLUVmvPGg/OoCe0mlFnmdNXu2fD05PLFxZXNurR9O/dHw69ffmUL
30LF5BDcP3/5+UdD4SOfcu+n3//47YPZtsTKjQ+/uvC+xCEExizlVBcSIZdikuFCHYKeIQie3cKU3QBTBlDkyBlPyxN7b8C4YgnC
BWaYSroIqp/Tg5a9qWqprgpMsRkb+S3V8QyVVy/7vjeC+mX7U1FIkAZawVRI6JAoJFGHtEKYL3plu3gmFHLDBy0VJTKWBFa8vxdH
pE0swL+XmvbTgsd2wsD4kMrxMvXmizq8rfhabUWhjbLukVqmYF31RNz0nRBC2LdvB6hk1J+xJEHed7Qs0Bm4vaq8vM/A0BnSeObd
d/JkE5jtYXXa63atTtVyp5NR5aE4IzuICq6ZnjEOpSYgptWjIdcSe4BLlLdQ/QvZh4xFwTUmMJViYRLNjn36jCl9J9omaPR/Qdfl
zARNRoJxrTxlribGZgmJckNcZaRV9s9zpZjxoOc+H15Y8xATkNJ/ihh7VhS+zKjuu9AA5LFI8PL87KlY5IYC116FH5iMuklwdzLB
/ytV8Hq99hekS8Rx
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
