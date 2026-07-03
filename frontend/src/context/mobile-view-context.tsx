import React, { createContext, useContext, useState, ReactNode } from "react";
import i18n from "@/lib/i18n";

type MobileView = "conversations" | "chat" | "contact";

interface MobileViewContextProps {
  mobileView: MobileView;
  setMobileView: (view: MobileView) => void;
}

const MobileViewContext = createContext<MobileViewContextProps | undefined>(
  undefined
);

export const MobileViewProvider: React.FC<{ children: ReactNode }> = ({
  children,
}) => {
  const [mobileView, setMobileView] = useState<MobileView>("chat");

  return (
    <MobileViewContext.Provider value={{ mobileView, setMobileView }}>
      {children}
    </MobileViewContext.Provider>
  );
};

export const useMobileView = () => {
  const context = useContext(MobileViewContext);
  if (!context) {
    throw new Error(i18n.t("errors.mobileViewProvider"));
  }
  return context;
};
