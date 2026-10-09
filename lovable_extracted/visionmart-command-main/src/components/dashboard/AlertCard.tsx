import { cn } from "@/lib/utils";
import { AlertTriangle, ChevronRight, MapPin, Clock } from "lucide-react";

export type Severity = "critical" | "high" | "medium";

export interface AlertItem {
  id: string;
  title: string;
  zone: string;
  time: string;
  severity: Severity;
  camera: string;
}

const sevStyles: Record<Severity, { dot: string; chip: string; ring: string }> = {
  critical: {
    dot: "bg-destructive",
    chip: "bg-destructive/15 text-destructive border border-destructive/30",
    ring: "before:bg-gradient-warning",
  },
  high: {
    dot: "bg-warning",
    chip: "bg-warning/15 text-warning border border-warning/30",
    ring: "before:bg-gradient-warning",
  },
  medium: {
    dot: "bg-accent",
    chip: "bg-accent/15 text-accent border border-accent/30",
    ring: "before:bg-gradient-electric",
  },
};

export const AlertCard = ({ alert }: { alert: AlertItem }) => {
  const s = sevStyles[alert.severity];
  return (
    <div
      className={cn(
        "glass glass-hover rounded-2xl p-4 relative overflow-hidden",
        "before:content-[''] before:absolute before:left-0 before:top-3 before:bottom-3 before:w-1 before:rounded-r-full",
        s.ring
      )}
    >
      <div className="flex items-start gap-4">
        <div className="relative shrink-0">
          <div className={cn("h-10 w-10 rounded-xl grid place-items-center bg-secondary/80")}>
            <AlertTriangle className={cn("h-4 w-4", alert.severity === "critical" ? "text-destructive" : alert.severity === "high" ? "text-warning" : "text-accent")} />
          </div>
          {alert.severity === "critical" && (
            <span className="absolute -top-0.5 -right-0.5 h-2.5 w-2.5 rounded-full bg-destructive animate-pulse-warn" />
          )}
        </div>

        <div className="flex-1 min-w-0">
          <div className="flex items-center gap-2 flex-wrap">
            <p className="text-sm font-semibold truncate">{alert.title}</p>
            <span className={cn("text-[10px] uppercase tracking-wider px-2 py-0.5 rounded-md font-mono", s.chip)}>
              {alert.severity}
            </span>
          </div>
          <div className="mt-1.5 flex items-center gap-3 text-xs text-muted-foreground">
            <span className="flex items-center gap-1"><MapPin className="h-3 w-3" />{alert.zone}</span>
            <span className="flex items-center gap-1"><Clock className="h-3 w-3" />{alert.time}</span>
            <span className="font-mono hidden sm:inline">{alert.camera}</span>
          </div>
        </div>

        <button className="shrink-0 self-center inline-flex items-center gap-1 text-xs font-medium px-3 py-1.5 rounded-xl bg-secondary hover:bg-secondary/70 active:scale-95 transition">
          Details <ChevronRight className="h-3.5 w-3.5" />
        </button>
      </div>
    </div>
  );
};
