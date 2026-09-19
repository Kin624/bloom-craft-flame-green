import { evaluateGate, TARGET } from "@/lib/kinzi/engine";
import { useLab } from "@/lib/store";
import { cn } from "@/lib/cn";

export function GatePanel() {
  const s = useLab();

  function runCheck() {
    const r = evaluateGate({
      gameOpen: s.gameOpen,
      packageName: s.packageName,
      version: s.version,
      ggAttached: s.ggAttached,
      processVisible: s.processVisible,
    });
    s.setGateState(r.state);
    if (r.state === "ready") s.setTab("wizard");
  }

  const result = evaluateGate({
    gameOpen: s.gameOpen,
    packageName: s.packageName,
    version: s.version,
    ggAttached: s.ggAttached,
    processVisible: s.processVisible,
  });

  return (
    <section className="grid gap-6 lg:grid-cols-[1.1fr_0.9fr]">
      <div className="rounded-xl border border-line bg-surface p-5 sm:p-6">
        <h2 className="text-lg font-medium">Process gate</h2>
        <p className="mt-1 text-sm leading-relaxed text-muted">
          Same rules as the KGO lua. This browser cannot see your phone — set
          the live state, then run the check. On device, the lua does this
          automatically via GameGuardian.
        </p>

        <dl className="mt-5 grid gap-3 font-mono text-xs">
          <Row k="Package" v={TARGET.package} />
          <Row k="Version" v={TARGET.version} />
          <Row k="Library" v={TARGET.lib} />
        </dl>

        <div className="mt-6 space-y-3">
          <Toggle
            label="Game is running"
            on={s.gameOpen}
            onChange={(v) => s.setGate({ gameOpen: v })}
          />
          <Toggle
            label="Car Parking [x64] visible in GG process list"
            on={s.processVisible}
            onChange={(v) => s.setGate({ processVisible: v })}
          />
          <Toggle
            label="GameGuardian attached"
            on={s.ggAttached}
            onChange={(v) => s.setGate({ ggAttached: v })}
          />
        </div>

        <label className="mt-5 block text-xs text-muted">
          Detected package
          <input
            value={s.packageName}
            onChange={(e) => s.setGate({ packageName: e.target.value })}
            className="mt-1.5 min-h-11 w-full rounded-md border border-line bg-raised px-3 font-mono text-sm text-fg outline-none focus:border-accent"
          />
        </label>
        <label className="mt-3 block text-xs text-muted">
          Detected version
          <input
            value={s.version}
            onChange={(e) => s.setGate({ version: e.target.value })}
            className="mt-1.5 min-h-11 w-full rounded-md border border-line bg-raised px-3 font-mono text-sm text-fg outline-none focus:border-accent"
          />
        </label>

        <button
          type="button"
          onClick={runCheck}
          className="mt-6 min-h-11 w-full rounded-lg bg-accent px-4 text-sm font-medium text-accent-fg"
        >
          Run process check
        </button>
      </div>

      <aside className="rounded-xl border border-line bg-raised p-5 sm:p-6">
        <p className="font-mono text-[11px] tracking-widest text-muted uppercase">
          Gate result
        </p>
        <h3 className="mt-3 text-xl font-medium">{result.title}</h3>
        <p className="mt-2 text-sm leading-relaxed text-muted">{result.detail}</p>
        <ul className="mt-6 space-y-2 text-sm text-muted">
          <li className={cn(s.gameOpen ? "text-ok" : "")}>
            {s.gameOpen ? "Game open" : "If the game is not running → open it"}
          </li>
          <li className={cn(result.state !== "wrong_game" ? "" : "text-danger")}>
            If the wrong game/version is running → required 1.3.3.6
          </li>
          <li>If the process cannot be detected → attach GG</li>
          <li>If required info is missing → stop and explain</li>
        </ul>
      </aside>
    </section>
  );
}

function Row({ k, v }: { k: string; v: string }) {
  return (
    <div className="flex items-baseline justify-between gap-3 border-b border-line/70 py-2">
      <dt className="text-subtle">{k}</dt>
      <dd className="truncate text-fg">{v}</dd>
    </div>
  );
}

function Toggle({
  label,
  on,
  onChange,
}: {
  label: string;
  on: boolean;
  onChange: (v: boolean) => void;
}) {
  return (
    <button
      type="button"
      onClick={() => onChange(!on)}
      className="flex min-h-11 w-full items-center justify-between gap-3 rounded-md border border-line bg-raised px-3 text-left text-sm"
    >
      <span>{label}</span>
      <span
        className={cn(
          "h-5 w-9 rounded-full p-0.5 transition-colors",
          on ? "bg-accent" : "bg-line",
        )}
      >
        <span
          className={cn(
            "block size-4 rounded-full bg-bg transition-transform",
            on ? "translate-x-4" : "translate-x-0",
          )}
        />
      </span>
    </button>
  );
}
