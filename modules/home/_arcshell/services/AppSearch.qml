pragma Singleton

import qs.config
import Quickshell
import Quickshell.Io

Singleton {
    id: root

    readonly property int maxResults: 32

    // Desktop entry id -> launch count. Loaded once, persisted on every launch.
    property var counts: ({})

    // All launchable applications. DesktopEntries scans asynchronously on
    // first access, so this binding warms the scan as soon as the launcher
    // loads and tracks apps (un)installed while the shell runs.
    readonly property var apps: DesktopEntries.applications.values.filter(e => !e.noDisplay)

    function query(text: string): var {
        const q = text.trim().toLowerCase();
        if (q.length === 0)
            return [];

        const scored = [];
        for (const e of root.apps) {
            const s = root.score(e, q);
            if (s > 0)
                scored.push({
                    entry: e,
                    score: s + 10 * Math.log1p(root.count(e))
                });
        }
        scored.sort((a, b) => (b.score - a.score) || (a.entry.name.length - b.entry.name.length) || a.entry.name.localeCompare(b.entry.name));
        return scored.slice(0, root.maxResults).map(x => x.entry);
    }

    function count(e: var): int {
        return root.counts[e.id] ?? 0;
    }

    // Base match score; 0 = no match.
    function score(e: var, q: string): int {
        const name = e.name.toLowerCase();
        if (name.startsWith(q))
            return 100;
        if (name.split(/[\s-]+/).some(w => w.startsWith(q)))
            return 80;
        if (name.includes(q))
            return 60;
        if (`${e.genericName}\n${e.keywords.join("\n")}`.toLowerCase().includes(q))
            return 40;
        if (root.subsequence(name, q))
            return 20;
        return 0;
    }

    function subsequence(hay: string, needle: string): bool {
        let i = 0;
        for (const c of hay) {
            if (c === needle[i])
                i++;
            if (i === needle.length)
                return true;
        }
        return false;
    }

    function launch(entry: var): void {
        Quickshell.execDetached([...Config.services.launcher.launchPrefix, ...entry.command]);
        root.counts[entry.id] = root.count(entry) + 1;
        countsFile.setText(JSON.stringify(root.counts));
    }

    FileView {
        id: countsFile

        path: Quickshell.statePath("launcher-frequency.json")
        onLoaded: {
            try {
                root.counts = JSON.parse(text());
            } catch (e) {
                root.counts = {};
            }
        }
        onLoadFailed: {} // First run: file absent, counts stays {}; created by first launch().
    }
}
