export const profile = {
  name: "Muhammad Elshan",
  title: "Full-Stack Developer",
  tagline:
    "Crafting polished digital products — from refined interfaces to resilient APIs.",
  email: "muhammad.elshan@devmail.com",
  phone: "+994 50 123 45 67",
  location: "Baku, Azerbaijan",
  socials: {
    github: "https://github.com/MuhammadMahmudlu",
    linkedin: "https://linkedin.com",
    email: "mailto:muhammad.elshan@devmail.com",
  },
  about: [
    "I build end-to-end products where interface polish meets solid systems thinking. From interactive frontends to scalable backend services, I care about performance, accessibility, and a refined first impression.",
    "My toolkit spans modern React/Next.js, Node ecosystems, cloud-native deploys, and motion-driven UX — always with an eye for craft.",
  ],
};

export const skills = [
  { name: "TypeScript", level: 92, category: "Language" },
  { name: "React / Next.js", level: 95, category: "Frontend" },
  { name: "Node.js", level: 88, category: "Backend" },
  { name: "PostgreSQL", level: 84, category: "Data" },
  { name: "GraphQL", level: 78, category: "API" },
  { name: "Tailwind CSS", level: 93, category: "Frontend" },
  { name: "Framer Motion", level: 86, category: "Frontend" },
  { name: "Docker", level: 80, category: "DevOps" },
  { name: "AWS", level: 75, category: "DevOps" },
  { name: "Three.js", level: 72, category: "Frontend" },
  { name: "Python", level: 70, category: "Language" },
  { name: "Redis", level: 76, category: "Data" },
];

export const skillGraph = [
  { id: "ts", label: "TS", x: 50, y: 42 },
  { id: "react", label: "React", x: 28, y: 28 },
  { id: "next", label: "Next", x: 72, y: 26 },
  { id: "node", label: "Node", x: 22, y: 58 },
  { id: "pg", label: "PG", x: 48, y: 72 },
  { id: "tw", label: "TW", x: 78, y: 55 },
  { id: "fm", label: "Motion", x: 65, y: 70 },
  { id: "aws", label: "AWS", x: 35, y: 78 },
  { id: "gql", label: "GQL", x: 18, y: 40 },
  { id: "docker", label: "Docker", x: 82, y: 40 },
];

export const skillEdges: [string, string][] = [
  ["ts", "react"],
  ["react", "next"],
  ["ts", "node"],
  ["node", "pg"],
  ["next", "tw"],
  ["react", "fm"],
  ["node", "aws"],
  ["node", "gql"],
  ["aws", "docker"],
  ["next", "docker"],
  ["pg", "aws"],
];

export type ProjectCategory = "All" | "Full-Stack" | "Frontend" | "Backend" | "Open Source";

export type Project = {
  id: string;
  title: string;
  description: string;
  longDescription: string;
  category: Exclude<ProjectCategory, "All">;
  stack: string[];
  metrics: { label: string; value: string }[];
  liveUrl: string;
  githubUrl: string;
  featured?: boolean;
};

