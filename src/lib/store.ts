import { create } from "zustand";
import { persist } from "zustand/middleware";
import {
  type ConvertMode,
  type GateState,
  type ScanEntry,
  TARGET,
} from "@/lib/kinzi/engine";

export type TabId = "gate" | "wizard" | "convertor" | "results" | "pack";

type LabState = {
  tab: TabId;
  setTab: (t: TabId) => void;
  gameOpen: boolean;
  processVisible: boolean;
  ggAttached: boolean;
  packageName: string;
  version: string;
  setGate: (p: Partial<Pick<LabState, "gameOpen" | "processVisible" | "ggAttached" | "packageName" | "version">>) => void;
  gateState: GateState;
  setGateState: (s: GateState) => void;
  libBase: string;
  setLibBase: (v: string) => void;
  logText: string;
  setLogText: (v: string) => void;
  mode: ConvertMode;
  setMode: (m: ConvertMode) => void;
  entries: ScanEntry[];
  setEntries: (e: ScanEntry[]) => void;
  wizardStep: number;
  setWizardStep: (n: number) => void;
};

export const useLab = create<LabState>()(
  persist(
    (set) => ({
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
      setWizardStep: (wizardStep) => set({ wizardStep }),
    }),
    {
      name: "kinzi-kgo-lab",
      partialize: (s) => ({
        packageName: s.packageName,
        version: s.version,
        libBase: s.libBase,
        logText: s.logText,
        entries: s.entries,
        mode: s.mode,
      }),
    },
  ),
);
