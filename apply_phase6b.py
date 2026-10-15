#!/usr/bin/env python3
"""
Phase 6b: notifications page in its own folder, sheets back to their own buttons

Run from the root of the `game` repository (the folder with index.html):

    python apply_phase6b.py            apply the changes to your working tree
    python apply_phase6b.py --check    only test whether they apply cleanly
    python apply_phase6b.py --show     print the changes (a git diff) without applying
    python apply_phase6b.py --revert   undo them again

It only edits files. Nothing is committed or pushed — review with
`git status` / `git diff`, then commit and push yourself.

Built against commit 52e36e0. If your copy has moved on since, the script
falls back to a 3-way merge and tells you about any file it could not
merge cleanly.
"""
import base64, os, subprocess, sys, zlib

PATCH = zlib.decompress(base64.b64decode("""
eNrtXNty40Z6vtdTtOnElCw2SIAHidJQtkYjx5Md2VMjeV27qZQLBJokJBDAAqA0yuxU5WpvsilvVXZvUqnsRaqSqs0L5CYvsy+Q
fYT8f3cDxJEEDxrP2NKMRKLR/Xf3f+5G4zOt0YhQOrZCojctx2SvlUk4tckwcbHDv5Jum6kHB6qi6Fpfa2s6UVutXqezQylNtd3Z
399Pt//8c0LV7mHjgOyLj88/3yHiZ+oGv5qxI/KGWIbrHJH6X/74h9/WG8TWh8z+GbuHkhHTw5nPFFE1gJsTn43ghqePWdD0bN2I
P3h/n4X3HhuI6nXythH15bMg1Ge+7oSp/v75f//vf74v7nLeonK38ybJroOJ66U6/f5PxT1ixcp9YWXeCxW9OG5ojSxDDy3XCVLd
/f73xd2lWpR0m6rDe4eKVvAVuzsioT9jOID9BxlA6malcUh2/8oa2npaqf6puH9eM9svLxR/RT9vGyQm7aQJ//Z3JYSdPFnQXjEV
uBkRjugOdd9wzbQl/FeJksi6WfqyOPosYBHMgzSb5M+/+R356vxb8sX56dU3r853zKQTWCB7IwjAsJfLBurtBNbUsnXfCu+JcB/9
/l/v+MzRp4yMfHdKFvcTVQ1dUq0/2YnZ6na1nqJ0O12j3e6mfdSSLoXfqtYdurQD9aChtsg+fvbApxFdcUJqTCzvaOLeMr+RKNCN
0LplINyhbtyMfXfmmEfkVvd3KfVsqhsGg5qBOwr3jonh2q6Pd1E3hq5vMp+G6D9U7zUJXNsy5y1ty2F7xzvk7Q7Zoc1PyXMnsExG
rpjNxr4+JeGEgfNhLCSBfssCcmeFk/huPSDunQNdhCEIZDiDD0chnzZ3qDILWECnuuVQUUwUz6ScEMWpABtgLqYVADNBMx3XYccw
hqJ2OC/ebuia99DI003TcsZU9HpEtJb3mrfdSfQxDB3yBqc/stlrmPgxfpct4bINjFAPoV2R6i7zGpVkzOOWw+7IyLIZRCngqVQl
oWgt8aMoZqc90nsHXMOaJrttOjPbrqxKcXhsNUCR1IbWO8TguP/ko2dfn1394uU5wRonUMBHbuvOeFCb/UONlzDdPEHP+2TKQp0Y
E90PWDiofXP1BT2skWbiHprSoHZrsTvP9cMaaJgTgsINaneWGU4GMGzLYJRfgL9wrNDSbRoYus0GakwptEKbnTy1bNPyrWDiuFMd
DPxJU5TzKqCNNxBm7UHN8xl04jADekMnNahNwtALjprNEfQdKGPXHdtM9ywwJ3ca97ECAQizoWWI1obvBoHrW2PLSVFa3nMTjFn7
bKSDs7ofvARlHumWv/9MKvbdeBJ+3mu1jg9arU+ktg+CO92rRRGPiNEG4b3NuOrWyJSZlo4TsBy4ch3b1c1BLZxAh+JWXbft+jHh
JfI2Kk3MBMcNDN/ywpOHnkR+7M2TJ824+4xEkvXEmBSlCf+h8ya/h46xQJKF7dIpTdWGOT8sWvF2iUFbI7Jru6C+l6Hrgw0qYxY+
D9l0tw7ucMrqe2QwGJC6YwFn4OKNEKbpGrMpWIUSfTm3Gb82bD0IXlhBqIAD2hXNKLqEOnheaPqW99+MB/CkKU3zCbq8aHwfgYP4
8vz02fkr8FdiqliN+YTTH9R0z/vuO1FUOxFDeqKnOD1PqWtRI1GfSoOuEc4z0Db2OqQmWJDPeRV5aBlZLGfCIDIfR91AR9Z0TALf
iHoC2iwMmmw6BB4o1964RnQb/MVTNyTnvDAeAfhxartjNxIgJzdRTy5mgW1Nyc/ZeHYDZgktgS9qNLGmLljQFBOImGRatxFdoRp8
ZhBOgE0QSNCh1mRd7EXLVMb7lPsjrM2/1Iiphzr1YPB4VxGFoOYTLRqLF1GBNreWnuBKcDtO36OYm9UIetKn7utBrUVaROvAf+CP
D7cnlmkyB/gPyRZ0Yli+AWMxoKaqAcfuxacvPiC0gJZ/rOmQ4bEamJ6nQ3AGX3HRVTpEVZVDovaUPjlQ2obSbVNFIypR1LZy2Fb6
XZuqSr9H+opmUEXtKL0ehUrKoQblrUOlq9q0TTUFLztATWn3sV4P/lOlrQC1ntK2FU2lbaXVIV3soGsoWodimdLqQi2o1D6ARppN
e8phh3QUpNiHKn3stId14aOLX2EIUNz9ZTyt0WiEc2oCDxMM9XQnIxDOcagGd2Ll8OYyRrO5giQG1IwYugMeABxsEEBL7kCJx/wA
FXwIBn/DzAZxQVMYZF+gsLZ7x0wlMre0eoE8ZZMasUy8fhpd+i6aEMaXGTgYIdJCnYD8C/WBzGkt0A/BFrRDtFLfvYE+jJkPeW54
hmYZlYowPKhpcQHmeIbuDWo8bUwVX7uWE5cXaWCsUj1yqPdIj+CIVKJqpGW0yAFpkz7+ftkOQLSkTfspPVRbSptoqg6ahioEf1r8
Xxv0s5WsOdUI/IO5tvIy9/Isp+ifspYZieNEyF+2lmkkX+/WxEUtSTBMsR8uI3GeovizfXCdwB4EpVjhQDHSKvcCojLkmqW6g9rB
oq5k5YTjSFQOPAvSGB87Fb3EbEkPzY6IzKdfMK5z3wcFbxJ3FqYT/UoD5a3zKu1l60v5JBpdYcFakgkdSM8nbhDTe8VC/z4rGJ8X
VhDMF89fXV6Rnz+/fH6VmHPA+KIk0T2beuF9PAVxkZ13mlMQE91CI5rnesJ/pZtQH/UkeUEpSEdIPOHVVmkfa0yV9kMGuWOiUqGP
+oF80jtzQBcwIaV7pkHMhBgIzqir9ODvgdK9QLekdA0VwydSgwoqVsh5Kp7EVWC46w9J4julEMBw23LN1kNszTch1yRgIIHv/5Rp
nXE3k3bWOHL5ES9NJEjtYg8hGmNqm2vLC0+S8Xu5nzAmLiw+SfyNUlg5TXU/bbynpnnqM32RMcrmXNvfU3NYMUk8QBUtvw1aHY25
aJRyJilzgiB928YPtQ+f8KFN4LLPP9exB8lzHi4yPC+uWKhyOkj2KlK7TI+lpAoVECk9lUqYHXp+LoWZnDFht/7WNETZbho37RP0
oT0Kv/lMax48S0KcYF1FIyLpS8q3Jz8oy3rg2PPDGAtf6m7HWjipEnMpomR5AV9XgydHAdwEkuK8YKnZpTO6nILeTVjKeacCD94s
YQreinniJQnM7CwF2wqy/LetEzHbAi36yx9/8wc5iczydd71V+wuZuGTJlBbgfq//vcy6me2G4h10Vod/Mu/L+vg5QQNcz36f/63
7+eZSzmD9ClbfwL/sYz813fJfHlV+nHmVkr/gj9LLuvgSXNmF6ZdUF2sS9JLmG+fX31JLr95enn26vnLq+dff3WZWb3JVSXoadH+
Q26pI0ukD+TPC21mDu/5KhgCYiAtIzHizBpREKC4F5exjFTaGNWTNijX2YU9FDmQqLnphsX+Ou+DcltGGOCDeY5a2iDfqwFxIkwN
+oyXFLq+ZPJbJYnVzXgbqSBTfdhQqXRKg+XCoAhhsHurdi66mP2pnYKIVsp/nG4x31LL9/wyJKd6SE945IRkXnAPnVnA5GxpZVv4
Vg+NyYPaQnEPD2ULd9gb8m5ze+ADr2wPS2TK04qUUF9iSWWpJmN+aHm1xTn7dqxIVQ63m3KCdbUTOSd8M/g+BFWVLulQTTkgXdw9
P1QOKW5LqEqHf2pKe0I7RosqfSpqYzHUb58dQEu1DaRUpNEj/SR92vtlJnslWmvSuVBVokG3E60oYy3Tp4lVoAj5fcl0OsdjG5ov
iU4ITJkzix92pXUEb0XaccG/i113UZ6Kect8LzahVoiPpOY0xDWfmhgNhHPTCmuL9vHfV02ChYoOXp7gr5A2LkHg98UhUQ9xxwtE
baugTd0XWPmXy567CCcu+JF58pLefq3KeZK8oNTUnTHkY4vFYTKbhexDFEiHHEzUHlqYqt7CZ0d89siBDYvL9kQFYVC1fdEnBz/v
THq37WryiBhSLpG8tT17Rprk/NnzK3L66vyUXH55fn5VZHHzgzW6cWP6rhfZ3iWWPo0LpeElDLyACImO9KSIROI2Ld12x5KFU9fU
bcnBopDMW6YCZuGox76VHvHfYMFJKrSlKsM8k+uBREpeRD4d64upZrcVHzcV19tUzAaVeVIVszqVUiU1JJGGZJ4MFao6njdLnT6r
FW9oc5Wspc2Rd6vgqTyxsPTKnhoFjD+8gQ9KtcgGQn2Y3WVY5kuRAH96GVOQIwrcmW9ACR5o4ant4972Vva2C72wEPv0/kXM7IIN
rfwaZ1PZwnrKZ0HwwYpWlbJT56KdnwyABFSlHaXd5X9Wk0TMmOViyO0sYoBEA/blgePIgOabLTljhirzZ/rGS91hdm35EwNo9Wh4
KzxUyixIkX3L98SxFp4rTsjnAi+r7Fxj22A2TDS9hKsqj4iWGDYS1sfpUZ2K6wJl9hlXQZZIs1bVYZ38zAV6DpGGsUCXsUZiT8oX
2pzdToRmI9efZtrRkcXs5I6W/wVUAk2bha7hTj1MVAc1dzRa6rFIRPFH7b4sx5uFUkvE0ZkMP3mFJD+fi4Kp/tpmzpgvU7RWjfB8
44bd4wJ8UAuY7huTWJfExsrEtU3mFzjJ89c6SiZ5DjOvw2AGUys/vpHlpMXNr6N+kX/JDnnt92F/c61HqB3cRgE3R/Cf2qIg9kKh
Fu1loq2UPZ7imyYJHn7Jr8uD2pdyk8UrN/9qWaqvm9YsqJylduKDWKKdzEqQiotvpngbpK2ciBzkzXRQ69ZONs+XskTV1oNQfZCx
akVjXfIQ1PMZGk68eSovyzdcp3q8Or7Ar3n1zy/sC084y54plGZ6v8SSlDm3Oy2i9g5rBBoFzL9lp4HHDFAqyLEGtdcXlvkL+CWB
jScOSra403mBVzCS1DE+ORZxmi/7oDdlK2zM5g7thbyKebCxxd1NLPDLiwwutGwWRAO4At0JVrEqbJ14tg5OSzyAFGxEhgfMzB9P
zGc+SAh46F5btSXPPpdSwXeIEszAcQXRO7mVsjBOJbSMm2JtQE3cRrxor39GcSoDQ0f8vlDx7P085G9jKZiT7Px94QeQbvGpwlUE
nHgD+lHIawsZX9R+APHmznyuJlv+rvmjVAuPy2YTOyI/Kb3T/Xi59xJY8rXDCmOEF90rCjv5vLGAguOGmfNM83bxLicTR/oTm6Xy
kL/IR3Sb4QufuTFU2D+VT/Fq1U78p17dTV5kTv/zIZ7pjpEKrbConLqOYojygoxpza7lUWKe++q36U3lSyx4Jzv6P8gKJrOnJjnM
uZB/slv41kXBA6crVw/CkgdMIb+H3gK/xLmPuEi/UyWeBFm3UOS5tpXYEone58CxJwhEr58kn4wtc8LYTipxajCnsqhoEyY1YfFC
JzHZiPni5cjoJdxQvnWjuP64eR3E1/SODanuecq18KuJ92j5yzu3DHTxzvVNggPnr6/hi2zIiYBYoLzidVjcQgASDcLzTGKFJJiA
WxBv78cSxlf7RQMBkUB2sYQ/xCceqCjRHZNXwlfnZgETWAAIqoAjCPYaRIdOw5ie7ANqWb54jzTgJLyJG7rEdt2bmafwd/HwNfQZ
DhyUCirhzlRMJfnebYMErkQgANImsdRDB+ZFdg818rOnewTmj+/zOYyZcHfCfKak6KCcLnQHKPnYDKrjS1JQdXifhhrBu3hOD1mF
RDnB+MW/AkHm3kCWLM9KrUJLOak1WnLGBlXbwn/QNN2zzlxnZI0rNcsyKdUCX1SWLyg/aQqYgapAINfVcECui2BAepVhQK5XQwG5
jkBA1INWx+wfKEqn1++1WKsyCMh1dQyQawEB0kFMo06jzxGNmk1hzq5j35Mp11tUSz0koW+NQYm5cU2VpB+YW1DG+BWkx2k+Tbzy
KlwV2AEHBgCDQRvOQ0p8FoSuN+AEj55Y5glx/R0KpEQ5Zhi8GDEIYHQzJ5gNUS2GOBTLD8IGDtRB1KK7QPgZfEdvZ39jEuRCTCTg
tAKImGTIRq7P4ipk6t5KZyBmGcu+FI6owYkJXwm0IEEzA2wWO9g5Lxd6FS437kZqF/dx1RrWAPdpcm/mesyxnDEnFg/ZdJnwZBDf
fDCd+aOmkfVa4YqitXuoKlp7Dn8FFC4nrh8asxCdfyhcZTjxmfTrBJ8h8yiAzOCOHV8V5J2gfhAymjniACQGwRd4AH93T+CmIC5F
OPMdgiAil8pU93bjyrshVqIkWa3+RM8c9Y8wF3KoU3WyT0L4rWcOYMh2C1Ys0DLy70u7zXnLbQ0gXuScX3z9t8//Lvx7pCQzC6TM
AmP3arculkhxV0F9b09U1E/qx4LI2z0Fc7bdOuJA4LVwCa0WdwotTUo6JSjUH34actd372JZ3eo+FyEZQKJ0h3AVpyH4DLB2tluP
15H1PfLrX5O6BDY7FhK8A58HTSKNU5B7QKYuERFMFuqWnWEecxAf6ptXz8/cqQdprBPu4r29SDxlNLMyWZm65Hz9E0jHSqqWzJ93
CDKQjCac1V1Va7T7ZL+rdjgAU4bXVsDz/K+B5WgWkc599BFfIBwLzCRuhxnUpAbBtQHafRYpSaSc6NFFXoW4Se4IryQl8IGMOUc8
Zwv1e8ighuDPePUbdj90wTehp7LBcc8f4kFHyCEzMvUEORwpdC47vnNnNmQ/mHhBCMEU59wOWNxIIj3dMOZhZhc1A19BE2zBp6hP
+Y3d2A+EEI9il4DwKeGYfPIJCccKogE9AwnIy4u4ca5ACVj4UgdmBXsRq1P3pcK+JQZPUXdBI968FWWyOqLg8FqIBpUcMkaRi4Jh
o91Mh6CayTnJfv5qty4XevW9BIRL6I7HNmhVFqiq3gDFmA6j1sgDvJRDOy5g03SouKPRmQ3r/F1cVkVNxR2n5EbMpN03BEP9EQFn
k1ic1SEvx/LvJFZLHYE04IcDuX13awXW0GYR4N1eEU+jzkoY4DOMsAUMiIkVSQD8KFtVApvyEPt86btjtJHd3J3dvVKF4mBiGafL
GbGLeUvsdQ18rwoPH+/uSY8u7GcAFbh7OeCQld3OgfQuaa7yQ2nAWpTWmcDfgaZXvA/yGanPN3LwpK2oTY6S5WD/kkjUP0ts4cRx
hfAE5QXTRzZMIZp21iaOo7APObAvZotl8wATHf2EQc4nER39xK5wzr2WmPNBLzHnACc7Ze4sTCQR6FG5hDnT9mLyigi50AvqKHjZ
BtEOW9HwcCDiabkcRfwwPJ4sEo2xmARunkRi4rBNvPWe+FCG9syPOZLV0ZgjkLL6DGe6m44fh2q3oSGA36EWZ2VvM0Fk5kH8YRgP
0krv3sAMDN0Rd3I+55KbsmJagQ72akLdj9yb48o2g4E+Ymy59WBlXgk9B6SGCeMXvgZUJDagkQ6hYm5FbwmD60yDEovjoeiUxJNJ
BAHcFgjmOws6bhlAWBf1IKLjRkcAa5wUKcO2QJpBvD2Arm4GS1aMlxA4Q9dV0vNI+ExwgkInjkAEjQjRCqQBFvdxq9vv9frcyj7u
j4ZdfVifO0np2XIOY3+p5BJinmsIzAMXlC8Q1lE+rTwiCN8REI6cJ6AWcXri+fwxLBMgJIP1g0R1O9q6ARoCH1fT+GJSVcHr9BII
ucKgY21OSD12ZNX8UhD7oucm+WjAo+3qfiqWS4n/KfJBEfdl1nxceZ8hBddYWkMu+7Vup6NqXUUZ9Q/14aj6sj8BWrysFl/KNbRe
F5ZyDbXDxZSDZiQSmpEsgGakW4Vm3JiS0uK0yHKYR7opzCPdGswjfQcwj/RhYB7p+wTzSNeEeVzWLgPuSNcCd6TzZw/gSlN1kvtF
JTuECnkqd8wsjnMbby/LDbUgtweF5GDphvvnmDaKTSS5UOMBC3xWtMmU3Ir3WYMvvHCHRuyR/fkf/zPegv84HH/Lhqeex5dSfMss
Ru4C4oHYqyYJGEu6BowlXR/GkkoYy/nGOywUuAB3cdm/FIkbFvNxQ3FsMVky0YOJCATz/WcSwWRSCZPJFxxZmEy6BCaTvhuYTLpd
mEy6HCaTxjCZNAmTKZhUDSaTSiIbw2TSEphM+giTuV2YTFoRJpPG7+NGMt4STCbdGCaTPsJkrgaTSTeCyaTvBiaTJs4FJFUuCZNJ
q8Nk0uUwmbQSTGbZuBbCZC4daAYmk64Fk7miZNaEySxjQBYmk64Bk0lXhMmkG8Jkrtw+A5NJq8Bk0keYzHVhMmn2PSm6EUzmiq3z
MJkrEsjAZNLUuT+6EUwmXRsmk1b1E6vCZNJqMJn08VXitd9orG4PaeQ/uj2YzOWkKsJkLprLjwUmk2ZPO9KSEBfDZFYxojKYzA/H
st4JTOa7NpYimMw1raUAJpNuCSazjCvpjK4MJpNuCpNJl8Nk0geFyaxOfU2YzOodrAeTWZX+2jCZK0xgLZjM6vTXhMmkaZjMgrQr
AQKXXMKUwGTSxTCZdHOYTFoNGpCuD5NJtwENSFeFyazU61KYTJqFBaQbwmTSDxQmczn/UzCZtOjVcpqBVKRrw2TSHKAiXdMWUiCW
D2ILxT08lC2UwmSubg9FMJnl9rBEplVgMhdJNQ+TSR9hMrcIk0lXhMmkCZhMmpZ/Mp1bAJNJ14TJpA8Ak0l/SjCZtDJMJi3w3+8G
JvODE8gGMJl0BZjMvETy1lYKk0m3AZNJ3y1MJn1YmEy6DCaTVoDJpI+bipttKmaDyuowmUVPhirDZNL1YTLpOjCZ9CFgMh/3trew
t70iTCZdtMbZHkzmhynatXDmqkgiB5NZLobczuJCmEy6AkzmsicGjzCZqz1UKofJpBvAZNK1YTIX7OC/K5jMqjpcCJNJ14HJpNuC
yaQ/UZhM+j7DZNJ3AZP5w+9vbh1kZtlepoDJpNuGySwz/zVgMpdnqVVgMtdNbRbCZG6LaBomc2tUH2SsWtFYlzwELYXJpNuCyaTv
EUwm3Qgmk64Jk7mZxSVhMml1mMzKSrUaTCbdCkzmMirVYDKXUfkxYO1tshRcHSZzE+kWnyrcGCbzUcjbg8ncRLy5M58bwWT+tKWa
O53/IDCZdE2YTLpFmMyq+6dzmMwqJ3kfCCZzw64rwGTSH+kKpgpMJi00hgWPd+cwmfSBYDJpBZjMSg8nV4fJzE54azCZdD2YzCJM
yli+8ZbmJpiUdMuYlMVcK0eiXFi/AH9yYf1C1Em6HuokXRl1ElRmjjrJP6NLshyEMo06ZgRBFrEhV0FCQxhtva9qfUVR+wfDdk9b
AA2RJ1GADJGvxCE8Wv1OQ22Rff4lwvAY2ew1+Frfcm6OSOt4R8CONT/Ngo5JJJSp5wbISFiKCbzXHAaZQB0T1qiQT5s7VMliOREl
G57IGyIxAaKXnN8ubscfC74BwzPxdTsqej0iWst7fSwAlpRUQHkTzfWIqPxNb9kSLtvea6IeQrvKor1eItkY6tNsqx1t1FaUTrfd
bavDyoK9riBXifGpHnYPGx2EZsEvKFaE1gAf/hXq+T0ZkDQqUgJxKXQEzJFnnjrOJYg0BjmCW0mIGURHi8uzwC1AF2FaHAdinsEU
VA1grMBoiQv5hmUM0LIMYgjuffIJuCWBjZfADUrhC4m6roNQTyVwQlgu5wEdRAg7+CPghQpQhbBIIASlWhThwiWhyPIwfcKNAzci
eLwcYF9jO1B9EDuB4Ql0vgiXT1JaE51vjij4k0XoE4bxsCB9hYh7OcOJoaRiFKkyHL70hn78kwCmwkR0EVxfBvcONLgYOzBxowzh
r4SB7y/IX3ay64H8FQC1uY5AeAOfw4H9IvgpCcuq9lUIzm304gfthqpVdOMRi18K/NGMb+bxQuEQ1YjMGgHDRo1eMd2YQKM0Il6M
qZdA+duP0P+Eb4/B2nhVAUHHjx1LILAyUD/eaxLSL64XIRtmVCaKOjnsPj6AUqRBumi4PsO9zvDUgTUlcvMLsD1WxNtEvxlsGmk3
9Tl4mAAvK68mRNztcgi1vtquHKcrYBsmupUwK0Gi71WQDzk05FwIuFyrCnsokCvxbyXQQ2GAETzRWEGlkEEgtkVhMXMeZ6pJLzTR
HdMWXcQ3JcO1lnooEt7+QZcjKC7j+M4cXRgkCAs98f4Oc0Cx69ES7myCB2NNcMAF8prD4cXupyCNKVHZlNLKPGruEffzBAurSxC7
5GS4eziVMQUBRMkUzfVIfJC3xzv/DzPkpKU=
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
