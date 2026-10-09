import { useState } from "react";
import { useNavigate } from "react-router-dom";
import { Bell, Moon, LogOut, ShieldCheck, Mail, User } from "lucide-react";
import { Switch } from "@/components/ui/switch";

const Settings = () => {
  const navigate = useNavigate();
  const [pushOn, setPushOn] = useState(true);
  const [darkMode, setDarkMode] = useState(true);

  const toggleDark = (v: boolean) => {
    setDarkMode(v);
    document.documentElement.classList.toggle("dark", v);
    document.documentElement.classList.toggle("light", !v);
  };

  return (
    <div className="space-y-6">
      <div className="lg:hidden">
        <p className="text-[11px] uppercase tracking-[0.2em] text-muted-foreground">VisionMart</p>
        <h1 className="font-display text-2xl font-semibold mt-1">Settings</h1>
      </div>

      {/* Account */}
      <section className="glass rounded-3xl p-5">
        <h2 className="font-display text-lg font-semibold mb-4">Account</h2>
        <div className="flex items-center gap-4">
          <div className="h-14 w-14 rounded-2xl bg-gradient-electric grid place-items-center text-sm font-bold text-accent-foreground shrink-0">
            AD
          </div>
          <div className="min-w-0 flex-1">
            <p className="font-semibold truncate">A. Doe</p>
            <p className="text-xs text-muted-foreground flex items-center gap-1.5 mt-0.5">
              <ShieldCheck className="h-3 w-3 text-success" /> Admin · Full access
            </p>
          </div>
        </div>
        <div className="mt-4 grid gap-2">
          <Row icon={User} label="Username" value="admin.doe" />
          <Row icon={Mail} label="Email" value="admin@visionmart.io" />
          <Row icon={ShieldCheck} label="Role" value="Administrator" />
        </div>
      </section>

      {/* Preferences */}
      <section className="glass rounded-3xl p-5">
        <h2 className="font-display text-lg font-semibold mb-4">Preferences</h2>
        <div className="divide-y divide-border/40">
          <ToggleRow
            icon={Bell}
            title="Push Notifications"
            desc="Get alerted instantly for critical events"
            checked={pushOn}
            onChange={setPushOn}
          />
          <ToggleRow
            icon={Moon}
            title="Dark Mode"
            desc="Easier on the eyes in command rooms"
            checked={darkMode}
            onChange={toggleDark}
          />
        </div>
      </section>

      {/* Logout */}
      <button
        onClick={() => navigate("/login")}
        className="w-full glass glass-hover rounded-2xl p-4 flex items-center justify-center gap-2 text-destructive font-medium active:scale-[0.99] transition"
      >
        <LogOut className="h-4 w-4" />
        Log out
      </button>

      <p className="text-center text-[11px] text-muted-foreground font-mono">VisionMart v1.0.0</p>
    </div>
  );
};

const Row = ({ icon: Icon, label, value }: { icon: any; label: string; value: string }) => (
  <div className="flex items-center justify-between py-2.5 px-3 rounded-xl bg-secondary/40">
    <span className="flex items-center gap-2 text-xs text-muted-foreground">
      <Icon className="h-3.5 w-3.5" />
      {label}
    </span>
    <span className="text-sm font-medium">{value}</span>
  </div>
);

const ToggleRow = ({
  icon: Icon, title, desc, checked, onChange,
}: { icon: any; title: string; desc: string; checked: boolean; onChange: (v: boolean) => void }) => (
  <div className="flex items-center gap-4 py-4 first:pt-0 last:pb-0">
    <div className="h-10 w-10 rounded-xl bg-secondary grid place-items-center shrink-0">
      <Icon className="h-4 w-4" />
    </div>
    <div className="flex-1 min-w-0">
      <p className="text-sm font-medium">{title}</p>
      <p className="text-xs text-muted-foreground mt-0.5">{desc}</p>
    </div>
    <Switch checked={checked} onCheckedChange={onChange} />
  </div>
);

export default Settings;
