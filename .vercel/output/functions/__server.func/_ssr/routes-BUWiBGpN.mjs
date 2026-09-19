import { v as require_jsx_runtime } from "../_libs/@tanstack/react-router+[...].mjs";
import { a as Download, i as GitBranch, n as ScrollText, o as Cpu, r as Radar } from "../_libs/lucide-react.mjs";
import { n as create, t as persist } from "../_libs/zustand.mjs";
//#region node_modules/.nitro/vite/services/ssr/assets/routes-BUWiBGpN.js
var import_jsx_runtime = require_jsx_runtime();
var TARGET = {
	name: "Car Parking Multiplayer 2",
	version: "1.3.3.6",
	package: "com.olzhas.carparking.multyplayer2",
	lib: "libil2cpp.so"
};
var HEX_RE = /\b0x[0-9a-fA-F]{5,16}\b/g;
var IGNORE = /* @__PURE__ */ new Set([
	1384120320,
	1384120360,
	706675680
]);
function parseHex(value) {
	const t = value.trim();
	if (!t) return null;
	const n = Number.parseInt(t, 16);
	if (!Number.isFinite(n) || Number.isNaN(n)) return null;
	return n;
}
function formatHex(n) {
	return "0x" + n.toString(16).toUpperCase();
}
function shouldIgnore(n) {
	if (IGNORE.has(n)) return true;
	if (n >= 1375731712 && (n & 4278190080) === 1375731712) return true;
	return false;
}
function extractHexes(text) {
	const found = text.match(HEX_RE) ?? [];
	const seen = /* @__PURE__ */ new Set();
	const out = [];
	for (const h of found) {
		const key = h.toLowerCase();
		if (seen.has(key)) continue;
		seen.add(key);
		out.push(h);
	}
	return out;
}
function classifyAddress(n, libBase) {
	if (shouldIgnore(n)) return "skipped";
	if (libBase > 0 && n > libBase) return "absolute";
	if (n > 65536 && n <= 2147483648) return "offset";
	if (n > 4294967296) return "absolute";
	return "skipped";
}
function toOffset(n, libBase, kind) {
	if (kind === "absolute" && libBase > 0 && n > libBase) return n - libBase;
	if (kind === "offset") return n;
	return n;
}
function parseLogToEntries(text, libBase) {
	const hexes = extractHexes(text);
	const entries = [];
	const seenOff = /* @__PURE__ */ new Set();
	const classBlocks = parseKinziBlocks(text);
	for (const raw of hexes) {
		const n = parseHex(raw);
		if (n == null) continue;
		const kind = classifyAddress(n, libBase);
		if (kind === "skipped") continue;
		const offset = toOffset(n, libBase, kind);
		if (offset <= 0) continue;
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
			hookDistance: hit?.hookDistance ?? "0x0"
		});
	}
	return entries;
}
function parseKinziBlocks(text) {
	const blocks = [];
	let cur = {};
	for (const line of text.split(/\r?\n/)) {
		const off = line.match(/(?:OFFSET|SCRIPT OFFSET):\s*(0x[0-9a-fA-F]+)/i);
		const cls = line.match(/CLASS:\s*(.+)/i);
		const meth = line.match(/METHOD:\s*(.+)/i);
		const typ = line.match(/TYPE:\s*(.+)/i);
		const hook = line.match(/HOOK DISTANCE:\s*(0x[0-9a-fA-F]+)/i);
		const inline = line.match(/(\w+)::(\w+)\s*[→>]/);
		if (off) cur.offset = parseHex(off[1] ?? "") ?? void 0;
		if (cls) cur.className = cls[1]?.trim();
		if (meth) cur.methodName = meth[1]?.trim();
		if (typ) cur.retType = typ[1]?.trim();
		if (hook) cur.hookDistance = hook[1]?.trim();
		if (inline) blocks.push({
			className: inline[1] ?? "Unknown",
			methodName: inline[2] ?? "Unknown",
			retType: "Unknown",
			hookDistance: "0x0"
		});
		if (/^-{4,}/.test(line.trim()) && (cur.className || cur.offset != null)) {
			blocks.push({
				offset: cur.offset,
				className: cur.className ?? "Unknown",
				methodName: cur.methodName ?? "Unknown",
				retType: cur.retType ?? "Unknown",
				hookDistance: cur.hookDistance ?? "0x0"
			});
			cur = {};
		}
	}
	if (cur.className || cur.offset != null) blocks.push({
		offset: cur.offset,
		className: cur.className ?? "Unknown",
		methodName: cur.methodName ?? "Unknown",
		retType: cur.retType ?? "Unknown",
		hookDistance: cur.hookDistance ?? "0x0"
	});
	return blocks;
}
function formatKinziFile(entries, libBase, mode) {
	const now = (/* @__PURE__ */ new Date()).toISOString().replace("T", " ").slice(0, 19);
	const lines = [
		"============================================================",
		`  KINZI TOOLS v3.0 — ${mode}`,
		`  Session: ${now}`,
		"  Arch: 64-bit",
		`  LIB BASE: ${libBase ? formatHex(libBase) : "not set"}`,
		`  TARGET: ${TARGET.name} ${TARGET.version}`,
		`  PACKAGE: ${TARGET.package}`,
		"============================================================",
		""
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
function formatPatchTable(entries) {
	const body = entries.map((e) => `    { offset = ${formatHex(e.offset)}, class = ${JSON.stringify(e.className)}, method = ${JSON.stringify(e.methodName)}, rettype = ${JSON.stringify(e.retType)} },`).join("\n");
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
function formatTemplate(entries) {
	const body = entries.map((e) => `    -- ${e.className}::${e.methodName} [${e.retType}]\n    -- Hook distance: ${e.hookDistance}\n    { offset = ${formatHex(e.offset)}, bytes = "?? ?? ?? ??", desc = ${JSON.stringify(e.methodName)} },\n`).join("\n");
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
function evaluateGate(input) {
	if (!input.gameOpen) return {
		state: "not_running",
		title: "Open the game",
		detail: "Car Parking Multiplayer 2 is not running. Open it inside the same KGO space, wait until the lobby loads, then attach GameGuardian."
	};
	const pkg = input.packageName.trim();
	const ver = input.version.trim();
	if (!input.processVisible) return {
		state: "no_process",
		title: "Process not detected",
		detail: "GameGuardian cannot see the process. In KGO, start CPM2 first, then open GG → Select process → Car Parking [x64]."
	};
	if (!input.ggAttached) return {
		state: "missing_info",
		title: "Required information is missing",
		detail: "GG is not attached. Select the Car Parking process, then enable script logging before running the convertor."
	};
	const pkgOk = pkg === TARGET.package || pkg.toLowerCase().includes("carparking.multyplayer2");
	const verOk = !ver || ver === TARGET.version || ver.startsWith("1.3.3.6");
	if (!pkgOk || !verOk) return {
		state: "wrong_game",
		title: "Required version not detected",
		detail: `Need ${TARGET.name} ${TARGET.version} (${TARGET.package}). Found package “${pkg || "unknown"}” version “${ver || "unknown"}”.`
	};
	return {
		state: "ready",
		title: "Process ready",
		detail: `${TARGET.name} ${TARGET.version} is attached. Continue to the convertor — no need to repeat the GG attach steps.`
	};
}
var DEMO_LOG = `gg.getRangesList("libil2cpp.so")
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
var WIZARD_STEPS = [
	{
		id: 1,
		title: "Remove log protection",
		body: "In GameGuardian, run your logger cleaner on the encrypted script first (the video’s Step 1). Save the cleared lua next to the original. Do not skip this — protected scripts dump empty refineNumber loops."
	},
	{
		id: 2,
		title: "Open CPM2 inside KGO",
		body: "Launch Car Parking Multiplayer 2 1.3.3.6 in the same KGO space as GameGuardian. Wait until the world loads (not the splash). Then in GG: Select process → Car Parking [x64]."
	},
	{
		id: 3,
		title: "Enable script logging",
		body: "Long-press the floating GG icon → Execute script options. Check “Log most script calls”. Leave disassemble and dump-all off unless you need them. Run the cleared script and walk the menus you care about."
	},
	{
		id: 4,
		title: "Kinzi convertor — option 2",
		body: "Execute the KGO app lua. Choose “Logged addresses (file)”. Point it at the .log / .txt GG just wrote (Telegram/Download folder). That is the video’s Step 3–4."
	},
	{
		id: 5,
		title: "Check offset_results.kinzi",
		body: "Open the saved result. You should see LIB ADDRESS, SCRIPT OFFSET, CLASS, METHOD, TYPE. Use “Re-offset from result file” after a game update, or export a patch table from this lab."
	}
];
var useLab = create()(persist((set) => ({
	tab: "gate",
	setTab: (tab) => set({ tab }),
	gameOpen: false,
	processVisible: false,
	ggAttached: false,
	packageName: TARGET.package,
	version: TARGET.version,
	setGate: (p) => set(p),
	gateState: "idle",
	setGateState: (gateState) => set({ gateState }),
	libBase: "0x774C870000",
	setLibBase: (libBase) => set({ libBase }),
	logText: "",
	setLogText: (logText) => set({ logText }),
	mode: "logged",
	setMode: (mode) => set({ mode }),
	entries: [],
	setEntries: (entries) => set({ entries }),
	wizardStep: 1,
	setWizardStep: (wizardStep) => set({ wizardStep })
}), {
	name: "kinzi-kgo-lab",
	partialize: (s) => ({
		packageName: s.packageName,
		version: s.version,
		libBase: s.libBase,
		logText: s.logText,
		entries: s.entries,
		mode: s.mode
	})
}));
function cn(...parts) {
	return parts.filter(Boolean).join(" ");
}
var MODES = [
	{
		id: "single",
		label: "1 · Single address",
		hint: "Paste one absolute address from the log."
	},
	{
		id: "logged",
		label: "2 · Logged file",
		hint: "Video step 4. Batch 0x addresses from a GG log."
	},
	{
		id: "direct",
		label: "3 · Direct offsets",
		hint: "Already-relative RVAs (0x1BD0E4 style)."
	},
	{
		id: "reoffset",
		label: "4 · Re-offset",
		hint: "CLASS/METHOD blocks from a previous .kinzi file."
	},
	{
		id: "template",
		label: "5 · Template",
		hint: "Build a patch lua with empty byte slots."
	},
	{
		id: "patch",
		label: "6 · Patch table",
		hint: "Export a Lua offsets = { } table."
	}
];
function ConvertorPanel() {
	const s = useLab();
	function run() {
		const base = parseHex(s.libBase) ?? 0;
		const entries = parseLogToEntries(s.logText, base);
		s.setEntries(entries);
		s.setTab("results");
	}
	function onFile(file) {
		if (!file) return;
		const reader = new FileReader();
		reader.onload = () => s.setLogText(String(reader.result ?? ""));
		reader.readAsText(file);
	}
	return /* @__PURE__ */ (0, import_jsx_runtime.jsxs)("section", {
		className: "space-y-5",
		children: [/* @__PURE__ */ (0, import_jsx_runtime.jsxs)("div", {
			className: "rounded-xl border border-line bg-surface p-5",
			children: [
				/* @__PURE__ */ (0, import_jsx_runtime.jsx)("h2", {
					className: "text-lg font-medium",
					children: "Kinzi convertor"
				}),
				/* @__PURE__ */ (0, import_jsx_runtime.jsx)("p", {
					className: "mt-1 text-sm text-muted",
					children: "Same six options as Kinzi Automatic Convertor v2. Class names resolve only if the paste includes CLASS/METHOD blocks or a dump snippet."
				}),
				/* @__PURE__ */ (0, import_jsx_runtime.jsx)("div", {
					className: "mt-4 grid gap-2 sm:grid-cols-2 lg:grid-cols-3",
					children: MODES.map((m) => /* @__PURE__ */ (0, import_jsx_runtime.jsxs)("button", {
						type: "button",
						onClick: () => s.setMode(m.id),
						className: cn("rounded-lg border px-3 py-3 text-left", s.mode === m.id ? "border-accent bg-raised" : "border-line bg-bg hover:border-muted"),
						children: [/* @__PURE__ */ (0, import_jsx_runtime.jsx)("div", {
							className: "text-sm font-medium",
							children: m.label
						}), /* @__PURE__ */ (0, import_jsx_runtime.jsx)("div", {
							className: "mt-1 text-xs leading-relaxed text-muted",
							children: m.hint
						})]
					}, m.id))
				})
			]
		}), /* @__PURE__ */ (0, import_jsx_runtime.jsxs)("div", {
			className: "rounded-xl border border-line bg-surface p-5",
			children: [
				/* @__PURE__ */ (0, import_jsx_runtime.jsxs)("label", {
					className: "text-xs text-muted",
					children: ["libil2cpp base (from GG ranges list)", /* @__PURE__ */ (0, import_jsx_runtime.jsx)("input", {
						value: s.libBase,
						onChange: (e) => s.setLibBase(e.target.value),
						className: "mt-1.5 min-h-11 w-full rounded-md border border-line bg-raised px-3 font-mono text-sm outline-none focus:border-accent"
					})]
				}),
				/* @__PURE__ */ (0, import_jsx_runtime.jsxs)("label", {
					className: "mt-4 block text-xs text-muted",
					children: ["Log, .kinzi, or dump snippet", /* @__PURE__ */ (0, import_jsx_runtime.jsx)("textarea", {
						value: s.logText,
						onChange: (e) => s.setLogText(e.target.value),
						rows: 12,
						placeholder: "Paste GG log, offset_results.kinzi, or dump.cs snippet…",
						className: "mt-1.5 w-full resize-y rounded-md border border-line bg-raised p-3 font-mono text-xs leading-relaxed text-fg outline-none focus:border-accent"
					})]
				}),
				/* @__PURE__ */ (0, import_jsx_runtime.jsxs)("div", {
					className: "mt-4 flex flex-wrap gap-3",
					children: [
						/* @__PURE__ */ (0, import_jsx_runtime.jsxs)("label", {
							className: "inline-flex min-h-11 cursor-pointer items-center rounded-lg border border-line px-4 text-sm",
							children: ["Upload file", /* @__PURE__ */ (0, import_jsx_runtime.jsx)("input", {
								type: "file",
								accept: ".txt,.log,.lua,.kinzi,.cs",
								className: "hidden",
								onChange: (e) => onFile(e.target.files?.[0] ?? null)
							})]
						}),
						/* @__PURE__ */ (0, import_jsx_runtime.jsx)("button", {
							type: "button",
							onClick: () => s.setLogText(DEMO_LOG),
							className: "min-h-11 rounded-lg border border-line px-4 text-sm",
							children: "Load sample from session log"
						}),
						/* @__PURE__ */ (0, import_jsx_runtime.jsx)("button", {
							type: "button",
							onClick: run,
							className: "min-h-11 rounded-lg bg-accent px-5 text-sm font-medium text-accent-fg",
							children: "Convert"
						})
					]
				}),
				s.libBase && /* @__PURE__ */ (0, import_jsx_runtime.jsxs)("p", {
					className: "mt-3 font-mono text-[11px] text-subtle",
					children: ["Base parsed as ", formatHex(parseHex(s.libBase) ?? 0)]
				})
			]
		})]
	});
}
function GatePanel() {
	const s = useLab();
	function runCheck() {
		const r = evaluateGate({
			gameOpen: s.gameOpen,
			packageName: s.packageName,
			version: s.version,
			ggAttached: s.ggAttached,
			processVisible: s.processVisible
		});
		s.setGateState(r.state);
		if (r.state === "ready") s.setTab("wizard");
	}
	const result = evaluateGate({
		gameOpen: s.gameOpen,
		packageName: s.packageName,
		version: s.version,
		ggAttached: s.ggAttached,
		processVisible: s.processVisible
	});
	return /* @__PURE__ */ (0, import_jsx_runtime.jsxs)("section", {
		className: "grid gap-6 lg:grid-cols-[1.1fr_0.9fr]",
		children: [/* @__PURE__ */ (0, import_jsx_runtime.jsxs)("div", {
			className: "rounded-xl border border-line bg-surface p-5 sm:p-6",
			children: [
				/* @__PURE__ */ (0, import_jsx_runtime.jsx)("h2", {
					className: "text-lg font-medium",
					children: "Process gate"
				}),
				/* @__PURE__ */ (0, import_jsx_runtime.jsx)("p", {
					className: "mt-1 text-sm leading-relaxed text-muted",
					children: "Same rules as the KGO lua. This browser cannot see your phone — set the live state, then run the check. On device, the lua does this automatically via GameGuardian."
				}),
				/* @__PURE__ */ (0, import_jsx_runtime.jsxs)("dl", {
					className: "mt-5 grid gap-3 font-mono text-xs",
					children: [
						/* @__PURE__ */ (0, import_jsx_runtime.jsx)(Row, {
							k: "Package",
							v: TARGET.package
						}),
						/* @__PURE__ */ (0, import_jsx_runtime.jsx)(Row, {
							k: "Version",
							v: TARGET.version
						}),
						/* @__PURE__ */ (0, import_jsx_runtime.jsx)(Row, {
							k: "Library",
							v: TARGET.lib
						})
					]
				}),
				/* @__PURE__ */ (0, import_jsx_runtime.jsxs)("div", {
					className: "mt-6 space-y-3",
					children: [
						/* @__PURE__ */ (0, import_jsx_runtime.jsx)(Toggle, {
							label: "Game is running",
							on: s.gameOpen,
							onChange: (v) => s.setGate({ gameOpen: v })
						}),
						/* @__PURE__ */ (0, import_jsx_runtime.jsx)(Toggle, {
							label: "Car Parking [x64] visible in GG process list",
							on: s.processVisible,
							onChange: (v) => s.setGate({ processVisible: v })
						}),
						/* @__PURE__ */ (0, import_jsx_runtime.jsx)(Toggle, {
							label: "GameGuardian attached",
							on: s.ggAttached,
							onChange: (v) => s.setGate({ ggAttached: v })
						})
					]
				}),
				/* @__PURE__ */ (0, import_jsx_runtime.jsxs)("label", {
					className: "mt-5 block text-xs text-muted",
					children: ["Detected package", /* @__PURE__ */ (0, import_jsx_runtime.jsx)("input", {
						value: s.packageName,
						onChange: (e) => s.setGate({ packageName: e.target.value }),
						className: "mt-1.5 min-h-11 w-full rounded-md border border-line bg-raised px-3 font-mono text-sm text-fg outline-none focus:border-accent"
					})]
				}),
				/* @__PURE__ */ (0, import_jsx_runtime.jsxs)("label", {
					className: "mt-3 block text-xs text-muted",
					children: ["Detected version", /* @__PURE__ */ (0, import_jsx_runtime.jsx)("input", {
						value: s.version,
						onChange: (e) => s.setGate({ version: e.target.value }),
						className: "mt-1.5 min-h-11 w-full rounded-md border border-line bg-raised px-3 font-mono text-sm text-fg outline-none focus:border-accent"
					})]
				}),
				/* @__PURE__ */ (0, import_jsx_runtime.jsx)("button", {
					type: "button",
					onClick: runCheck,
					className: "mt-6 min-h-11 w-full rounded-lg bg-accent px-4 text-sm font-medium text-accent-fg",
					children: "Run process check"
				})
			]
		}), /* @__PURE__ */ (0, import_jsx_runtime.jsxs)("aside", {
			className: "rounded-xl border border-line bg-raised p-5 sm:p-6",
			children: [
				/* @__PURE__ */ (0, import_jsx_runtime.jsx)("p", {
					className: "font-mono text-[11px] tracking-widest text-muted uppercase",
					children: "Gate result"
				}),
				/* @__PURE__ */ (0, import_jsx_runtime.jsx)("h3", {
					className: "mt-3 text-xl font-medium",
					children: result.title
				}),
				/* @__PURE__ */ (0, import_jsx_runtime.jsx)("p", {
					className: "mt-2 text-sm leading-relaxed text-muted",
					children: result.detail
				}),
				/* @__PURE__ */ (0, import_jsx_runtime.jsxs)("ul", {
					className: "mt-6 space-y-2 text-sm text-muted",
					children: [
						/* @__PURE__ */ (0, import_jsx_runtime.jsx)("li", {
							className: cn(s.gameOpen ? "text-ok" : ""),
							children: s.gameOpen ? "Game open" : "If the game is not running → open it"
						}),
						/* @__PURE__ */ (0, import_jsx_runtime.jsx)("li", {
							className: cn(result.state !== "wrong_game" ? "" : "text-danger"),
							children: "If the wrong game/version is running → required 1.3.3.6"
						}),
						/* @__PURE__ */ (0, import_jsx_runtime.jsx)("li", { children: "If the process cannot be detected → attach GG" }),
						/* @__PURE__ */ (0, import_jsx_runtime.jsx)("li", { children: "If required info is missing → stop and explain" })
					]
				})
			]
		})]
	});
}
function Row({ k, v }) {
	return /* @__PURE__ */ (0, import_jsx_runtime.jsxs)("div", {
		className: "flex items-baseline justify-between gap-3 border-b border-line/70 py-2",
		children: [/* @__PURE__ */ (0, import_jsx_runtime.jsx)("dt", {
			className: "text-subtle",
			children: k
		}), /* @__PURE__ */ (0, import_jsx_runtime.jsx)("dd", {
			className: "truncate text-fg",
			children: v
		})]
	});
}
function Toggle({ label, on, onChange }) {
	return /* @__PURE__ */ (0, import_jsx_runtime.jsxs)("button", {
		type: "button",
		onClick: () => onChange(!on),
		className: "flex min-h-11 w-full items-center justify-between gap-3 rounded-md border border-line bg-raised px-3 text-left text-sm",
		children: [/* @__PURE__ */ (0, import_jsx_runtime.jsx)("span", { children: label }), /* @__PURE__ */ (0, import_jsx_runtime.jsx)("span", {
			className: cn("h-5 w-9 rounded-full p-0.5 transition-colors", on ? "bg-accent" : "bg-line"),
			children: /* @__PURE__ */ (0, import_jsx_runtime.jsx)("span", { className: cn("block size-4 rounded-full bg-bg transition-transform", on ? "translate-x-4" : "translate-x-0") })
		})]
	});
}
function PackPanel() {
	return /* @__PURE__ */ (0, import_jsx_runtime.jsxs)("section", {
		className: "grid gap-5 lg:grid-cols-2",
		children: [/* @__PURE__ */ (0, import_jsx_runtime.jsxs)("article", {
			className: "rounded-xl border border-line bg-surface p-6",
			children: [
				/* @__PURE__ */ (0, import_jsx_runtime.jsx)("p", {
					className: "font-mono text-[11px] tracking-widest text-muted uppercase",
					children: "For KGO Multi Space"
				}),
				/* @__PURE__ */ (0, import_jsx_runtime.jsx)("h2", {
					className: "mt-2 text-xl font-medium",
					children: "KINZI_KGO_APP.lua"
				}),
				/* @__PURE__ */ (0, import_jsx_runtime.jsx)("p", {
					className: "mt-3 text-sm leading-relaxed text-muted",
					children: "This is the application you put on KGO. Copy it into the virtual space (Download/Telegram), open GameGuardian while CPM2 1.3.3.6 is running, then Execute script."
				}),
				/* @__PURE__ */ (0, import_jsx_runtime.jsxs)("ol", {
					className: "mt-5 list-decimal space-y-2 pl-5 text-sm text-muted",
					children: [
						/* @__PURE__ */ (0, import_jsx_runtime.jsx)("li", { children: "Install KGO Multi Space and clone / open the space." }),
						/* @__PURE__ */ (0, import_jsx_runtime.jsx)("li", { children: "Install GameGuardian inside that space (your GG apk)." }),
						/* @__PURE__ */ (0, import_jsx_runtime.jsx)("li", { children: "Install Car Parking Multiplayer 2 1.3.3.6 in the same space." }),
						/* @__PURE__ */ (0, import_jsx_runtime.jsx)("li", { children: "Copy KINZI_KGO_APP.lua into the space storage." }),
						/* @__PURE__ */ (0, import_jsx_runtime.jsx)("li", { children: "Start the game → attach GG → execute the lua." })
					]
				}),
				/* @__PURE__ */ (0, import_jsx_runtime.jsx)("a", {
					href: "/KINZI_KGO_APP.lua",
					download: true,
					className: "mt-6 inline-flex min-h-11 items-center rounded-lg bg-accent px-5 text-sm font-medium text-accent-fg",
					children: "Download KGO app"
				})
			]
		}), /* @__PURE__ */ (0, import_jsx_runtime.jsxs)("article", {
			className: "rounded-xl border border-line bg-raised p-6",
			children: [
				/* @__PURE__ */ (0, import_jsx_runtime.jsx)("h3", {
					className: "text-lg font-medium",
					children: "Full convertor (class names)"
				}),
				/* @__PURE__ */ (0, import_jsx_runtime.jsx)("p", {
					className: "mt-2 text-sm leading-relaxed text-muted",
					children: "The KGO app gates the process and converts addresses to offsets. For CLASS/METHOD resolution (Il2Cpp FindMethods), also drop Kinzi Automatic Convertor v2 into the same folder and run it after attach."
				}),
				/* @__PURE__ */ (0, import_jsx_runtime.jsx)("a", {
					href: "/Kinzi_Automatic_Convertor_v2.lua",
					download: true,
					className: "mt-6 inline-flex min-h-11 items-center rounded-lg border border-line px-5 text-sm",
					children: "Download Kinzi Convertor v2"
				}),
				/* @__PURE__ */ (0, import_jsx_runtime.jsx)("p", {
					className: "mt-6 text-xs leading-relaxed text-subtle",
					children: "Live Il2Cpp lookup only works while the game is attached in GG. This lab handles the offline half: logs, offset math, templates, and the KGO pack."
				})
			]
		})]
	});
}
function downloadText(filename, text, mime = "text/plain") {
	const blob = new Blob([text], { type: mime });
	const url = URL.createObjectURL(blob);
	const a = document.createElement("a");
	a.href = url;
	a.download = filename;
	a.click();
	URL.revokeObjectURL(url);
}
function ResultsPanel() {
	const entries = useLab((s) => s.entries);
	const libBase = useLab((s) => s.libBase);
	const mode = useLab((s) => s.mode);
	const base = parseHex(libBase) ?? 0;
	if (entries.length === 0) return /* @__PURE__ */ (0, import_jsx_runtime.jsxs)("section", {
		className: "rounded-xl border border-line bg-surface p-8 text-center",
		children: [/* @__PURE__ */ (0, import_jsx_runtime.jsx)("h2", {
			className: "text-lg font-medium",
			children: "No results yet"
		}), /* @__PURE__ */ (0, import_jsx_runtime.jsx)("p", {
			className: "mt-2 text-sm text-muted",
			children: "Convert a log first. Absolute addresses above the lib base become script offsets; smaller values are treated as RVAs."
		})]
	});
	const kinzi = formatKinziFile(entries, base, mode);
	const table = formatPatchTable(entries);
	const tmpl = formatTemplate(entries);
	return /* @__PURE__ */ (0, import_jsx_runtime.jsxs)("section", {
		className: "space-y-5",
		children: [
			/* @__PURE__ */ (0, import_jsx_runtime.jsxs)("div", {
				className: "flex flex-wrap items-center justify-between gap-3",
				children: [/* @__PURE__ */ (0, import_jsx_runtime.jsxs)("h2", {
					className: "text-lg font-medium",
					children: [
						entries.length,
						" converted address",
						entries.length === 1 ? "" : "es"
					]
				}), /* @__PURE__ */ (0, import_jsx_runtime.jsxs)("div", {
					className: "flex flex-wrap gap-2",
					children: [
						/* @__PURE__ */ (0, import_jsx_runtime.jsx)(OutBtn, {
							label: "offset_results.kinzi",
							onClick: () => downloadText("offset_results.kinzi", kinzi)
						}),
						/* @__PURE__ */ (0, import_jsx_runtime.jsx)(OutBtn, {
							label: "patch_table.lua",
							onClick: () => downloadText("patch_table.lua", table)
						}),
						/* @__PURE__ */ (0, import_jsx_runtime.jsx)(OutBtn, {
							label: "generated_patch.lua",
							onClick: () => downloadText("generated_patch.lua", tmpl)
						})
					]
				})]
			}),
			/* @__PURE__ */ (0, import_jsx_runtime.jsx)("div", {
				className: "overflow-x-auto rounded-xl border border-line",
				children: /* @__PURE__ */ (0, import_jsx_runtime.jsxs)("table", {
					className: "w-full min-w-[640px] text-left text-sm",
					children: [/* @__PURE__ */ (0, import_jsx_runtime.jsx)("thead", {
						className: "bg-raised font-mono text-[11px] tracking-wide text-muted uppercase",
						children: /* @__PURE__ */ (0, import_jsx_runtime.jsxs)("tr", { children: [
							/* @__PURE__ */ (0, import_jsx_runtime.jsx)("th", {
								className: "px-3 py-3",
								children: "Offset"
							}),
							/* @__PURE__ */ (0, import_jsx_runtime.jsx)("th", {
								className: "px-3 py-3",
								children: "Log address"
							}),
							/* @__PURE__ */ (0, import_jsx_runtime.jsx)("th", {
								className: "px-3 py-3",
								children: "Kind"
							}),
							/* @__PURE__ */ (0, import_jsx_runtime.jsx)("th", {
								className: "px-3 py-3",
								children: "Class"
							}),
							/* @__PURE__ */ (0, import_jsx_runtime.jsx)("th", {
								className: "px-3 py-3",
								children: "Method"
							})
						] })
					}), /* @__PURE__ */ (0, import_jsx_runtime.jsx)("tbody", { children: entries.map((e) => /* @__PURE__ */ (0, import_jsx_runtime.jsxs)("tr", {
						className: "border-t border-line font-mono text-xs",
						children: [
							/* @__PURE__ */ (0, import_jsx_runtime.jsx)("td", {
								className: "px-3 py-3 text-accent",
								children: formatHex(e.offset)
							}),
							/* @__PURE__ */ (0, import_jsx_runtime.jsx)("td", {
								className: "px-3 py-3",
								children: formatHex(e.absolute)
							}),
							/* @__PURE__ */ (0, import_jsx_runtime.jsx)("td", {
								className: "px-3 py-3 text-muted",
								children: e.kind
							}),
							/* @__PURE__ */ (0, import_jsx_runtime.jsx)("td", {
								className: "px-3 py-3",
								children: e.className
							}),
							/* @__PURE__ */ (0, import_jsx_runtime.jsx)("td", {
								className: "px-3 py-3",
								children: e.methodName
							})
						]
					}, e.offset)) })]
				})
			}),
			/* @__PURE__ */ (0, import_jsx_runtime.jsx)("pre", {
				className: "max-h-80 overflow-auto rounded-xl border border-line bg-raised p-4 font-mono text-[11px] leading-relaxed text-muted",
				children: kinzi
			})
		]
	});
}
function OutBtn({ label, onClick }) {
	return /* @__PURE__ */ (0, import_jsx_runtime.jsx)("button", {
		type: "button",
		onClick,
		className: "min-h-10 rounded-md border border-line px-3 text-xs",
		children: label
	});
}
var NAV = [
	{
		id: "gate",
		label: "Process",
		icon: Radar
	},
	{
		id: "wizard",
		label: "Wizard",
		icon: GitBranch
	},
	{
		id: "convertor",
		label: "Convertor",
		icon: Cpu
	},
	{
		id: "results",
		label: "Results",
		icon: ScrollText
	},
	{
		id: "pack",
		label: "KGO pack",
		icon: Download
	}
];
function Shell({ children }) {
	const tab = useLab((s) => s.tab);
	const setTab = useLab((s) => s.setTab);
	const gateState = useLab((s) => s.gateState);
	return /* @__PURE__ */ (0, import_jsx_runtime.jsxs)("div", {
		className: "min-h-dvh bg-bg text-fg",
		children: [/* @__PURE__ */ (0, import_jsx_runtime.jsxs)("div", {
			className: "mx-auto flex min-h-dvh max-w-5xl flex-col px-4 pb-24 pt-6 sm:px-6 lg:px-8",
			children: [
				/* @__PURE__ */ (0, import_jsx_runtime.jsxs)("header", {
					className: "mb-8 flex items-end justify-between gap-4",
					children: [/* @__PURE__ */ (0, import_jsx_runtime.jsxs)("div", { children: [
						/* @__PURE__ */ (0, import_jsx_runtime.jsx)("p", {
							className: "font-mono text-xs tracking-[0.22em] text-muted uppercase",
							children: "KGO · GameGuardian space"
						}),
						/* @__PURE__ */ (0, import_jsx_runtime.jsx)("h1", {
							className: "mt-1 font-sans text-3xl font-semibold tracking-tight sm:text-4xl",
							children: "KINZI KGO"
						}),
						/* @__PURE__ */ (0, import_jsx_runtime.jsxs)("p", {
							className: "mt-2 max-w-xl text-sm leading-relaxed text-muted",
							children: [
								"Offset lab for ",
								TARGET.name,
								" ",
								TARGET.version,
								". Gate the process, walk the video steps, convert logs, then drop the lua into KGO."
							]
						})
					] }), /* @__PURE__ */ (0, import_jsx_runtime.jsx)(StatusChip, { state: gateState })]
				}),
				/* @__PURE__ */ (0, import_jsx_runtime.jsx)("div", {
					className: "mb-6 hidden gap-2 sm:flex",
					children: NAV.map((n) => /* @__PURE__ */ (0, import_jsx_runtime.jsx)(NavBtn, {
						...n,
						active: tab === n.id,
						onClick: () => setTab(n.id)
					}, n.id))
				}),
				/* @__PURE__ */ (0, import_jsx_runtime.jsx)("main", {
					className: "flex-1",
					children
				})
			]
		}), /* @__PURE__ */ (0, import_jsx_runtime.jsx)("nav", {
			className: "fixed inset-x-0 bottom-0 z-20 border-t border-line bg-bg/95 backdrop-blur-sm sm:hidden",
			children: /* @__PURE__ */ (0, import_jsx_runtime.jsx)("div", {
				className: "grid grid-cols-5",
				children: NAV.map((n) => /* @__PURE__ */ (0, import_jsx_runtime.jsxs)("button", {
					type: "button",
					onClick: () => setTab(n.id),
					className: cn("flex min-h-14 flex-col items-center justify-center gap-1 text-[10px] tracking-wide", tab === n.id ? "text-accent" : "text-muted"),
					children: [/* @__PURE__ */ (0, import_jsx_runtime.jsx)(n.icon, {
						className: "size-4",
						strokeWidth: 1.6
					}), n.label]
				}, n.id))
			})
		})]
	});
}
function NavBtn({ label, icon: Icon, active, onClick }) {
	return /* @__PURE__ */ (0, import_jsx_runtime.jsxs)("button", {
		type: "button",
		onClick,
		className: cn("inline-flex min-h-11 items-center gap-2 rounded-lg px-3.5 text-sm transition-colors duration-150", active ? "bg-accent text-accent-fg" : "bg-raised text-muted hover:text-fg"),
		children: [/* @__PURE__ */ (0, import_jsx_runtime.jsx)(Icon, {
			className: "size-4",
			strokeWidth: 1.6
		}), label]
	});
}
function StatusChip({ state }) {
	const map = {
		idle: {
			label: "Not attached",
			cls: "text-muted border-line"
		},
		ready: {
			label: "Process ready",
			cls: "text-ok border-ok/30"
		},
		not_running: {
			label: "Game closed",
			cls: "text-warn border-warn/30"
		},
		wrong_game: {
			label: "Wrong version",
			cls: "text-danger border-danger/30"
		},
		no_process: {
			label: "No process",
			cls: "text-danger border-danger/30"
		},
		missing_info: {
			label: "Missing info",
			cls: "text-warn border-warn/30"
		}
	};
	const m = map[state] ?? map.idle;
	return /* @__PURE__ */ (0, import_jsx_runtime.jsx)("span", {
		className: cn("hidden shrink-0 rounded-full border px-3 py-1 font-mono text-[11px] uppercase tracking-wider sm:inline-flex", m.cls),
		children: m.label
	});
}
function WizardPanel() {
	const step = useLab((s) => s.wizardStep);
	const setStep = useLab((s) => s.setWizardStep);
	const setTab = useLab((s) => s.setTab);
	const current = WIZARD_STEPS[step - 1] ?? WIZARD_STEPS[0];
	return /* @__PURE__ */ (0, import_jsx_runtime.jsxs)("section", {
		className: "rounded-xl border border-line bg-surface p-5 sm:p-7",
		children: [
			/* @__PURE__ */ (0, import_jsx_runtime.jsx)("p", {
				className: "font-mono text-[11px] tracking-widest text-muted uppercase",
				children: "From the recorded session"
			}),
			/* @__PURE__ */ (0, import_jsx_runtime.jsx)("h2", {
				className: "mt-2 text-lg font-medium",
				children: "Five-step attach flow"
			}),
			/* @__PURE__ */ (0, import_jsx_runtime.jsx)("p", {
				className: "mt-1 max-w-2xl text-sm text-muted",
				children: "Matches the video: logger cleaner → attach CPM2 in KGO → log script calls → Kinzi option 2 → read offset_results.kinzi."
			}),
			/* @__PURE__ */ (0, import_jsx_runtime.jsx)("ol", {
				className: "mt-6 flex gap-2",
				children: WIZARD_STEPS.map((s) => /* @__PURE__ */ (0, import_jsx_runtime.jsx)("li", {
					className: "flex-1",
					children: /* @__PURE__ */ (0, import_jsx_runtime.jsx)("button", {
						type: "button",
						onClick: () => setStep(s.id),
						className: cn("h-1.5 w-full rounded-full", s.id <= step ? "bg-accent" : "bg-line"),
						"aria-label": `Step ${s.id}`
					})
				}, s.id))
			}),
			/* @__PURE__ */ (0, import_jsx_runtime.jsxs)("div", {
				className: "mt-8",
				children: [
					/* @__PURE__ */ (0, import_jsx_runtime.jsxs)("p", {
						className: "font-mono text-xs text-accent",
						children: [
							"STEP ",
							current.id,
							" / 5"
						]
					}),
					/* @__PURE__ */ (0, import_jsx_runtime.jsx)("h3", {
						className: "mt-2 text-2xl font-medium",
						children: current.title
					}),
					/* @__PURE__ */ (0, import_jsx_runtime.jsx)("p", {
						className: "mt-3 max-w-xl text-sm leading-relaxed text-muted",
						children: current.body
					})
				]
			}),
			/* @__PURE__ */ (0, import_jsx_runtime.jsxs)("div", {
				className: "mt-8 flex flex-wrap gap-3",
				children: [/* @__PURE__ */ (0, import_jsx_runtime.jsx)("button", {
					type: "button",
					disabled: step <= 1,
					onClick: () => setStep(step - 1),
					className: "min-h-11 rounded-lg border border-line px-4 text-sm disabled:opacity-40",
					children: "Back"
				}), step < 5 ? /* @__PURE__ */ (0, import_jsx_runtime.jsx)("button", {
					type: "button",
					onClick: () => setStep(step + 1),
					className: "min-h-11 rounded-lg bg-accent px-5 text-sm font-medium text-accent-fg",
					children: "Next"
				}) : /* @__PURE__ */ (0, import_jsx_runtime.jsx)("button", {
					type: "button",
					onClick: () => setTab("convertor"),
					className: "min-h-11 rounded-lg bg-accent px-5 text-sm font-medium text-accent-fg",
					children: "Open convertor"
				})]
			})
		]
	});
}
function Home() {
	const tab = useLab((s) => s.tab);
	return /* @__PURE__ */ (0, import_jsx_runtime.jsxs)(Shell, { children: [
		tab === "gate" && /* @__PURE__ */ (0, import_jsx_runtime.jsx)(GatePanel, {}),
		tab === "wizard" && /* @__PURE__ */ (0, import_jsx_runtime.jsx)(WizardPanel, {}),
		tab === "convertor" && /* @__PURE__ */ (0, import_jsx_runtime.jsx)(ConvertorPanel, {}),
		tab === "results" && /* @__PURE__ */ (0, import_jsx_runtime.jsx)(ResultsPanel, {}),
		tab === "pack" && /* @__PURE__ */ (0, import_jsx_runtime.jsx)(PackPanel, {})
	] });
}
//#endregion
export { Home as component };
