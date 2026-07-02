"use client";

import { useState } from "react";
import {
  ChevronDown,
  Plus,
  Search,
  Users,
  Rocket,
  TrendingUp,
  Wrench,
  AlertTriangle,
  Flame,
  X,
  Inbox as InboxIcon,
} from "lucide-react";
import { Button } from "@/components/ui/button";
import {
  Collapsible,
  CollapsibleContent,
  CollapsibleTrigger,
} from "@/components/ui/collapsible";
import { cn } from "@/lib/utils";
import { Input } from "@/components/ui/input";
import { Inbox } from "@/lib/interfaces";
import { Link } from "react-router-dom";
import { useTranslation } from "react-i18next";

interface InboxSidebarProps {
  inboxes: Inbox[];
  activeInboxId: string | null;
  onInboxChange: (inboxId: string | null) => void;
  onClose?: () => void;
}

export default function InboxSidebar({
  inboxes,
  activeInboxId,
  onInboxChange,
  onClose,
}: InboxSidebarProps) {
  const { t } = useTranslation();
  const [isTeamInboxesOpen, setIsTeamInboxesOpen] = useState(true);
  const [searchQuery, setSearchQuery] = useState("");

  // Filter inboxes based on search query
  const filteredInboxes = inboxes.filter(
    (inbox) =>
      searchQuery === "" ||
      inbox.name.toLowerCase().includes(searchQuery.toLowerCase())
  );

  return (
    <div className={cn("flex flex-col h-full bg-muted/60 w-100 md:w-60")}>
      {/* Header */}
      <div className="flex items-center justify-between p-4 border-b">
        <h2 className="font-semibold text-lg">
          {t("liveChat.inboxSidebar.title")}
        </h2>
      </div>

      {/* Search and Quick Filters */}
      <div className="p-4 space-y-4">
        <h3 className="font-semibold flex items-center justify-between">
          {t("liveChat.inboxSidebar.sectionTitle")}
          <Link to="/portal/settings/inboxes/new">
            <Button variant="ghost" size="icon" className="h-8 w-8">
              <Plus className="h-4 w-4" />
            </Button>
          </Link>
        </h3>
        <div className="relative">
          <Search className="absolute left-2.5 top-2.5 h-4 w-4 text-muted-foreground" />
          <Input
            type="search"
            placeholder={t("liveChat.inboxSidebar.searchPlaceholder")}
            className="pl-8 h-9 bg-background"
            value={searchQuery}
            onChange={(e: React.ChangeEvent<HTMLInputElement>) =>
              setSearchQuery(e.target.value)
            }
          />
        </div>
        <div className="space-y-1">
          <Button
            variant="ghost"
            className={cn(
              "w-full justify-start h-9 px-2 font-normal",
              activeInboxId === "my-inbox" && "bg-accent"
            )}
            onClick={() => onInboxChange("my-inbox")}
          >
            <InboxIcon className="h-4 w-4 mr-2" />
            {t("liveChat.inboxSidebar.myInbox")}
          </Button>
          <Button
            variant="ghost"
            className={cn(
              "w-full justify-start h-9 px-2 font-normal",
              activeInboxId === "unassigned" && "bg-accent"
            )}
            onClick={() => onInboxChange("unassigned")}
          >
            <Users className="h-4 w-4 mr-2" />
            {t("liveChat.inboxSidebar.unassigned")}
          </Button>
          <Button
            variant="ghost"
            className={cn(
              "w-full justify-start h-9 px-2 font-normal",
              activeInboxId === null && "bg-accent"
            )}
            onClick={() => onInboxChange(null)}
          >
            <Users className="h-4 w-4 mr-2" />
            {t("liveChat.inboxSidebar.all")}
          </Button>
        </div>
      </div>

      {/* Team Inboxes */}
      <div className="px-4 flex-1 overflow-auto">
        <Collapsible
          open={isTeamInboxesOpen}
          onOpenChange={setIsTeamInboxesOpen}
        >
          <CollapsibleTrigger asChild>
            <Button
              variant="ghost"
              className="w-full justify-between h-9 px-2 font-medium text-sm"
            >
              {t("liveChat.inboxSidebar.teamInboxes")}
              <ChevronDown
                className={cn(
                  "h-4 w-4 transition-transform",
                  isTeamInboxesOpen && "rotate-180"
                )}
              />
            </Button>
          </CollapsibleTrigger>
          <CollapsibleContent className="space-y-1">
            {filteredInboxes.length > 0 ? (
              filteredInboxes.map((inbox) => (
                <Button
                  key={inbox.id}
                  variant="ghost"
                  className={cn(
                    "w-full justify-start h-9 px-2 font-normal",
                    activeInboxId === inbox.id && "bg-accent"
                  )}
                  onClick={() => {
                    onInboxChange(inbox.id);
                    onClose?.();
                  }}
                >
                  <InboxIcon className="h-4 w-4" />
                  <span className="ml-2 flex-1">{inbox.name}</span>
                  {/* {inbox.unreadCount > 0 && (
                    <span className="ml-auto text-xs rounded-full px-2 py-0.5">
                      {inbox.unreadCount}
                    </span>
                  )} */}
                </Button>
              ))
            ) : (
              <div className="py-2 px-2 text-sm text-muted-foreground">
                {t("liveChat.inboxSidebar.empty")}
              </div>
            )}
          </CollapsibleContent>
        </Collapsible>
      </div>
    </div>
  );
}
