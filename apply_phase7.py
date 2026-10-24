#!/usr/bin/env python3
"""
Phase 7: Find button and exact addresses for areas

Run from the root of the `game` repository (the folder with index.html):

    python apply_phase7.py            apply the changes to your working tree
    python apply_phase7.py --check    only test whether they apply cleanly
    python apply_phase7.py --show     print the changes (a git diff) without applying
    python apply_phase7.py --revert   undo them again

It only edits files. Nothing is committed or pushed — review with
`git status` / `git diff`, then commit and push yourself.

Built against commit 7e9514b. If your copy has moved on since, the script
falls back to a 3-way merge and tells you about any file it could not
merge cleanly.
"""
import base64, os, subprocess, sys, zlib

PATCH = zlib.decompress(base64.b64decode("""
eNrNWVtvG8cVftevON4WkVRxVyTFmyhTjWzYcBq7SW0VSFMUxnB3yB1pb9qLJCoxoDhNkyJCbu1DEjgtggJ9yoNycSPXtvIXyL/g
xzj9Dz1n9sIlKVlSYheVLa52ZvZcvnPON2eWhuh0QFW7IgQ277EuD+YdNxQdobNQuM7YnaYHAbRPt25KOAbfhmqlqi8sVDXNqOsL
7UoHSsVirVKZUlX1tBqn5ubmTq31+edBbdTLhXIR5uS1DjjENCdUdVN4TdPd5H4hN8D0UGxyeA3aTF/v+m7kGE3YZP6MqnqWynSd
48rA7YSzS6C7luvT7BRMAUlghuGrHfQUXpsCgI7Ft9XA9IWz3oTi0pQKsCWM0GzCQsPblvcmF10zTAfmcgO1ZMBDocLpogAoVWgM
Bbdd3+Co2XEdnhtQfWaIKGgiqIn4I50IIr/DdK6WZ+WazItk2o5CbsxK3U/AIF6QPPuzTqcj7zsuotBhtrB6TRCOyX0RDicCscPR
D61R9bk9HN5KXK4Xi3JwyxQhVwMPbSQXt3zmSSf1yA9Im+cKJ+S+HDNE4FkMlRHWcoRZouuoKMFGIMhSWolurkUBJkdP1VEljg7n
UGOXeU2oSnBvYSzVXCy5ZWgiUDsEwniMz5QjY+ihInVUnIazAq1DuUmWlCgpsoyI725NzY081kQEWNviZI6LkImwRxDXljK4DN5h
kRWOP/psHFMNzr3ZSTOP8q464l01844GVNs1+IRZaboVq2VeLj9p+RO9O8n0pJpNTDNcbTO/KxxMT28ba7C4NJrL9RrlMljC4Wrm
i1ZdOq6sSHwq/PemMAzu/AGVZHksSxoXGWdjYjO0rVORIi1MuNioLHRYra5pdV7sNPT2WblYijotGcvFxMalxXJhEebo0kAuppKN
f853XN8G3WJB0FJGIqmAMGhoBUcu4yIFWBS6umt7Fg95S3E7HWV5KAhFBZvdVFKad6lEulFgU/CtC+52S8GIQrmC/xXoCMtCNRgA
BYLQd9dRNBaRj7lxkYKZjqoygVtKORug6OvMaymyZEaG15CssnHmC6bGQW8poR9xZfm8Lnzd4qCjLaWSAnovvvotpa7ML5/3WGgC
em+XS1AuqRVtoSo/aG4e3Rz1WzheFELY89D0kG+HyjieckEezxfiAZttW9zpklulclEByY3rvEdp2lICznzdVMBgIVO9ENMZudl0
LdxzWgrzObthch5qpIEHwaVtRpFRYH6ZiDczrh2FIQYiti6I2raYtI8qdCTc8j7VS/jlFcrVI0qOjP1TCrdWeSoBzyJa0apQKuMH
/SsVVQx7FtQ8bvMxcMu0U2WD57BIlVXXEwHGJXJCYUFockhCACIAyX0FGnVAeXTnL0CrLUMoMDNammvBrIZUMyr/RwdreWhvzgWq
7fyAl5NFOZYXc0XeJzE/Ir/kPKrxMoHn5w2xuXxWzlw7XfO6lvauldpirciLmtbQ+QJv1M/Kl2unb13X4s61vFiowRx+1jOm1H03
CEwmcGuZfnap/tSZrZwwW3nIbMdPY02kNh9lZeJJjhyvlcpQ3lygS2kRr3gpm3i7KK9ZVU0XYgw92s7/39HLfMOjS6moF6GmNtAd
+RGoDRVv1VKZNaBBJwP6V4Piq8cBW5TATkJhuz4/Oxaj3p8Q++pobE8I/fj04uR06oCkK93k+vozjaZW+5/RfhqVNresZxGVkXrR
yqymLQD9kqiimtxhqlW0mlrSKni3qOK2Bw2mLWqL8TLQ6tTgmqXa6CA+UNXVEl5K9Iy6gL90bayMaIFY9asj5buo1bBwtYZZ0RqM
FNKvXIy9TiNJ6xghAugWntMkP9bqDaTGuVo9z5AAGtKobs50IkcnOoUZ7vuz8ZE8/hEdmLF7cK7VgoBvwOuvQ0AbTDwwCz4PI99Z
Gq4P5NZzyfddH1rA6bqK3ZWUuzTcq0ksDmk6HUZaKGs62bFuIrvflPvx9Gwi7DITdGhrAbVpS8Ot9zQyyODj1/BtpofH6Um03JrN
sKL+IAfVBE5HIkPg1ytV2p3qlVqhVMrQx/NO3HmgynPnAi0+ZQfp3g3PPZcYdp0HrrVJprVGjPv5zPSw05+e1WT+XxVBqIVut2vx
men0XDddiDXNnuVJGTx8kmzLgjqbBGB+HlZgy/WxbUIkgTlANdcEBqHQ17EssY3BHsvphdizdLMmC2FhBrAAFINoRYuFSSSwc7gQ
OojF0DhBWZAoTOY14Tjcv7J67SqujEX+El64+NKvNUlvMEdc4DFneRr/5IE+szozneuC48Salcvm43X5Xu6on+aTJYoJgWMGZ28d
MC3kcsRjaZgB8uicc5patuk0TjR5tuAMkzE3HMuhzLkYv9KRtmTzcZKWiiVJEaViuTLCEcemdlbyAdukIGNAmBXwbMJkHibDzHRs
67D8T1W4MvsDN/L10TXTVHZzQ0FPiQKeqO6U7JZbNl7LLXAiyxqSCnAECiUf0YfLE2N6kUHLt99HziZdd1Gvsk6xrmltvbpQr5aP
6rqPfj7fbB+9Qu4hC4v0PiK+4MAWqnW3tJevrly8dOPm6qVXVtHPBC27d9WNW/Rm7PJrEO00QfmV28N0NqNNYSsF8CMc6t/pHw4+
hP6D/t3BG4Pb/UOc4PiYcq0HViJEgVvJhp8g2szATgRfY86OsDKZH/S/GeySwFTYSvzchCCqtyZaneRmTpYjYB1JrBcgpVnCYLAu
fBFioiuFdHWs66P+V/27/W/6B2j8Xejvp6qh/7C/D/1/o3t43783eIP+7j8YPi8tu0SpMnokdeBF1MwcJc10adaLeWsKaNyj3Y91
kyGNQFs4Lvhsg9kC/7aQjkOatcQG2NKZvPFzeeP/jhbd7z8cvNu/dwrTmzB4E5cfDP5E0we07FAGbhcQAPpzf6hAencZ837SsQIm
D3Y05DR2hsQtDJm8HdGpG5nEiew295U4UGMBS96ZNLPI//DHOz98egCP3//k8d7u4y8Ovr/7Bfzn073vD/Yff34HqrU0J06xTlp8
4rrMIpmd3JjIxSvujqA3oQy9EhsYDUNkifm3/ncS0m/w9z7+IoBASd+/P9gjjGHwdr4GrsYq5Dt5esMvlctirMgTL13qJxUj8jM3
LkpKaubtvMHIuC5mi838dbaTGfk5xv0tNHMfE+NDNDFODww62ju4PdhNrbtBguXXAz4fwuLzGJjmGCy/Yb0whSQwc4h8KdPoKyqg
wV4q+7eegTKGUuUr/PzGnEhN3uyk0j5Do+8hggepnPi92K0kKzvxm/ojpVi5MEkxMkgPh8G4HJ9Z8hbJ75uOpCLYEAbWnGW7GwZ7
tPvPTPTHgz+j2Ae5aotnk3i761QBkZdnBFqQqXXcNJTZzpSopRgia4XMobDCo92/YklBj/tIXkgNvrsZk4aPqWkITUkyqVGTmdSo
F8q1k1IJXllZfenqynWYh0vXr790/QZ0fNeWto68l4GVl18oQLsHtO0mj6o/7gd+MT8l3aYvpeTeGzTTHmBiK28OuwMJyoqTo0Du
MzwAP5E3C7g4YESgJ9GABjdMZmIH18OIQRihErQR5fR4aLNejO8I1X6G3PkvyihZ8IO3J1mXInYiwRYkOUsaOUimTrZVJvS3WGNY
0ij9feh/Lbn9EKWSItIJsuLv4Zgk/4eSpQ7lnryfWtw/1MYIPt6+0HmJf0b15Mrx1I7ZrnW1U9i9AvQ9HWC/hX106AvU4DCb44HC
ebT7SYgmuFHX1JKNMq1y6s9vtiOjyycS4kpkRIaFR36nK3aQVmlfZyHyEsXMdbB8qFJYG1yLagQuYA1TJyB000f+ortuHPI4jeTA
RKg/QsTeGUF08C4QqVIEkOXeldf3BrcBd1YK9zvx/grIhXIrGLwzeHPwHvS/w9lDJAzKkT0M4z8o4ihtj8TH/UYSuzcpklKWHKXA
HmCq4ce3IGP+1njkfoftroQqwJNcZCGR01f82Dm4YEe6CfHXmhpcY+sc8LgGgc0sC1dQNDh9oUSj49jj4zexFno3scQcbCjHA3Ah
6kYOmEkYkggQlp5EdKfLfELZIvAv+SHrMogoBO2Muybh/hwx+Vq6/BBTexT0GK/3JTJvDPbGAcek3o/bTkSXmqHvZFV8iXjei5H8
FqV9Rbtef38cwVWCCn2VKELiMCJgsJ4GL1uILIfQx+kuE9SS2S7S19axiHk+p3dWx0CWR2rN7aVwtFGv2PgpeMUuIy4P8PO27E5k
VzKWmQ8kF+FjWav+UxCLzxfYQrnr2EKw8CyowTj1J7v66H54IUqJP6TN3ZblPNZDUzPiuxtY0DvjgEEesA/yjfHdmICT9uA4ECRH
U87Jgt/LOB+fuVs4rr8mxf8FdNbJpA==
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
