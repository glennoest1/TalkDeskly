"use client";

import { Tabs, TabsList, TabsTrigger } from "@/components/ui/tabs";
import { useTranslation } from "react-i18next";

// Tabs Component
function TabsComponent({
  activeTab,
  setActiveTab,
}: {
  activeTab: string;
  setActiveTab: (tab: string) => void;
}) {
  const { t } = useTranslation();

  return (
    <Tabs defaultValue="all" className="my-4" onValueChange={setActiveTab}>
      <TabsList className="flex w-full justify-start overflow-x-auto rounded-none px-1 [scrollbar-width:none] [&::-webkit-scrollbar]:hidden">
        <TabsTrigger
          value="all"
          className="shrink-0 whitespace-nowrap text-xs sm:text-sm px-3"
        >
          {t("liveChat.filter.tabs.all")}
        </TabsTrigger>
        <TabsTrigger
          value="unassigned"
          className="shrink-0 whitespace-nowrap text-xs sm:text-sm px-3"
        >
          {t("liveChat.filter.tabs.unassigned")}
        </TabsTrigger>
        <TabsTrigger
          value="active"
          className="shrink-0 whitespace-nowrap text-xs sm:text-sm px-3"
        >
          {t("liveChat.filter.tabs.active")}
        </TabsTrigger>
        <TabsTrigger
          value="closed"
          className="shrink-0 whitespace-nowrap text-xs sm:text-sm px-3"
        >
          {t("liveChat.filter.tabs.closed")}
        </TabsTrigger>
      </TabsList>
    </Tabs>
  );
}

export default TabsComponent;
