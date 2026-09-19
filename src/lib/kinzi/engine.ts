export const TARGET = {
  name: "Car Parking Multiplayer 2",
  version: "1.3.3.6",
  package: "com.olzhas.carparking.multyplayer2",
  lib: "libil2cpp.so",
} as const;

const HEX_RE = /\b0x[0-9a-fA-F]{5,16}\b/g;
const IGNORE = new Set([0x52800000, 0x52800028, 0x2a1f03e0]);

export type ScanEntry = {
  raw: string;
  absolute: number;
  offset: number;
  kind: "absolute" | "offset" | "skipped";
  className: string;
  methodName: string;
  retType: string;
  hookDistance: string;
};

export type GateState =
  | "idle"
  | "not_running"
  | "wrong_game"
  | "no_process"
  | "missing_info"
  | "ready";

export type ConvertMode =
  | "single"
  | "logged"
  | "direct"
  | "reoffset"
  | "template"
  | "patch";

export function parseHex(value: string): number | null {
  const t = value.trim();
  if (!t) return null;
  const n = Number.parseInt(t, 16);
  if (!Number.isFinite(n) || Number.isNaN(n)) return null;
  return n;
}

export function formatHex(n: number): string {
  return "0x" + n.toString(16).toUpperCase();
}

function shouldIgnore(n: number): boolean {
  if (IGNORE.has(n)) return true;
  if (n >= 0x52000000 && (n & 0xff000000) === 0x52000000) return true;
  return false;
}

export function extractHexes(text: string): string[] {
  const found = text.match(HEX_RE) ?? [];
  const seen = new Set<string>();
  const out: string[] = [];
  for (const h of found) {
    const key = h.toLowerCase();
    if (seen.has(key)) continue;
    seen.add(key);
    out.push(h);
  }
  return out;
}

export function classifyAddress(n: number, libBase: number): ScanEntry["kind"] {
  if (shouldIgnore(n)) return "skipped";
  if (libBase > 0 && n === libBase) return "skipped";
  if (libBase > 0 && n > libBase) return "absolute";
  if (n > 0x10000 && n <= 0x80000000) return "offset";
  if (n > 0x100000000) return "absolute";
  return "skipped";
}

export function toOffset(n: number, libBase: number, kind: ScanEntry["kind"]): number {
  if (kind === "absolute" && libBase > 0 && n > libBase) return n - libBase;
  if (kind === "offset") return n;
  return n;
}

export function parseLogToEntries(text: string, libBase: number): ScanEntry[] {
  const hexes = extractHexes(text);
  const entries: ScanEntry[] = [];
  const seenOff = new Set<number>();

  const classBlocks = parseKinziBlocks(text);

  for (const raw of hexes) {
    const n = parseHex(raw);
    if (n == null) continue;
    const kind = classifyAddress(n, libBase);
    if (kind === "skipped") continue;
    const offset = toOffset(n, libBase, kind);
    if (offset <= 0) continue;
    if (libBase > 0 && n === libBase) continue;
    if (seenOff.has(offset)) continue;
    seenOff.add(offset);

    const hit = classBlocks.find((b) => b.offset === offset);
    entries.push({
      raw,
      absolute: kind === "absolute" ? n : libBase > 0 ? libBase + offset : n,
      offset,
      kind,
      className: hit?.className ?? "Unknown",
      methodName: hit?.methodName ?? "Unknown",
      retType: hit?.retType ?? "Unknown",
      hookDistance: hit?.hookDistance ?? "0x0",
    });
  }

  return entries;
}

export type KinziBlock = {
  offset?: number;
  className: string;
  methodName: string;
  retType: string;
  hookDistance: string;
};

