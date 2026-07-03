import { MessageSquare } from "lucide-react";
import { Button } from "@/components/ui/button";
import { useTranslation } from "react-i18next";

interface EmptyChatStateProps {
  onViewConversations?: () => void;
}

export default function EmptyChatState({
  onViewConversations,
}: EmptyChatStateProps) {
  const { t } = useTranslation();

  return (
    <div className="flex-1 flex items-center justify-center p-4 text-muted-foreground">
      <div className="text-center">
        <MessageSquare className="h-12 w-12 mx-auto mb-4 opacity-20" />
        <p>{t("liveChat.emptyChatState.description")}</p>
        {onViewConversations && (
          <Button
            variant="outline"
            className="mt-4 sm:hidden"
            onClick={onViewConversations}
          >
            {t("liveChat.emptyChatState.viewConversations")}
          </Button>
        )}
      </div>
    </div>
  );
}
