import React from "react";
import {
  AlertDialog,
  AlertDialogAction,
  AlertDialogCancel,
  AlertDialogContent,
  AlertDialogDescription,
  AlertDialogFooter,
  AlertDialogHeader,
  AlertDialogTitle,
  AlertDialogTrigger,
} from "@/components/ui/alert-dialog";
import type { Contact } from "@/types/chat";
import { useTranslation } from "react-i18next";

interface DeleteContactDialogProps {
  contact: Contact;
  onDelete: (contactId: string) => void;
  trigger: React.ReactNode;
}

export function DeleteContactDialog({
  contact,
  onDelete,
  trigger,
}: DeleteContactDialogProps) {
  const { t } = useTranslation();

  return (
    <AlertDialog>
      <AlertDialogTrigger asChild>{trigger}</AlertDialogTrigger>
      <AlertDialogContent>
        <AlertDialogHeader>
          <AlertDialogTitle>{t("contacts.delete.title")}</AlertDialogTitle>
          <AlertDialogDescription>
            {t("contacts.delete.description", { name: contact.name })}
          </AlertDialogDescription>
        </AlertDialogHeader>
        <AlertDialogFooter>
          <AlertDialogCancel>{t("common.cancel")}</AlertDialogCancel>
          <AlertDialogAction
            onClick={() => onDelete(contact.id)}
            className="bg-destructive text-destructive-foreground hover:bg-destructive/90"
          >
            {t("contacts.actions.delete")}
          </AlertDialogAction>
        </AlertDialogFooter>
      </AlertDialogContent>
    </AlertDialog>
  );
}
