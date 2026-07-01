import { useState, useEffect } from "react";
import {
  Table,
  TableBody,
  TableCell,
  TableHead,
  TableHeader,
  TableRow,
} from "@/components/ui/table";
import { TeamMember } from "@/lib/interfaces";
import { TeamMemberRow } from "./team-member-row";
import { useTranslation } from "react-i18next";

interface TeamMembersTableProps {
  members: TeamMember[];
  onDelete: (id: string) => void;
  onUpdateRole: (id: string, role: "admin" | "agent") => void;
  onResendInvite: (email: string) => void;
}

export function TeamMembersTable({
  members,
  onDelete,
  onUpdateRole,
  onResendInvite,
}: TeamMembersTableProps) {
  const { t } = useTranslation();
  const [isMobile, setIsMobile] = useState(false);

  useEffect(() => {
    const checkIsMobile = () => setIsMobile(window.innerWidth < 768);
    checkIsMobile();
    window.addEventListener("resize", checkIsMobile);
    return () => window.removeEventListener("resize", checkIsMobile);
  }, []);

  return (
    <>
      <div className="border rounded-md overflow-x-auto">
        <Table>
          <TableHeader>
            <TableRow>
              <TableHead>{t("team.columns.name")}</TableHead>
              <TableHead className={isMobile ? "hidden md:table-cell" : ""}>
                {t("team.columns.role")}
              </TableHead>
              <TableHead className={isMobile ? "hidden md:table-cell" : ""}>
                {t("team.columns.status")}
              </TableHead>
              <TableHead className="text-right">
                {t("team.columns.actions")}
              </TableHead>
            </TableRow>
          </TableHeader>
          <TableBody>
            {members.length === 0 ? (
              <TableRow>
                <TableCell
                  colSpan={5}
                  className="text-center py-8 text-muted-foreground"
                >
                  {t("team.empty")}
                </TableCell>
              </TableRow>
            ) : (
              members.map((member) => (
                <TeamMemberRow
                  key={member.id}
                  member={member}
                  onDelete={onDelete}
                  onUpdateRole={onUpdateRole}
                  onResendInvite={onResendInvite}
                />
              ))
            )}
          </TableBody>
        </Table>
      </div>
    </>
  );
}
