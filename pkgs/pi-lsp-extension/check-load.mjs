// Load the built Pi package the way Pi does, without a model or a language
// server: Pi's own loader resolves the extension, which imports every runtime
// dependency, and the tree-sitter assets are opened here directly.
//
// Usage: node check-load.mjs <package-dir> <pi-coding-agent-store-path>

import { existsSync, mkdtempSync, readFileSync } from "node:fs";
import { createRequire } from "node:module";
import { tmpdir } from "node:os";
import { dirname, join, sep } from "node:path";
import { pathToFileURL } from "node:url";

function fail(message) {
  console.error(`error: ${message}`);
  process.exit(1);
}

const [packageDir, piDir] = process.argv.slice(2);
if (!packageDir || !piDir) fail("expected <package-dir> <pi-coding-agent-store-path>");

const require = createRequire(join(packageDir, "package.json"));

// Imports must resolve from the package's own dependency tree, not from
// whatever happens to be installed elsewhere on the machine.
for (const id of ["tree-sitter-wasms/package.json", "vscode-languageserver-protocol", "web-tree-sitter/package.json"]) {
  const resolved = require.resolve(id);
  if (!resolved.startsWith(packageDir + sep)) fail(`${id} resolved outside the package: ${resolved}`);
}

// Pi supplies these itself; a physical copy would shadow its module mapping.
for (const id of ["@earendil-works/pi-coding-agent", "@earendil-works/pi-tui", "typebox"]) {
  if (existsSync(join(packageDir, "node_modules", id))) fail(`host-provided package shipped: ${id}`);
  try {
    require.resolve(id);
  } catch (error) {
    if (error.code === "MODULE_NOT_FOUND") continue;
    throw error;
  }
  fail(`host-provided package resolves from the package: ${id}`);
}

const webTreeSitterPkg = dirname(require.resolve("web-tree-sitter/package.json"));
const grammarsDir = join(dirname(require.resolve("tree-sitter-wasms/package.json")), "out");

// Every grammar the extension can ask for has to be in the package.
const dist = readFileSync(join(packageDir, "dist", "index.js"), "utf8");
const grammars = new Set([...dist.matchAll(/"tree-sitter-[a-z_]+\.wasm"/g)].map((m) => m[0].slice(1, -1)));
if (grammars.size === 0) fail("dist/index.js references no tree-sitter grammars");
for (const grammar of grammars) {
  if (!existsSync(join(grammarsDir, grammar))) fail(`missing grammar: ${grammar}`);
}

const { default: Parser } = await import(pathToFileURL(join(webTreeSitterPkg, "tree-sitter.js")));
await Parser.init({ locateFile: (name) => join(webTreeSitterPkg, name) });
const typescript = await Parser.Language.load(join(grammarsDir, "tree-sitter-typescript.wasm"));
const parser = new Parser();
parser.setLanguage(typescript);
const tree = parser.parse("const answer: number = 42;\n");
if (tree.rootNode.type !== "program") fail(`tree-sitter produced ${tree.rootNode.type}`);
tree.delete();

const piMonorepo = join(piDir, "lib", "node_modules", "pi-monorepo");
const { discoverAndLoadExtensions } = await import(
  pathToFileURL(join(piMonorepo, "dist", "core", "extensions", "loader.js"))
);
const { createEventBus } = await import(pathToFileURL(join(piMonorepo, "dist", "core", "event-bus.js")));

const manifest = JSON.parse(readFileSync(join(packageDir, "package.json"), "utf8"));
if (!(manifest.pi?.extensions?.length > 0)) fail("package.json declares no pi.extensions");

// The package directory is what a local packages entry points at, so let Pi's
// own discovery read the manifest. Empty cwd/agent dirs keep it to just this
// package.
const workDir = mkdtempSync(join(tmpdir(), "pi-lsp-check-"));
const loaded = await discoverAndLoadExtensions([packageDir], workDir, join(workDir, "agent"), createEventBus());
if (loaded.errors.length > 0) fail(`loader errors: ${JSON.stringify(loaded.errors)}`);
if (loaded.extensions.length !== 1) fail(`expected one extension, loaded ${loaded.extensions.length}`);

const extension = loaded.extensions[0];
for (const tool of ["lsp_diagnostics", "lsp_hover", "lsp_definition", "lsp_references", "lsp_symbols", "ast_search"]) {
  if (!extension.tools.has(tool)) fail(`missing tool: ${tool}`);
}
for (const command of ["lsp", "lsp-restart", "lsp-config"]) {
  if (!extension.commands.has(command)) fail(`missing command: ${command}`);
}
if (!extension.handlers.has("session_start")) fail("missing session_start handler");

console.log(`loaded ${manifest.name}@${manifest.version}: ${extension.tools.size} tools, ${grammars.size} grammars`);
