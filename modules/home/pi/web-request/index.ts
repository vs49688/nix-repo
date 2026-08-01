import type { ExtensionAPI } from "@earendil-works/pi-coding-agent";
import { Type } from "typebox";
import { StringEnum } from "@earendil-works/pi-ai";

export default function (pi: ExtensionAPI) {
  pi.registerTool({
    name: "web_request",
    label: "Web Request",
    description:
      "Make an HTTP request to a URL. Use for calling REST APIs, fetching docs, or any HTTP interaction. " +
      "Returns status, headers, and body. The body is returned as text — use JSON.parse() in your code if you need structured data.",
    promptSnippet: "Make HTTP requests: GET, POST, PUT, PATCH, DELETE",
    promptGuidelines: [
      "Use web_request when you need to interact with REST APIs or fetch web content.",
      "Prefer web_request over curl in bash — it returns structured results and has no output truncation.",
    ],
    parameters: Type.Object({
      url: Type.String({ description: "Full URL including protocol (https://...)" }),
      method: StringEnum(["GET", "POST", "PUT", "PATCH", "DELETE"] as const, {
        description: "HTTP method",
      }),
      headers: Type.Optional(
        Type.Record(Type.String(), Type.String(), {
          description: "HTTP headers as key-value pairs",
        }),
      ),
      body: Type.Optional(
        Type.String({ description: "Request body. Pass a JSON string for JSON APIs." }),
      ),
      timeout: Type.Optional(
        Type.Number({ description: "Timeout in seconds (default: 30)" }),
      ),
    }),
    async execute(_toolCallId, params, signal) {
      const timeout = (params.timeout ?? 30) * 1000;
      const controller = new AbortController();
      const linked = AbortSignal.any([signal, controller.signal]);
      const timer = setTimeout(() => controller.abort(new Error("Request timeout")), timeout);

      try {
        const response = await fetch(params.url, {
          method: params.method,
          headers: params.headers ?? {},
          body: params.body,
          signal: linked,
        });

        const body = await response.text();

        const resHeaders: Record<string, string> = {};
        response.headers.forEach((value, key) => {
          resHeaders[key] = value;
        });

        const details: Record<string, unknown> = {
          status: response.status,
          statusText: response.statusText,
          headers: resHeaders,
        };

        if (!response.ok) {
          const truncated = body.length > 4000 ? body.slice(0, 4000) + "\n... (truncated)" : body;
          return {
            content: [
              {
                type: "text",
                text: `HTTP ${response.status} ${response.statusText}\n\n${truncated}`,
              },
            ],
            details,
          };
        }

        return {
          content: [{ type: "text", text: body }],
          details,
        };
      } catch (err) {
        const message = err instanceof Error ? err.message : String(err);
        return {
          content: [{ type: "text", text: `Request failed: ${message}` }],
          details: { error: message },
        };
      } finally {
        clearTimeout(timer);
      }
    },
  });
}
