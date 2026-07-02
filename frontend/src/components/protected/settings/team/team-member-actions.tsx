import {
  Trash2,
  RefreshCw,
  Shield,
  ShieldAlert,
  ShieldCheck,
  MoreHorizontal,
} from "lucide-react";
import { Button } from "@/components/ui/button";
import {
  DropdownMenu,
  DropdownMenuContent,
  DropdownMenuItem,
  DropdownMenuLabel,
  DropdownMenuSeparator,
  DropdownMenuSub,
  DropdownMenuSubTrigger,
  DropdownMenuSubContent,
  DropdownMenuPortal,
  DropdownMenuTrigger,
} from "@/components/ui/dropdown-menu";
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
import { TeamMember } from "@/lib/interfaces";
import { useTranslation } from "react-i18next";

interface TeamMemberActionsProps {
  member: TeamMember;
  onDelete: (id: string) => void;
  onResendInvite: (id: string) => void;
  onUpdateRole: (id: string, role: "admin" | "agent") => void;
}

export function TeamMemberActions({
  member,
  onDelete,
  onResendInvite,
  onUpdateRole,
}: TeamMemberActionsProps) {
  const { t } = useTranslation();

  return (
    <DropdownMenu>
      <DropdownMenuTrigger asChild>
        <Button variant="ghost" size="icon">
          <MoreHorizontal className="h-4 w-4" />
          <span className="sr-only">Open menu</span>
        </Button>
      </DropdownMenuTrigger>
      <DropdownMenuContent align="end">
        <DropdownMenuLabel>{t("team.actions.label")}</DropdownMenuLabel>
        <DropdownMenuSeparator />
        <DropdownMenuSub>
          <DropdownMenuSubTrigger>
            <Shield className="h-4 w-4 mr-2" />
            {t("team.actions.changeRole")}
          </DropdownMenuSubTrigger>
          <DropdownMenuPortal>
            <DropdownMenuSubContent>
              <DropdownMenuItem
                onClick={() => onUpdateRole(member.id, "admin")}
              >
                <ShieldAlert className="h-4 w-4 mr-2" />
                {t("team.roles.admin")}
              </DropdownMenuItem>
              <DropdownMenuItem
                onClick={() => onUpdateRole(member.id, "agent")}
              >
                <ShieldCheck className="h-4 w-4 mr-2" />
                {t("team.roles.agent")}
              </DropdownMenuItem>
            </DropdownMenuSubContent>
          </DropdownMenuPortal>
        </DropdownMenuSub>
        {member.status === "Invited" && (
          <DropdownMenuItem onClick={() => onResendInvite(member.id)}>
            <RefreshCw className="h-4 w-4 mr-2" />
            {t("team.actions.resendInvite")}
          </DropdownMenuItem>
        )}
        <DropdownMenuSeparator />
        <AlertDialog>
          <AlertDialogTrigger asChild>
            <DropdownMenuItem
              onSelect={(e) => e.preventDefault()}
              className="text-destructive focus:text-destructive"
            >
              <Trash2 className="h-4 w-4 mr-2" />
              {t("team.actions.remove")}
            </DropdownMenuItem>
          </AlertDialogTrigger>
          <AlertDialogContent>
            <AlertDialogHeader>
              <AlertDialogTitle>{t("team.remove.title")}</AlertDialogTitle>
              <AlertDialogDescription>
                {t("team.remove.description", { name: member.name })}
              </AlertDialogDescription>
            </AlertDialogHeader>
            <AlertDialogFooter>
              <AlertDialogCancel>{t("common.cancel")}</AlertDialogCancel>
              <AlertDialogAction
                onClick={() => onDelete(member.id)}
                className="bg-destructive text-destructive-foreground hover:bg-destructive/90"
              >
                {t("team.actions.remove")}
              </AlertDialogAction>
            </AlertDialogFooter>
          </AlertDialogContent>
        </AlertDialog>
      </DropdownMenuContent>
    </DropdownMenu>
  );
}
