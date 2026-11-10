/**
 * The litellm proxy serves one catalogue and Pi should not keep a copy of it.
 *
 * `/model/info` reports each deployment with the fields a Pi model needs --
 * context window, output limit, capability flags, per-token rates -- so the list
 * is read from the proxy, and a model it gains or loses appears without this
 * file changing.
 *
 * The runtime's startup refresh is cache-only (`allowNetwork: false`), which a
 * provider that lives on loopback does not need: the fetch is a read of a local
 * socket, not a network round trip. So a loopback base URL is fetched anyway,
 * and anything else waits for a refresh that is allowed to use the network.
 *
 * Only chat deployments are taken: the same catalogue carries image, speech and
 * transcription models, which are not models Pi can hold a conversation with.
 */

import type { ExtensionAPI } from "@earendil-works/pi-coding-agent";

const PROVIDER_ID = "litellm";
const DEFAULT_BASE_URL = "http://localhost:8080/v1"; // ssh -L8080:localhost:8080

/** The subset of `/model/info` this needs, as litellm actually emits it. */
interface LiteLLMDeployment {
  model_name: string;
  model_info?: {
    mode?: string | null;
    max_input_tokens?: number | null;
    max_output_tokens?: number | null;
    supports_reasoning?: boolean | null;
    supports_vision?: boolean | null;
    input_cost_per_token?: number | null;
    output_cost_per_token?: number | null;
    cache_read_input_token_cost?: number | null;
    cache_creation_input_token_cost?: number | null;
  };
}

/**
 * Pi prices in dollars per million tokens and litellm reports dollars per token.
 * A missing rate becomes zero, which is what Pi shows for a deployment litellm
 * has no pricing for.
 */
const perMillion = (perToken: number | null | undefined) => (perToken ?? 0) * 1e6;

const isLoopback = (url: string) =>
  /^https?:\/\/(localhost|127\.0\.0\.1|\[::1\])(:|\/|$)/.test(url);

function toModel(deployment: LiteLLMDeployment) {
  const info = deployment.model_info ?? {};
  return {
    type: "chat" as const,
    id: deployment.model_name,
    name: deployment.model_name,
    api: "openai-completions" as const,
    reasoning: info.supports_reasoning === true,
    input: info.supports_vision ? (["text", "image"] as const) : (["text"] as const),
    cost: {
      input: perMillion(info.input_cost_per_token),
      output: perMillion(info.output_cost_per_token),
      cacheRead: perMillion(info.cache_read_input_token_cost),
      cacheWrite: perMillion(info.cache_creation_input_token_cost),
    },
    // The proxy reports these for any deployment it can describe; the fallbacks
    // match Pi's own defaults so one it cannot describe still loads.
    contextWindow: info.max_input_tokens ?? 128000,
    maxTokens: info.max_output_tokens ?? 16384,
  };
}

export default function (pi: ExtensionAPI) {
  // Held so a refresh that fails -- the forward down, the proxy restarting --
  // leaves the last good list in place instead of emptying the model picker.
  let models: ReturnType<typeof toModel>[] = [];

  pi.registerProvider(PROVIDER_ID, {
    name: "litellm",
    baseUrl: DEFAULT_BASE_URL,
    api: "openai-completions",
    // The proxy is unauthenticated; litellm wants a key present in some paths,
    // so send the same placeholder every other local client uses.
    apiKey: "unnecessary",

    refreshModels: async (context) => {
      if (context.signal.aborted) {
        return models;
      }

      const baseUrl = context.baseUrl ?? DEFAULT_BASE_URL;
      if (!context.allowNetwork && !isLoopback(baseUrl) && models.length > 0) {
        return models;
      }
      if (process.env.PI_OFFLINE !== undefined) {
        return models;
      }

      try {
        const response = await fetch(`${baseUrl.replace(/\/+$/, "")}/model/info`, {
          signal: context.signal,
          headers: { accept: "application/json" },
        });
        if (!response.ok) {
          return models;
        }

        const body = (await response.json()) as { data?: LiteLLMDeployment[] };
        const deployments = Array.isArray(body.data) ? body.data : [];
        models = deployments
          .filter((deployment) => deployment.model_info?.mode === "chat")
          .map(toModel);
      } catch (error) {
        // A cancelled refresh is normal -- the runtime aborts the ones it does
        // not need -- so only a real failure is worth saying anything about.
        if (!context.signal.aborted) {
          console.error(`[litellm-models] ${baseUrl} unreachable: ${error}`);
        }
      }

      return models;
    },
  });
}
