import { MessageSquare } from "lucide-react";
import SettingsContent from "@/components/protected/settings/settings-content";
import { useTranslation } from "react-i18next";

interface ChannelSelectProps {
  onSelect: (channel: string) => void;
}

export function ChannelSelect({ onSelect }: ChannelSelectProps) {
  const { t } = useTranslation();

  return (
    <SettingsContent
      title={t("inbox.wizard.channelSelect.title")}
      description={t("inbox.wizard.channelSelect.description")}
      showBackButton={false}
    >
      <div className="grid gap-4 sm:grid-cols-1 md:grid-cols-3">
        <button
          onClick={() => onSelect("website")}
          className="flex flex-col items-center gap-4 p-4 sm:p-6 rounded-lg border bg-card text-card-foreground hover:bg-accent/50 transition-colors"
        >
          <div className="p-4 bg-blue-100 rounded-lg">
            <MessageSquare className="h-6 sm:h-8 w-6 sm:w-8 text-blue-600" />
          </div>
          <div className="text-center">
            <h3 className="font-semibold mb-1">
              {t("inbox.wizard.channelSelect.website.title")}
            </h3>
            <p className="text-sm text-muted-foreground">
              {t("inbox.wizard.channelSelect.website.description")}
            </p>
          </div>
        </button>

        {/* Other channel options would go here, but they're disabled for now */}
      </div>
    </SettingsContent>
  );
}
