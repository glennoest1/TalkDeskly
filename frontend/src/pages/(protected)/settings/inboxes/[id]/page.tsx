import EditInbox from "@/components/protected/settings/inbox/edit/edit-inbox";
import { useParams } from "react-router-dom";
import { useTranslation } from "react-i18next";

export default function EditInboxPage() {
  const { t } = useTranslation();
  const { id } = useParams();
  if (!id) {
    return <div>{t("inbox.list.missingId")}</div>;
  }
  return <EditInbox id={id} />;
}
