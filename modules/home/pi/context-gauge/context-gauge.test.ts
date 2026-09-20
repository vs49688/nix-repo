// Tests for ./index.ts.
//
// Run with:  bun test   (from this directory)
//
// The loader treats every `extensions/*.ts` file as an extension, and only
// `extensions/*/index.ts` inside a directory, so this file sits next to the
// extension without being loaded as one.
//
// Pi injects `typebox` (and the @earendil-works/* modules) into extensions via
// its own alias map, so a standalone test has no node_modules to resolve them
// from. Only `Type.Object` is used, so stub just that.
import { describe, expect, mock, test } from "bun:test";

mock.module("typebox", () => ({
  Type: { Object: (properties: Record<string, unknown>) => ({ type: "object", properties }) },
}));

const { default: contextGauge } = await import("./index.ts");

// ─── harness ──────────────────────────────────────────────────────────────
type Usage = { tokens: number | null; contextWindow: number; percent?: number | null };
type Sent = { message: any; options: any };

/** A reading shaped like Pi's ContextUsage, with a consistent percent. */
function usage(tokens: number, contextWindow: number): Usage {
  return { tokens, contextWindow, percent: (tokens / contextWindow) * 100 };
}

function harness(initial?: Usage, opts: { flag?: string } = {}) {
  let current = initial;
  const events = new Map<string, (event: any, ctx: any) => unknown>();
  const sent: Sent[] = [];
  const flagDefaults = new Map<string, unknown>();
  const cliOverrides = new Map<string, unknown>();
  if (opts.flag !== undefined) cliOverrides.set("context-gauge-bands", opts.flag);

  // Model Pi's loader: during the factory, getFlag sees the registered default
  // (pending); CLI values are applied only after loading finishes.
  let loading = true;
  const pi: any = {
    on: (type: string, handler: (event: any, ctx: any) => unknown) => events.set(type, handler),
    registerTool: (tool: any) => { pi.tool = tool; },
    registerCommand: (name: string, options: any) => { pi.command = { name, ...options }; },
    registerFlag: (name: string, options: any) => { flagDefaults.set(name, options.default); },
    getFlag: (name: string) =>
      loading
        ? flagDefaults.get(name)
        : cliOverrides.has(name)
          ? cliOverrides.get(name)
          : flagDefaults.get(name),
    sendMessage: (message: any, options: any) => sent.push({ message, options }),
  };
  contextGauge(pi);
  loading = false;

  const notified: Array<{ message: string; type?: string }> = [];
  const ctx: any = {
    getContextUsage: () => current,
    model: { contextWindow: 1_000_000 },
    ui: { notify: (message: string, type?: string) => notified.push({ message, type }) },
  };

  return {
    pi, events, sent, notified, ctx, flagDefaults,
    setUsage: (next?: Usage) => { current = next; },
    start: () => events.get("session_start")!({ type: "session_start", reason: "startup" }, ctx),
    turn: () => events.get("turn_end")!({ type: "turn_end" }, ctx),
    run: () => pi.tool.execute("call-1", {}, undefined, undefined, ctx),
  };
}

// ══════════════════════════════════════════════════════════════════════════
describe("context_usage tool", () => {
  test("reports tokens, window and percentage", async () => {
    const h = harness(usage(38173, 1_000_000));
    const result = await h.run();
    expect(result.content[0].text).toBe("3.8% used — 38,173 / 1,000,000 tokens");
    expect(result.details).toEqual({ tokens: 38173, window: 1_000_000, pct: 3.8173 });
  });

  test("uses the SDK's `percent` field", async () => {
    const h = harness({ tokens: 100, contextWindow: 1000, percent: 42 });
    const result = await h.run();
    expect(result.content[0].text).toBe("42.0% used — 100 / 1,000 tokens");
    expect(result.details.pct).toBe(42);
  });

  test("ignores a stray `percentage` field (regression: field was renamed)", async () => {
    const h = harness({ tokens: 100, contextWindow: 1000, percentage: 42 } as unknown as Usage);
    const result = await h.run();
    expect(result.content[0].text).toBe("10.0% used — 100 / 1,000 tokens");
  });

  test("computes the percentage when `percent` is null", async () => {
    const h = harness({ tokens: 250, contextWindow: 1000, percent: null });
    const result = await h.run();
    expect(result.content[0].text).toBe("25.0% used — 250 / 1,000 tokens");
  });

  test("handles zero tokens", async () => {
    const h = harness(usage(0, 1000));
    const result = await h.run();
    expect(result.content[0].text).toBe("0.0% used — 0 / 1,000 tokens");
  });

  test("says the size is unknown right after a compaction (tokens null)", async () => {
    const h = harness({ tokens: null, contextWindow: 1_000_000, percent: null });
    const result = await h.run();
    expect(result.content[0].text).toContain("right after a compaction");
  });

  test("says usage is unavailable when there is no reading at all", async () => {
    const h = harness(undefined);
    const result = await h.run();
    expect(result.content[0].text).toContain("no model is active");
  });
});

