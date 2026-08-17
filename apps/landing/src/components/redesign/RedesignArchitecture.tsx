import type { ReactElement } from "react";

const archRows = [
  { label: "Swift app",    value: "Capture UI, editor timeline, screenshot composition, Finder integration" },
  { label: "Rust service", value: "Project metadata, path handling, screenshot indexing, exports" },
  { label: "Local paths",  value: "~/Movies/Open Recorder, ~/Pictures/Open Recorder, and local project files" },
] as const;

const tags = ["Swift 6", "Rust", "ScreenCaptureKit", "AVFoundation", "Apache 2.0"] as const;

export function RedesignArchitecture(): ReactElement {
  return (
    <section className="rd-section" id="architecture">
      <div className="rd-inner rd-arch-inner">
        <div className="rd-arch-copy" data-reveal="left">
          <p className="rd-eyebrow">Local-first architecture</p>
          <h2 className="rd-h2">Swift where the Mac matters. Rust where durability matters.</h2>
          <p className="rd-body">
            A native Swift UI layer engineered for macOS privacy and ScreenCaptureKit,
            paired with a durable Rust core for metadata, indexing, and fast exports.
          </p>
          <div className="rd-tags">
            {tags.map((t) => (
              <span className="rd-tag" key={t}>{t}</span>
            ))}
          </div>
        </div>

        <div className="rd-arch-panel" data-reveal="right">
          {archRows.map((row, i) => (
            <div className="rd-arch-row" key={row.label} style={{ transitionDelay: `${i * 60}ms` }}>
              <span className="rd-arch-label">{row.label}</span>
              <span className="rd-arch-value">{row.value}</span>
            </div>
          ))}
        </div>
      </div>
    </section>
  );
}
