import { createFileRoute } from "@tanstack/react-router";
import { ConvertorPanel } from "@/components/lab/convertor-panel";
import { GatePanel } from "@/components/lab/gate-panel";
import { PackPanel } from "@/components/lab/pack-panel";
import { ResultsPanel } from "@/components/lab/results-panel";
import { Shell } from "@/components/lab/shell";
import { WizardPanel } from "@/components/lab/wizard-panel";
import { useLab } from "@/lib/store";

export const Route = createFileRoute("/")({ component: Home });

function Home() {
  const tab = useLab((s) => s.tab);
  return (
    <Shell>
      {tab === "gate" && <GatePanel />}
      {tab === "wizard" && <WizardPanel />}
      {tab === "convertor" && <ConvertorPanel />}
      {tab === "results" && <ResultsPanel />}
      {tab === "pack" && <PackPanel />}
    </Shell>
  );
}
