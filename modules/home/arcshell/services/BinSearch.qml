pragma Singleton

import qs.config
import Quickshell
import Quickshell.Io
import QtQuick

Singleton {
    id: root

    readonly property int maxResults: 32

    // One {binary, name} per unique basename: `binary` is the absolute
    // path, first PATH dir winning, like execvp resolution. `binary` and
    // not `command`/`result`/`glyph`/`shellCommand`: launchSelected()
    // discriminates rows by field, and those are taken.
    property var entries: []

    function query(text: string): var {
        const q = text.trim().toLowerCase();
        // Empty terminalCommand disables the mode, like qalcPath.
        if (q.length === 0 || Config.services.launcher.terminalCommand.length === 0)
            return [];

        const scored = [];
        for (const e of root.entries) {
            const s = root.score(e.name, q);
            if (s > 0)
                scored.push({ entry: e, score: s });
        }
        scored.sort((a, b) => (b.score - a.score) || (a.entry.name.length - b.entry.name.length) || a.entry.name.localeCompare(b.entry.name));
        return scored.slice(0, root.maxResults).map(x => x.entry);
    }

    // AppSearch.score's tiers minus the keyword tier (binaries have no
    // metadata); word separators are -_. instead of whitespace.
    function score(name: string, q: string): int {
        const n = name.toLowerCase();
        if (n.startsWith(q))
            return 100;
        if (n.split(/[-_.]+/).some(w => w.startsWith(q)))
            return 80;
        if (n.includes(q))
            return 60;
        if (AppSearch.subsequence(n, q))
            return 20;
        return 0;
    }

    function run(item: var): void {
        // Absolute path: the terminal's PATH may differ from the shell's.
        // No arguments by design; the "$" mode covers those.
        Quickshell.execDetached([...Config.services.launcher.launchPrefix, ...Config.services.launcher.terminalCommand, item.binary]);
    }

    Process {
        id: scanProc

        running: true
        // Pure sh: needs nothing beyond PATH itself. The glob skips
        // dotfiles; a missing/empty dir leaves the glob unexpanded and
        // [ -f ] rejects it. `exit 0` keeps a trailing failed -x test from
        // surfacing as a nonzero process exit.
        command: ["sh", "-c", "IFS=:; for d in $PATH; do for f in \"$d\"/*; do [ -f \"$f\" ] && [ -x \"$f\" ] && printf '%s\\n' \"$f\"; done; done; exit 0"]

        stdout: StdioCollector {
            onStreamFinished: {
                const seen = new Set();
                const out = [];
                for (const line of text.split("\n")) {
                    if (line.length === 0)
                        continue;
                    const name = line.slice(line.lastIndexOf("/") + 1);
                    if (!seen.has(name)) {
                        seen.add(name);
                        out.push({ binary: line, name });
                    }
                }
                root.entries = out;
            }
        }
    }

    Connections {
        target: UiState

        function onShowLauncherChanged() {
            // PATH dir contents change without an arcshell restart (nix
            // rebuilds swap profile contents), so rescan on every open:
            // ~12ms for ~1.2k files, async, results land via entriesChanged.
            if (UiState.showLauncher)
                scanProc.running = true;
        }
    }
}
