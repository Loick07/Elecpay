# Outil local (jamais en CI) : il lance des commandes FIXES (adb, ffmpeg), sans entrée extérieure.
# ruff: noqa: S603, S607
"""Montage de la vidéo de démonstration ElecPay.

Pillow pour les images fixes, ffmpeg pour la vidéo.

Entrées : build/video/rush/tournage.json et part*.mp4 (écrits par tool/video/tournage.py).
Sortie  : chemin donné en argument (par défaut build/video/montage/ElecPay-demo.mp4).
ffmpeg : dossier `FFMPEG_BIN` s'il est défini, sinon celui de WinGet (Gyan.FFmpeg 9.1).
Jamais encore essayé sur un vrai tournage : vérifier les légendes image par image.

Image 1080 × 1920 (9:16) : écran du téléphone au centre, coins arrondis, nom de l'écran dans un
bandeau en bas, « Mode démo · données simulées » en petit ; carton de titre et carton de fin.
Couleurs et police de la charte (navy #050D1A, jaune #F5A623, Poppins embarquée dans l'app).

Usage (depuis frontend/mobile) : python tool/video/montage.py [sortie.mp4] [--latence=0.30]
"""

import json
import os
import shutil
import subprocess
import sys
from pathlib import Path

from PIL import Image, ImageChops, ImageDraw, ImageFilter, ImageFont

MOBILE = Path(__file__).resolve().parents[2]  # frontend/mobile
RUSH = MOBILE / "build" / "video" / "rush"
WORK = MOBILE / "build" / "video" / "montage"
FONTS = MOBILE / "assets" / "fonts"
ICON = MOBILE / "assets" / "launcher" / "icon.png"
FFBIN = Path(
    os.environ.get("FFMPEG_BIN")
    or Path(os.environ.get("LOCALAPPDATA", ""))
    / r"Microsoft\WinGet\Packages\Gyan.FFmpeg_Microsoft.Winget.Source_8wekyb3d8bbwe"
    / "ffmpeg-9.1-full_build"
    / "bin"
)
FFMPEG, FFPROBE = str(FFBIN / "ffmpeg.exe"), str(FFBIN / "ffprobe.exe")

args = [a for a in sys.argv[1:] if not a.startswith("--")]
opts = dict(
    a[2:].split("=", 1) if "=" in a else (a[2:], "1") for a in sys.argv[1:] if a.startswith("--")
)
OUT = Path(args[0]) if args else WORK / "ElecPay-demo.mp4"

W, H, FPS = 1080, 1920, 30
NAVY, YELLOW, WHITE, MUTED = (5, 13, 26), (245, 166, 35), (255, 255, 255), (143, 160, 184)
BEZEL, BEZEL_LINE = (11, 21, 38), (38, 54, 82)
SW, SH = 696, 1558  # écran du téléphone (720 × 1612) réduit, proportions gardées
SX, SY = (W - SW) // 2, 60
RADIUS = 36
BAND_TOP = SY + SH + 14  # haut du bandeau des légendes
CAPTION_Y = BAND_TOP + 78
TITLE_S, END_S, XF = 3.5, 4.5, 0.5  # durées des cartons et des fondus enchaînés
SHIFT = -0.30  # le repère arrive ~0,3 s après l'affichage de l'écran (waitFor + 300 ms)


def font(weight, size):
    return ImageFont.truetype(str(FONTS / f"Poppins-{weight}.ttf"), size)


def run(cmd, **kw):
    return subprocess.run(
        cmd, capture_output=True, text=True, encoding="utf-8", errors="replace", **kw
    )


# ---------------------------------------------------------------- images fixes (Pillow)


def backdrop():
    """Fond navy avec deux halos très doux (bleu en haut, jaune en bas)."""
    img = Image.new("RGB", (W, H), NAVY)
    glow = Image.new("RGB", (W, H), (0, 0, 0))
    d = ImageDraw.Draw(glow)
    d.ellipse((-420, -380, 640, 680), fill=(8, 38, 78))
    d.ellipse((520, 1380, 1500, 2300), fill=(46, 30, 5))
    return ImageChops.add(img, glow.filter(ImageFilter.GaussianBlur(230)))


def centered(d, y, text, fnt, fill, max_width=W - 120):
    while fnt.getlength(text) > max_width:
        fnt = ImageFont.truetype(fnt.path, fnt.size - 2)
    d.text(((W - fnt.getlength(text)) / 2, y), text, font=fnt, fill=fill)


