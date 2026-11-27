# Outil local (jamais en CI) : il lance des commandes FIXES (adb, ffmpeg), sans entrée extérieure.
# Journal ouvert pendant tout le tournage, fermé à la fin.
# ruff: noqa: S603, S607, SIM115
"""Pilote du tournage de la vidéo de démonstration (côté PC).

Lit les repères écrits par integration_test/demo_video_test.dart dans le journal du téléphone
(logcat, étiquette `flutter`) :
  DEMO_PRET            -> lance l'enregistrement de l'écran (screenrecord) ;
  DEMO_ECRAN|ms|Nom    -> note l'écran (nom écrit sous la vidéo au montage) ;
  DEMO_PDF             -> attend le lecteur PDF, le laisse ~4 s à l'écran, puis « retour » ;
  DEMO_FIN|ms          -> arrête l'enregistrement, récupère les fichiers.

screenrecord s'arrête seul à 180 s : l'enregistrement est découpé en segments, relancés pendant
une pause fixe d'un écran (repère « sûr » + 0,8 s), jamais pendant une animation. Le montage comble
le petit trou entre deux segments avec la dernière image (écran immobile à ce moment-là).

Usage (depuis frontend/mobile, AVANT de lancer le parcours) :
  python tool/video/tournage.py <numéro de série adb>
Rushes et journal : build/video/rush/ (jamais commités). Mode d'emploi complet : JOURNAL.md.
"""

import json
import re
import subprocess
import sys
import threading
import time
from pathlib import Path

SERIAL = sys.argv[1]
MOBILE = Path(__file__).resolve().parents[2]  # frontend/mobile
RUSH = MOBILE / "build" / "video" / "rush"
DEVICE_DIR = "/sdcard/ep_demo"
APP = "cg.elecpay.client"

# Écrans suivis d'une pause immobile d'au moins 3 s : on peut y couper l'enregistrement.
SAFE = {
    "Connexion",
    "Mot de passe oublié",
    "Accueil",
    "Notifications",
    "Mes factures",
    "Détail d’une facture",
    "Paiement Mobile Money",
    "Reçu",
    "Historique des paiements",
    "Consommation · Jour",
    "Consommation · Semaine",
    "Consommation · Mois",
    "Consommation · Année",
    "Compteurs et foyers",
    "Compte et paramètres",
    "Assistance",
}
ROTATE_AFTER = 95.0  # s : au-delà, on relance au prochain écran sûr (limite dure : 180 s)
IDLE_TIMEOUT = 150.0  # s sans repère pendant l'enregistrement : le test a sans doute échoué
WAIT_READY = 20 * 60  # s : attente maximale de DEMO_PRET (préparation de la base + compilation)


def adb(*args, check=False, timeout=30):
    return subprocess.run(
        ["adb", "-s", SERIAL, *args],
        capture_output=True,
        text=True,
        encoding="utf-8",
        errors="replace",
        timeout=timeout,
        check=check,
    )


def log(text):
    print(f"[{time.strftime('%H:%M:%S')}] {text}", flush=True)


class Recorder:
    """Segments successifs de screenrecord ; un seul à la fois."""

    def __init__(self):
        self.lock = threading.Lock()
        self.segments = []  # {index, file, phone_start_ms, pc_start}
        self.proc = None
        self.stopping = False
        self.watcher = None

    def _start_segment(self):
        index = len(self.segments) + 1
        remote = f"{DEVICE_DIR}/part{index}.mp4"
        # `date` juste avant screenrecord : heure du téléphone au début du segment.
        cmd = f"date +%s%3N; exec screenrecord --bit-rate 12000000 --time-limit 180 {remote}"
        proc = subprocess.Popen(
            ["adb", "-s", SERIAL, "shell", cmd],
            stdout=subprocess.PIPE,
            stderr=subprocess.STDOUT,
            text=True,
            encoding="utf-8",
            errors="replace",
        )
        first = proc.stdout.readline().strip()
        phone_ms = int(first) if first.isdigit() else None
        seg = {
            "index": index,
            "remote": remote,
            "phone_start_ms": phone_ms,
            "pc_start": time.time(),
        }
        self.segments.append(seg)
        self.proc = proc
        log(f"segment {index} lancé (téléphone {phone_ms})")
        self.watcher = threading.Thread(target=self._watch, args=(proc, seg), daemon=True)
        self.watcher.start()

    def _watch(self, proc, seg):
        rest = proc.stdout.read()
        proc.wait()
        seg["pc_end"] = time.time()
        if rest.strip():
            seg["output"] = rest.strip()
        with self.lock:
            # Fin par la limite de 180 s (pas demandée) : on enchaîne tout de suite.
            if self.proc is proc and not self.stopping and not seg.get("rotating"):
                log(f"segment {seg['index']} terminé seul (limite) : relance immédiate")
                seg["ended_by_limit"] = True
                self._start_segment()

    def start(self):
        with self.lock:
            adb("shell", f"rm -rf {DEVICE_DIR}; mkdir -p {DEVICE_DIR}")
            self._start_segment()

    def _interrupt_current(self):
        proc = self.proc
        self.segments[-1]["rotating"] = True
        # SIGINT au seul processus screenrecord : il termine proprement le mp4. (Jamais `pkill` :
        # sur l'itel, `pkill -2 screenrecord` vise aussi des processus du système.)
        adb("shell", 'p=$(pidof screenrecord); [ -n "$p" ] && kill -2 $p')
        try:
            proc.wait(timeout=15)
        except subprocess.TimeoutExpired:
            log("screenrecord ne s'arrête pas : kill -9")
            adb("shell", 'p=$(pidof screenrecord); [ -n "$p" ] && kill -9 $p')
            proc.wait(timeout=10)
        time.sleep(0.3)

    def elapsed(self):
        return time.time() - self.segments[-1]["pc_start"] if self.segments else 0.0

    def rotate(self):
        with self.lock:
            if self.stopping:
                return
            self._interrupt_current()
            self._start_segment()

    def stop(self):
        with self.lock:
            self.stopping = True
            if self.proc and self.proc.poll() is None:
                self._interrupt_current()


