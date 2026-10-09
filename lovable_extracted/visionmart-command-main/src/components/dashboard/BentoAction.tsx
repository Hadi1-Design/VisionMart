import { cn } from "@/lib/utils";
import { LucideIcon, ArrowUpRight } from "lucide-react";

interface BentoActionProps {
  title: string;
  desc: string;
  icon: LucideIcon;
  gradient: "indigo" | "electric" | "warning" | "success" | "violet";
  count?: number;
  className?: string;
  large?: boolean;
}

const gradMap = {
  indigo: "bg-gradient-indigo",
  electric: "bg-gradient-electric",
  warning: "bg-gradient-warning",
  success: "bg-gradient-success",
  violet: "bg-gradient-violet",
};

export const BentoAction = ({
  title, desc, icon: Icon, gradient, count, className, large,
}: BentoActionProps) => (
  <button
    className={cn(
      "glass glass-hover rounded-3xl p-5 text-left relative overflow-hidden group",
      large && "md:row-span-2",
      className
    )}
  >
    <div className={cn("absolute -bottom-16 -right-10 h-44 w-44 rounded-full opacity-20 blur-3xl", gradMap[gradient])} />
    <div className="flex items-center justify-between">
      <div className={cn("h-12 w-12 rounded-2xl grid place-items-center", gradMap[gradient])}>
        <Icon className="h-5 w-5 text-primary-foreground" />
      </div>
      {count !== undefined && (
        <span className="text-xs font-mono px-2.5 py-1 rounded-full bg-secondary/80 text-muted-foreground">
          {count}
        </span>
      )}
    </div>
    <div className="mt-6">
      <h3 className="font-display text-lg font-semibold">{title}</h3>
      <p className="text-xs text-muted-foreground mt-1 leading-relaxed">{desc}</p>
    </div>
    <div className="mt-4 inline-flex items-center gap-1 text-xs font-medium text-primary-glow opacity-0 group-hover:opacity-100 transition-all -translate-x-1 group-hover:translate-x-0">
      Open module
      <ArrowUpRight className="h-3.5 w-3.5" />
    </div>
  </button>
);
