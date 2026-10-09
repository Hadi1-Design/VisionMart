import { NavLink, Outlet, useLocation } from "react-router-dom";
import { LayoutDashboard, ShieldAlert, BarChart3, Settings as SettingsIcon, LogOut, Bell, Search } from "lucide-react";
import { cn } from "@/lib/utils";

const nav = [
  { to: "/dashboard", label: "Dashboard", icon: LayoutDashboard },
  { to: "/alerts", label: "Alerts", icon: ShieldAlert },
  { to: "/analytics", label: "Analytics", icon: BarChart3 },
  { to: "/settings", label: "Settings", icon: SettingsIcon },
];

const AppLayout = () => {
  const location = useLocation();
  const current = nav.find(n => location.pathname.startsWith(n.to))?.label ?? "VisionMart";

  return (
    <div className="min-h-screen flex flex-col lg:flex-row">
      {/* Desktop sidebar */}
      <aside className="hidden lg:flex flex-col w-64 p-4 sticky top-0 h-screen">
        <div className="glass rounded-3xl p-5 flex flex-col h-full">
          <Brand />
          <nav className="mt-8 flex-1 space-y-1">
            {nav.map(({ to, label, icon: Icon }) => (
              <NavLink
                key={to}
                to={to}
                className={({ isActive }) =>
                  cn(
                    "group flex items-center gap-3 px-3 py-2.5 rounded-xl text-sm font-medium transition-all",
                    isActive
                      ? "bg-gradient-indigo text-primary-foreground shadow-[0_8px_30px_-8px_hsl(244_92%_55%/0.6)]"
                      : "text-muted-foreground hover:bg-secondary hover:text-foreground"
                  )
                }
              >
                <Icon className="h-4 w-4" />
                {label}
              </NavLink>
            ))}
          </nav>
          <UserChip />
        </div>
      </aside>

      {/* Mobile top bar */}
      <header className="lg:hidden sticky top-0 z-40 px-4 pt-4">
        <div className="glass-strong rounded-2xl px-4 py-3 flex items-center justify-between">
          <Brand compact />
          <button className="h-9 w-9 rounded-xl bg-secondary flex items-center justify-center">
            <Bell className="h-4 w-4" />
          </button>
        </div>
      </header>

      <main className="flex-1 min-w-0 px-4 lg:px-6 py-4 lg:py-6">
        {/* Top bar (desktop) */}
        <div className="hidden lg:flex items-center justify-between mb-6">
          <div>
            <p className="text-xs uppercase tracking-[0.2em] text-muted-foreground">VisionMart · Live</p>
            <h1 className="font-display text-3xl font-semibold mt-1">{current}</h1>
          </div>
          <div className="flex items-center gap-3">
            <div className="glass rounded-2xl px-4 py-2.5 flex items-center gap-2 w-72">
              <Search className="h-4 w-4 text-muted-foreground" />
              <input
                placeholder="Search cameras, alerts, zones…"
                className="bg-transparent outline-none text-sm flex-1 placeholder:text-muted-foreground"
              />
            </div>
            <button className="relative glass rounded-2xl h-11 w-11 flex items-center justify-center hover:border-white/20 transition">
              <Bell className="h-4 w-4" />
              <span className="absolute top-2 right-2 h-2 w-2 rounded-full bg-destructive animate-blip" />
            </button>
          </div>
        </div>

        <div className="animate-fade-in pb-10">
          <Outlet />
        </div>

        {/* Mobile bottom nav */}
        <nav className="lg:hidden fixed bottom-4 left-4 right-4 z-40">
          <div className="glass-strong rounded-2xl p-2 flex justify-around">
            {nav.map(({ to, label, icon: Icon }) => (
              <NavLink
                key={to}
                to={to}
                className={({ isActive }) =>
                  cn(
                    "flex-1 flex flex-col items-center gap-1 py-2 rounded-xl text-[10px] font-medium transition-all",
                    isActive ? "bg-gradient-indigo text-primary-foreground" : "text-muted-foreground"
                  )
                }
              >
                <Icon className="h-4 w-4" />
                {label}
              </NavLink>
            ))}
          </div>
        </nav>
      </main>
    </div>
  );
};

const Brand = ({ compact = false }: { compact?: boolean }) => (
  <div className="flex items-center gap-3">
    <div className="relative">
      <div className="h-10 w-10 rounded-2xl bg-gradient-indigo grid place-items-center shadow-[0_10px_40px_-10px_hsl(244_92%_55%/0.7)]">
        <div className="h-3 w-3 rounded-full bg-primary-foreground animate-blip" />
      </div>
      <div className="absolute -inset-1 rounded-2xl bg-gradient-indigo opacity-20 blur-xl -z-10" />
    </div>
    {!compact && (
      <div>
        <p className="font-display font-bold text-lg leading-none">VisionMart</p>
        <p className="text-[10px] uppercase tracking-[0.18em] text-muted-foreground mt-1">AI Surveillance</p>
      </div>
    )}
    {compact && <p className="font-display font-bold text-base">VisionMart</p>}
  </div>
);

const UserChip = () => (
  <div className="mt-4 pt-4 border-t border-border/50">
    <div className="flex items-center gap-3 px-2">
      <div className="h-9 w-9 rounded-full bg-gradient-electric grid place-items-center text-xs font-bold text-accent-foreground">
        AD
      </div>
      <div className="flex-1 min-w-0">
        <p className="text-sm font-medium truncate">Admin · A. Doe</p>
        <p className="text-[10px] uppercase tracking-wider text-success">● online</p>
      </div>
      <button className="h-8 w-8 rounded-lg hover:bg-secondary grid place-items-center text-muted-foreground">
        <LogOut className="h-4 w-4" />
      </button>
    </div>
  </div>
);

export default AppLayout;
