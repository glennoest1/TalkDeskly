import { ColumnDef } from "@tanstack/react-table";
import { Edit, MoreHorizontal, Trash2 } from "lucide-react";
import { Button } from "@/components/ui/button";
import {
  DropdownMenu,
  DropdownMenuContent,
  DropdownMenuItem,
  DropdownMenuLabel,
  DropdownMenuSeparator,
  DropdownMenuTrigger,
} from "@/components/ui/dropdown-menu";
import { Avatar, AvatarFallback, AvatarImage } from "@/components/ui/avatar";
import type { Contact } from "@/lib/interfaces";
import { DeleteContactDialog } from "@/components/protected/contacts/dialogs/delete-contact-dialog";
import type { TFunction } from "i18next";

type ContactsColumnProps = {
  onEdit: (contact: Contact) => void;
  onDelete: (contactId: string) => void;
  t: TFunction;
};

export const createColumns = ({
  onEdit,
  onDelete,
  t,
}: ContactsColumnProps): ColumnDef<Contact>[] => [
  {
    accessorKey: "name",
    header: t("contacts.name"),
    cell: ({ row }) => {
      const contact = row.original;
      return (
        <div className="flex items-center gap-3">
          <Avatar className="h-8 w-8">
            <AvatarImage src={""} alt={contact.name} />
            <AvatarFallback>
              {contact.name.substring(0, 2).toUpperCase()}
            </AvatarFallback>
          </Avatar>
          <span className="font-medium">{contact.name}</span>
        </div>
      );
    },
  },
  {
    accessorKey: "email",
    header: t("contacts.email"),
  },
  {
    accessorKey: "phone",
    header: t("contacts.phone"),
  },
  {
    accessorKey: "company",
    header: t("contacts.company"),
  },
  {
    id: "actions",
    cell: ({ row }) => {
      const contact = row.original;

      return (
        <div className="text-right">
          <DropdownMenu>
            <DropdownMenuTrigger asChild>
              <Button variant="ghost" size="icon">
                <MoreHorizontal className="h-4 w-4" />
                <span className="sr-only">Open menu</span>
              </Button>
            </DropdownMenuTrigger>
            <DropdownMenuContent align="end">
              <DropdownMenuLabel>{t("contacts.actions.label")}</DropdownMenuLabel>
              <DropdownMenuSeparator />
              <DropdownMenuItem onClick={() => onEdit(contact)}>
                <Edit className="h-4 w-4 mr-2" />
                {t("contacts.actions.edit")}
              </DropdownMenuItem>
              {/* <DeleteContactDialog
                contact={contact}
                onDelete={onDelete}
                trigger={
                  <DropdownMenuItem onSelect={(e) => e.preventDefault()}>
                    <Trash2 className="h-4 w-4 mr-2" />
                    {t("contacts.actions.delete")}
                  </DropdownMenuItem>
                }
              /> */}
            </DropdownMenuContent>
          </DropdownMenu>
        </div>
      );
    },
  },
];
