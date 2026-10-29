export const profile = {
  name: "Muhammad Elshan",
  title: "Full-Stack Developer & Software Architect",
  tagline:
    "Architecting bold digital systems — from editorial interfaces to resilient platforms.",
  email: "muhammad.elshan@devmail.com",
  phone: "+994 50 123 45 67",
  location: "Baku, Azerbaijan",
  socials: {
    github: "https://github.com/MuhammadMahmudlu",
    linkedin: "https://linkedin.com",
    email: "mailto:muhammad.elshan@devmail.com",
  },
  stats: [
    { label: "Years Experience", value: "06+" },
    { label: "Projects Shipped", value: "40+" },
    { label: "Stack Mastery", value: "FS" },
    { label: "Uptime Focus", value: "99%" },
  ],
  about: [
    "I design and ship end-to-end products where interface sharpness meets systems thinking — performance, accessibility, and architectural clarity first.",
    "From Next.js platforms to Node services and cloud-native delivery, I care about craft you can feel under the cursor.",
  ],
};

export const education = [
  {
    school: "Azerbaijan Technical University",
    degree: "B.Sc. Computer Engineering",
    period: "2016 — 2020",
    detail: "Software systems, algorithms, and distributed computing foundations.",
  },
  {
    school: "Self-Directed Architecture Lab",
    degree: "Cloud & Platform Engineering",
    period: "2020 — Present",
    detail: "Continuous study of edge patterns, observability, and product architecture.",
  },
];

export const skillGroups = [
  {
    title: "Frontend",
    items: ["Next.js", "React", "TypeScript", "Framer Motion", "Tailwind CSS"],
  },
  {
    title: "Backend",
    items: ["Node.js", "Python", "GraphQL", "REST", "WebSockets"],
  },
  {
    title: "Data",
    items: ["PostgreSQL", "Redis", "Prisma", "MongoDB"],
  },
  {
    title: "DevOps",
    items: ["Docker", "AWS", "CI/CD", "Observability"],
  },
];

export const processSteps = [
  {
    id: "01",
    title: "Discovery",
    text: "Clarify goals, constraints, users, and success metrics before a single line of production code.",
  },
  {
    id: "02",
    title: "Architecture",
    text: "Map domains, data flow, and deployment topology — choose boring reliability where it matters.",
  },
  {
    id: "03",
    title: "Development",
    text: "Ship vertical slices fast: accessible UI, typed APIs, and tests that protect the happy path.",
  },
  {
    id: "04",
    title: "Testing",
    text: "Unit, integration, and performance gates. Catch regressions before users do.",
  },
  {
    id: "05",
    title: "Deployment",
    text: "Zero-drama releases with observability, rollbacks, and post-ship learning loops.",
  },
];

export const skills = [
  { name: "TypeScript", level: 92, category: "Language" },
  { name: "React / Next.js", level: 95, category: "Frontend" },
  { name: "Node.js", level: 88, category: "Backend" },
  { name: "PostgreSQL", level: 84, category: "Data" },
  { name: "Python", level: 78, category: "Language" },
  { name: "Docker", level: 80, category: "DevOps" },
  { name: "AWS", level: 75, category: "DevOps" },
  { name: "GraphQL", level: 78, category: "API" },
];

export type ProjectCategory =
  | "All"
  | "Full-Stack"
  | "Frontend"
  | "Backend"
  | "Open Source";

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

/** Legacy static fallback — live site prefers /api/projects */
export const projects: Project[] = [];

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
      "Automated CI/CD with Docker + GitHub Actions.",
    ],
  },
];

export const navLinks = [
  { href: "#projects", label: "Projects" },
  { href: "/apps", label: "Apps" },
  { href: "#skills", label: "Skills" },
  { href: "#process", label: "Process" },
  { href: "#contact", label: "Contact" },
];