def phone_layers():
    """Fond (halos, bandeau) et premier plan (cadre du téléphone, coins arrondis de l'écran)."""
    bg = backdrop()
    d = ImageDraw.Draw(bg)
    # ombre portée sous le téléphone
    shadow = Image.new("L", (W, H), 0)
    ImageDraw.Draw(shadow).rounded_rectangle(
        (SX - 8, SY + 10, SX + SW + 8, SY + SH + 26), RADIUS + 14, fill=150
    )
    bg.paste(
        Image.new("RGB", (W, H), (0, 0, 0)), (0, 0), shadow.filter(ImageFilter.GaussianBlur(24))
    )
    d = ImageDraw.Draw(bg)
    d.rounded_rectangle((W / 2 - 30, BAND_TOP + 44, W / 2 + 30, BAND_TOP + 50), 3, fill=YELLOW)
    centered(d, BAND_TOP + 186, "Mode démo · données simulées", font("Regular", 28), MUTED)
    bg.save(WORK / "fond.png")

    fg = Image.new("RGBA", (W, H), (0, 0, 0, 0))
    fd = ImageDraw.Draw(fg)
    fd.rounded_rectangle(
        (SX - 12, SY - 12, SX + SW + 11, SY + SH + 11), RADIUS + 12, fill=BEZEL + (255,)
    )
    fd.rounded_rectangle(
        (SX - 12, SY - 12, SX + SW + 11, SY + SH + 11),
        RADIUS + 12,
        outline=BEZEL_LINE + (255,),
        width=2,
    )
    hole = Image.new("L", (W, H), 0)
    ImageDraw.Draw(hole).rounded_rectangle((SX, SY, SX + SW - 1, SY + SH - 1), RADIUS, fill=255)
    alpha = ImageChops.subtract(fg.getchannel("A"), hole)
    fg.putalpha(alpha)
    fg.save(WORK / "cadre.png")


