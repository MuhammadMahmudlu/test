"use client";

import dynamic from "next/dynamic";

const ParticleBackground = dynamic(() => import("./ParticleBackground"), {
  ssr: false,
});

const CursorRing = dynamic(() => import("./CursorRing"), {
  ssr: false,
});

export default function ClientEffects() {
  return (
    <>
      <ParticleBackground />
      <CursorRing />
    </>
  );
}
