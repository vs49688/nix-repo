import type { ExtensionAPI } from "@earendil-works/pi-coding-agent";
import { Type } from "typebox";
import { StringEnum } from "@earendil-works/pi-ai";
import { readFile } from "node:fs/promises";
import { homedir } from "node:os";
import vm from "node:vm";

// Evaluate a filter expression against the parsed body, bound as `data`, in a
// fresh VM context with string code generation disabled and a 1s timeout. This
// is not a security boundary (the agent already has code execution), but it
// keeps a filter from touching process/fs by accident and stops a runaway
// expression from hanging the tool.
function runFilter(expression: string, body: string): string {
  let data: unknown;
  try {
    data = JSON.parse(body);
  } catch (err) {
    const message = err instanceof Error ? err.message : String(err);
    throw new Error(`filter requires a JSON response body (${message})`);
  }

  let value: unknown;
  try {
    const context = vm.createContext({ data }, { codeGeneration: { strings: false, wasm: false } });
    value = vm.runInContext(`(${expression})`, context, { timeout: 1000 });
  } catch (err) {
    const message = err instanceof Error ? err.message : String(err);
    throw new Error(`filter failed (${message})`);
  }

  if (typeof value === "string") return value;
  if (value === undefined) return "(filter returned undefined)";
  try {
    return JSON.stringify(value) ?? String(value);
  } catch (err) {
    const message = err instanceof Error ? err.message : String(err);
    throw new Error(`filter result is not serialisable (${message})`);
  }
}

type HeaderFileValue = { file: string; prefix?: string; suffix?: string };

// A header value is either a literal string or a reference to a file whose
// (whitespace-trimmed) contents become the value. This is how secret headers
// are supplied. Values are never shell-expanded, so "$(cat ...)" or "$VAR" in a
// value is sent literally.
async function resolveHeaderValue(value: string | HeaderFileValue): Promise<string> {
  if (typeof value === "string") return value;
  if (!value.file) {
    throw new Error('Header value object must have a "file" path');
  }

  let path = value.file;
  if (path.startsWith("@")) path = path.slice(1); // models sometimes prefix @
  if (path === "~") path = homedir();
  else if (path.startsWith("~/")) path = path.replace(/^~(?=\/)/, homedir());

  let contents: string;
  try {
    contents = await readFile(path, "utf8");
  } catch (err) {
    const message = err instanceof Error ? err.message : String(err);
    throw new Error(`Failed to read header file "${path}": ${message}`);
  }

  return `${value.prefix ?? ""}${contents.trim()}${value.suffix ?? ""}`;
}

export default function (pi: ExtensionAPI) {
  pi.registerTool({
    name: "web_request",
    label: "Web Request",
    description:
      "Make HTTP requests, including authenticated REST API calls. Returns response text; HTTP status and response headers are recorded in the result details. " +
      "Successful output has no automatic size cap. Non-2xx output is capped at 4000 UTF-16 code units; filter failures return an error with up to 2000 code units of the raw body. " +
      'Truncated text has a "... (truncated)" marker appended.',
    promptSnippet: "Make HTTP requests: GET, POST, PUT, PATCH, DELETE",
    promptGuidelines: [
      "Prefer web_request to curl in bash for REST APIs and raw HTTP responses. Use curl -o when the response should go to a file.",
      "Use web_request's filter to project large JSON responses before they enter context.",
    ],
    parameters: Type.Object({
      url: Type.String({ description: "Full URL including protocol (https://...)" }),
      method: StringEnum(["GET", "POST", "PUT", "PATCH", "DELETE"] as const, {
        description: "HTTP method",
      }),
      headers: Type.Optional(
        Type.Record(
          Type.String(),
          Type.Union([
            Type.String({ description: "Literal header value" }),
            Type.Object({
              file: Type.String({
                description:
                  'Path to a file whose trimmed contents become the header value. "~" expands to the home directory; a leading "@" is ignored.',
              }),
              prefix: Type.Optional(
                Type.String({
                  description: 'Text prepended to the file contents (e.g. "token " for an Authorization header)',
                }),
              ),
              suffix: Type.Optional(
                Type.String({ description: "Text appended to the file contents" }),
              ),
            }),
          ]),
          {
            description:
              'HTTP headers as key-value pairs. A value is either a literal string or a file reference for a secret, e.g. {"file":"<path>","prefix":"token "}: the file\'s trimmed contents become the value. Values are sent literally — there is no shell expansion — so "$(cat ...)" or "$VAR" would be sent as-is and not authenticate.',
          },
        ),
      ),
      body: Type.Optional(
        Type.String({
          description:
            "Request body. Pass a JSON string for JSON APIs — it is sent with Content-Type: application/json unless you set the header yourself.",
        }),
      ),
      filter: Type.Optional(
        Type.String({
          description:
            'JavaScript expression evaluated against the parsed JSON response, with the body bound as `data`. Its result replaces the body, so a large response can be projected down to the fields you need, e.g. filter="data.map(i => ({number: i.number, title: i.title}))" or filter="Object.keys(data)". Requires a JSON body; if the expression fails, the error comes back with a capped preview of the raw body.',
        }),
      ),
      maxBytes: Type.Optional(
        Type.Number({
          description:
            'Limit response text after filtering to this many UTF-16 code units (legacy name; not bytes). The truncation marker is extra. Does not apply to filter-failure previews or raise the automatic non-2xx cap.',
        }),
      ),
      timeout: Type.Optional(
        Type.Number({ description: "Timeout in seconds (default: 30)" }),
      ),
    }),
    async execute(_toolCallId, params, signal) {
      const timeout = (params.timeout ?? 30) * 1000;
      const controller = new AbortController();
      const linked = AbortSignal.any(
        signal ? [signal, controller.signal] : [controller.signal],
      );
      const timer = setTimeout(() => controller.abort(new Error("Request timeout")), timeout);

      try {
        const headers: Record<string, string> = {};
        for (const [key, value] of Object.entries(params.headers ?? {})) {
          headers[key] = await resolveHeaderValue(value);
        }

        // APIs (Forgejo included) reject JSON bodies without this, and agents
        // keep forgetting it. Only a default: an explicit header wins.
        if (
          params.body !== undefined &&
          !Object.keys(headers).some((key) => key.toLowerCase() === "content-type")
        ) {
          headers["Content-Type"] = "application/json";
        }

        const response = await fetch(params.url, {
          method: params.method,
          headers,
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

        let text = body;
        if (params.filter !== undefined) {
          try {
            text = runFilter(params.filter, body);
          } catch (err) {
            const message = err instanceof Error ? err.message : String(err);
            const preview = body.length > 2000 ? body.slice(0, 2000) + "\n... (truncated)" : body;
            return {
              content: [
                {
                  type: "text",
                  text: `HTTP ${response.status} ${response.statusText}\n\n${message}\n\nRaw response:\n${preview}`,
                },
              ],
              details,
            };
          }
        }

        if (params.maxBytes !== undefined && text.length > params.maxBytes) {
          text = text.slice(0, params.maxBytes) + "\n... (truncated)";
        }

        if (!response.ok) {
          const truncated = text.length > 4000 ? text.slice(0, 4000) + "\n... (truncated)" : text;
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

        // NB: emit `text`, not `body` — it carries the filter/maxBytes result.
        return {
          content: [{ type: "text", text }],
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
