pragma ComponentBehavior: Bound

import qs.config.tokens.feature as FeatureTokens
import QtQuick

// Reversed (point-down) equilateral triangle: three overshot strokes with
// round caps, each fading to transparent at both ends — the bar's sibling of
// the panels' BorderLine whiskers. Drawn on a Canvas because ShapePath has no
// stroke gradients and BorderLine only handles axis-aligned lines.
Canvas {
    id: root

    required property FeatureTokens.BarDecorator theme

    implicitWidth: theme.size
    implicitHeight: theme.size

    // The horizontal top edge is the widest extent: side + overshoot and cap
    // radius on both sides must fit the canvas width.
    readonly property real side: width - 2 * (theme.overshoot + theme.thickness / 2)
    readonly property real triHeight: side * Math.sqrt(3) / 2

    onPaint: {
        const ctx = getContext("2d");
        ctx.clearRect(0, 0, width, height);
        ctx.lineWidth = theme.thickness;
        ctx.lineCap = "round";

        const o = theme.overshoot;
        const r = theme.thickness / 2;
        // Drawn vertical extent: triHeight + sqrt(3)*o (the diagonal edges'
        // overshoots rise above the top edge / sink below the apex) + 2r
        // (caps). Center that extent, then offset to the top edge's y.
        const yTop = (height - (triHeight + Math.sqrt(3) * o + 2 * r)) / 2
                   + (Math.sqrt(3) / 2) * o + r;
        const cx = width / 2;
        const a = Qt.point(cx - side / 2, yTop);   // top-left corner
        const b = Qt.point(cx + side / 2, yTop);   // top-right corner
        const c = Qt.point(cx, yTop + triHeight);  // bottom apex

        strokeEdge(ctx, a, b, o);
        strokeEdge(ctx, b, c, o);
        strokeEdge(ctx, c, a, o);
    }

    // One edge, extended `o` past both corners, stroked with the BorderLine
    // gradient: transparent -> color -> color -> transparent.
    function strokeEdge(ctx, from, to, o) {
        const dx = to.x - from.x;
        const dy = to.y - from.y;
        const len = Math.hypot(dx, dy);
        const ux = dx / len;
        const uy = dy / len;
        const x0 = from.x - ux * o;
        const y0 = from.y - uy * o;
        const x1 = to.x + ux * o;
        const y1 = to.y + uy * o;
        // Fade fraction of the extended length, clamped so fades never overlap.
        const fade = Math.min(0.5, theme.fade / (len + 2 * o));

        const grad = ctx.createLinearGradient(x0, y0, x1, y1);
        grad.addColorStop(0, Qt.alpha(theme.color, 0));
        grad.addColorStop(fade, theme.color);
        grad.addColorStop(1 - fade, theme.color);
        grad.addColorStop(1, Qt.alpha(theme.color, 0));
        ctx.strokeStyle = grad;

        ctx.beginPath();
        ctx.moveTo(x0, y0);
        ctx.lineTo(x1, y1);
        ctx.stroke();
    }

    // Canvas never repaints on its own when bindings read inside onPaint
    // change; repaint on every token change (theme is a live JsonObject —
    // shell.json edits hot-reload through these signals).
    onThemeChanged: requestPaint()
    Connections {
        target: root.theme
        function onSizeChanged() { root.requestPaint(); }
        function onThicknessChanged() { root.requestPaint(); }
        function onOvershootChanged() { root.requestPaint(); }
        function onFadeChanged() { root.requestPaint(); }
        function onColorChanged() { root.requestPaint(); }
    }
}