export function parseKinziBlocks(text: string): KinziBlock[] {
  const blocks: KinziBlock[] = [];
  let cur: Partial<KinziBlock> = {};
  for (const line of text.split(/\r?\n/)) {
    const off = line.match(/(?:OFFSET|SCRIPT OFFSET):\s*(0x[0-9a-fA-F]+)/i);
    const cls = line.match(/CLASS:\s*(.+)/i);
    const meth = line.match(/METHOD:\s*(.+)/i);
    const typ = line.match(/TYPE:\s*(.+)/i);
    const hook = line.match(/HOOK DISTANCE:\s*(0x[0-9a-fA-F]+)/i);
    const inline = line.match(/(\w+)::(\w+)\s*[→>]/);
    if (off) cur.offset = parseHex(off[1] ?? "") ?? undefined;
    if (cls) cur.className = cls[1]?.trim();
    if (meth) cur.methodName = meth[1]?.trim();
    if (typ) cur.retType = typ[1]?.trim();
    if (hook) cur.hookDistance = hook[1]?.trim();
    if (inline) {
      blocks.push({
        className: inline[1] ?? "Unknown",
        methodName: inline[2] ?? "Unknown",
        retType: "Unknown",
        hookDistance: "0x0",
      });
    }
    if (/^-{4,}/.test(line.trim()) && (cur.className || cur.offset != null)) {
      blocks.push({
        offset: cur.offset,
        className: cur.className ?? "Unknown",
        methodName: cur.methodName ?? "Unknown",
        retType: cur.retType ?? "Unknown",
        hookDistance: cur.hookDistance ?? "0x0",
      });
      cur = {};
    }
  }
  if (cur.className || cur.offset != null) {
    blocks.push({
      offset: cur.offset,
      className: cur.className ?? "Unknown",
      methodName: cur.methodName ?? "Unknown",
      retType: cur.retType ?? "Unknown",
      hookDistance: cur.hookDistance ?? "0x0",
    });
  }
  return blocks;
}

export function formatKinziFile(
  entries: ScanEntry[],
  libBase: number,
  mode: string,
): string {
  const now = new Date().toISOString().replace("T", " ").slice(0, 19);
  const lines = [
    "============================================================",
    `  KINZI TOOLS v3.0 — ${mode}`,
    `  Session: ${now}`,
    "  Arch: 64-bit",
    `  LIB BASE: ${libBase ? formatHex(libBase) : "not set"}`,
    `  TARGET: ${TARGET.name} ${TARGET.version}`,
    `  PACKAGE: ${TARGET.package}`,
    "============================================================",
    "",
  ];
  entries.forEach((e, i) => {
    lines.push(`SCAN #${i + 1}`);
    lines.push(`LIB ADDRESS:        ${libBase ? formatHex(libBase) : "—"}`);
    lines.push(`LOG ADDRESS:        ${formatHex(e.absolute)}`);
    lines.push(`SCRIPT OFFSET:      ${formatHex(e.offset)}`);
    lines.push(`REAL FUNC START:    ${formatHex(e.offset)}`);
    lines.push(`HOOK DISTANCE:      ${e.hookDistance}`);
    lines.push("");
    lines.push(`CLASS:  ${e.className}`);
    lines.push(`METHOD: ${e.methodName}`);
    lines.push(`TYPE:   ${e.retType}`);
    lines.push("");
    lines.push("----------------------------------------");
    lines.push("");
  });
  return lines.join("\n");
}

export function formatPatchTable(entries: ScanEntry[]): string {
  const body = entries
    .map(
      (e) =>
        `    { offset = ${formatHex(e.offset)}, class = ${JSON.stringify(e.className)}, method = ${JSON.stringify(e.methodName)}, rettype = ${JSON.stringify(e.retType)} },`,
    )
    .join("\n");
  return `-- PATCH TABLE — Kinzi KGO v3.0
-- Target: ${TARGET.name} ${TARGET.version}

local gg = gg
local ranges = gg.getRangesList("${TARGET.lib}")
if not ranges or not ranges[2] then gg.alert("libil2cpp not found") os.exit() end
local base = ranges[2].start

local offsets = {
${body}
}

for i, e in ipairs(offsets) do
    local addr = base + e.offset
    gg.toast(i .. ": " .. e.class .. "::" .. e.method .. " @ 0x" .. string.format("%X", addr))
end
`;
}

export function formatTemplate(entries: ScanEntry[]): string {
  const body = entries
    .map(
      (e) =>
        `    -- ${e.className}::${e.methodName} [${e.retType}]\n    -- Hook distance: ${e.hookDistance}\n    { offset = ${formatHex(e.offset)}, bytes = "?? ?? ?? ??", desc = ${JSON.stringify(e.methodName)} },\n`,
    )
    .join("\n");
  return `-- AUTO-GENERATED PATCH SCRIPT
-- Kinzi KGO v3.0 · ${TARGET.version}

local gg = gg
local ranges = gg.getRangesList("${TARGET.lib}")
if not ranges or not ranges[2] then
    gg.alert("libil2cpp.so not found!")
    os.exit()
end
local lib_base = ranges[2].start

local patches = {
${body}
}

for _, p in ipairs(patches) do
    if p.bytes ~= "?? ?? ?? ??" then
        local addr = lib_base + p.offset
        gg.toast("Patched: " .. p.desc .. " @ 0x" .. string.format("%X", addr))
    end
end
`;
}

