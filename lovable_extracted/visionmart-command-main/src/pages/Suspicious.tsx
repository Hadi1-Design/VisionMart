import { AlertTriangle, Check, Send, Filter, Clock, MapPin, Camera } from "lucide-react";
import { cn } from "@/lib/utils";
import img1 from "@/assets/cctv-suspicious-1.jpg";
import img2 from "@/assets/cctv-suspicious-2.jpg";
import img3 from "@/assets/cctv-suspicious-3.jpg";

interface Detection {
  id: string;
  title: string;
  type: string;
  zone: string;
  camera: string;
  time: string;
  confidence: number;
  severity: "critical" | "high" | "medium";
  image: string;
  reviewed?: boolean;
}

const detections: Detection[] = [
  { id: "d1", title: "Hooded individual loitering near liquor shelf", type: "Loitering · Concealment", zone: "Aisle B-3", camera: "CAM-04", time: "2 min ago", confidence: 0.94, severity: "critical", image: img1 },
  { id: "d2", title: "Unrecognized person near restricted display", type: "Unauthorized zone", zone: "Tech Wall", camera: "CAM-11", time: "8 min ago", confidence: 0.87, severity: "high", image: img2 },
  { id: "d3", title: "Item concealment gesture detected", type: "Concealment", zone: "Aisle G-2", camera: "CAM-22", time: "23 min ago", confidence: 0.79, severity: "medium", image: img3, reviewed: true },
];

const sevColor = {
  critical: { text: "text-destructive", bg: "bg-destructive/15", border: "border-destructive/40", glow: "shadow-[0_0_30px_hsl(358_85%_55%/0.4)]" },
  high:     { text: "text-warning", bg: "bg-warning/15", border: "border-warning/40", glow: "shadow-[0_0_30px_hsl(38_95%_55%/0.3)]" },
  medium:   { text: "text-accent", bg: "bg-accent/15", border: "border-accent/40", glow: "" },
};

const Suspicious = () => {
  return (
    <div className="space-y-6">
      <div className="lg:hidden">
        <p className="text-[11px] uppercase tracking-[0.2em] text-muted-foreground">VisionMart</p>
        <h1 className="font-display text-2xl font-semibold mt-1">Suspicious Activity</h1>
      </div>

      {/* Filter bar */}
      <div className="glass rounded-2xl p-3 flex items-center gap-2 overflow-x-auto">
        <button className="flex items-center gap-1.5 text-xs px-3 py-1.5 rounded-xl bg-secondary text-foreground">
          <Filter className="h-3.5 w-3.5" /> Filter
        </button>
        {["All", "Critical", "High", "Medium", "Reviewed"].map((f, i) => (
          <button
            key={f}
            className={cn(
              "text-xs px-3 py-1.5 rounded-xl whitespace-nowrap transition",
              i === 0 ? "bg-gradient-indigo text-primary-foreground" : "bg-secondary/40 text-muted-foreground hover:text-foreground"
            )}
          >
            {f}
          </button>
        ))}
        <span className="ml-auto text-xs font-mono text-muted-foreground hidden sm:flex items-center gap-1.5">
          <span className="h-1.5 w-1.5 rounded-full bg-success animate-blip" />
          12 active
        </span>
      </div>

      {/* Detection cards */}
      <div className="grid lg:grid-cols-2 gap-4">
        {detections.map((d) => {
          const c = sevColor[d.severity];
          return (
            <article key={d.id} className={cn("glass glass-hover rounded-3xl overflow-hidden flex flex-col", d.severity === "critical" && c.glow)}>
              {/* Image */}
              <div className="relative aspect-[16/9] overflow-hidden scanline">
                <img
                  src={d.image}
                  alt={d.title}
                  loading="lazy"
                  className="absolute inset-0 h-full w-full object-cover"
                  width={1024}
                  height={576}
                />
                <div className="absolute inset-0 bg-gradient-to-t from-background via-background/30 to-transparent" />

                {/* Severity chip */}
                <div className={cn("absolute top-3 left-3 flex items-center gap-1.5 px-2.5 py-1 rounded-lg backdrop-blur border", c.bg, c.border)}>
                  <AlertTriangle className={cn("h-3.5 w-3.5", c.text)} />
                  <span className={cn("text-[10px] font-mono uppercase tracking-wider", c.text)}>
                    {d.severity} · {Math.round(d.confidence * 100)}%
                  </span>
                </div>

                {/* Live indicator */}
                {!d.reviewed && (
                  <div className="absolute top-3 right-3 flex items-center gap-1.5 px-2.5 py-1 rounded-lg bg-background/40 backdrop-blur border border-border/50">
                    <span className="h-1.5 w-1.5 rounded-full bg-destructive animate-blip" />
                    <span className="text-[10px] font-mono uppercase tracking-wider">Live</span>
                  </div>
                )}

                {/* Bounding box */}
                <div className={cn("absolute left-[35%] top-[32%] h-[45%] w-[28%] rounded border-2", c.border.replace("/40", ""))}>
                  <span className={cn("absolute -top-5 left-0 text-[9px] font-mono px-1.5 py-0.5 rounded font-semibold", c.bg, c.text)}>
                    TARGET · {Math.round(d.confidence * 100)}%
                  </span>
                </div>

                {/* Footer meta */}
                <div className="absolute bottom-3 left-3 right-3 flex items-end justify-between">
                  <div>
                    <p className="text-[10px] uppercase tracking-wider text-muted-foreground font-mono">{d.type}</p>
                    <p className="text-sm font-semibold leading-tight mt-1">{d.title}</p>
                  </div>
                </div>
              </div>

              {/* Body */}
              <div className="p-4 flex flex-col gap-3">
                <div className="flex flex-wrap items-center gap-x-4 gap-y-1.5 text-xs text-muted-foreground">
                  <span className="flex items-center gap-1"><MapPin className="h-3 w-3" />{d.zone}</span>
                  <span className="flex items-center gap-1"><Camera className="h-3 w-3" />{d.camera}</span>
                  <span className="flex items-center gap-1"><Clock className="h-3 w-3" />{d.time}</span>
                </div>

                <div className="flex flex-wrap gap-2 pt-1">
                  <button
                    className={cn(
                      "inline-flex items-center gap-1.5 text-xs font-medium px-4 py-2 rounded-full transition active:scale-95",
                      d.reviewed
                        ? "bg-success/15 text-success border border-success/30"
                        : "bg-secondary hover:bg-secondary/70"
                    )}
                  >
                    <Check className="h-3.5 w-3.5" />
                    {d.reviewed ? "Reviewed" : "Mark Reviewed"}
                  </button>
                  <button className="inline-flex items-center gap-1.5 text-xs font-medium px-4 py-2 rounded-full bg-gradient-indigo text-primary-foreground transition active:scale-95 hover:shadow-[0_8px_24px_-8px_hsl(244_92%_55%/0.6)]">
                    <Send className="h-3.5 w-3.5" />
                    Notify Team
                  </button>
                  <button className="inline-flex items-center gap-1.5 text-xs font-medium px-4 py-2 rounded-full bg-destructive/15 text-destructive border border-destructive/30 transition active:scale-95 hover:bg-destructive/25">
                    Escalate
                  </button>
                </div>
              </div>
            </article>
          );
        })}
      </div>

      {/* Shimmer placeholder for "loading next" */}
      <div className="grid lg:grid-cols-2 gap-4">
        <div className="shimmer rounded-3xl aspect-[16/11]" />
        <div className="shimmer rounded-3xl aspect-[16/11] hidden lg:block" />
      </div>
    </div>
  );
};

export default Suspicious;
