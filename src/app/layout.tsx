import type { Metadata } from "next";
import { IBM_Plex_Mono, Plus_Jakarta_Sans, Sora } from "next/font/google";
import "./globals.css";

const display = Sora({
  variable: "--font-display",
  subsets: ["latin"],
  weight: ["500", "600", "700", "800"],
});

const body = Plus_Jakarta_Sans({
  variable: "--font-body",
  subsets: ["latin"],
  weight: ["400", "500", "600", "700"],
});

const mono = IBM_Plex_Mono({
  variable: "--font-mono",
  subsets: ["latin"],
  weight: ["400", "500"],
});

export const metadata: Metadata = {
  title: "Muhammad Elshan — Full-Stack Developer",
  description:
    "Modern portfolio of Muhammad Elshan, Full-Stack Developer. Projects, skills, experience, and contact.",
  keywords: [
    "Muhammad Elshan",
    "Full-Stack Developer",
    "Next.js",
    "Portfolio",
    "React",
  ],
};

export default function RootLayout({ children }: LayoutProps<"/">) {
  return (
    <html
      lang="en"
      className={`${display.variable} ${body.variable} ${mono.variable} h-full antialiased`}
    >
      <body className="cursor-glow min-h-full bg-surface text-ink">
        {children}
      </body>
    </html>
  );
}
