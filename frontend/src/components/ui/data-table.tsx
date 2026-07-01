"use client";

import {
  ColumnDef,
  flexRender,
  getCoreRowModel,
  getPaginationRowModel,
  useReactTable,
} from "@tanstack/react-table";

import {
  Table,
  TableBody,
  TableCell,
  TableHead,
  TableHeader,
  TableRow,
} from "@/components/ui/table";
import { Button } from "@/components/ui/button";
import { Input } from "@/components/ui/input";
import { Label } from "@/components/ui/label";
import {
  Select,
  SelectContent,
  SelectItem,
  SelectTrigger,
  SelectValue,
} from "@/components/ui/select";
import { useTranslation } from "react-i18next";

interface DataTableProps<TData, TValue> {
  columns: ColumnDef<TData, TValue>[];
  data: TData[];
  isLoading?: boolean;
  autoResetPageIndex?: boolean;
  // Server-side pagination props
  pageCount?: number;
  currentPage?: number;
  pageSize?: number;
  totalItems?: number;
  onPageChange?: (page: number) => void;
  onPageSizeChange?: (pageSize: number) => void;
  // Custom pagination options
  pageSizeOptions?: number[];
  showAdvancedPagination?: boolean;
}

const TableLoader = ({ columns }: { columns: number }) => {
  const { t } = useTranslation();

  return (
    <>
      <TableRow>
        <TableCell colSpan={columns} className="h-24 text-center">
          <div className="flex items-center justify-center">
            <div className="h-6 w-6 animate-spin rounded-full border-b-2 border-primary"></div>
            <span className="ml-2">{t("ui.common.loading")}</span>
          </div>
        </TableCell>
      </TableRow>
    </>
  );
};

