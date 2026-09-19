import {
  formatKinziFile,
  formatPatchTable,
  formatTemplate,
  formatHex,
  parseHex,
} from "@/lib/kinzi/engine";
import { downloadText } from "@/lib/kinzi/download";
import { useLab } from "@/lib/store";

export function ResultsPanel() {
  const entries = useLab((s) => s.entries);
  const libBase = useLab((s) => s.libBase);
  const mode = useLab((s) => s.mode);
  const base = parseHex(libBase) ?? 0;

  if (entries.length === 0) {
    return (
      <section className="rounded-xl border border-line bg-surface p-8 text-center">
        <h2 className="text-lg font-medium">No results yet</h2>
        <p className="mt-2 text-sm text-muted">
          Convert a log first. Absolute addresses above the lib base become
          script offsets; smaller values are treated as RVAs.
        </p>
      </section>
    );
  }

  const kinzi = formatKinziFile(entries, base, mode);
  const table = formatPatchTable(entries);
  const tmpl = formatTemplate(entries);

  return (
    <section className="space-y-5">
      <div className="flex flex-wrap items-center justify-between gap-3">
        <h2 className="text-lg font-medium">
          {entries.length} converted address{entries.length === 1 ? "" : "es"}
        </h2>
        <div className="flex flex-wrap gap-2">
          <OutBtn
            label="offset_results.kinzi"
            onClick={() => downloadText("offset_results.kinzi", kinzi)}
          />
          <OutBtn
            label="patch_table.lua"
            onClick={() => downloadText("patch_table.lua", table)}
          />
          <OutBtn
            label="generated_patch.lua"
            onClick={() => downloadText("generated_patch.lua", tmpl)}
          />
        </div>
      </div>

      <div className="overflow-x-auto rounded-xl border border-line">
        <table className="w-full min-w-[640px] text-left text-sm">
          <thead className="bg-raised font-mono text-[11px] tracking-wide text-muted uppercase">
            <tr>
              <th className="px-3 py-3">Offset</th>
              <th className="px-3 py-3">Log address</th>
              <th className="px-3 py-3">Kind</th>
              <th className="px-3 py-3">Class</th>
              <th className="px-3 py-3">Method</th>
            </tr>
          </thead>
          <tbody>
            {entries.map((e) => (
              <tr key={e.offset} className="border-t border-line font-mono text-xs">
                <td className="px-3 py-3 text-accent">{formatHex(e.offset)}</td>
                <td className="px-3 py-3">{formatHex(e.absolute)}</td>
                <td className="px-3 py-3 text-muted">{e.kind}</td>
                <td className="px-3 py-3">{e.className}</td>
                <td className="px-3 py-3">{e.methodName}</td>
              </tr>
            ))}
          </tbody>
        </table>
      </div>

      <pre className="max-h-80 overflow-auto rounded-xl border border-line bg-raised p-4 font-mono text-[11px] leading-relaxed text-muted">
        {kinzi}
      </pre>
    </section>
  );
}

function OutBtn({ label, onClick }: { label: string; onClick: () => void }) {
  return (
    <button
      type="button"
      onClick={onClick}
      className="min-h-10 rounded-md border border-line px-3 text-xs"
    >
      {label}
    </button>
  );
}
