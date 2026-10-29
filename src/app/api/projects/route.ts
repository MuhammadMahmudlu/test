import { fetchDynamicProjects } from "@/lib/projects";

export async function GET() {
  const projects = await fetchDynamicProjects();
  return Response.json(
    { projects, source: "mini-apps+github", count: projects.length },
    {
      headers: {
        "Cache-Control": "public, s-maxage=300, stale-while-revalidate=3600",
      },
    },
  );
}
