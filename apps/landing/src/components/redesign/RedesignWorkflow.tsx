import type { ReactElement } from "react";

const steps = [
  { step: "01", title: "Choose the source", copy: "Pick a display, window, or hand-drawn region with a capture flow built natively for macOS." },
  { step: "02", title: "Record or screenshot", copy: "Save clips to Movies and screenshots to Pictures with project metadata created automatically." },
  { step: "03", title: "Edit the timeline", copy: "Refine clips with trims, speed changes, zoom effects, cursor overlays, and independently controlled camera segments." },
  { step: "04", title: "Export or compose", copy: "Export MOV, MP4, GIF, or PNG assets with crop and aspect controls, styled backgrounds, and screenshot composition." },
] as const;

export function RedesignWorkflow(): ReactElement {
  return (
    <section className="rd-section rd-workflow" id="workflow">
      <div className="rd-inner rd-workflow-inner">
        <div className="rd-workflow-copy" data-reveal="left">
          <p className="rd-eyebrow">Built for repeated work</p>
          <h2 className="rd-h2">Every capture moves through one calm, local flow.</h2>
          <p className="rd-body">
            No accounts, no uploads, no cloud processing. Everything lives in
            your Movies and Pictures folders, organised by project.
          </p>
        </div>

        <ol className="rd-steps">
          {steps.map((s, i) => (
            <li
              className="rd-step"
              key={s.step}
              data-reveal="right"
              data-delay={i * 90}
            >
              <span className="rd-step-num rd-mono">{s.step}</span>
              <div className="rd-step-content">
                <h3 className="rd-step-title">{s.title}</h3>
                <p className="rd-step-copy">{s.copy}</p>
              </div>
            </li>
          ))}
        </ol>
      </div>
    </section>
  );
}
