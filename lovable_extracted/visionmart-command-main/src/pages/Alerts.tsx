import { Filter, ShieldAlert } from "lucide-react";
import { cn } from "@/lib/utils";
import { AlertCard, AlertItem } from "@/components/dashboard/AlertCard";
import { StatCard } from "@/components/dashboard/StatCard";

const alerts: AlertItem[] = [
  { id: "1", title: "Loitering detected near electronics aisle", zone: "Zone B-3", time: "12s ago", severity: "critical", camera: "CAM-04" },
  { id: "2", title: "Unattended bag flagged", zone: "Entrance · West", time: "1m ago", severity: "high", camera: "CAM-11" },
  { id: "3", title: "Density threshold exceeded", zone: "Checkout Lane 2", time: "4m ago", severity: "medium", camera: "CAM-22" },
  { id: "4", title: "Repeat visitor identified · 7th today", zone: "Cosmetics", time: "9m ago", severity: "medium", camera: "CAM-09" },
  { id: "5", title: "Concealment gesture detected", zone: "Aisle G-2", time: "14m ago", severity: "high", camera: "CAM-22" },
  { id: "6", title: "Restricted zone entry", zone: "Stockroom", time: "22m ago", severity: "critical", camera: "CAM-31" },
  { id: "7", title: "Crowd spike at entrance", zone: "Main Entry", time: "31m ago", severity: "medium", camera: "CAM-01" },
];

const filters = ["All", "Critical", "High", "Medium"];

const Alerts = () => {
  const counts = {
    total: alerts.length,
    critical: alerts.filter(a => a.severity === "critical").length,
    high: alerts.filter(a => a.severity === "high").length,
  };

  return (
    <div className="space-y-6">
      <div className="lg:hidden">
        <p className="text-[11px] uppercase tracking-[0.2em] text-muted-foreground">VisionMart</p>
        <h1 className="font-display text-2xl font-semibold mt-1">Alerts</h1>
      </div>

      <section className="grid grid-cols-3 gap-3">
        <StatCard label="Total" value={counts.total.toString().padStart(2, "0")} icon={ShieldAlert} gradient="indigo" />
        <StatCard label="Critical" value={counts.critical.toString().padStart(2, "0")} icon={ShieldAlert} gradient="warning" glow />
        <StatCard label="High" value={counts.high.toString().padStart(2, "0")} icon={ShieldAlert} gradient="electric" />
      </section>

      <div className="glass rounded-2xl p-3 flex items-center gap-2 overflow-x-auto">
        <button className="flex items-center gap-1.5 text-xs px-3 py-1.5 rounded-xl bg-secondary text-foreground shrink-0">
          <Filter className="h-3.5 w-3.5" /> Filter
        </button>
        {filters.map((f, i) => (
          <button
            key={f}
            className={cn(
              "text-xs px-3 py-1.5 rounded-xl whitespace-nowrap transition shrink-0",
              i === 0 ? "bg-gradient-indigo text-primary-foreground" : "bg-secondary/40 text-muted-foreground hover:text-foreground"
            )}
          >
            {f}
          </button>
        ))}
      </div>

      <div className="grid gap-3">
        {alerts.map(a => <AlertCard key={a.id} alert={a} />)}
      </div>
    </div>
  );
};

export default Alerts;