def focus():
    out = adb("shell", "dumpsys window | grep mCurrentFocus").stdout
    return out.strip()


def handle_pdf(events):
    """Laisse le PDF à l'écran ~4 s, puis « retour » (jamais quand ElecPay est devant)."""
    end = time.time() + 25
    while time.time() < end:
        f = focus()
        if f and APP not in f and "null" not in f:
            events.append({"pdf_viewer": f, "pc": time.time()})
            log(f"lecteur PDF au premier plan : {f}")
            break
        time.sleep(0.4)
    else:
        log("lecteur PDF jamais vu au premier plan")
        return
    time.sleep(4.5)
    for attempt in range(4):
        f = focus()
        if APP in f:
            log("retour dans ElecPay")
            return
        log(f"retour ({attempt + 1}) depuis : {f}")
        adb("shell", "input keyevent 4")
        time.sleep(1.5)


def main():
    RUSH.mkdir(parents=True, exist_ok=True)
    adb("logcat", "-c")
    reader = subprocess.Popen(
        ["adb", "-s", SERIAL, "logcat", "-v", "epoch", "-s", "flutter:I"],
        stdout=subprocess.PIPE,
        stderr=subprocess.STDOUT,
        text=True,
        encoding="utf-8",
        errors="replace",
    )
    recorder = Recorder()
    markers, events = [], []
    full_log = open(RUSH / "logcat-flutter.txt", "w", encoding="utf-8")
    pattern = re.compile(r"(DEMO_[A-Z]+)(\|.*)?$")
    started = None
    last_marker = time.time()
    result = "incomplet"
    begin = time.time()

    # Lecture du journal dans un fil : la boucle principale garde la main sur les délais.
    lines = []
    lines_lock = threading.Lock()

    def pump():
        for line in reader.stdout:
            with lines_lock:
                lines.append(line)

    threading.Thread(target=pump, daemon=True).start()
    log("en attente de DEMO_PRET…")
    finished = False
    while not finished:
        time.sleep(0.05)
        with lines_lock:
            batch, lines[:] = lines[:], []
        for line in batch:
            full_log.write(line)
            m = pattern.search(line.rstrip())
            if not m:
                continue
            kind, rest = m.group(1), (m.group(2) or "")[1:]
            last_marker = time.time()
            if kind == "DEMO_PRET" and started is None:
                started = time.time()
                recorder.start()
            elif kind == "DEMO_ECRAN" and started is not None:
                ms, name = rest.split("|", 1)
                markers.append({"ms": int(ms), "name": name})
                log(f"écran : {name}")
                if name in SAFE and recorder.elapsed() > ROTATE_AFTER:

                    def later():
                        time.sleep(0.8)
                        log("relance de l'enregistrement pendant la pause")
                        recorder.rotate()

                    threading.Thread(target=later, daemon=True).start()
            elif kind == "DEMO_PDF" and started is not None:
                events.append({"pdf_marker": True, "pc": time.time()})
                threading.Thread(target=handle_pdf, args=(events,), daemon=True).start()
            elif kind == "DEMO_FIN" and started is not None:
                events.append({"fin_ms": int(rest), "pc": time.time()})
                log("DEMO_FIN : arrêt dans 1,5 s")
                time.sleep(1.5)
                result = "complet"
                finished = True
                break
        full_log.flush()
        if started is None and time.time() - begin > WAIT_READY:
            log("DEMO_PRET jamais reçu")
            break
        if started is not None and not finished and time.time() - last_marker > IDLE_TIMEOUT:
            log("plus aucun repère depuis 150 s : le test a sans doute échoué")
            break

    recorder.stop()
    reader.terminate()
    full_log.close()
    for seg in recorder.segments:
        local = RUSH / f"part{seg['index']}.mp4"
        r = adb("pull", seg["remote"], str(local), timeout=120)
        seg["local"] = str(local)
        seg["pulled"] = r.returncode == 0
        log(f"récupéré {local.name} : {r.returncode == 0}")
    if started is not None:
        adb("shell", f"rm -rf {DEVICE_DIR}")
    data = {"result": result, "segments": recorder.segments, "markers": markers, "events": events}
    (RUSH / "tournage.json").write_text(json.dumps(data, ensure_ascii=False, indent=2), "utf-8")
    log(f"fin du tournage : {result}, {len(recorder.segments)} segment(s), {len(markers)} écrans")


if __name__ == "__main__":
    main()
