import ClientEffects from "@/components/ClientEffects";
import Contact from "@/components/Contact";
import EducationSkills from "@/components/EducationSkills";
import Footer from "@/components/Footer";
import Hero from "@/components/Hero";
import Navbar from "@/components/Navbar";
import Process from "@/components/Process";
import Projects from "@/components/Projects";

export default function Home() {
  return (
    <>
      <ClientEffects />
      <div aria-hidden className="noise-overlay" />
      <Navbar />
      <main className="relative z-10">
        <Hero />
        <Projects />
        <EducationSkills />
        <Process />
        <Contact />
      </main>
      <div className="relative z-10">
        <Footer />
      </div>
    </>
  );
}
