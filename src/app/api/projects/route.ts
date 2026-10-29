import { connection } from "next/server";
import { fetchDynamicProjects } from "@/lib/projects";

export async function GET() {
  // Always resolve at request time so GitHub repos stay fresh
  await connection();
  const projects = await fetchDynamicProjects();
  return Response.json(
    {
      projects,
      source: "mini-apps+github",
      count: projects.length,
    },
    {
      headers: {
        "Cache-Control": "public, s-maxage=60, stale-while-revalidate=600",
      },
    },
  );
}
