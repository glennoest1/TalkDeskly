import { Languages } from "lucide-react";
import { useTranslation } from "react-i18next";
import {
  DropdownMenu,
  DropdownMenuContent,
  DropdownMenuItem,
  DropdownMenuTrigger,
} from "@/components/ui/dropdown-menu";
import { Button } from "@/components/ui/button";
import {
  supportedLanguages,
  type SupportedLanguage,
} from "@/lib/i18n";
import { cn } from "@/lib/utils";

const languageLabels: Record<SupportedLanguage, string> = {
  vi: "Tiếng Việt",
  en: "English",
  zh: "中文",
};

interface LanguageSwitcherProps {
  className?: string;
  showLabel?: boolean;
}

export function LanguageSwitcher({
  className,
  showLabel = true,
}: LanguageSwitcherProps) {
  const { i18n, t } = useTranslation();
  const currentLanguage = (
    supportedLanguages.includes(i18n.resolvedLanguage as SupportedLanguage)
      ? i18n.resolvedLanguage
      : i18n.language
  ) as SupportedLanguage;

  const handleLanguageChange = (language: SupportedLanguage) => {
    localStorage.setItem("i18nextLng", language);
    i18n.changeLanguage(language);
  };

  return (
    <DropdownMenu>
      <DropdownMenuTrigger asChild>
        <Button
          variant="ghost"
          size="sm"
          className={cn("h-9 gap-2 px-2", className)}
          aria-label={t("common.language")}
        >
          <Languages className="h-4 w-4 mr-2" />
          {showLabel && (
            <span className="hidden sm:inline text-sm">
              {languageLabels[currentLanguage] ?? languageLabels.vi}
            </span>
          )}
        </Button>
      </DropdownMenuTrigger>
      <DropdownMenuContent align="end" className="w-40">
        {supportedLanguages.map((language) => (
          <DropdownMenuItem
            key={language}
            onClick={() => handleLanguageChange(language)}
            className="flex cursor-pointer items-center gap-2"
          >
            <span>{languageLabels[language]}</span>
            {currentLanguage === language && (
              <div className="ml-auto h-2 w-2 rounded-full bg-primary" />
            )}
          </DropdownMenuItem>
        ))}
      </DropdownMenuContent>
    </DropdownMenu>
  );
}
