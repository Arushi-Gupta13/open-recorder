"use client";
import { useEffect } from "react";

/**
 * Mounts once and observes all [data-reveal] elements.
 * Adds data-visible="true" when they enter the viewport.
 * CSS transitions/animations are driven entirely by that attribute.
 */
export function MotionObserver(): null {
  useEffect(() => {
    const items = document.querySelectorAll<HTMLElement>("[data-reveal]");
    if (!items.length) return;

    const io = new IntersectionObserver(
      (entries) => {
        entries.forEach((entry) => {
          if (entry.isIntersecting) {
            const el = entry.target as HTMLElement;
            const delay = el.dataset.delay ?? "0";
            setTimeout(() => {
              el.setAttribute("data-visible", "true");
            }, Number(delay));
            io.unobserve(el);
          }
        });
      },
      { threshold: 0.12, rootMargin: "0px 0px -40px 0px" }
    );

    items.forEach((el) => io.observe(el));
    return () => io.disconnect();
  }, []);

  return null;
}
