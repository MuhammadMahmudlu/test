import { profile } from "@/data/portfolio";

export default function Footer() {
  return (
    <footer className="border-t border-line py-8">
      <div className="mx-auto flex max-w-6xl flex-col items-center justify-between gap-3 px-4 text-center sm:flex-row sm:px-6 sm:text-left lg:px-8">
        <p className="font-mono text-xs text-ink-muted">
          © 2026 {profile.name}. Editorial systems & code.
        </p>
        <a
          href="#top"
          className="font-mono text-xs tracking-[0.18em] text-crimson uppercase hover:underline"
        >
          Back to top ↑
        </a>
      </div>
    </footer>
  );
}
