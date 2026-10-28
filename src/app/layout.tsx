import type { Metadata } from "next";
import { JetBrains_Mono, Orbitron, Space_Grotesk } from "next/font/google";
import "./globals.css";

const display = Orbitron({
  variable: "--font-display",
  subsets: ["latin"],
  weight: ["500", "600", "700", "800"],
});

const body = Space_Grotesk({
  variable: "--font-body",
  subsets: ["latin"],
  weight: ["400", "500", "600", "700"],
});

const mono = JetBrains_Mono({
  variable: "--font-mono",
  subsets: ["latin"],
  weight: ["400", "500", "600"],
});

export const metadata: Metadata = {
  title: "Muhammad Elshan — Full-Stack Developer",
  description:
    "Cyberpunk portfolio of Muhammad Elshan, Full-Stack Developer. Interactive projects, skills, and contact.",
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
      <body className="cursor-glow min-h-full bg-void text-foreground">
        {children}
      </body>
    </html>
  );
}
