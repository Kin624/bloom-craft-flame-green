import { Cpu, Download, GitBranch, Radar, ScrollText } from "lucide-react";
import { useLab, type TabId } from "@/lib/store";
import { TARGET } from "@/lib/kinzi/engine";
import { cn } from "@/lib/cn";

const NAV: { id: TabId; label: string; icon: typeof Radar }[] = [
  { id: "gate", label: "Process", icon: Radar },
  { id: "wizard", label: "Wizard", icon: GitBranch },
  { id: "convertor", label: "Convertor", icon: Cpu },
  { id: "results", label: "Results", icon: ScrollText },
  { id: "pack", label: "KGO pack", icon: Download },
];

export function Shell({ children }: { children: React.ReactNode }) {
  const tab = useLab((s) => s.tab);
  const setTab = useLab((s) => s.setTab);
  const gateState = useLab((s) => s.gateState);

  return (
    <div className="min-h-dvh bg-bg text-fg">
      <div className="mx-auto flex min-h-dvh max-w-5xl flex-col px-4 pb-24 pt-6 sm:px-6 lg:px-8">
        <header className="mb-8 flex items-end justify-between gap-4">
          <div>
            <p className="font-mono text-xs tracking-[0.22em] text-muted uppercase">
              KGO · GameGuardian space
            </p>
            <h1 className="mt-1 font-sans text-3xl font-semibold tracking-tight sm:text-4xl">
              KINZI KGO
            </h1>
            <p className="mt-2 max-w-xl text-sm leading-relaxed text-muted">
              Offset lab for {TARGET.name} {TARGET.version}. Gate the process,
              walk the video steps, convert logs, then drop the lua into KGO.
            </p>
          </div>
          <StatusChip state={gateState} />
        </header>

        <div className="mb-6 hidden gap-2 sm:flex">
          {NAV.map((n) => (
            <NavBtn key={n.id} {...n} active={tab === n.id} onClick={() => setTab(n.id)} />
          ))}
        </div>

        <main className="flex-1">{children}</main>
      </div>

      <nav className="fixed inset-x-0 bottom-0 z-20 border-t border-line bg-bg/95 backdrop-blur-sm sm:hidden">
        <div className="grid grid-cols-5">
          {NAV.map((n) => (
            <button
              key={n.id}
              type="button"
              onClick={() => setTab(n.id)}
              className={cn(
                "flex min-h-14 flex-col items-center justify-center gap-1 text-[10px] tracking-wide",
                tab === n.id ? "text-accent" : "text-muted",
              )}
            >
              <n.icon className="size-4" strokeWidth={1.6} />
              {n.label}
            </button>
          ))}
        </div>
      </nav>
    </div>
  );
}

function NavBtn({
  label,
  icon: Icon,
  active,
  onClick,
}: {
  label: string;
  icon: typeof Radar;
  active: boolean;
  onClick: () => void;
}) {
  return (
    <button
      type="button"
      onClick={onClick}
      className={cn(
        "inline-flex min-h-11 items-center gap-2 rounded-lg px-3.5 text-sm transition-colors duration-150",
        active ? "bg-accent text-accent-fg" : "bg-raised text-muted hover:text-fg",
      )}
    >
      <Icon className="size-4" strokeWidth={1.6} />
      {label}
    </button>
  );
}

function StatusChip({ state }: { state: string }) {
  const map: Record<string, { label: string; cls: string }> = {
    idle: { label: "Not attached", cls: "text-muted border-line" },
    ready: { label: "Process ready", cls: "text-ok border-ok/30" },
    not_running: { label: "Game closed", cls: "text-warn border-warn/30" },
    wrong_game: { label: "Wrong version", cls: "text-danger border-danger/30" },
    no_process: { label: "No process", cls: "text-danger border-danger/30" },
    missing_info: { label: "Missing info", cls: "text-warn border-warn/30" },
  };
  const m = map[state] ?? map.idle;
  return (
    <span
      className={cn(
        "hidden shrink-0 rounded-full border px-3 py-1 font-mono text-[11px] uppercase tracking-wider sm:inline-flex",
        m.cls,
      )}
    >
      {m.label}
    </span>
  );
}
