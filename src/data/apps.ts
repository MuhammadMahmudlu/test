export type MiniApp = {
  id: string;
  slug: string;
  title: string;
  description: string;
  longDescription: string;
  category: "Frontend" | "Full-Stack" | "Open Source";
  stack: string[];
  metrics: { label: string; value: string }[];
  featured?: boolean;
  icon: "timer" | "palette" | "braces" | "receipt";
};

/** Single source of truth for mini-apps shipped in this repo. */
export const miniApps: MiniApp[] = [
  {
    id: "pomodoro",
    slug: "pomodoro",
    title: "Focus Pomodoro",
    description: "Minimal focus timer with sessions, breaks, and progress ring.",
    longDescription:
      "A calm pomodoro timer for deep work — customizable focus/break lengths, session counter, and a smooth circular progress ring. Built as a self-contained Next.js mini-app.",
    category: "Frontend",
    stack: ["Next.js", "React", "TypeScript", "Framer Motion", "Tailwind"],
    metrics: [
      { label: "Modes", value: "3" },
      { label: "State", value: "Local" },
      { label: "A11y", value: "Keys" },
    ],
    featured: true,
    icon: "timer",
  },
  {
    id: "palette",
    slug: "palette",
    title: "Palette Lab",
    description: "Generate harmonious color palettes and copy CSS tokens instantly.",
    longDescription:
      "Pick a base hue and generate a cohesive palette with tints, shades, and ready-to-paste CSS variables. One-click copy for hex values and design tokens.",
    category: "Frontend",
    stack: ["Next.js", "React", "TypeScript", "Tailwind"],
    metrics: [
      { label: "Swatches", value: "7" },
      { label: "Export", value: "CSS" },
      { label: "Copy", value: "1-tap" },
    ],
    featured: true,
    icon: "palette",
  },
  {
    id: "json-lab",
    slug: "json-lab",
    title: "JSON Lab",
    description: "Format, validate, and minify JSON with instant feedback.",
    longDescription:
      "Paste messy JSON and get pretty-printed or minified output with clear validation errors. Built for everyday API debugging without leaving the browser.",
    category: "Frontend",
    stack: ["Next.js", "React", "TypeScript", "Tailwind"],
    metrics: [
      { label: "Validate", value: "Live" },
      { label: "Minify", value: "Yes" },
      { label: "Pretty", value: "2-space" },
    ],
    featured: true,
    icon: "braces",
  },
  {
    id: "tip-split",
    slug: "tip-split",
    title: "Tip Split",
    description: "Split a bill with tip percentage and per-person totals.",
    longDescription:
      "Enter the bill, tip %, and party size to see total tip, grand total, and each person's share — updated live as you type.",
    category: "Frontend",
    stack: ["Next.js", "React", "TypeScript", "Tailwind"],
    metrics: [
      { label: "Live", value: "Calc" },
      { label: "Tip", value: "%" },
      { label: "People", value: "N" },
    ],
    icon: "receipt",
  },
];

export const GITHUB_USER = "MuhammadMahmudlu";
export const GITHUB_REPO = "test";
/** Source branch until merged to main */
export const GITHUB_BRANCH = "cursor/elshan-cyberpunk-portfolio-f7b3";

export function appLivePath(slug: string) {
  return `/apps/${slug}`;
}

export function appGithubUrl(slug: string) {
  return `https://github.com/${GITHUB_USER}/${GITHUB_REPO}/tree/${GITHUB_BRANCH}/src/app/apps/${slug}`;
}

export function getMiniApp(slug: string) {
  return miniApps.find((a) => a.slug === slug);
}
