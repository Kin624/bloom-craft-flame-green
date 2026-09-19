import { WIZARD_STEPS } from "@/lib/kinzi/engine";
import { useLab } from "@/lib/store";
import { cn } from "@/lib/cn";

export function WizardPanel() {
  const step = useLab((s) => s.wizardStep);
  const setStep = useLab((s) => s.setWizardStep);
  const setTab = useLab((s) => s.setTab);
  const current = WIZARD_STEPS[step - 1] ?? WIZARD_STEPS[0];

  return (
    <section className="rounded-xl border border-line bg-surface p-5 sm:p-7">
      <p className="font-mono text-[11px] tracking-widest text-muted uppercase">
        From the recorded session
      </p>
      <h2 className="mt-2 text-lg font-medium">Five-step attach flow</h2>
      <p className="mt-1 max-w-2xl text-sm text-muted">
        Matches the video: logger cleaner → attach CPM2 in KGO → log script
        calls → Kinzi option 2 → read offset_results.kinzi.
      </p>

      <ol className="mt-6 flex gap-2">
        {WIZARD_STEPS.map((s) => (
          <li key={s.id} className="flex-1">
            <button
              type="button"
              onClick={() => setStep(s.id)}
              className={cn(
                "h-1.5 w-full rounded-full",
                s.id <= step ? "bg-accent" : "bg-line",
              )}
              aria-label={`Step ${s.id}`}
            />
          </li>
        ))}
      </ol>

      <div className="mt-8">
        <p className="font-mono text-xs text-accent">STEP {current.id} / 5</p>
        <h3 className="mt-2 text-2xl font-medium">{current.title}</h3>
        <p className="mt-3 max-w-xl text-sm leading-relaxed text-muted">{current.body}</p>
      </div>

      <div className="mt-8 flex flex-wrap gap-3">
        <button
          type="button"
          disabled={step <= 1}
          onClick={() => setStep(step - 1)}
          className="min-h-11 rounded-lg border border-line px-4 text-sm disabled:opacity-40"
        >
          Back
        </button>
        {step < 5 ? (
          <button
            type="button"
            onClick={() => setStep(step + 1)}
            className="min-h-11 rounded-lg bg-accent px-5 text-sm font-medium text-accent-fg"
          >
            Next
          </button>
        ) : (
          <button
            type="button"
            onClick={() => setTab("convertor")}
            className="min-h-11 rounded-lg bg-accent px-5 text-sm font-medium text-accent-fg"
          >
            Open convertor
          </button>
        )}
      </div>
    </section>
  );
}
