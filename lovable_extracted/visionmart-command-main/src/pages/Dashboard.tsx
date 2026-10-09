import { Users, ShieldAlert, Camera, TrendingUp, Crosshair } from "lucide-react";
import { StatCard } from "@/components/dashboard/StatCard";
import { BentoAction } from "@/components/dashboard/BentoAction";
import { AlertCard, AlertItem } from "@/components/dashboard/AlertCard";
import cctvHero from "@/assets/cctv-store-1.jpg";

const alerts: AlertItem[] = [
  { id: "1", title: "Loitering detected near electronics aisle", zone: "Zone B-3", time: "12s ago", severity: "critical", camera: "CAM-04" },
  { id: "2", title: "Unattended bag flagged", zone: "Entrance · West", time: "1m ago", severity: "high", camera: "CAM-11" },
  { id: "3", title: "Density threshold exceeded", zone: "Checkout Lane 2", time: "4m ago", severity: "medium", camera: "CAM-22" },
  { id: "4", title: "Repeat visitor identified · 7th today", zone: "Cosmetics", time: "9m ago", severity: "medium", camera: "CAM-09" },
];

const Dashboard = () => {
  return (
    <div className="space-y-6">
      {/* Mobile title */}
      <div className="lg:hidden">
        <p className="text-[11px] uppercase tracking-[0.2em] text-muted-foreground">VisionMart · Live</p>
        <h1 className="font-display text-2xl font-semibold mt-1">Command</h1>
      </div>

      {/* Top stats */}
      <section className="grid grid-cols-2 lg:grid-cols-4 gap-4">
        <StatCard
          label="Live People Count"
          value="247"
          delta="+12.4%"
          trend="up"
          icon={Users}
          gradient="indigo"
          subtle="Across 18 zones"
          glow
        />
        <StatCard
          label="Priority Alerts"
          value="08"
          delta="+3 new"
          trend="warn"
          icon={ShieldAlert}
          gradient="warning"
          subtle="2 critical · 6 high"
          glow
        />
        <StatCard
          label="Active Cameras"
          value="34/36"
          delta="2 offline"
          trend="down"
          icon={Camera}
          gradient="electric"
          subtle="System nominal"
        />
        <StatCard
          label="Footfall Today"
          value="3,182"
          delta="+8.1%"
          trend="up"
          icon={TrendingUp}
          gradient="success"
          subtle="Peak: 14:00–15:00"
        />
      </section>

      {/* Bento + live feed */}
      <section className="grid grid-cols-12 gap-4">
        {/* Bento quick actions */}
        <div className="col-span-12 lg:col-span-7">
          <SectionHeader title="Quick Actions" caption="Tap a module to enter" />
          <div className="grid grid-cols-2 md:grid-cols-3 gap-4 auto-rows-[180px]">
            <BentoAction
              large
              title="Suspicious Activity"
              desc="AI-flagged behaviour patterns across all live cameras."
              icon={ShieldAlert}
              gradient="warning"
              count={12}
              className="col-span-2 md:col-span-1"
            />
            <BentoAction
              title="ROI Management"
              desc="Define detection zones."
              icon={Crosshair}
              gradient="indigo"
            />
            <BentoAction
              title="Weapon Alerts"
              desc="Real-time threat scan."
              icon={Crosshair}
              gradient="violet"
              count={0}
            />
          </div>
        </div>

        {/* Live camera */}
        <div className="col-span-12 lg:col-span-5">
          <SectionHeader title="Primary Feed" caption="CAM-01 · Main Entrance" />
          <div className="glass rounded-3xl p-3 relative overflow-hidden">
            <div className="relative rounded-2xl overflow-hidden aspect-[16/10] scanline">
              <img
                src={cctvHero}
                alt="Live CCTV feed of retail store entrance"
                className="absolute inset-0 h-full w-full object-cover"
                width={1280}
                height={768}
              />
              <div className="absolute inset-0 bg-gradient-to-t from-background/80 via-transparent to-background/40" />
              {/* HUD overlays */}
              <div className="absolute top-3 left-3 flex items-center gap-2 px-2.5 py-1 rounded-lg bg-destructive/20 backdrop-blur border border-destructive/40">
                <span className="h-2 w-2 rounded-full bg-destructive animate-blip" />
                <span className="text-[10px] font-mono uppercase tracking-wider text-destructive">REC · LIVE</span>
              </div>
              <div className="absolute top-3 right-3 px-2.5 py-1 rounded-lg bg-background/40 backdrop-blur text-[10px] font-mono">
                {new Date().toLocaleTimeString()}
              </div>
              {/* Detection box */}
              <div className="absolute left-[42%] top-[55%] h-20 w-16 border-2 border-accent rounded-md shadow-[0_0_20px_hsl(198_100%_60%/0.5)]">
                <span className="absolute -top-5 left-0 text-[9px] font-mono bg-accent text-accent-foreground px-1.5 py-0.5 rounded">
                  PERSON · 0.97
                </span>
              </div>
              <div className="absolute bottom-3 left-3 right-3 flex items-center justify-between">
                <p className="text-xs font-mono text-foreground/90">CAM-01 · Entrance · 1080p</p>
                <p className="text-xs font-mono text-foreground/90">FPS 30</p>
              </div>
            </div>
            <div className="mt-3 grid grid-cols-3 gap-2">
              {["CAM-04", "CAM-11", "CAM-22"].map((c) => (
                <button
                  key={c}
                  className="rounded-xl bg-secondary/60 hover:bg-secondary aspect-video grid place-items-center text-[10px] font-mono text-muted-foreground transition"
                >
                  {c}
                </button>
              ))}
            </div>
          </div>
        </div>
      </section>

      {/* Recent alerts */}
      <section>
        <SectionHeader title="Recent Alerts" caption="Last 30 minutes" action="View all" />
        <div className="grid gap-3">
          {alerts.map((a) => (
            <AlertCard key={a.id} alert={a} />
          ))}
        </div>
      </section>
    </div>
  );
};

const SectionHeader = ({ title, caption, action }: { title: string; caption?: string; action?: string }) => (
  <div className="flex items-end justify-between mb-3">
    <div>
      <h2 className="font-display text-xl font-semibold">{title}</h2>
      {caption && <p className="text-xs text-muted-foreground mt-0.5">{caption}</p>}
    </div>
    {action && (
      <button className="text-xs text-primary-glow hover:underline font-medium">{action}</button>
    )}
  </div>
);

export default Dashboard;
