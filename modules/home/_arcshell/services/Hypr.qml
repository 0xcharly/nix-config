pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Hyprland

// https://quickshell.org/docs/v0.1.0/types/Quickshell.Hyprland/Hyprland/
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
        if (workspaceId < 0) {
            return;
        }
        if (Hyprland.focusedWorkspace?.id === workspaceId) {
            return;
        }
        // This Hyprland's control socket evaluates Lua: `dispatch X` is wrapped
        // as `hl.dispatch(X)`, so X must be an hl.dsp.* dispatcher expression.
        // Upstream strings like "workspace 2" fail to parse.
        Hyprland.dispatch(`hl.dsp.focus({ workspace = ${workspaceId} })`);
    }

    function goToNextOccupiedWorkspace(): void {
        Hyprland.dispatch('hl.dsp.focus({ workspace = "m+1" })');
    }

    function goToPreviousOccupiedWorkspace(): void {
        Hyprland.dispatch('hl.dsp.focus({ workspace = "m-1" })');
    }

    function goToFirstEmptyWorkspace(): void {
        Hyprland.dispatch('hl.dsp.focus({ workspace = "empty" })');
    }
}
