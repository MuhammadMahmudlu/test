"use client";

import { FormEvent, useState } from "react";
import { motion } from "framer-motion";
import { Check, Copy, Mail, Phone, Send } from "lucide-react";
import { profile } from "@/data/portfolio";
import { GitHubIcon, LinkedInIcon } from "./icons";
import SectionHeading from "./SectionHeading";

export default function Contact() {
  const [copied, setCopied] = useState(false);
  const [status, setStatus] = useState<"idle" | "sent">("idle");
  const [form, setForm] = useState({ name: "", email: "", message: "" });

  const copyEmail = async () => {
    try {
      await navigator.clipboard.writeText(profile.email);
      setCopied(true);
      window.setTimeout(() => setCopied(false), 1800);
    } catch {
      /* ignore */
    }
  };

  const onSubmit = (e: FormEvent) => {
    e.preventDefault();
    const subject = encodeURIComponent(`Portfolio inquiry from ${form.name}`);
    const body = encodeURIComponent(
      `${form.message}\n\n— ${form.name} (${form.email})`,
    );
    window.location.href = `mailto:${profile.email}?subject=${subject}&body=${body}`;
    setStatus("sent");
  };

  return (
    <section id="contact" className="relative scroll-mt-20 py-24 sm:py-28">
      <div
        aria-hidden
        className="pointer-events-none absolute inset-x-0 bottom-0 h-72 bg-[radial-gradient(ellipse_at_bottom,rgba(220,38,38,0.16),transparent_70%)]"
      />
      <div className="relative z-10 mx-auto max-w-6xl px-4 sm:px-6 lg:px-8">
        <SectionHeading
          eyebrow="04 — Contact"
          title="Let's build"
          description="Direct channels and a lean form — copy email or send a message."
        />

        <div className="grid gap-8 lg:grid-cols-[0.9fr_1.1fr]">
          <motion.div
            initial={{ opacity: 0, y: 16 }}
            whileInView={{ opacity: 1, y: 0 }}
            viewport={{ once: true }}
            className="space-y-3"
          >
            <button
              type="button"
              onClick={copyEmail}
              data-cursor="interactive"
              className="flex w-full items-center justify-between gap-3 border border-crimson/40 bg-crimson/10 px-4 py-4 text-left transition hover:bg-crimson/20"
            >
              <span className="flex items-center gap-3">
                <Mail className="text-crimson" size={18} />
                <span>
                  <span className="block font-mono text-[10px] tracking-wider text-ink-muted uppercase">
                    Email
                  </span>
                  <span className="text-sm font-semibold text-ink">
                    {profile.email}
                  </span>
                </span>
              </span>
              {copied ? (
                <Check className="text-emerald-400" size={18} />
              ) : (
                <Copy className="text-crimson" size={18} />
              )}
            </button>

            <a
              href={`tel:${profile.phone.replace(/\s/g, "")}`}
              className="flex items-center gap-3 border border-line bg-charcoal px-4 py-4 transition hover:border-crimson/50"
            >
              <Phone className="text-crimson" size={18} />
              <span>
                <span className="block font-mono text-[10px] tracking-wider text-ink-muted uppercase">
                  Phone
                </span>
                <span className="text-sm font-semibold text-ink">
                  {profile.phone}
                </span>
              </span>
            </a>

            <div className="flex flex-wrap gap-2 pt-2">
              <a
                href={profile.socials.linkedin}
                target="_blank"
                rel="noopener noreferrer"
                className="inline-flex items-center gap-2 border border-line px-4 py-2.5 text-xs font-bold tracking-wide text-ink uppercase hover:border-crimson hover:text-crimson"
              >
                <LinkedInIcon size={14} /> LinkedIn
              </a>
              <a
                href={profile.socials.github}
                target="_blank"
                rel="noopener noreferrer"
                className="inline-flex items-center gap-2 border border-line px-4 py-2.5 text-xs font-bold tracking-wide text-ink uppercase hover:border-crimson hover:text-crimson"
              >
                <GitHubIcon size={14} /> GitHub
              </a>
            </div>
          </motion.div>

          <motion.form
            onSubmit={onSubmit}
            initial={{ opacity: 0, y: 16 }}
            whileInView={{ opacity: 1, y: 0 }}
            viewport={{ once: true }}
            className="border border-line bg-charcoal p-5 sm:p-6"
          >
            <div className="grid gap-4 sm:grid-cols-2">
              <label className="block">
                <span className="mb-1.5 block font-mono text-[10px] tracking-wider text-ink-muted uppercase">
                  Name
                </span>
                <input
                  required
                  value={form.name}
                  onChange={(e) =>
                    setForm((f) => ({ ...f, name: e.target.value }))
                  }
                  className="w-full border border-line bg-void px-3 py-2.5 text-sm text-ink outline-none focus:border-crimson"
                  placeholder="Your name"
                />
              </label>
              <label className="block">
                <span className="mb-1.5 block font-mono text-[10px] tracking-wider text-ink-muted uppercase">
                  Email
                </span>
                <input
                  required
                  type="email"
                  value={form.email}
                  onChange={(e) =>
                    setForm((f) => ({ ...f, email: e.target.value }))
                  }
                  className="w-full border border-line bg-void px-3 py-2.5 text-sm text-ink outline-none focus:border-crimson"
                  placeholder="you@domain.com"
                />
              </label>
            </div>
            <label className="mt-4 block">
              <span className="mb-1.5 block font-mono text-[10px] tracking-wider text-ink-muted uppercase">
                Message
              </span>
              <textarea
                required
                rows={5}
                value={form.message}
                onChange={(e) =>
                  setForm((f) => ({ ...f, message: e.target.value }))
                }
                className="w-full resize-y border border-line bg-void px-3 py-2.5 text-sm text-ink outline-none focus:border-crimson"
                placeholder="Tell me about the mission..."
              />
            </label>
            <button
              type="submit"
              className="mt-5 inline-flex items-center gap-2 bg-crimson px-5 py-3 text-sm font-bold tracking-wide text-white uppercase hover:bg-crimson-bright"
            >
              <Send size={14} />
              {status === "sent" ? "Opening mail…" : "Send message"}
            </button>
          </motion.form>
        </div>
      </div>
    </section>
  );
}
