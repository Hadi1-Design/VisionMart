import { AreaChart, Area, ResponsiveContainer, XAxis, YAxis, Tooltip, CartesianGrid, BarChart, Bar } from "recharts";
import { Star, Clock, TrendingUp, Activity, Users } from "lucide-react";
import { StatCard } from "@/components/dashboard/StatCard";

const flowData = Array.from({ length: 24 }, (_, i) => ({
  hour: `${i.toString().padStart(2, "0")}:00`,
  visitors: Math.round(40 + Math.sin(i / 3) * 60 + (i > 10 && i < 19 ? 80 : 0) + Math.random() * 20),
  predicted: Math.round(50 + Math.sin(i / 3) * 55 + (i > 10 && i < 19 ? 75 : 0)),
}));

const zoneData = [
  { zone: "Entry",     value: 312 },
  { zone: "Apparel",   value: 248 },
  { zone: "Tech",      value: 196 },
  { zone: "Beauty",    value: 174 },
  { zone: "Checkout",  value: 289 },
  { zone: "Exit",      value: 268 },
];

const VisitorFlow = () => {
  return (
    <div className="space-y-6">
      <div className="lg:hidden">
        <p className="text-[11px] uppercase tracking-[0.2em] text-muted-foreground">VisionMart</p>
        <h1 className="font-display text-2xl font-semibold mt-1">Visitor Flow</h1>
      </div>

      <section className="grid grid-cols-2 lg:grid-cols-4 gap-4">
        <StatCard label="Total Today" value="3,182" delta="+8.1%" trend="up" icon={Users} gradient="indigo" glow />
        <StatCard label="Avg Dwell" value="14m" delta="+2m" trend="up" icon={Clock} gradient="electric" />
        <StatCard label="Conversion" value="32%" delta="+1.4%" trend="up" icon={TrendingUp} gradient="success" />
        <StatCard label="Bounce" value="9%" delta="-0.8%" trend="up" icon={Activity} gradient="violet" />
      </section>

      <section className="grid grid-cols-12 gap-4">
        {/* Real-time flow chart */}
        <div className="col-span-12 lg:col-span-8 glass rounded-3xl p-5">
          <div className="flex items-start justify-between mb-4">
            <div>
              <h2 className="font-display text-xl font-semibold">Real-time Visitor Flow</h2>
              <p className="text-xs text-muted-foreground mt-0.5">Last 24 hours · all zones combined</p>
            </div>
            <div className="hidden sm:flex items-center gap-3 text-xs">
              <Legend dot="bg-primary" label="Live" />
              <Legend dot="bg-accent" label="Predicted" />
            </div>
          </div>
          <div className="h-72 -ml-4">
            <ResponsiveContainer width="100%" height="100%">
              <AreaChart data={flowData}>
                <defs>
                  <linearGradient id="liveFill" x1="0" y1="0" x2="0" y2="1">
                    <stop offset="0%" stopColor="hsl(244 92% 66%)" stopOpacity={0.5} />
                    <stop offset="100%" stopColor="hsl(244 92% 66%)" stopOpacity={0} />
                  </linearGradient>
                  <linearGradient id="predFill" x1="0" y1="0" x2="0" y2="1">
                    <stop offset="0%" stopColor="hsl(198 100% 60%)" stopOpacity={0.3} />
                    <stop offset="100%" stopColor="hsl(198 100% 60%)" stopOpacity={0} />
                  </linearGradient>
                </defs>
                <CartesianGrid stroke="hsl(var(--border))" strokeDasharray="3 6" vertical={false} />
                <XAxis dataKey="hour" stroke="hsl(var(--muted-foreground))" fontSize={11} tickLine={false} axisLine={false} interval={2} />
                <YAxis stroke="hsl(var(--muted-foreground))" fontSize={11} tickLine={false} axisLine={false} width={36} />
                <Tooltip
                  contentStyle={{
                    background: "hsl(var(--popover))",
                    border: "1px solid hsl(var(--border))",
                    borderRadius: 12,
                    fontSize: 12,
                  }}
                />
                <Area type="monotone" dataKey="predicted" stroke="hsl(198 100% 60%)" strokeWidth={1.5} strokeDasharray="4 4" fill="url(#predFill)" />
                <Area type="monotone" dataKey="visitors" stroke="hsl(244 92% 70%)" strokeWidth={2.5} fill="url(#liveFill)" />
              </AreaChart>
            </ResponsiveContainer>
          </div>
        </div>

        {/* Peak hour highlight */}
        <div className="col-span-12 lg:col-span-4 glass rounded-3xl p-5 relative overflow-hidden">
          <div className="absolute -top-10 -right-10 h-40 w-40 rounded-full bg-gradient-warning opacity-20 blur-2xl" />
          <p className="text-[11px] uppercase tracking-[0.18em] text-muted-foreground font-medium">Peak Hour</p>
          <h3 className="font-display text-3xl font-bold mt-2">14:00 – 15:00</h3>
          <p className="text-xs text-muted-foreground mt-1">Highest dwell · 412 visitors</p>

          <PeakRing pct={82} />

          <div className="mt-4 flex items-center justify-between">
            <p className="text-[11px] uppercase tracking-wider text-muted-foreground">Impact</p>
            <div className="flex gap-0.5">
              {[1, 2, 3, 4, 5].map((i) => (
                <Star
                  key={i}
                  className={i <= 4 ? "h-4 w-4 fill-warning text-warning" : "h-4 w-4 text-muted-foreground/40"}
                />
              ))}
            </div>
          </div>
        </div>

        {/* Zone breakdown */}
        <div className="col-span-12 glass rounded-3xl p-5">
          <h2 className="font-display text-xl font-semibold mb-4">Visitors by Zone</h2>
          <div className="h-56 -ml-2">
            <ResponsiveContainer width="100%" height="100%">
              <BarChart data={zoneData}>
                <defs>
                  <linearGradient id="barFill" x1="0" y1="0" x2="0" y2="1">
                    <stop offset="0%" stopColor="hsl(244 92% 66%)" />
                    <stop offset="100%" stopColor="hsl(198 100% 60%)" />
                  </linearGradient>
                </defs>
                <CartesianGrid stroke="hsl(var(--border))" strokeDasharray="3 6" vertical={false} />
                <XAxis dataKey="zone" stroke="hsl(var(--muted-foreground))" fontSize={11} tickLine={false} axisLine={false} />
                <YAxis stroke="hsl(var(--muted-foreground))" fontSize={11} tickLine={false} axisLine={false} width={36} />
                <Tooltip cursor={{ fill: "hsl(var(--secondary))" }}
                  contentStyle={{
                    background: "hsl(var(--popover))",
                    border: "1px solid hsl(var(--border))",
                    borderRadius: 12,
                    fontSize: 12,
                  }}
                />
                <Bar dataKey="value" fill="url(#barFill)" radius={[10, 10, 4, 4]} />
              </BarChart>
            </ResponsiveContainer>
          </div>
        </div>
      </section>
    </div>
  );
};