// ══════════════════════════════════════════════════════════════════════════
describe("band messages", () => {
  test("seeds from session_start and does not re-announce the current band", async () => {
    const h = harness(usage(550, 1000));
    await h.start();
    h.setUsage(usage(570, 1000));
    await h.turn();
    expect(h.sent).toHaveLength(0);
  });

  test("fires once when crossing upward into a band", async () => {
    const h = harness(usage(550, 1000));
    await h.start();
    h.setUsage(usage(720, 1000));
    await h.turn();

    expect(h.sent).toHaveLength(1);
    expect(h.sent[0].options).toEqual({ triggerTurn: false });
    expect(h.sent[0].message.customType).toBe("context-gauge");
    expect(h.sent[0].message.display).toBe(true);
    expect(h.sent[0].message.content).toBe(
      "[context-gauge] Context waypoint: 72.0% used — 720 / 1,000 tokens (28% left).",
    );
    expect(h.sent[0].message.details).toEqual({ band: 70, tokens: 720, window: 1000, pct: 72 });
  });

  test("appends a wrap-up hint at the high bands", async () => {
    const h = harness(usage(850, 1000));
    await h.turn();
    expect(h.sent[0].message.content).toBe(
      "[context-gauge] Context waypoint: 85.0% used — 850 / 1,000 tokens (15% left). " +
        "Consider compacting or handing off to a new session.",
    );
  });

  test("fires only once while inside the same band", async () => {
    const h = harness(usage(550, 1000));
    await h.start();
    h.setUsage(usage(720, 1000));
    await h.turn();
    h.setUsage(usage(740, 1000));
    await h.turn();
    expect(h.sent).toHaveLength(1);
  });

  test("reports the highest band on a multi-band jump", async () => {
    const h = harness(usage(550, 1000));
    await h.start();
    h.setUsage(usage(910, 1000));
    await h.turn();
    expect(h.sent).toHaveLength(1);
    expect(h.sent[0].message.details.band).toBe(90);
  });

  test("stays silent on the way down, then re-fires on the next climb", async () => {
    const h = harness(usage(550, 1000));
    await h.start();

    h.setUsage(usage(910, 1000));
    await h.turn(); // 90
    h.setUsage(usage(650, 1000));
    await h.turn(); // silent
    h.setUsage(usage(820, 1000));
    await h.turn(); // 80

    expect(h.sent.map((s) => s.message.details.band)).toEqual([90, 80]);
  });

  test("re-arms after dropping below the lowest band", async () => {
    const h = harness(usage(950, 1000));
    await h.start();
    await h.turn(); // seeded at 90, silent

    h.setUsage(usage(50, 1000));
    await h.turn(); // below every band, silent
    h.setUsage(usage(510, 1000));
    await h.turn();

    expect(h.sent).toHaveLength(1);
    expect(h.sent[0].message.details.band).toBe(50);
  });

  test("does not fire when the reading is unavailable", async () => {
    const h = harness(usage(550, 1000));
    await h.start();
    h.setUsage(undefined);
    await h.turn();
    expect(h.sent).toHaveLength(0);
  });

  test("fires on the first turn when session_start never seeded", async () => {
    const h = harness(usage(850, 1000));
    await h.turn();
    expect(h.sent).toHaveLength(1);
    expect(h.sent[0].message.details.band).toBe(80);
  });

  test("registers the band list as a flag default", () => {
    const h = harness();
    expect(h.flagDefaults.get("context-gauge-bands")).toBe("50,60,70,80,90");
  });

  test("reads the band list from --context-gauge-bands", async () => {
    const h = harness(usage(200, 1000), { flag: "20,75" });
    await h.start(); // seeded at band 20
    h.setUsage(usage(500, 1000)); // 50 → still band 20, silent
    await h.turn();
    expect(h.sent).toHaveLength(0);

    h.setUsage(usage(800, 1000)); // 80 → band 75, upward → fires
    await h.turn();
    expect(h.sent).toHaveLength(1);
    expect(h.sent[0].message.details.band).toBe(75);
  });

  test("falls back to the default bands when the flag is unusable", async () => {
    const h = harness(usage(500, 1000), { flag: "not,numbers" });
    await h.start(); // seeded with defaults
    h.setUsage(usage(880, 1000));
    await h.turn();
    expect(h.sent[0].message.details.band).toBe(80);
  });
});

// ══════════════════════════════════════════════════════════════════════════
describe("/context command", () => {
  test("dumps the formatted reading plus the raw object", async () => {
    const h = harness({ tokens: 12345, contextWindow: 100000, percent: 12.345 });
    expect(h.pi.command.name).toBe("context");

    await h.pi.command.handler("", h.ctx);

    expect(h.notified).toHaveLength(1);
    expect(h.notified[0].type).toBe("info");
    expect(h.notified[0].message).toContain("12.3% used — 12,345 / 100,000 tokens");
    expect(h.notified[0].message).toContain('"percent":12.345');
  });
});
