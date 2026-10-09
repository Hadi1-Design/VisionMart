import { useState } from "react";
import { Link, useNavigate } from "react-router-dom";
import { Eye, EyeOff, Shield, User, ScanFace, ArrowRight, Mail, Lock, UserRound } from "lucide-react";
import { cn } from "@/lib/utils";

type Role = "admin" | "staff";

const Signup = () => {
  const navigate = useNavigate();
  const [role, setRole] = useState<Role>("staff");
  const [show, setShow] = useState(false);
  const [showConfirm, setShowConfirm] = useState(false);
  const [loading, setLoading] = useState(false);

  const submit = (e: React.FormEvent) => {
    e.preventDefault();
    setLoading(true);
    // NOTE: wire Firebase Auth signup here
    setTimeout(() => navigate("/dashboard"), 800);
  };

  return (
    <div className="min-h-screen grid place-items-center px-4 py-10 relative overflow-hidden">
      {/* Ambient glow */}
      <div className="absolute top-1/4 -left-24 h-96 w-96 rounded-full bg-primary/30 blur-[120px] pointer-events-none" />
      <div className="absolute bottom-0 right-0 h-96 w-96 rounded-full bg-accent/20 blur-[120px] pointer-events-none" />

      <div className="w-full max-w-md animate-scale-in">
        {/* Logo */}
        <div className="flex items-center justify-center gap-3 mb-8">
          <div className="h-12 w-12 rounded-2xl bg-gradient-indigo grid place-items-center shadow-[0_10px_40px_-5px_hsl(244_92%_55%/0.6)]">
            <ScanFace className="h-6 w-6 text-primary-foreground" />
          </div>
          <div>
            <p className="font-display font-bold text-2xl leading-none">VisionMart</p>
            <p className="text-[10px] uppercase tracking-[0.25em] text-muted-foreground mt-1">
              Command Console
            </p>
          </div>
        </div>

        <div className="glass-strong rounded-3xl p-7 sm:p-8">
          <div className="text-center mb-6">
            <h1 className="font-display text-2xl font-semibold">Create account</h1>
            <p className="text-sm text-muted-foreground mt-1">
              Provision your operator credentials
            </p>
          </div>

          {/* Role toggle */}
          <div className="relative grid grid-cols-2 p-1 rounded-2xl bg-secondary/60 mb-6">
            <span
              className={cn(
                "absolute top-1 bottom-1 w-[calc(50%-0.25rem)] rounded-xl bg-gradient-indigo transition-all duration-300 shadow-[0_8px_24px_-8px_hsl(244_92%_55%/0.6)]",
                role === "admin" ? "left-1" : "left-[calc(50%+0px)]"
              )}
            />
            {(["admin", "staff"] as Role[]).map((r) => {
              const Icon = r === "admin" ? Shield : User;
              return (
                <button
                  key={r}
                  type="button"
                  onClick={() => setRole(r)}
                  className={cn(
                    "relative z-10 flex items-center justify-center gap-2 py-2.5 text-sm font-medium rounded-xl transition-colors",
                    role === r ? "text-primary-foreground" : "text-muted-foreground"
                  )}
                >
                  <Icon className="h-4 w-4" />
                  {r === "admin" ? "Admin" : "Staff"}
                </button>
              );
            })}
          </div>

          <form onSubmit={submit} className="space-y-4">
            <Field label="Full name" icon={<UserRound className="h-4 w-4 text-muted-foreground" />}>
              <input
                type="text"
                required
                className="bg-transparent outline-none w-full text-sm placeholder:text-muted-foreground"
                placeholder="Alex Morgan"
              />
            </Field>

            <Field label="Email" icon={<Mail className="h-4 w-4 text-muted-foreground" />}>
              <input
                type="email"
                required
                className="bg-transparent outline-none w-full text-sm placeholder:text-muted-foreground"
                placeholder="you@store.com"
              />
            </Field>

            <Field label="Password" icon={<Lock className="h-4 w-4 text-muted-foreground" />}>
              <input
                type={show ? "text" : "password"}
                required
                minLength={8}
                className="bg-transparent outline-none w-full text-sm placeholder:text-muted-foreground"
                placeholder="At least 8 characters"
              />
              <button
                type="button"
                onClick={() => setShow((s) => !s)}
                className="text-muted-foreground hover:text-foreground transition"
              >
                {show ? <EyeOff className="h-4 w-4" /> : <Eye className="h-4 w-4" />}
              </button>
            </Field>

            <Field label="Confirm password" icon={<Lock className="h-4 w-4 text-muted-foreground" />}>
              <input
                type={showConfirm ? "text" : "password"}
                required
                minLength={8}
                className="bg-transparent outline-none w-full text-sm placeholder:text-muted-foreground"
                placeholder="Re-enter password"
              />
              <button
                type="button"
                onClick={() => setShowConfirm((s) => !s)}
                className="text-muted-foreground hover:text-foreground transition"
              >
                {showConfirm ? <EyeOff className="h-4 w-4" /> : <Eye className="h-4 w-4" />}
              </button>
            </Field>

            <label className="flex items-start gap-2 text-xs text-muted-foreground cursor-pointer pt-1">
              <input type="checkbox" required className="accent-primary h-3.5 w-3.5 mt-0.5" />
              <span>
                I agree to the{" "}
                <span className="text-primary-glow hover:underline">Terms</span> and{" "}
                <span className="text-primary-glow hover:underline">Privacy Policy</span>.
              </span>
            </label>

            <button
              type="submit"
              disabled={loading}
              className={cn(
                "group w-full mt-2 h-12 rounded-2xl bg-gradient-indigo text-primary-foreground font-medium",
                "flex items-center justify-center gap-2 transition-all",
                "shadow-[0_15px_50px_-15px_hsl(244_92%_55%/0.8)] hover:shadow-[0_20px_60px_-15px_hsl(244_92%_55%/1)]",
                "hover:scale-[1.01] active:scale-[0.99]",
                loading && "opacity-70"
              )}
            >
              {loading ? (
                <span className="h-4 w-4 rounded-full border-2 border-primary-foreground/40 border-t-primary-foreground animate-spin" />
              ) : (
                <>
                  Create Account
                  <ArrowRight className="h-4 w-4 transition-transform group-hover:translate-x-0.5" />
                </>
              )}
            </button>
          </form>

          <p className="text-center text-xs text-muted-foreground mt-6">
            Already have an account?{" "}
            <Link to="/login" className="text-primary-glow hover:underline font-medium">
              Sign in
            </Link>
          </p>
        </div>
      </div>
    </div>
  );
};

const Field = ({
  label,
  icon,
  children,
}: {
  label: string;
  icon?: React.ReactNode;
  children: React.ReactNode;
}) => (
  <label className="block group">
    <span className="text-[11px] uppercase tracking-wider text-muted-foreground font-medium">
      {label}
    </span>
    <div
      className={cn(
        "mt-1.5 flex items-center gap-2 px-4 h-12 rounded-2xl bg-secondary/60 border border-border/60",
        "transition-all duration-300",
        "focus-within:border-primary/60 focus-within:bg-secondary/80 focus-within:shadow-[0_0_0_4px_hsl(244_92%_66%/0.1)]"
      )}
    >
      {icon}
      {children}
    </div>
  </label>
);

export default Signup;