export const projects: Project[] = [
  {
    id: "neon-commerce",
    title: "NeonCommerce",
    description: "Realtime commerce dashboard with adaptive inventory sync.",
    longDescription:
      "A full-stack commerce control plane with live inventory websockets, role-based ops, and a neon-themed analytics surface built for high-frequency retail teams.",
    category: "Full-Stack",
    stack: ["Next.js", "Node", "PostgreSQL", "Redis", "WebSockets"],
    metrics: [
      { label: "Latency", value: "<120ms" },
      { label: "Uptime", value: "99.9%" },
      { label: "SKU sync", value: "Realtime" },
    ],
    liveUrl: "https://example.com",
    githubUrl: "https://github.com",
    featured: true,
  },
  {
    id: "signal-mesh",
    title: "SignalMesh",
    description: "Collaborative whiteboard with CRDT conflict resolution.",
    longDescription:
      "Multiplayer canvas workspace powered by CRDTs, presence cursors, and offline-first sync — designed for distributed product teams sketching under pressure.",
    category: "Frontend",
    stack: ["React", "TypeScript", "Yjs", "Canvas API", "WebRTC"],
    metrics: [
      { label: "Peers", value: "50+" },
      { label: "Sync", value: "CRDT" },
      { label: "FPS", value: "60" },
    ],
    liveUrl: "https://example.com",
    githubUrl: "https://github.com",
    featured: true,
  },
  {
    id: "pulse-api",
    title: "PulseAPI Gateway",
    description: "Edge-aware API gateway with adaptive rate limiting.",
    longDescription:
      "A Node/TypeScript gateway featuring token-bucket limiting, circuit breakers, and OpenTelemetry traces — deployable at the edge for multi-region APIs.",
    category: "Backend",
    stack: ["Node.js", "Fastify", "Redis", "OpenTelemetry", "Docker"],
    metrics: [
      { label: "RPS", value: "25k+" },
      { label: "p99", value: "18ms" },
      { label: "Regions", value: "4" },
    ],
    liveUrl: "https://example.com",
    githubUrl: "https://github.com",
  },
  {
    id: "aurora-kit",
    title: "Aurora UI Kit",
    description: "Open-source motion primitives for neon interfaces.",
    longDescription:
      "A collection of accessible Framer Motion primitives — glow buttons, tilt cards, terminal reveals — packaged for teams shipping cyber-styled product UIs.",
    category: "Open Source",
    stack: ["React", "Framer Motion", "Tailwind", "Storybook"],
    metrics: [
      { label: "Stars", value: "1.2k" },
      { label: "Components", value: "40+" },
      { label: "A11y", value: "WCAG AA" },
    ],
    liveUrl: "https://example.com",
    githubUrl: "https://github.com",
  },
  {
    id: "orbit-ops",
    title: "OrbitOps",
    description: "DevOps status board with predictive incident cues.",
    longDescription:
      "Unified observability board aggregating deploy health, SLO burn rates, and AI-assisted incident digests for on-call engineers.",
    category: "Full-Stack",
    stack: ["Next.js", "Python", "Grafana", "AWS", "GraphQL"],
    metrics: [
      { label: "MTTR", value: "-34%" },
      { label: "Sources", value: "12" },
      { label: "Alerts", value: "Smart" },
    ],
    liveUrl: "https://example.com",
    githubUrl: "https://github.com",
  },
  {
    id: "cipher-vault",
    title: "CipherVault",
    description: "Encrypted secrets vault with zero-knowledge sharing.",
    longDescription:
      "Client-side encrypted vault for team secrets with audit trails, temporary share links, and hardware-key support.",
    category: "Backend",
    stack: ["Node.js", "WebCrypto", "PostgreSQL", "React"],
    metrics: [
      { label: "Encryption", value: "AES-GCM" },
      { label: "ZK share", value: "Yes" },
      { label: "Audit", value: "Full" },
    ],
    liveUrl: "https://example.com",
    githubUrl: "https://github.com",
  },
];

export const experience = [
  {
    id: "1",
    role: "Senior Full-Stack Engineer",
    company: "Nova Systems",
    period: "2023 — Present",
    location: "Remote",
    highlights: [
      "Led Next.js platform rewrite cutting TTI by 42% with streaming SSR.",
      "Designed realtime collaboration layer used by 8k daily active users.",
      "Mentored a pod of 4 engineers on motion-first accessible UI patterns.",
    ],
  },
  {
    id: "2",
    role: "Full-Stack Developer",
    company: "PulseForge Labs",
    period: "2021 — 2023",
    location: "Baku / Hybrid",
    highlights: [
      "Shipped multi-tenant SaaS billing + API gateway serving 3 regions.",
      "Built design-system tokens and neon-themed component library.",
      "Automated CI/CD with Docker + GitHub Actions, zero-downtime deploys.",
    ],
  },
  {
    id: "3",
    role: "Frontend Developer",
    company: "Orbit Digital",
    period: "2019 — 2021",
    location: "Baku",
    highlights: [
      "Delivered interactive marketing sites with canvas and WebGL accents.",
      "Partnered with design to ship micro-interaction systems at scale.",
      "Improved Lighthouse performance scores from mid-60s to 90+.",
    ],
  },
];

export const navLinks = [
  { href: "#about", label: "About" },
  { href: "#projects", label: "Projects" },
  { href: "/apps", label: "Apps" },
  { href: "#skills", label: "Skills" },
  { href: "#experience", label: "Experience" },
  { href: "#contact", label: "Contact" },
];
