"use client";

import { useEffect, useRef } from "react";
import { usePrefersReducedMotion } from "@/hooks/usePrefersReducedMotion";

/**
 * Lightweight Three.js neon torus knot — lazily loaded for hero visual impact.
 */
export default function NeonScene() {
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
      const camera = new THREE.PerspectiveCamera(42, width / height, 0.1, 100);
      camera.position.z = 5.2;

      const renderer = new THREE.WebGLRenderer({
        antialias: true,
        alpha: true,
        powerPreference: "high-performance",
      });
      renderer.setPixelRatio(Math.min(window.devicePixelRatio, 2));
      renderer.setSize(width, height);
      renderer.setClearColor(0x000000, 0);
      mount.appendChild(renderer.domElement);

      const geometry = new THREE.TorusKnotGeometry(1.1, 0.32, 180, 24);
      const material = new THREE.MeshStandardMaterial({
        color: 0x0a0a12,
        emissive: 0x00f0ff,
        emissiveIntensity: 0.55,
        metalness: 0.85,
        roughness: 0.25,
        wireframe: false,
      });
      const mesh = new THREE.Mesh(geometry, material);
      scene.add(mesh);

      const wireGeo = new THREE.TorusKnotGeometry(1.35, 0.08, 100, 8);
      const wireMat = new THREE.MeshBasicMaterial({
        color: 0x8a2be2,
        wireframe: true,
        transparent: true,
        opacity: 0.35,
      });
      const wire = new THREE.Mesh(wireGeo, wireMat);
      scene.add(wire);

      const ambient = new THREE.AmbientLight(0x4060ff, 0.45);
      const point = new THREE.PointLight(0x00f0ff, 2.2, 20);
      point.position.set(3, 2, 4);
      const point2 = new THREE.PointLight(0x8a2be2, 1.6, 18);
      point2.position.set(-3, -1, 3);
      scene.add(ambient, point, point2);

      let mx = 0;
      let my = 0;
      const onMove = (e: PointerEvent) => {
        const rect = mount.getBoundingClientRect();
        mx = ((e.clientX - rect.left) / rect.width - 0.5) * 0.6;
        my = ((e.clientY - rect.top) / rect.height - 0.5) * 0.6;
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
        mesh.rotation.x += 0.004 + my * 0.01;
        mesh.rotation.y += 0.006 + mx * 0.01;
        wire.rotation.x -= 0.003;
        wire.rotation.y += 0.005;
        point.position.x = 3 + Math.sin(performance.now() * 0.001) * 0.8;
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
        wireGeo.dispose();
        wireMat.dispose();
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
      {reduced && (
        <div className="absolute inset-0 rounded-full bg-[radial-gradient(circle_at_center,rgba(0,240,255,0.25),transparent_65%)]" />
      )}
    </div>
  );
}
