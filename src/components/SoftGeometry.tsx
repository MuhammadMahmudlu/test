"use client";

import { useEffect, useRef } from "react";
import { usePrefersReducedMotion } from "@/hooks/usePrefersReducedMotion";

/**
 * Kinetic monogram sculpture for the hero:
 * stylized "ME" mark + orbital indigo nodes that lean toward the cursor.
 */
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
      const camera = new THREE.PerspectiveCamera(38, width / height, 0.1, 100);
      camera.position.set(0, 0.15, 6.2);

      const renderer = new THREE.WebGLRenderer({
        antialias: true,
        alpha: true,
        powerPreference: "high-performance",
      });
      renderer.setPixelRatio(Math.min(window.devicePixelRatio, 2));
      renderer.setSize(width, height);
      renderer.setClearColor(0x000000, 0);
      mount.appendChild(renderer.domElement);

      const disposables: { dispose: () => void }[] = [];
      const track = <T extends { dispose: () => void }>(obj: T) => {
        disposables.push(obj);
        return obj;
      };

      const porcelain = track(
        new THREE.MeshPhysicalMaterial({
          color: 0xf8fafc,
          metalness: 0.08,
          roughness: 0.28,
          clearcoat: 1,
          clearcoatRoughness: 0.18,
          emissive: 0x6366f1,
          emissiveIntensity: 0.04,
        }),
      );

      const indigoGlass = track(
        new THREE.MeshPhysicalMaterial({
          color: 0x6366f1,
          metalness: 0.2,
          roughness: 0.18,
          clearcoat: 0.9,
          clearcoatRoughness: 0.15,
          transparent: true,
          opacity: 0.92,
          emissive: 0x4f46e5,
          emissiveIntensity: 0.25,
        }),
      );

      const softAccent = track(
        new THREE.MeshStandardMaterial({
          color: 0xa5b4fc,
          metalness: 0.35,
          roughness: 0.35,
          emissive: 0x6366f1,
          emissiveIntensity: 0.35,
        }),
      );

      const root = new THREE.Group();
      scene.add(root);

      const monogram = new THREE.Group();
      monogram.position.set(-0.15, 0, 0);
      root.add(monogram);

      const bar = (
        w: number,
        h: number,
        d: number,
        x: number,
        y: number,
        z: number,
        mat = porcelain,
        rotZ = 0,
      ) => {
        const geo = track(new THREE.BoxGeometry(w, h, d));
        const mesh = new THREE.Mesh(geo, mat);
        mesh.position.set(x, y, z);
        mesh.rotation.z = rotZ;
        monogram.add(mesh);
        return mesh;
      };

      // Stylized "M"
      bar(0.22, 1.7, 0.22, -1.55, 0, 0);
      bar(0.22, 1.7, 0.22, -0.55, 0, 0);
      bar(0.2, 1.05, 0.2, -1.2, 0.18, 0.05, indigoGlass, 0.55);
      bar(0.2, 1.05, 0.2, -0.9, 0.18, 0.05, indigoGlass, -0.55);

      // Stylized "E"
      bar(0.22, 1.7, 0.22, 0.15, 0, 0);
      bar(0.85, 0.2, 0.2, 0.68, 0.75, 0);
      bar(0.7, 0.18, 0.2, 0.6, 0, 0, indigoGlass);
      bar(0.85, 0.2, 0.2, 0.68, -0.75, 0);

      // Floating accent prism above monogram
      const prismGeo = track(new THREE.OctahedronGeometry(0.28, 0));
      const prism = new THREE.Mesh(prismGeo, indigoGlass);
      prism.position.set(1.35, 1.15, 0.4);
      root.add(prism);

      // Nested orbital rings
      const rings: InstanceType<typeof THREE.Mesh>[] = [];
      const ringSpecs = [
        { r: 2.05, tube: 0.018, rx: Math.PI / 2.1, ry: 0.2, speed: 0.004 },
        { r: 2.35, tube: 0.014, rx: Math.PI / 2.6, ry: -0.45, speed: -0.003 },
        { r: 2.7, tube: 0.012, rx: Math.PI / 3.2, ry: 0.7, speed: 0.0025 },
      ];
      for (const spec of ringSpecs) {
        const geo = track(new THREE.TorusGeometry(spec.r, spec.tube, 16, 128));
        const mat = track(
          new THREE.MeshBasicMaterial({
            color: 0x818cf8,
            transparent: true,
            opacity: 0.45,
          }),
        );
        const ring = new THREE.Mesh(geo, mat);
        ring.rotation.x = spec.rx;
        ring.rotation.y = spec.ry;
        root.add(ring);
        rings.push(ring);
      }

      // Orbiting satellite nodes
      type Satellite = {
        mesh: InstanceType<typeof THREE.Mesh>;
        radius: number;
        speed: number;
        phase: number;
        tilt: number;
        bob: number;
      };
      const satellites: Satellite[] = [];
      const nodeGeo = track(new THREE.SphereGeometry(0.09, 24, 24));
      const cubeGeo = track(new THREE.BoxGeometry(0.14, 0.14, 0.14));

      for (let i = 0; i < 8; i++) {
        const useCube = i % 3 === 0;
        const mesh = new THREE.Mesh(
          useCube ? cubeGeo : nodeGeo,
          i % 2 === 0 ? softAccent : indigoGlass,
        );
        root.add(mesh);
        satellites.push({
          mesh,
          radius: 1.85 + (i % 3) * 0.35,
          speed: 0.35 + i * 0.08,
          phase: (i / 8) * Math.PI * 2,
          tilt: 0.25 + (i % 4) * 0.12,
          bob: 0.15 + (i % 3) * 0.05,
        });
      }

      // Soft ground glow disc
      const glowGeo = track(new THREE.CircleGeometry(2.2, 48));
      const glowMat = track(
        new THREE.MeshBasicMaterial({
          color: 0x6366f1,
          transparent: true,
          opacity: 0.07,
        }),
      );
      const glow = new THREE.Mesh(glowGeo, glowMat);
      glow.rotation.x = -Math.PI / 2;
      glow.position.y = -1.35;
      root.add(glow);

      const ambient = new THREE.AmbientLight(0xffffff, 0.9);
      const key = new THREE.DirectionalLight(0xffffff, 1.15);
      key.position.set(4, 5, 6);
      const fill = new THREE.PointLight(0x6366f1, 1.6, 20);
      fill.position.set(-3, 1, 3);
      const rim = new THREE.PointLight(0xc7d2fe, 1.2, 18);
      rim.position.set(2, -2, 4);
      scene.add(ambient, key, fill, rim);

      let targetMX = 0;
      let targetMY = 0;
      let curMX = 0;
      let curMY = 0;

      const onMove = (e: PointerEvent) => {
        const rect = mount.getBoundingClientRect();
        targetMX = ((e.clientX - rect.left) / rect.width - 0.5) * 2;
        targetMY = ((e.clientY - rect.top) / rect.height - 0.5) * 2;
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

      const clock = new THREE.Clock();

      const tick = () => {
        const t = clock.getElapsedTime();
        curMX += (targetMX - curMX) * 0.06;
        curMY += (targetMY - curMY) * 0.06;

        root.rotation.y = curMX * 0.45 + t * 0.08;
        root.rotation.x = -curMY * 0.28 + Math.sin(t * 0.6) * 0.04;
        root.position.y = Math.sin(t * 0.9) * 0.08;

        monogram.rotation.y = Math.sin(t * 0.5) * 0.06;
        prism.rotation.x = t * 0.7;
        prism.rotation.y = t * 0.9;
        prism.position.y = 1.15 + Math.sin(t * 1.4) * 0.12;
        prism.position.x = 1.35 + curMX * 0.15;

        rings.forEach((ring, i) => {
          ring.rotation.z += ringSpecs[i].speed;
          ring.rotation.x = ringSpecs[i].rx + curMY * 0.15;
        });

        satellites.forEach((s) => {
          const a = t * s.speed + s.phase;
          s.mesh.position.x = Math.cos(a) * s.radius;
          s.mesh.position.z = Math.sin(a) * s.radius * 0.75;
          s.mesh.position.y =
            Math.sin(a * 1.3) * s.bob + Math.cos(t + s.phase) * s.tilt * 0.4;
          // Magnetic lean toward cursor
          s.mesh.position.x += curMX * 0.25;
          s.mesh.position.y -= curMY * 0.2;
          s.mesh.rotation.x = t * 0.8 + s.phase;
          s.mesh.rotation.y = t * 0.6;
        });

        fill.intensity = 1.35 + Math.sin(t * 2) * 0.25;
        glowMat.opacity = 0.05 + Math.abs(Math.sin(t)) * 0.04;

        renderer.render(scene, camera);
        raf = requestAnimationFrame(tick);
      };
      tick();

      cleanup = () => {
        cancelAnimationFrame(raf);
        mount.removeEventListener("pointermove", onMove);
        window.removeEventListener("resize", onResize);
        disposables.forEach((d) => d.dispose());
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
      {/* Soft aurora wash behind the kinetic monogram */}
      <div className="pointer-events-none absolute inset-6 -z-0 overflow-hidden rounded-[40%]">
        <div className="aurora-spin absolute -top-8 left-1/4 h-40 w-40 rounded-full bg-[conic-gradient(from_90deg,rgba(99,102,241,0.22),transparent_55%,rgba(167,139,250,0.18),transparent_80%)] blur-2xl" />
        <div className="aurora-spin-rev absolute right-4 bottom-4 h-32 w-32 rounded-full bg-[radial-gradient(circle,rgba(99,102,241,0.2),transparent_70%)] blur-xl" />
      </div>
      {reduced && (
        <div className="absolute inset-0 flex items-center justify-center">
          <div className="font-display text-7xl font-bold tracking-tight text-ink/10 sm:text-8xl">
            <span className="text-accent/30">M</span>E
          </div>
        </div>
      )}
    </div>
  );
}
