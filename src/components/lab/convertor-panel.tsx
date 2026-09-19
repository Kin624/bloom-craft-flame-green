import {
  DEMO_LOG,
  formatHex,
  parseHex,
  parseLogToEntries,
  type ConvertMode,
} from "@/lib/kinzi/engine";
import { useLab } from "@/lib/store";
import { cn } from "@/lib/cn";

const MODES: { id: ConvertMode; label: string; hint: string }[] = [
  { id: "single", label: "1 · Single address", hint: "Paste one absolute address from the log." },
  { id: "logged", label: "2 · Logged file", hint: "Video step 4. Batch 0x addresses from a GG log." },
  { id: "direct", label: "3 · Direct offsets", hint: "Already-relative RVAs (0x1BD0E4 style)." },
  { id: "reoffset", label: "4 · Re-offset", hint: "CLASS/METHOD blocks from a previous .kinzi file." },
  { id: "template", label: "5 · Template", hint: "Build a patch lua with empty byte slots." },
  { id: "patch", label: "6 · Patch table", hint: "Export a Lua offsets = { } table." },
];

export function ConvertorPanel() {
  const s = useLab();

  function run() {
    const base = parseHex(s.libBase) ?? 0;
    const entries = parseLogToEntries(s.logText, base);
    s.setEntries(entries);
    s.setTab("results");
  }

  function onFile(file: File | null) {
    if (!file) return;
    const reader = new FileReader();
    reader.onload = () => s.setLogText(String(reader.result ?? ""));
    reader.readAsText(file);
  }

  return (
    <section className="space-y-5">
      <div className="rounded-xl border border-line bg-surface p-5">
        <h2 className="text-lg font-medium">Kinzi convertor</h2>
        <p className="mt-1 text-sm text-muted">
          Same six options as Kinzi Automatic Convertor v2. Class names resolve
          only if the paste includes CLASS/METHOD blocks or a dump snippet.
        </p>
        <div className="mt-4 grid gap-2 sm:grid-cols-2 lg:grid-cols-3">
          {MODES.map((m) => (
            <button
              key={m.id}
              type="button"
              onClick={() => s.setMode(m.id)}
              className={cn(
                "rounded-lg border px-3 py-3 text-left",
                s.mode === m.id
                  ? "border-accent bg-raised"
                  : "border-line bg-bg hover:border-muted",
              )}
            >
              <div className="text-sm font-medium">{m.label}</div>
              <div className="mt-1 text-xs leading-relaxed text-muted">{m.hint}</div>
            </button>
          ))}
        </div>
      </div>

      <div className="rounded-xl border border-line bg-surface p-5">
        <label className="text-xs text-muted">
          libil2cpp base (from GG ranges list)
          <input
            value={s.libBase}
            onChange={(e) => s.setLibBase(e.target.value)}
            className="mt-1.5 min-h-11 w-full rounded-md border border-line bg-raised px-3 font-mono text-sm outline-none focus:border-accent"
          />
        </label>

        <label className="mt-4 block text-xs text-muted">
          Log, .kinzi, or dump snippet
          <textarea
            value={s.logText}
            onChange={(e) => s.setLogText(e.target.value)}
            rows={12}
            placeholder="Paste GG log, offset_results.kinzi, or dump.cs snippet…"
            className="mt-1.5 w-full resize-y rounded-md border border-line bg-raised p-3 font-mono text-xs leading-relaxed text-fg outline-none focus:border-accent"
          />
        </label>

        <div className="mt-4 flex flex-wrap gap-3">
          <label className="inline-flex min-h-11 cursor-pointer items-center rounded-lg border border-line px-4 text-sm">
            Upload file
            <input
              type="file"
              accept=".txt,.log,.lua,.kinzi,.cs"
              className="hidden"
              onChange={(e) => onFile(e.target.files?.[0] ?? null)}
            />
          </label>
          <button
            type="button"
            onClick={() => s.setLogText(DEMO_LOG)}
            className="min-h-11 rounded-lg border border-line px-4 text-sm"
          >
            Load sample from session log
          </button>
          <button
            type="button"
            onClick={run}
            className="min-h-11 rounded-lg bg-accent px-5 text-sm font-medium text-accent-fg"
          >
            Convert
          </button>
        </div>
        {s.libBase && (
          <p className="mt-3 font-mono text-[11px] text-subtle">
            Base parsed as {formatHex(parseHex(s.libBase) ?? 0)}
          </p>
        )}
      </div>
    </section>
  );
}
