import { cn } from "@/lib/utils";
import { LucideIcon } from "lucide-react";

interface StatCardProps {
  label: string;
  value: string | number;
  delta?: string;
  trend?: "up" | "down" | "warn";
  icon: LucideIcon;
  gradient: "indigo" | "electric" | "warning" | "success" | "violet";
  subtle?: string;
  glow?: boolean;
}

const gradients: Record<StatCardProps["gradient"], string> = {
  indigo: "bg-gradient-indigo",
  electric: "bg-gradient-electric",
  warning: "bg-gradient-warning",
  success: "bg-gradient-success",
  violet: "bg-gradient-violet",
};

const glows: Record<StatCardProps["gradient"], string> = {
  indigo: "shadow-[0_20px_60px_-20px_hsl(244_92%_55%/0.55)]",
  electric: "shadow-[0_20px_60px_-20px_hsl(198_100%_55%/0.5)]",
  warning: "shadow-[0_20px_60px_-20px_hsl(358_85%_55%/0.55)]",
  success: "shadow-[0_20px_60px_-20px_hsl(152_76%_45%/0.5)]",
  violet: "shadow-[0_20px_60px_-20px_hsl(280_85%_60%/0.5)]",
};

export const StatCard = ({
  label, value, delta, trend = "up", icon: Icon, gradient, subtle, glow,
}: StatCardProps) => (
  <div className={cn("glass glass-hover rounded-3xl p-5 relative overflow-hidden", glow && glows[gradient])}>
    <div className={cn("absolute -top-12 -right-12 h-40 w-40 rounded-full opacity-20 blur-2xl", gradients[gradient])} />
    <div className="flex items-start justify-between">
      <div>
        <p className="text-[11px] uppercase tracking-[0.18em] text-muted-foreground font-medium">{label}</p>
        <p className="font-display text-4xl font-bold mt-2 tracking-tight">{value}</p>
        {subtle && <p className="text-xs text-muted-foreground mt-1">{subtle}</p>}
      </div>
      <div className={cn("h-11 w-11 rounded-2xl grid place-items-center", gradients[gradient])}>
        <Icon className="h-5 w-5 text-primary-foreground" />
      </div>
    </div>
    {delta && (
      <div className="mt-4 flex items-center gap-2">
        <span
          className={cn(
            "text-xs font-mono px-2 py-0.5 rounded-md",
            trend === "up" && "text-success bg-success/10",
            trend === "down" && "text-destructive bg-destructive/10",
            trend === "warn" && "text-warning bg-warning/10"
          )}
        >
          {delta}
        </span>
        <span className="text-[11px] text-muted-foreground">vs last hour</span>
      </div>
    )}
  </div>
);
