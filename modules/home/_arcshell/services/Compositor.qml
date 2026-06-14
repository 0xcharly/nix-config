pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Hyprland

// https://wiki.hypr.land/Configuring/Dispatchers/
Singleton {
    id: root

    property var workspaces: Hyprland.workspaces

    function monitorFor(screen: ShellScreen): var {
        return Hyprland.monitorFor(screen);
    }

    function workspacesFor(screen: ShellScreen): var {
        let monitorId = monitorFor(screen)?.id;
        return root.workspaces.values.filter(ws => {
            return ws.monitor?.id === monitorId;
        });
    }

    function getWorkspaceName(workspace: HyprlandWorkspace): string {
        return workspace?.name || workspace?.id || "";
    }

    function isWorkspaceActive(workspace: HyprlandWorkspace): bool {
        return workspace?.active || false;
    }

    function goToWorkspace(workspace: HyprlandWorkspace): void {
        goToWorkspaceId(workspace?.id || -1);
    }

    function goToWorkspaceId(workspaceId: int): void {
        if (workspaceId < 0)
            return;
        if (root.activeWorkspaceId === workspaceId)
            return;
        Hyprland.dispatch(`workspace ${workspaceId}`);
    }

    function goToNextOccupiedWorkspace(): void {
        Hyprland.dispatch("workspace m+1");
    }

    function goToPreviousOccupiedWorkspace(): void {
        Hyprland.dispatch("workspace m-1");
    }
}
