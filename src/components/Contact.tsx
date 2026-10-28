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
      /* clipboard may be unavailable */
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
        className="pointer-events-none absolute inset-x-0 bottom-0 h-64 bg-[radial-gradient(ellipse_at_bottom,rgba(0,240,255,0.12),transparent_70%)]"
      />
      <div className="relative z-10 mx-auto max-w-6xl px-4 sm:px-6 lg:px-8">
        <SectionHeading
          eyebrow="05 — Contact"
          title="Let's build something electric"
          description="Drop a message, copy my email, or ping me on the channels below."
        />

        <div className="grid gap-8 lg:grid-cols-[0.9fr_1.1fr]">
          <motion.div
            initial={{ opacity: 0, y: 16 }}
            whileInView={{ opacity: 1, y: 0 }}
            viewport={{ once: true }}
            className="space-y-4"
          >
            <button
              type="button"
              onClick={copyEmail}
              data-cursor="interactive"
              className="flex w-full items-center justify-between gap-3 rounded-xl border border-cyan/30 bg-cyan/10 px-4 py-4 text-left transition hover:bg-cyan/15 hover:shadow-[0_0_24px_rgba(0,240,255,0.2)]"
            >
              <span className="flex items-center gap-3">
                <Mail className="text-cyan" size={18} />
                <span>
                  <span className="block font-mono text-[10px] tracking-wider text-zinc-500 uppercase">
                    Email
                  </span>
                  <span className="font-mono text-sm text-white">
                    {profile.email}
                  </span>
                </span>
              </span>
              {copied ? (
                <Check className="text-emerald-400" size={18} />
              ) : (
                <Copy className="text-cyan" size={18} />
              )}
            </button>

            <a
              href={`tel:${profile.phone.replace(/\s/g, "")}`}
              className="flex items-center gap-3 rounded-xl border border-white/10 bg-white/[0.03] px-4 py-4 transition hover:border-neon-purple/40"
            >
              <Phone className="text-neon-purple" size={18} />
              <span>
                <span className="block font-mono text-[10px] tracking-wider text-zinc-500 uppercase">
                  Phone
                </span>
                <span className="font-mono text-sm text-white">
                  {profile.phone}
                </span>
              </span>
            </a>

            <div className="flex flex-wrap gap-3 pt-2">
              <a
                href={profile.socials.linkedin}
                target="_blank"
                rel="noopener noreferrer"
                className="inline-flex items-center gap-2 rounded-md border border-white/15 px-4 py-2.5 font-mono text-xs text-zinc-300 transition hover:border-cyan/40 hover:text-cyan"
              >
                <LinkedInIcon size={14} /> LinkedIn
              </a>
              <a
                href={profile.socials.github}
                target="_blank"
                rel="noopener noreferrer"
                className="inline-flex items-center gap-2 rounded-md border border-white/15 px-4 py-2.5 font-mono text-xs text-zinc-300 transition hover:border-neon-purple/40 hover:text-neon-purple"
              >
                <GitHubIcon size={14} /> GitHub
              </a>
              <a
                href={profile.socials.email}
                className="inline-flex items-center gap-2 rounded-md border border-white/15 px-4 py-2.5 font-mono text-xs text-zinc-300 transition hover:border-cyan/40 hover:text-cyan"
              >
                <Mail size={14} /> Mailto
              </a>
            </div>
          </motion.div>

          <motion.form
            onSubmit={onSubmit}
            initial={{ opacity: 0, y: 16 }}
            whileInView={{ opacity: 1, y: 0 }}
            viewport={{ once: true }}
            className="rounded-2xl border border-white/10 bg-white/[0.03] p-5 sm:p-6"
          >
            <div className="grid gap-4 sm:grid-cols-2">
              <label className="block">
                <span className="mb-1.5 block font-mono text-[10px] tracking-wider text-zinc-500 uppercase">
                  Name
                </span>
                <input
                  required
                  name="name"
                  value={form.name}
                  onChange={(e) =>
                    setForm((f) => ({ ...f, name: e.target.value }))
                  }
                  className="w-full rounded-lg border border-white/10 bg-void/60 px-3 py-2.5 text-sm text-white outline-none transition focus:border-cyan/50 focus:shadow-[0_0_0_3px_rgba(0,240,255,0.12)]"
                  placeholder="Your name"
                />
              </label>
              <label className="block">
                <span className="mb-1.5 block font-mono text-[10px] tracking-wider text-zinc-500 uppercase">
                  Email
                </span>
                <input
                  required
                  type="email"
                  name="email"
                  value={form.email}
                  onChange={(e) =>
                    setForm((f) => ({ ...f, email: e.target.value }))
                  }
                  className="w-full rounded-lg border border-white/10 bg-void/60 px-3 py-2.5 text-sm text-white outline-none transition focus:border-cyan/50 focus:shadow-[0_0_0_3px_rgba(0,240,255,0.12)]"
                  placeholder="you@domain.com"
                />
              </label>
            </div>
            <label className="mt-4 block">
              <span className="mb-1.5 block font-mono text-[10px] tracking-wider text-zinc-500 uppercase">
                Message
              </span>
              <textarea
                required
                name="message"
                rows={5}
                value={form.message}
                onChange={(e) =>
                  setForm((f) => ({ ...f, message: e.target.value }))
                }
                className="w-full resize-y rounded-lg border border-white/10 bg-void/60 px-3 py-2.5 text-sm text-white outline-none transition focus:border-cyan/50 focus:shadow-[0_0_0_3px_rgba(0,240,255,0.12)]"
                placeholder="Tell me about the mission..."
              />
            </label>
            <button
              type="submit"
              className="mt-5 inline-flex w-full items-center justify-center gap-2 rounded-md bg-gradient-to-r from-cyan to-[#5ce1ff] px-5 py-3 font-mono text-sm font-semibold text-void transition hover:shadow-[0_0_28px_rgba(0,240,255,0.4)] sm:w-auto"
            >
              <Send size={14} />
              {status === "sent" ? "Opening mail client…" : "Send message"}
            </button>
          </motion.form>
        </div>
      </div>
    </section>
  );
}
