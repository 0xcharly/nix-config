pragma Singleton

import qs.config
import Quickshell
import Quickshell.Io

Singleton {
    id: root

    readonly property int maxResults: 32

    // Raw parses of emoji-test.txt (CLDR names, includes skin-tone and ZWJ
    // sequences) and UnicodeData.txt. Both files load asynchronously; the
    // search index rebuilds as each lands.
    property var emoji: []
    property var characters: []

    // Search index. `entries` are {glyph, name} sorted by (name length,
    // name), emoji names winning for glyphs present in both sources;
    // `haystack` holds one lowercase name per line, starting at offset
    // `starts[i]`. Queries run as native regex scans over the one string:
    // per-entry interpreted JS takes hundreds of ms at ~40k entries.
    property var entries: []
    property string haystack: ""
    property var starts: []

    onEmojiChanged: root.rebuild()
    onCharactersChanged: root.rebuild()

    function rebuild(): void {
        // Emoji names win for glyphs present in both sources. Overlap is
        // only possible for single-codepoint emoji, and every UCD entry is
        // a single codepoint, so a codepoint bitmap dedups in O(1) per
        // entry. (QV4's Set and string-keyed objects both degenerate at
        // this key count, costing seconds.)
        const emojiCp = new Uint8Array(0x110000);
        for (const g of root.emoji) {
            const cp = g.glyph.codePointAt(0);
            if (g.glyph.length === (cp > 0xFFFF ? 2 : 1))
                emojiCp[cp] = 1;
        }
        const pool = root.emoji.slice();
        for (const g of root.characters) {
            if (emojiCp[g.glyph.codePointAt(0)] === 0)
                pool.push(g);
        }

        // (length, name) order makes first-matched = best within a tier.
        // Sort composite key strings natively: an interpreted comparator
        // over ~40k entries takes seconds. The length prefix is a single
        // char code, so lexicographic key order is (length, name) order;
        // "\u0001" never occurs in names and separates the back-reference.
        const keys = new Array(pool.length);
        for (let i = 0; i < pool.length; i++)
            keys[i] = String.fromCharCode(33 + pool[i].name.length) + pool[i].name + "\u0001" + i;
        keys.sort();

        const all = new Array(pool.length);
        const starts = new Array(pool.length);
        const names = new Array(pool.length);
        let off = 0;
        for (let i = 0; i < keys.length; i++) {
            const k = keys[i];
            const g = pool[parseInt(k.slice(k.indexOf("\u0001") + 1), 10)];
            all[i] = g;
            starts[i] = off;
            names[i] = g.name;
            off += g.name.length + 1;
        }
        root.haystack = names.join("\n") + "\n";
        root.starts = starts;
        root.entries = all; // Set last: signals consumers with the index ready.
    }

    function query(text: string): var {
        const q = text.trim().toLowerCase();
        if (q.length === 0 || root.entries.length === 0)
            return [];

        const esc = s => s.replace(/[.*+?^${}()|[\]\\]/g, "\\$&");
        // Same tiers as AppSearch.score, best first: name prefix, word
        // prefix, substring, character subsequence (pointless for a single
        // character, where it equals substring). No pattern can match "\n",
        // so every match stays within a single name.
        const tiers = [new RegExp("^" + esc(q), "gm"), new RegExp("[ -]" + esc(q), "g"), new RegExp(esc(q), "g")];
        if (q.length > 1)
            tiers.push(new RegExp(Array.from(q, esc).join("[^\\n]*"), "g"));

        const hay = root.haystack;
        const starts = root.starts;
        const out = [];
        const picked = new Set();
        for (const re of tiers) {
            let m;
            while (out.length < root.maxResults && (m = re.exec(hay)) !== null) {
                const i = root.lineOf(m.index);
                if (!picked.has(i)) {
                    picked.add(i);
                    out.push(root.entries[i]);
                }
                // Skip to the next name: at most one hit per name and tier.
                re.lastIndex = i + 1 < starts.length ? starts[i + 1] : hay.length;
            }
            if (out.length >= root.maxResults)
                break;
        }
        return out;
    }

    // Index of the name whose haystack line contains `offset`.
    function lineOf(offset: int): int {
        const starts = root.starts;
        let lo = 0;
        let hi = starts.length - 1;
        while (lo < hi) {
            const mid = (lo + hi + 1) >> 1;
            if (starts[mid] <= offset)
                lo = mid;
            else
                hi = mid - 1;
        }
        return lo;
    }

    function copy(item: var): void {
        // "--" guards glyphs that look like flags (e.g. "-").
        Quickshell.execDetached(["wl-copy", "--", item.glyph]);
    }

    FileView {
        path: Config.services.launcher.emojiData
        onLoaded: {
            const out = [];
            for (const line of text().split("\n")) {
                if (!line.includes("; fully-qualified"))
                    continue;
                const m = line.match(/#\s(\S+)\sE[\d.]+\s(.+)$/);
                if (m)
                    out.push({ glyph: m[1], name: m[2].toLowerCase() });
            }
            root.emoji = out;
        }
        onLoadFailed: {} // Path empty or missing: glyph mode yields no results.
    }

    FileView {
        path: Config.services.launcher.unicodeData
        onLoaded: {
            const out = [];
            for (const line of text().split("\n")) {
                const f = line.split(";");
                // Skip range markers/controls ("<control>", "<CJK Ideograph, First>", ...)
                // and keep only letters, numbers, punctuation, symbols.
                if (f.length < 3 || f[1].startsWith("<") || !"LNPS".includes(f[2][0]))
                    continue;
                out.push({ glyph: String.fromCodePoint(parseInt(f[0], 16)), name: f[1].toLowerCase() });
            }
            root.characters = out;
        }
        onLoadFailed: {}
    }
}
