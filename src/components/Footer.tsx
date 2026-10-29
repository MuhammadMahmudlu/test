import { profile } from "@/data/portfolio";

export default function Footer() {
  return (
    <footer className="border-t border-line py-8">
      <div className="mx-auto flex max-w-6xl flex-col items-center justify-between gap-3 px-4 text-center sm:flex-row sm:px-6 sm:text-left lg:px-8">
        <p className="text-xs text-ink-muted">
          © 2026 {profile.name}. Crafted with Next.js & care.
        </p>
        <a
          href="#top"
          className="text-xs font-semibold tracking-wide text-accent uppercase hover:underline"
        >
          Back to top ↑
        </a>
      </div>
    </footer>
  );
}
