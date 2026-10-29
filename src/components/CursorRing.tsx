"use client";

import { motion, useMotionValue, useSpring } from "framer-motion";
import { useEffect, useState } from "react";

export default function CursorRing() {
  const x = useMotionValue(-100);
  const y = useMotionValue(-100);
  const sx = useSpring(x, { stiffness: 420, damping: 32, mass: 0.4 });
  const sy = useSpring(y, { stiffness: 420, damping: 32, mass: 0.4 });
  const [hovering, setHovering] = useState(false);
  const [visible, setVisible] = useState(false);

  useEffect(() => {
    const fine = window.matchMedia("(pointer: fine)").matches;
    if (!fine) return;

    setVisible(true);

    const onMove = (e: PointerEvent) => {
      x.set(e.clientX);
      y.set(e.clientY);
    };

    const onOver = (e: PointerEvent) => {
      const t = e.target as HTMLElement | null;
      const interactive = t?.closest(
        "a, button, input, textarea, [data-cursor='interactive']",
      );
      setHovering(Boolean(interactive));
    };

    window.addEventListener("pointermove", onMove, { passive: true });
    window.addEventListener("pointerover", onOver, { passive: true });
    return () => {
      window.removeEventListener("pointermove", onMove);
      window.removeEventListener("pointerover", onOver);
    };
  }, [x, y]);

  if (!visible) return null;

  return (
    <motion.div
      aria-hidden
      className="pointer-events-none fixed left-0 top-0 z-[100]"
      style={{
        x: sx,
        y: sy,
        translateX: "-50%",
        translateY: "-50%",
      }}
    >
      <motion.div
        animate={{
          width: hovering ? 48 : 26,
          height: hovering ? 48 : 26,
          borderColor: hovering
            ? "rgba(99,102,241,0.9)"
            : "rgba(15,23,42,0.35)",
          backgroundColor: hovering
            ? "rgba(99,102,241,0.08)"
            : "rgba(255,255,255,0.15)",
        }}
        className="rounded-full border shadow-[0_0_0_1px_rgba(255,255,255,0.4)] backdrop-blur-[1px]"
        transition={{ type: "spring", stiffness: 380, damping: 28 }}
      />
    </motion.div>
  );
}
