import type { ExtensionAPI } from "@earendil-works/pi-coding-agent";
import { Type } from "typebox";
import { StringEnum } from "@earendil-works/pi-ai";
import { readFile } from "node:fs/promises";
import { homedir } from "node:os";
import vm from "node:vm";

// Evaluate a JavaScript expression against the parsed JSON response body, with
// the body bound as `data`. Used to project large API responses down to the
// fields that matter before they reach the model. Runs in a fresh VM context
// with a timeout and with string code generation disabled, so an accidental
// `Function`/`eval` constructor escape can't reach the host process. This is
// not a security boundary (the agent already has code execution), but it
// keeps filters from touching process/fs by accident and stops a runaway
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
// (e.g. API tokens stored in files) are supplied: web_request never runs
// shell expansions, so "$(cat ...)" or "$VAR" in a value is sent literally.
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
      "Make an HTTP request to a URL. Use for calling REST APIs, fetching docs, or any HTTP interaction. " +
      "Returns status, headers, and body. The body is returned as text — use JSON.parse() in your code if you need structured data. " +
      "For large responses, pass filter to project a JSON body down to the fields you need before it reaches you. " +
      "Request bodies are sent as application/json unless you set your own Content-Type header. " +
      "Header values may reference a file instead of a literal string, for secrets: " +
      'pass {"file":"<path>","prefix":"token "} as the value and the file contents (trimmed) are read and sent. ' +
      'The file path expands "~" to the home directory. Values are sent literally — no shell expansion — so ' +
      '"$(cat ...)" or "$VAR" would be sent as-is and not authenticate.',
    promptSnippet: "Make HTTP requests: GET, POST, PUT, PATCH, DELETE",
    promptGuidelines: [
      "Use web_request when you need to interact with REST APIs or fetch web content.",
      "Prefer web_request over curl in bash — it returns structured results and has no output truncation.",
      'For APIs that return fat objects (issue trackers, etc.), pass filter — a JavaScript expression with the parsed body bound as `data` — to project only the fields you need, e.g. filter="data.map(i => ({number: i.number, title: i.title}))". One Forgejo issue is ~1 KB and a 50-item list is ~145 KB; the swagger spec is ~850 KB.',
      "web_request runs no shell expansions: putting $(cat ...) or $VAR in a header value sends that text literally and it will not authenticate. To send a token stored in a file, pass the header value as an object instead of a string, e.g. headers={\"Authorization\":{\"file\":\"~/.config/sops-nix/secrets/agents/forgejo_token\",\"prefix\":\"token \"}} — the file contents are trimmed of leading/trailing whitespace and ~ expands to the home directory, keeping the secret out of the request text.",
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
                  'Path to a file whose trimmed contents become the header value. "~" expands to the home directory; a leading "@" is ignored. Use this form for secrets — $(cat ...) or $VAR in a literal value would be sent as-is.',
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
          { description: "HTTP headers as key-value pairs; values may be literal strings or file references" },
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
            'JavaScript expression evaluated against the parsed JSON response, with the body bound as `data`. Its result replaces the body, so a large response can be projected down to the fields you need, e.g. filter="data.map(i => ({number: i.number, title: i.title}))" or filter="Object.keys(data.paths)". Requires a JSON body.',
        }),
      ),
      maxBytes: Type.Optional(
        Type.Number({
          description: "Truncate the returned body to this many bytes (appends a truncation marker).",
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