export function DataTable<TData, TValue>({
  columns,
  data,
  isLoading = false,
  autoResetPageIndex = true,
  // Server-side pagination
  pageCount,
  currentPage = 1,
  pageSize = 10,
  totalItems,
  onPageChange,
  onPageSizeChange,
  // Custom pagination options
  pageSizeOptions = [10, 20, 50, 100],
  showAdvancedPagination = false,
}: DataTableProps<TData, TValue>) {
  const { t } = useTranslation();
  const isServerSide = pageCount !== undefined && onPageChange !== undefined;

  const table = useReactTable({
    data,
    columns,
    getCoreRowModel: getCoreRowModel(),
    getPaginationRowModel: isServerSide ? undefined : getPaginationRowModel(),
    autoResetPageIndex: autoResetPageIndex,
    pageCount: isServerSide ? pageCount : undefined,
    manualPagination: isServerSide,
  });

  const handlePageSizeChange = (newPageSize: string) => {
    const size = parseInt(newPageSize);
    if (isServerSide && onPageSizeChange) {
      onPageSizeChange(size);
    } else {
      table.setPageSize(size);
    }
  };

  const handlePageChange = (page: number) => {
    if (isServerSide && onPageChange) {
      onPageChange(page);
    } else {
      table.setPageIndex(page - 1);
    }
  };

  const getCurrentPage = () => {
    return isServerSide
      ? currentPage
      : table.getState().pagination.pageIndex + 1;
  };

  const getPageSize = () => {
    return isServerSide ? pageSize : table.getState().pagination.pageSize;
  };

  const getTotalPages = () => {
    if (isServerSide && totalItems) {
      return Math.ceil(totalItems / pageSize);
    }
    return table.getPageCount();
  };

  const getCanPreviousPage = () => {
    return isServerSide ? currentPage > 1 : table.getCanPreviousPage();
  };

  const getCanNextPage = () => {
    const totalPages = getTotalPages();
    return isServerSide ? currentPage < totalPages : table.getCanNextPage();
  };

  return (
    <div>
      <div className="rounded-md border">
        <Table>
          <TableHeader>
            {table.getHeaderGroups().map((headerGroup) => (
              <TableRow key={headerGroup.id}>
                {headerGroup.headers.map((header) => {
                  return (
                    <TableHead key={header.id}>
                      {header.isPlaceholder
                        ? null
                        : flexRender(
                            header.column.columnDef.header,
                            header.getContext()
                          )}
                    </TableHead>
                  );
                })}
              </TableRow>
            ))}
          </TableHeader>
          <TableBody>
            {isLoading ? (
              <TableLoader columns={columns.length} />
            ) : table.getRowModel().rows?.length ? (
              table.getRowModel().rows.map((row) => (
                <TableRow
                  key={row.id}
                  data-state={row.getIsSelected() && "selected"}
                >
                  {row.getVisibleCells().map((cell) => (
                    <TableCell key={cell.id}>
                      {flexRender(
                        cell.column.columnDef.cell,
                        cell.getContext()
                      )}
                    </TableCell>
                  ))}
                </TableRow>
              ))
            ) : (
              <TableRow>
                <TableCell
                  colSpan={columns.length}
                  className="h-24 text-center"
                >
                  {t("ui.common.noResults")}
                </TableCell>
              </TableRow>
            )}
          </TableBody>
        </Table>
      </div>

      {/* Pagination */}
      {(isServerSide || table.getPageCount() > 0) && (
        <div className="flex flex-col sm:flex-row items-start sm:items-center justify-between gap-4 py-4">
          <div className="flex flex-col sm:flex-row items-start sm:items-center gap-4">
            {/* Pagination Info */}
            {isServerSide && totalItems ? (
              <p className="text-sm text-gray-600 dark:text-gray-400">
                {t("ui.pagination.showingItems", {
                  from: (currentPage - 1) * pageSize + 1,
                  to: Math.min(currentPage * pageSize, totalItems),
                  total: totalItems,
                })}
              </p>
            ) : (
              <p className="text-sm text-gray-600 dark:text-gray-400">
                {t("ui.pagination.showingItems", {
                  from:
                    table.getState().pagination.pageIndex *
                      table.getState().pagination.pageSize +
                    1,
                  to: Math.min(
                    (table.getState().pagination.pageIndex + 1) *
                      table.getState().pagination.pageSize,
                    table.getRowCount()
                  ),
                  total: table.getRowCount(),
                })}
              </p>
            )}

            {/* Page Size Selector */}
            <div className="flex items-center gap-2">
              <Label htmlFor="pageSize" className="text-sm">
                {t("ui.pagination.show")}
              </Label>
              <Select
                value={getPageSize().toString()}
                onValueChange={handlePageSizeChange}
              >
                <SelectTrigger className="w-20">
                  <SelectValue />
                </SelectTrigger>
                <SelectContent>
                  {pageSizeOptions.map((size) => (
                    <SelectItem key={size} value={size.toString()}>
                      {size}
                    </SelectItem>
                  ))}
                </SelectContent>
              </Select>
            </div>
          </div>

          {/* Pagination Controls */}
          {showAdvancedPagination ? (
            <div className="flex items-center gap-2">
              <Button
                variant="outline"
                size="sm"
                onClick={() => handlePageChange(1)}
                disabled={!getCanPreviousPage()}
              >
                {t("ui.pagination.first")}
              </Button>
              <Button
                variant="outline"
                size="sm"
                onClick={() => handlePageChange(getCurrentPage() - 1)}
                disabled={!getCanPreviousPage()}
              >
                {t("ui.common.previous")}
              </Button>

              <div className="flex items-center gap-1">
                <span className="text-sm">{t("ui.pagination.page")}</span>
                <Input
                  type="number"
                  min="1"
                  max={getTotalPages()}
                  value={getCurrentPage()}
                  onChange={(e) => {
                    const page = parseInt(e.target.value);
                    if (page >= 1 && page <= getTotalPages()) {
                      handlePageChange(page);
                    }
                  }}
                  className="w-16 text-center"
                />
                <span className="text-sm">
                  {t("ui.pagination.of", { total: getTotalPages() })}
                </span>
              </div>

              <Button
                variant="outline"
                size="sm"
                onClick={() => handlePageChange(getCurrentPage() + 1)}
                disabled={!getCanNextPage()}
              >
                {t("ui.common.next")}
              </Button>
              <Button
                variant="outline"
                size="sm"
                onClick={() => handlePageChange(getTotalPages())}
                disabled={!getCanNextPage()}
              >
                {t("ui.pagination.last")}
              </Button>
            </div>
          ) : (
            <div className="flex items-center space-x-2">
              <Button
                variant="outline"
                size="sm"
                onClick={() => handlePageChange(getCurrentPage() - 1)}
                disabled={!getCanPreviousPage()}
              >
                {t("ui.common.previous")}
              </Button>
              <Button
                variant="outline"
                size="sm"
                onClick={() => handlePageChange(getCurrentPage() + 1)}
                disabled={!getCanNextPage()}
              >
                {t("ui.common.next")}
              </Button>
            </div>
          )}
        </div>
      )}
    </div>
  );
}