export function evaluateGate(input: {
  gameOpen: boolean;
  packageName: string;
  version: string;
  ggAttached: boolean;
  processVisible: boolean;
}): { state: GateState; title: string; detail: string } {
  if (!input.gameOpen) {
    return {
      state: "not_running",
      title: "Open the game",
      detail:
        "Car Parking Multiplayer 2 is not running. Open it inside the same KGO space, wait until the lobby loads, then attach GameGuardian.",
    };
  }
  const pkg = input.packageName.trim();
  const ver = input.version.trim();
  if (!input.processVisible) {
    return {
      state: "no_process",
      title: "Process not detected",
      detail:
        "GameGuardian cannot see the process. In KGO, start CPM2 first, then open GG → Select process → Car Parking [x64].",
    };
  }
  if (!input.ggAttached) {
    return {
      state: "missing_info",
      title: "Required information is missing",
      detail:
        "GG is not attached. Select the Car Parking process, then enable script logging before running the convertor.",
    };
  }
  const pkgOk =
    pkg === TARGET.package || pkg.toLowerCase().includes("carparking.multyplayer2");
  const verOk = !ver || ver === TARGET.version || ver.startsWith("1.3.3.6");
  if (!pkgOk || !verOk) {
    return {
      state: "wrong_game",
      title: "Required version not detected",
      detail: `Need ${TARGET.name} ${TARGET.version} (${TARGET.package}). Found package “${pkg || "unknown"}” version “${ver || "unknown"}”.`,
    };
  }
  return {
    state: "ready",
    title: "Process ready",
    detail: `${TARGET.name} ${TARGET.version} is attached. Continue to the convertor — no need to repeat the GG attach steps.`,
  };
}

export const DEMO_LOG = `gg.getRangesList("libil2cpp.so")
gg.addListItems({
  [1] = {
    ['address'] = 0x6340718,
    ['flags'] = 4,
    ['value'] = 'D2800000h',
  },
})
gg.getRangesList("libil2cpp.so")
gg.addListItems({
  [1] = {
    ['address'] = 0x776cb4c71c,
    ['flags'] = 4,
    ['value'] = 'D65F03C0h',
  },
})
LIB ADDRESS:        0x774C870000
LOG ADDRESS:        0x776CB4C71C
SCRIPT OFFSET:      0x2CD4C71C
CLASS:  setText
METHOD: itz
TYPE:   bool
----------------------------------------
`;

export const WIZARD_STEPS = [
  {
    id: 1,
    title: "Remove log protection",
    body: "In GameGuardian, run your logger cleaner on the encrypted script first (the video’s Step 1). Save the cleared lua next to the original. Do not skip this — protected scripts dump empty refineNumber loops.",
  },
  {
    id: 2,
    title: "Open CPM2 inside KGO",
    body: "Launch Car Parking Multiplayer 2 1.3.3.6 in the same KGO space as GameGuardian. Wait until the world loads (not the splash). Then in GG: Select process → Car Parking [x64].",
  },
  {
    id: 3,
    title: "Enable script logging",
    body: "Long-press the floating GG icon → Execute script options. Check “Log most script calls”. Leave disassemble and dump-all off unless you need them. Run the cleared script and walk the menus you care about.",
  },
  {
    id: 4,
    title: "Kinzi convertor — option 2",
    body: "Execute the KGO app lua. Choose “Logged addresses (file)”. Point it at the .log / .txt GG just wrote (Telegram/Download folder). That is the video’s Step 3–4.",
  },
  {
    id: 5,
    title: "Check offset_results.kinzi",
    body: "Open the saved result. You should see LIB ADDRESS, SCRIPT OFFSET, CLASS, METHOD, TYPE. Use “Re-offset from result file” after a game update, or export a patch table from this lab.",
  },
] as const;
