"""Limitation des tentatives (fenêtres glissantes, en mémoire).

    limiter.consume("login:ip:196.44.0.1", Limit(20, 900))   # compte ET vérifie
    limiter.check("login:phone:+242…", Limit(5, 900))         # vérifie seulement
    limiter.record("login:phone:+242…", Limit(5, 900))        # compte seulement (un échec)

Les compteurs vivent dans la mémoire du processus : suffisant pour une API qui tourne en
un seul processus (sans Redis, exclu pour l'instant). Le passage à plusieurs processus
ou serveurs est prévu en B11. Chaque application FastAPI a son propre limiteur.
"""

import math
import threading
import time
from collections import deque
from collections.abc import Callable
from dataclasses import dataclass

from fastapi import Request

from app.core.errors import TooManyAttemptsError

CLEANUP_EVERY = 1_000  # opérations entre deux nettoyages des compteurs oubliés
MAX_WINDOW_SECONDS = 24 * 3600


@dataclass(frozen=True, slots=True)
class Limit:
    max_events: int
    window_seconds: int


class RateLimiter:
    def __init__(self, clock: Callable[[], float] = time.monotonic) -> None:
        self._clock = clock
        self._events: dict[str, deque[float]] = {}
        self._lock = threading.Lock()  # FastAPI exécute les routes synchrones en parallèle
        self._operations = 0

    def retry_after(self, key: str, limit: Limit) -> int | None:
        """Secondes à attendre si la limite est atteinte, sinon None."""
        with self._lock:
            return self._retry_after(key, limit, self._clock())

    def check(self, key: str, limit: Limit) -> None:
        """Lève `TooManyAttemptsError` si la limite est atteinte (sans rien compter)."""
        wait = self.retry_after(key, limit)
        if wait is not None:
            raise TooManyAttemptsError(wait)

    def record(self, key: str, limit: Limit) -> None:
        """Compte un événement (ex. un échec de connexion)."""
        with self._lock:
            now = self._clock()
            self._prune(key, limit, now)
            self._events.setdefault(key, deque()).append(now)
            self._maybe_cleanup(now)

    def consume(self, key: str, limit: Limit) -> None:
        """Vérifie puis compte, en une seule opération (deux requêtes simultanées ne peuvent
        pas passer toutes les deux sur la dernière place)."""
        with self._lock:
            now = self._clock()
            wait = self._retry_after(key, limit, now)
            if wait is not None:
                raise TooManyAttemptsError(wait)
            self._events.setdefault(key, deque()).append(now)
            self._maybe_cleanup(now)

    def reset(self, key: str) -> None:
        with self._lock:
            self._events.pop(key, None)

    def __len__(self) -> int:
        """Nombre de compteurs actifs (pour les tests et la supervision)."""
        return len(self._events)

    # --- Interne --------------------------------------------------------------------

    def _prune(self, key: str, limit: Limit, now: float) -> deque[float]:
        events = self._events.get(key, deque())
        while events and events[0] <= now - limit.window_seconds:
            events.popleft()
        if not events:
            self._events.pop(key, None)
        return events

    def _retry_after(self, key: str, limit: Limit, now: float) -> int | None:
        events = self._prune(key, limit, now)
        if len(events) < limit.max_events:
            return None
        # La place se libère quand le plus ancien événement sort de la fenêtre.
        return max(1, math.ceil(events[0] + limit.window_seconds - now))

    def _maybe_cleanup(self, now: float) -> None:
        """Supprime de temps en temps les compteurs qu'on ne consulte plus (mémoire)."""
        self._operations += 1
        if self._operations % CLEANUP_EVERY:
            return
        stale = [k for k, events in self._events.items() if events[-1] <= now - MAX_WINDOW_SECONDS]
        for key in stale:
            del self._events[key]


def get_rate_limiter(request: Request) -> RateLimiter:
    """Dépendance FastAPI : le limiteur de l'application en cours."""
    return request.app.state.rate_limiter
