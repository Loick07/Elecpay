// Événements de session, dans l'onglet ET entre les onglets du back-office (BroadcastChannel) :
// une déconnexion dans un onglet ramène tous les autres à la connexion ; une connexion permet aux
// onglets restés sur « session expirée » de reprendre.
export type SessionEvent =
  "connexion" | "deconnexion" | "expiree" | "double-authentification-requise";

const CHANNEL_NAME = "elecpay-session";
const EVENTS: readonly SessionEvent[] = [
  "connexion",
  "deconnexion",
  "expiree",
  "double-authentification-requise",
];
const local = new EventTarget();
let channel: BroadcastChannel | null = null;

function broadcastChannel(): BroadcastChannel | null {
  if (typeof BroadcastChannel === "undefined") return null;
  channel ??= new BroadcastChannel(CHANNEL_NAME);
  return channel;
}

/** Annonce un événement dans cet onglet et, par défaut, aux autres onglets. */
export function announceSession(event: SessionEvent, options: { otherTabs?: boolean } = {}): void {
  local.dispatchEvent(new CustomEvent(event));
  if (options.otherTabs !== false) broadcastChannel()?.postMessage(event);
}

/** Écoute les événements (`fromOtherTab` : venu d'un autre onglet). Renvoie la fonction d'arrêt. */
export function onSessionEvent(
  listener: (event: SessionEvent, fromOtherTab: boolean) => void,
): () => void {
  const handlers = EVENTS.map((event) => {
    const handler = () => listener(event, false);
    local.addEventListener(event, handler);
    return [event, handler] as const;
  });
  const fromChannel = (message: MessageEvent<unknown>) => {
    if (EVENTS.includes(message.data as SessionEvent)) listener(message.data as SessionEvent, true);
  };
  const shared = broadcastChannel();
  shared?.addEventListener("message", fromChannel);
  return () => {
    for (const [event, handler] of handlers) local.removeEventListener(event, handler);
    shared?.removeEventListener("message", fromChannel);
  };
}
