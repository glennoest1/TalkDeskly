import { Outlet } from "react-router-dom";
import { LeftColumn } from "@/components/auth/left-column";
import { RightColumn } from "../auth/right-column";
import { useEffect } from "react";
import { miscService } from "@/lib/api/services/misc";
import { useMiscStore } from "@/stores/misc";
import { LanguageSwitcher } from "@/components/ui/language-switcher";

export function AuthLayout() {
  const { setAppInformation } = useMiscStore();

  useEffect(() => {
    miscService.getAppInformation().then((res) => {
      setAppInformation({
        appName: res.data.appName,
        version: res.data.version,
        registrationEnabled: res.data.registrationEnabled,
      });
    });
  }, []);

  return (
    <div className="flex min-h-screen flex-col md:flex-row">
      <div className="absolute right-4 top-4 z-20">
        <LanguageSwitcher className="bg-background/80 shadow-sm backdrop-blur" />
      </div>

      {/* Left Column - Slider */}
      <div className="md:w-1/2">
        <LeftColumn />
      </div>

      {/* Right Column - Form */}
      <div className="md:w-1/2">
        <RightColumn>
          <Outlet />
        </RightColumn>
      </div>
    </div>
  );
}
