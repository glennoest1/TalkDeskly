"use client";

import { ArrowLeft } from "lucide-react";
import { Button } from "@/components/ui/button";
import { useTranslation } from "react-i18next";

function Header({ onMobileBack }: { onMobileBack?: () => void }) {
  const { t } = useTranslation();

  return (
    <div className="p-4 border-b flex items-center gap-2">
      <Button
        variant="ghost"
        size="icon"
        className="md:hidden"
        onClick={() => onMobileBack && onMobileBack()}
      >
        <ArrowLeft className="h-5 w-5" />
      </Button>
      <h2 className="text-lg font-semibold">{t("liveChat.filter.title")}</h2>
    </div>
  );
}

export default Header;
