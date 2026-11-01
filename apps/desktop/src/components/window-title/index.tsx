import { useActiveFilePath, useActiveTab, useOpenFiles } from "@/hooks/use-tabs";
import { pageKind } from "@/components/editor-area/page-kinds";
import { getFileName } from "@/lib/paths";
import { useWindowTitle } from "./use-window-title";

export function WindowTitle() {
  const activeTab = useActiveTab();
  const activeFilePath = useActiveFilePath();
  const openFiles = useOpenFiles();

  const title = (() => {
    if (!activeTab) return "Lekhok";
    if (!activeFilePath) {
      const label = pageKind(activeTab.location).title(activeTab.location);
      return `${label} - Lekhok`;
    }
    const file = openFiles.get(activeFilePath);
    const name = getFileName(activeFilePath);
    return file?.isDirty ? `${name} (unsaved) - Lekhok` : `${name} - Lekhok`;
  })();

  useWindowTitle(title);

  return null;
}
