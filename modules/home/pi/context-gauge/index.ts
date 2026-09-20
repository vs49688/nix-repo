// ~/.pi/agent/extensions/context-gauge/index.ts
//
// Surfaces Pi's internal context accounting to the agent.
//  - context_usage tool: on-demand
//  - band messages: passive, fired once per band crossing
//  - /context command: human-visible, also dumps the raw reading

import type { ExtensionAPI, ExtensionContext } from "@earendil-works/pi-coding-agent";
import { Type } from "typebox";

// ─── knobs ────────────────────────────────────────────────────────────────
// Override the bands with `--context-gauge-bands=50,60,70,80,90`.
const DEFAULT_BANDS = [50, 60, 70, 80, 90];
const BANDS_FLAG = "context-gauge-bands";
// Bands at or above this get a "wrap up" hint appended to the waypoint.
const HINT_FROM_BAND = 80;
const ENABLE_BANDS = true;
const ENABLE_TOOL = true;
// ──────────────────────────────────────────────────────────────────────────

type Reading = { tokens: number; window: number; pct: number };

function read(ctx: ExtensionContext): Reading | undefined {
  const raw = ctx.getContextUsage();
  // `tokens` is null right after a compaction, before the next LLM response.
  if (!raw || typeof raw.tokens !== "number") return undefined;

  const { tokens, contextWindow, percent } = raw;
  const pct = percent ?? (tokens / contextWindow) * 100;

  return { tokens, window: contextWindow, pct };
}

function format(r: Reading): string {
  return (
    `${r.pct.toFixed(1)}% used — ` +
    `${r.tokens.toLocaleString()} / ${r.window.toLocaleString()} tokens`
  );
}

/** read() comes back empty for two different reasons; say which. */
function unavailableText(ctx: ExtensionContext): string {
  return ctx.getContextUsage()
    ? "Context size is unknown right after a compaction — it should be available " +
        "again after the next model response."
    : "Context usage is unavailable — no model is active, or its context window is " +
        "unknown.";
}

function parseBands(value: unknown): number[] {
  if (typeof value !== "string") return DEFAULT_BANDS;
  const parsed = value
    .split(",")
    .map((part) => Number(part.trim()))
    .filter((n) => Number.isFinite(n) && n > 0 && n <= 100);
  return parsed.length > 0 ? [...new Set(parsed)].sort((a, b) => a - b) : DEFAULT_BANDS;
}

function bandFor(pct: number, bands: readonly number[]): number | undefined {
  return [...bands].reverse().find((b) => pct >= b);
}

function waypointText(r: Reading, band: number): string {
  const left = `${Math.max(0, 100 - r.pct).toFixed(0)}% left`;
  const hint =
    band >= HINT_FROM_BAND ? " Consider compacting or handing off to a new session." : "";
  return `[context-gauge] Context waypoint: ${format(r)} (${left}).${hint}`;
}

export default function (pi: ExtensionAPI) {
  let lastBand: number | undefined;

  pi.registerFlag(BANDS_FLAG, {
    description: "Comma-separated context-usage percentages that emit a waypoint",
    type: "string",
    default: DEFAULT_BANDS.join(","),
  });

  // CLI flag values are applied only after extensions finish loading, so read
  // the flag at session start (which also fires on /reload) rather than here.
  let bands = DEFAULT_BANDS;

  // Seed rather than fire on load: a resumed session should not announce a
  // band it crossed before you got here.
  pi.on("session_start", async (_event, ctx) => {
    bands = parseBands(pi.getFlag(BANDS_FLAG));
    const r = read(ctx);
    lastBand = r ? bandFor(r.pct, bands) : undefined;
  });

  if (ENABLE_TOOL) {
    pi.registerTool({
      name: "context_usage",
      label: "Context Usage",
      description:
        "Report how much of the model's context window is currently used: tokens " +
        "consumed, the window size, and the percentage. Worth calling before " +
        "starting work that will consume a lot of context.",
      promptSnippet: "Report current context window usage (tokens and percentage)",
      parameters: Type.Object({}),
      async execute(_toolCallId, _params, _signal, _onUpdate, ctx) {
        const r = read(ctx);
        if (!r) {
          return {
            content: [{ type: "text", text: unavailableText(ctx) }],
            details: {},
          };
        }
        return {
          content: [{ type: "text", text: format(r) }],
          details: { ...r },
        };
      },
    });
  }

  if (ENABLE_BANDS) {
    pi.on("turn_end", async (_event, ctx) => {
      const r = read(ctx);
      if (!r) return;

      const band = bandFor(r.pct, bands);
      const previous = lastBand;
      lastBand = band;

      // Fire only on an upward crossing. Falling back below the lowest band
      // resets silently, so a second crossing (after a compaction or branch
      // switch) still reports. A jump over several bands reports the highest.
      if (band === undefined) return;
      if (previous !== undefined && band <= previous) return;

      pi.sendMessage(
        {
          customType: "context-gauge",
          content: waypointText(r, band),
          display: true,
          details: { band, ...r },
        },
        // triggerTurn: false routes this through Pi's passive custom-message
        // path: it is appended at the turn boundary (never between a tool call
        // and its result) and can never start a turn of its own.
        { triggerTurn: false },
      );
    });
  }

  // Doubles as the probe for the raw shape of getContextUsage().
  pi.registerCommand("context", {
    description: "Show current context usage, plus the raw reading",
    handler: async (_args, ctx) => {
      const r = read(ctx);
      const raw = ctx.getContextUsage();
      ctx.ui.notify(
        `${r ? format(r) : "unavailable"}\n\nraw: ${JSON.stringify(raw)}`,
        "info",
      );
    },
  });
}