const Legend = ({ dot, label }: { dot: string; label: string }) => (
  <span className="flex items-center gap-1.5 text-muted-foreground">
    <span className={`h-2 w-2 rounded-full ${dot}`} />
    {label}
  </span>
);

const PeakRing = ({ pct }: { pct: number }) => {
  const r = 52;
  const c = 2 * Math.PI * r;
  const offset = c - (pct / 100) * c;
  return (
    <div className="mt-5 grid place-items-center">
      <div className="relative h-32 w-32">
        <svg viewBox="0 0 120 120" className="h-full w-full -rotate-90">
          <defs>
            <linearGradient id="ringGrad" x1="0" y1="0" x2="1" y2="1">
              <stop offset="0%" stopColor="hsl(358 85% 60%)" />
              <stop offset="100%" stopColor="hsl(38 95% 58%)" />
            </linearGradient>
          </defs>
          <circle cx="60" cy="60" r={r} stroke="hsl(var(--border))" strokeWidth="9" fill="none" />
          <circle
            cx="60" cy="60" r={r}
            stroke="url(#ringGrad)" strokeWidth="9" fill="none"
            strokeLinecap="round"
            strokeDasharray={c}
            strokeDashoffset={offset}
            style={{ transition: "stroke-dashoffset 1s ease-out" }}
          />
        </svg>
        <div className="absolute inset-0 grid place-items-center">
          <div className="text-center">
            <p className="font-display text-2xl font-bold">{pct}%</p>
            <p className="text-[10px] uppercase tracking-wider text-muted-foreground">capacity</p>
          </div>
        </div>
      </div>
    </div>
  );
};

export default VisitorFlow;
