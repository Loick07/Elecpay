// Relais `/api/v1/*` → API ElecPay (toute la logique et ses tests : `src/lib/relay/`).
import { apiOrigin, RelayConfigError } from "@/lib/relay/config";
import { relay, relayError } from "@/lib/relay/relay";

async function handle(request: Request, context: RouteContext<"/api/v1/[...path]">) {
  const { path } = await context.params;
  let origin: string;
  try {
    origin = apiOrigin(process.env.ELECPAY_API_URL, process.env.NODE_ENV);
  } catch (error) {
    if (!(error instanceof RelayConfigError)) throw error;
    console.error(error.message);
    return relayError(
      500,
      "RELAY_CONFIG",
      "Le back-office est mal configuré (adresse de l'API). Prévenez l'administrateur.",
      crypto.randomUUID().replaceAll("-", ""),
    );
  }
  return relay(request, path, { apiOrigin: origin });
}

export {
  handle as DELETE,
  handle as GET,
  handle as HEAD,
  handle as PATCH,
  handle as POST,
  handle as PUT,
};
