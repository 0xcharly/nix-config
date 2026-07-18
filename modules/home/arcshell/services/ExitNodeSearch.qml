pragma Singleton

import qs.services
import Quickshell
import Quickshell.Io
import QtQuick

// Tailscale exit-node selector backend: wraps `tailscale exit-node
// list`/`suggest` (refreshed every time the launcher enters exit-node
// mode) and applies selections with `tailscale set`.
Singleton {
    id: root

    // Parsed rows: { hostname, name, glyph, selected }. hostname is the
    // dot-trimmed FQDN as printed by the CLI.
    property var entries: []
    // Dot-trimmed FQDN of `tailscale exit-node suggest`, "" while
    // unknown/unavailable.
    property string suggested: ""

    // Flag emoji from the ISO country prefix of Mullvad node names
    // ("jp-tyo-wg-002..." -> regional indicators J+P).
    function flagFor(hostname: string): string {
        const m = hostname.match(/^([a-z]{2})-/);
        if (!m)
            return "";
        const cc = m[1].toUpperCase();
        return String.fromCodePoint(0x1F1E6 + cc.charCodeAt(0) - 65, 0x1F1E6 + cc.charCodeAt(1) - 65);
    }

    function query(text: string): var {
        const q = text.trim().toLowerCase();
        // Suggested node ranks first: the first row is preselected, so
        // Enter right after entering the mode accepts the suggestion.
        // Then the currently selected node, then alphabetical.
        const nodes = root.entries
            .map(e => Object.assign({}, e, { suggested: e.hostname === root.suggested }))
            .filter(e => q.length === 0 || e.name.toLowerCase().includes(q))
            .sort((a, b) => (b.suggested - a.suggested) || (b.selected - a.selected) || a.name.localeCompare(b.name));
        // The CLI list collapses Mullvad nodes to the best one per city, so
        // the latency-based suggestion can name a node absent from the list
        // (e.g. suggest says jp-tyo-wg-002 while the list shows
        // jp-tyo-wg-001). Synthesize a row so Enter-on-entry can always
        // accept the suggestion.
        if (root.suggested !== "" && !root.entries.some(e => e.hostname === root.suggested) && (q.length === 0 || root.suggested.toLowerCase().includes(q))) {
            nodes.unshift({
                hostname: root.suggested,
                name: root.suggested,
                glyph: root.flagFor(root.suggested),
                selected: false,
                suggested: true
            });
        }
        // "Disabled" (clears the exit node) slots directly below the
        // suggested row — prominent without stealing the Enter-to-accept
        // spot — and carries the checkmark when no exit node is active.
        if (q.length === 0 || qsTr("Disabled").toLowerCase().includes(q)) {
            const disabled = {
                hostname: "",
                name: qsTr("Disabled"),
                glyph: "",
                selected: !root.entries.some(e => e.selected),
                suggested: false
            };
            nodes.splice(nodes.length > 0 && nodes[0].suggested ? 1 : 0, 0, disabled);
        }
        return nodes;
    }

    // Selecting the "Disabled" row (hostname "") clears the exit node.
    // The CLI prints dot-trimmed FQDNs but `set --exit-node=` wants the
    // trailing-dot form (same as node-skl's pinned exitNode).
    // allow-lan-access is a persistent pref applied only when its flag is
    // passed: set it true with every node selection; deliberately left
    // untouched when disabling so it survives exit-node round-trips.
    function select(node: var): void {
        if (node.hostname === "")
            Quickshell.execDetached(["tailscale", "set", "--exit-node="]);
        else
            Quickshell.execDetached(["tailscale", "set", "--exit-node=" + node.hostname + ".", "--exit-node-allow-lan-access=true"]);
    }

    // Refresh on every entry into the mode: launcherMode is reset to
    // "default" at every open site, so entering always fires this.
    Connections {
        target: UiState

        function onLauncherModeChanged() {
            if (UiState.launcherMode === "exit-node") {
                listProc.running = true;
                suggestProc.running = true;
            }
        }
    }

    Process {
        id: listProc

        command: ["tailscale", "exit-node", "list"]
        stdout: StdioCollector {
            onStreamFinished: {
                const out = [];
                for (const line of text.split("\n")) {
                    const trimmed = line.trim();
                    // Header, blank spacer, and trailing "#" hint lines.
                    if (trimmed === "" || trimmed.startsWith("#") || trimmed.startsWith("IP"))
                        continue;
                    // tabwriter pads columns with >=5 spaces; cities like
                    // "Seattle, WA" only contain single spaces.
                    const cols = trimmed.split(/\s{2,}/);
                    if (cols.length < 5)
                        continue;
                    const [ip, hostname, country, city, status] = cols;
                    // Countries with several cities get an "Any" roll-up row
                    // duplicating a concrete row below it.
                    if (city === "Any")
                        continue;
                    out.push({
                        hostname,
                        name: country === "-" ? hostname : `${hostname} (${city}, ${country})`,
                        glyph: country === "-" ? "" : root.flagFor(hostname),
                        // "-" | "selected" | "selected but offline; …" | "offline; …"
                        selected: status.startsWith("selected")
                    });
                }
                root.entries = out;
            }
        }
    }

    Process {
        id: suggestProc

        command: ["tailscale", "exit-node", "suggest"]
        stdout: StdioCollector {
            onStreamFinished: {
                // "Suggested exit node: jp-tyo-wg-002.mullvad.ts.net." —
                // printed with the FQDN root dot; list rows are dot-trimmed.
                const m = text.match(/Suggested exit node: (\S+)/);
                root.suggested = m ? m[1].replace(/\.$/, "") : "";
            }
        }
    }
}
