pragma Singleton

import qs.config
import Quickshell

Singleton {
    id: root

    function query(text: string): var {
        const cmd = text.trim();
        // Empty terminalCommand disables the mode, like qalcPath/emojiData.
        if (cmd.length === 0 || Config.services.launcher.terminalCommand.length === 0)
            return [];
        // `shellCommand`, not `command`: app rows are desktop entries and
        // already carry `.command`, which launchSelected() must not confuse
        // with this mode's rows.
        return [{ shellCommand: cmd, name: cmd }];
    }

    function run(item: var): void {
        // sh -c so arguments, quotes, and pipes behave as typed; the
        // terminal closes when the command exits. `sh` resolves via PATH,
        // same as wl-copy in CalcSearch.
        Quickshell.execDetached([...Config.services.launcher.launchPrefix, ...Config.services.launcher.terminalCommand, "sh", "-c", item.shellCommand]);
    }
}
