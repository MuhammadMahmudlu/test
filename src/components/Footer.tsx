import { profile } from "@/data/portfolio";

export default function Footer() {
  return (
    <footer className="border-t border-white/8 py-8">
      <div className="mx-auto flex max-w-6xl flex-col items-center justify-between gap-3 px-4 text-center sm:flex-row sm:text-left sm:px-6 lg:px-8">
        <p className="font-mono text-xs text-zinc-500">
          © 2026 {profile.name}. Crafted with Next.js & neon.
        </p>
        <a
          href="#top"
          className="font-mono text-xs tracking-wider text-cyan uppercase hover:underline"
        >
          Back to top ↑
        </a>
      </div>
    </footer>
  );
}
