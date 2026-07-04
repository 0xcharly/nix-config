pragma Singleton
pragma ComponentBehavior: Bound

import qs.config
import QtQuick
import Quickshell
import Quickshell.Io

Singleton {
    id: root

    // Expression whose result is shown, and the one being evaluated. A
    // superseded run is not killed; its output is dropped on arrival
    // because its expression no longer matches `pending` (kill-and-restart
    // on one shared Process races its collector against the next run).
    property string evaluated: ""
    property string pending: ""
    property var results: []

    function query(text: string): var {
        const q = text.trim();
        const qalc = Config.services.launcher.qalcPath;
        // Never spawn with an empty expression: `qalc -t ''` hangs on an
        // interactive prompt.
        if (q.length === 0 || qalc === "") {
            root.evaluated = "";
            root.pending = "";
            // Guarded write: `var` assignments always re-emit resultsChanged,
            // and the launcher's onResultsChanged handler requeries — an
            // unconditional reset here would recurse until stack overflow.
            if (root.results.length !== 0)
                root.results = [];
            return [];
        }
        if (q !== root.evaluated && q !== root.pending) {
            root.pending = q;
            const proc = qalcProcess.createObject(root, { expression: q });
            proc.command = [qalc, "-t", q];
            proc.running = true;
        }
        // The previous result stays visible for the ~100ms a run takes,
        // avoiding per-keystroke row/height flicker.
        return root.results;
    }

    function copy(item: var): void {
        // "--" guards results that look like flags (e.g. "-1").
        Quickshell.execDetached(["wl-copy", "--", item.result]);
    }

    Component {
        id: qalcProcess

        Process {
            id: proc

            required property string expression

            // Stable number formatting regardless of session locale.
            environment: ({
                    LANG: "C.UTF-8",
                    LC_ALL: "C.UTF-8"
                })

            stdout: StdioCollector {
                onStreamFinished: {
                    if (proc.expression === root.pending) {
                        root.evaluated = proc.expression;
                        // qalc -t output is single-line in practice; the
                        // join guards exotic multiline answers.
                        const out = text.trim().split("\n").join("; ");
                        root.results = out.length === 0 ? [] : [{ result: out, name: `${proc.expression} = ${out}` }];
                    }
                    proc.destroy();
                }
            }
        }
    }
}
