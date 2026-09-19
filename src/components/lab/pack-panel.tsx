export function PackPanel() {
  return (
    <section className="grid gap-5 lg:grid-cols-2">
      <article className="rounded-xl border border-line bg-surface p-6">
        <p className="font-mono text-[11px] tracking-widest text-muted uppercase">
          For KGO Multi Space
        </p>
        <h2 className="mt-2 text-xl font-medium">KINZI_KGO_APP.lua</h2>
        <p className="mt-3 text-sm leading-relaxed text-muted">
          This is the application you put on KGO. Copy it into the virtual
          space (Download/Telegram), open GameGuardian while CPM2 1.3.3.6 is
          running, then Execute script.
        </p>
        <ol className="mt-5 list-decimal space-y-2 pl-5 text-sm text-muted">
          <li>Install KGO Multi Space and clone / open the space.</li>
          <li>Install GameGuardian inside that space (your GG apk).</li>
          <li>Install Car Parking Multiplayer 2 1.3.3.6 in the same space.</li>
          <li>Copy KINZI_KGO_APP.lua into the space storage.</li>
          <li>Start the game → attach GG → execute the lua.</li>
        </ol>
        <a
          href="/KINZI_KGO_APP.lua"
          download
          className="mt-6 inline-flex min-h-11 items-center rounded-lg bg-accent px-5 text-sm font-medium text-accent-fg"
        >
          Download KGO app
        </a>
      </article>

      <article className="rounded-xl border border-line bg-raised p-6">
        <h3 className="text-lg font-medium">Full convertor (class names)</h3>
        <p className="mt-2 text-sm leading-relaxed text-muted">
          The KGO app gates the process and converts addresses to offsets. For
          CLASS/METHOD resolution (Il2Cpp FindMethods), also drop Kinzi
          Automatic Convertor v2 into the same folder and run it after attach.
        </p>
        <a
          href="/Kinzi_Automatic_Convertor_v2.lua"
          download
          className="mt-6 inline-flex min-h-11 items-center rounded-lg border border-line px-5 text-sm"
        >
          Download Kinzi Convertor v2
        </a>
        <p className="mt-6 text-xs leading-relaxed text-subtle">
          Live Il2Cpp lookup only works while the game is attached in GG. This
          lab handles the offline half: logs, offset math, templates, and the
          KGO pack.
        </p>
      </article>
    </section>
  );
}