def card(name, lines, icon_y):
    img = backdrop()
    icon = Image.open(ICON).convert("RGBA").resize((220, 220), Image.LANCZOS)
    img.paste(icon, ((W - 220) // 2, icon_y), icon)
    d = ImageDraw.Draw(img)
    y = icon_y + 300
    for text, weight, size, color, gap in lines:
        centered(d, y, text, font(weight, size), color)
        y += gap
    img.save(WORK / name)


# ---------------------------------------------------------------- analyse des rushes


def frames(path):
    out = run(
        [
            FFPROBE,
            "-v",
            "error",
            "-select_streams",
            "v:0",
            "-show_entries",
            "frame=pts_time",
            "-of",
            "csv=p=0",
            str(path),
        ]
    ).stdout
    return [float(x.strip(",")) for x in out.split() if x.strip(",") not in ("", "N/A")]


def main():
    WORK.mkdir(parents=True, exist_ok=True)
    data = json.loads((RUSH / "tournage.json").read_text("utf-8"))
    segs = [s for s in data["segments"] if s.get("pulled")]
    markers = sorted(data["markers"], key=lambda m: m["ms"])
    fin_ms = next(e["fin_ms"] for e in data["events"] if "fin_ms" in e)
    start1 = segs[0]["phone_start_ms"] / 1000
    for s in segs:
        s["frames"] = frames(RUSH / f"part{s['index']}.mp4")
        s["off"] = s["phone_start_ms"] / 1000 - start1  # place sur la ligne de temps (même latence)
        print(
            f"segment {s['index']} : décalage {s['off']:.3f} s, {len(s['frames'])} images, "
            f"de {s['frames'][0]:.3f} à {s['frames'][-1]:.3f} s"
        )

    # Latence entre `date` et la première image : la première image après le repère « Démarrage »
    # est l'écran de démarrage (rien ne bouge à l'écran pendant les 4 s d'attente avant).
    m0 = markers[0]["ms"] / 1000 - start1
    later = [p for p in segs[0]["frames"] if p >= max(0.3, m0 - 1.5)]
    first_splash = later[0]
    latency = float(opts.get("latence", m0 + 0.08 - first_splash))
    if not 0.0 <= latency <= 1.5:
        print(f"latence calculée improbable ({latency:.3f} s) : 0,30 s retenu")
        latency = 0.30
    print(
        f"repère Démarrage à {m0:.3f} s après `date` ; "
        f"première image suivante à {first_splash:.3f} s ; latence retenue {latency:.3f} s"
    )

    def t_of(ms):  # temps sur la ligne de temps brute (0 = première image du segment 1)
        return ms / 1000 - start1 - latency

    tb = max(0.0, first_splash - 0.05)
    te = t_of(fin_ms) + 1.0
    dm = te - tb
    print(f"film de l'écran : {tb:.2f} s → {te:.2f} s ({dm:.1f} s)")

    # Légendes : un nom par écran, doublons consécutifs fusionnés.
    caps = []
    for m in markers:
        if caps and caps[-1]["name"] == m["name"]:
            continue
        caps.append({"name": m["name"], "a": max(0.0, t_of(m["ms"]) - tb + SHIFT)})
    caps[0]["a"] = 0.0
    for i, c in enumerate(caps):
        c["b"] = caps[i + 1]["a"] if i + 1 < len(caps) else dm

    # ------------------------------------------------------------ images fixes
    phone_layers()
    card(
        "titre.png",
        [
            ("ElecPay — Démonstration", "Bold", 66, WHITE, 104),
            ("(données simulées)", "Medium", 44, MUTED, 0),
        ],
        610,
    )
    card("fin.png", [("ElecPay — Loick Makosso", "Bold", 64, WHITE, 0)], 660)
    shutil.copy(FONTS / "Poppins-SemiBold.ttf", WORK / "semibold.ttf")
    cap_font = font("SemiBold", 54)

    # ------------------------------------------------------------ graphe ffmpeg
    n = len(segs)
    g = []
    for k, s in enumerate(segs):
        span = (segs[k + 1]["off"] if k + 1 < n else te) - s["off"]
        g.append(
            f"[{k}:v]fps={FPS},setpts=PTS-STARTPTS,"
            f"tpad=stop_mode=clone:stop_duration={span + 3:.3f},"
            f"trim=duration={span:.3f},setpts=PTS-STARTPTS[s{k}]"
        )
    g.append("".join(f"[s{k}]" for k in range(n)) + f"concat=n={n}:v=1:a=0[raw]")
    g.append(
        f"[raw]trim=start={tb:.3f}:end={te:.3f},setpts=PTS-STARTPTS,"
        f"scale={SW}:{SH}:flags=lanczos,format=yuv420p[scr]"
    )
    g.append(f"[{n}:v][scr]overlay={SX}:{SY}:shortest=1[a]")
    chain = f"[a][{n + 1}:v]overlay=0:0:shortest=1"
    for i, c in enumerate(caps):
        (WORK / f"legende{i:02d}.txt").write_text(c["name"], "utf-8")
        size = 54
        while ImageFont.truetype(cap_font.path, size).getlength(c["name"]) > W - 140:
            size -= 2
        a, b = c["a"], c["b"]
        chain += (
            f",drawtext=fontfile=semibold.ttf:textfile=legende{i:02d}.txt:expansion=none:"
            f"fontsize={size}:fontcolor=white:x=(w-text_w)/2:y={CAPTION_Y + (54 - size) // 2}:"
            f"enable='between(t,{a:.3f},{b:.3f})':alpha='min(1,(t-{a:.3f})/0.25)'"
        )
    g.append(chain + f",fps={FPS},format=yuv420p,settb=AVTB[main]")
    g.append(f"[{n + 2}:v]fps={FPS},format=yuv420p,settb=AVTB,fade=t=in:st=0:d=0.6[ti]")
    g.append(
        f"[{n + 3}:v]fps={FPS},format=yuv420p,settb=AVTB,fade=t=out:st={END_S - 0.9}:d=0.9[en]"
    )
    g.append(f"[ti][main]xfade=transition=fade:duration={XF}:offset={TITLE_S - XF}[x1]")
    total = TITLE_S + dm + END_S - 2 * XF
    g.append(f"[x1][en]xfade=transition=fade:duration={XF}:offset={TITLE_S + dm - 2 * XF:.3f}[v]")
    (WORK / "graphe.txt").write_text(";\n".join(g), "utf-8")

    cmd = [FFMPEG, "-hide_banner", "-y"]
    for s in segs:
        cmd += ["-i", str(RUSH / f"part{s['index']}.mp4")]
    cmd += ["-loop", "1", "-framerate", str(FPS), "-t", f"{dm:.3f}", "-i", "fond.png"]
    cmd += ["-loop", "1", "-framerate", str(FPS), "-t", f"{dm:.3f}", "-i", "cadre.png"]
    cmd += ["-loop", "1", "-framerate", str(FPS), "-t", str(TITLE_S), "-i", "titre.png"]
    cmd += ["-loop", "1", "-framerate", str(FPS), "-t", str(END_S), "-i", "fin.png"]
    cmd += [
        "-f",
        "lavfi",
        "-t",
        f"{total:.3f}",
        "-i",
        "anullsrc=channel_layout=stereo:sample_rate=48000",
    ]
    cmd += ["-/filter_complex", "graphe.txt", "-map", "[v]", "-map", f"{n + 4}:a"]
    cmd += [
        "-c:v",
        "libx264",
        "-preset",
        "slow",
        "-crf",
        "19",
        "-profile:v",
        "high",
        "-pix_fmt",
        "yuv420p",
        "-r",
        str(FPS),
        "-c:a",
        "aac",
        "-b:a",
        "96k",
        "-t",
        f"{total:.3f}",
        "-movflags",
        "+faststart",
        "-metadata",
        "title=ElecPay — Démonstration (données simulées)",
        "-metadata",
        "artist=Loick Makosso",
        str(OUT.resolve()),
    ]
    OUT.parent.mkdir(parents=True, exist_ok=True)
    print(f"montage : {len(caps)} légendes, durée prévue {total:.1f} s → {OUT}")
    for c in caps:
        print(f"  {c['a'] + TITLE_S - XF:7.2f} s  {c['name']}")
    res = run(cmd, cwd=WORK)
    if res.returncode != 0:
        print(res.stderr[-4000:])
        sys.exit(1)
    (WORK / "legendes.json").write_text(
        json.dumps(
            {"latence": latency, "tb": tb, "te": te, "titre": TITLE_S - XF, "legendes": caps},
            ensure_ascii=False,
            indent=2,
        ),
        "utf-8",
    )
    print("vidéo écrite")


if __name__ == "__main__":
    main()
