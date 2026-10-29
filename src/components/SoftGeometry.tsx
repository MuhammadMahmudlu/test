"use client";

import { useEffect, useRef } from "react";
import { usePrefersReducedMotion } from "@/hooks/usePrefersReducedMotion";

/** Soft indigo torus knot for the light hero — lazily loaded Three.js. */
export default function SoftGeometry() {
  const mountRef = useRef<HTMLDivElement>(null);
  const reduced = usePrefersReducedMotion();

  useEffect(() => {
    const mount = mountRef.current;
    if (!mount || reduced) return;

    let disposed = false;
    let raf = 0;
    let cleanup: (() => void) | undefined;

    (async () => {
      const THREE = await import("three");
      if (disposed || !mount) return;

      const width = mount.clientWidth || 420;
      const height = mount.clientHeight || 420;

      const scene = new THREE.Scene();
      const camera = new THREE.PerspectiveCamera(40, width / height, 0.1, 100);
      camera.position.z = 5.4;

      const renderer = new THREE.WebGLRenderer({
        antialias: true,
        alpha: true,
        powerPreference: "high-performance",
      });
      renderer.setPixelRatio(Math.min(window.devicePixelRatio, 2));
      renderer.setSize(width, height);
      renderer.setClearColor(0x000000, 0);
      mount.appendChild(renderer.domElement);

      const geometry = new THREE.TorusKnotGeometry(1.05, 0.34, 160, 28);
      const material = new THREE.MeshPhysicalMaterial({
        color: 0xffffff,
        metalness: 0.15,
        roughness: 0.22,
        clearcoat: 0.85,
        clearcoatRoughness: 0.2,
        transmission: 0.08,
        thickness: 0.6,
        emissive: 0x6366f1,
        emissiveIntensity: 0.12,
      });
      const mesh = new THREE.Mesh(geometry, material);
      scene.add(mesh);

      const ringGeo = new THREE.TorusGeometry(1.65, 0.02, 16, 100);
      const ringMat = new THREE.MeshBasicMaterial({
        color: 0xa5b4fc,
        transparent: true,
        opacity: 0.55,
      });
      const ring = new THREE.Mesh(ringGeo, ringMat);
      ring.rotation.x = Math.PI / 2.4;
      scene.add(ring);

      const ambient = new THREE.AmbientLight(0xffffff, 0.85);
      const key = new THREE.DirectionalLight(0xffffff, 1.1);
      key.position.set(3, 4, 5);
      const fill = new THREE.PointLight(0x6366f1, 1.4, 18);
      fill.position.set(-3, -1, 3);
      const rim = new THREE.PointLight(0xc7d2fe, 1.1, 16);
      rim.position.set(2, -2, -2);
      scene.add(ambient, key, fill, rim);

      let mx = 0;
      let my = 0;
      const onMove = (e: PointerEvent) => {
        const rect = mount.getBoundingClientRect();
        mx = ((e.clientX - rect.left) / rect.width - 0.5) * 0.45;
        my = ((e.clientY - rect.top) / rect.height - 0.5) * 0.45;
      };
      mount.addEventListener("pointermove", onMove);

      const onResize = () => {
        const w = mount.clientWidth;
        const h = mount.clientHeight;
        camera.aspect = w / h;
        camera.updateProjectionMatrix();
        renderer.setSize(w, h);
      };
      window.addEventListener("resize", onResize);

      const tick = () => {
        mesh.rotation.x += 0.0035 + my * 0.008;
        mesh.rotation.y += 0.005 + mx * 0.008;
        ring.rotation.z += 0.002;
        fill.position.x = -3 + Math.sin(performance.now() * 0.0008) * 0.6;
        renderer.render(scene, camera);
        raf = requestAnimationFrame(tick);
      };
      tick();

      cleanup = () => {
        cancelAnimationFrame(raf);
        mount.removeEventListener("pointermove", onMove);
        window.removeEventListener("resize", onResize);
        geometry.dispose();
        material.dispose();
        ringGeo.dispose();
        ringMat.dispose();
        renderer.dispose();
        if (renderer.domElement.parentNode === mount) {
          mount.removeChild(renderer.domElement);
        }
      };
    })();

    return () => {
      disposed = true;
      cleanup?.();
    };
  }, [reduced]);

  return (
    <div
      ref={mountRef}
      aria-hidden
      className="relative h-[280px] w-full max-w-[420px] sm:h-[360px] lg:h-[420px]"
    >
      <div className="absolute inset-10 rounded-full bg-[radial-gradient(circle_at_center,rgba(99,102,241,0.18),transparent_68%)] blur-2xl" />
      {reduced && (
        <div className="absolute inset-12 rounded-full bg-gradient-to-br from-accent/25 via-white to-accent-soft" />
      )}
    </div>
  );
}
