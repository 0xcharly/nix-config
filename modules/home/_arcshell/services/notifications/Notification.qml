pragma ComponentBehavior: Bound

import QtQuick
import Quickshell.Services.Notifications
import qs.services

QtObject {
    id: root

    property bool popup
    property bool closed
    // Card expansion (full body + action row). Lives here, not on the
    // delegate, so it survives delegate recreation when the list changes.
    property bool expanded
    property var locks: new Set()

    property date time: new Date()
    property string timeStr: qsTr("now")

    readonly property Timer timeStrTimer: Timer {
        running: !root.closed
        repeat: true
        interval: 5000
        onTriggered: root.updateTimeStr()
    }

    property Notification notification
    property string notificationId
    property string summary
    property string body
    property int urgency: NotificationUrgency.Normal

    // True when the body contains fdo-spec/HTML markup or entities.
    readonly property bool bodyIsHtml: /<\/?(?:b|strong|i|em|u|s|a|img|br|p|div|span|font|h[1-6]|ul|ol|li|pre|code|tt|blockquote)\b[^>]*\/?>|&(?:[a-zA-Z]+|#\d+|#x[0-9a-fA-F]+);/.test(body)
    // Conservative Markdown detection: only unambiguous constructs.
    readonly property bool bodyIsMarkdown: !bodyIsHtml && /\*\*[^*\n]+\*\*|__[^_\n]+__|`[^`\n]+`|\[[^\]\n]+\]\([^)\s]+\)|^#{1,6}\s+\S|^[-*]\s+\S/m.test(body)
    readonly property int bodyFormat: bodyIsHtml || bodyIsMarkdown ? Text.StyledText : Text.PlainText
    readonly property string bodyText: bodyIsMarkdown ? markdownToStyledText(body) : body

    readonly property Connections conn: Connections {
        function onClosed(): void {
            root.close();
        }

        function onSummaryChanged(): void {
            root.summary = root.notification.summary;
        }

        function onBodyChanged(): void {
            root.body = root.notification.body;
        }

        function onUrgencyChanged(): void {
            root.urgency = root.notification.urgency;
        }

        target: root.notification
    }

    function updateTimeStr(): void {
        const diff = Date.now() - time.getTime();
        const m = Math.floor(diff / 60000);

        if (m < 1) {
            timeStr = qsTr("now");
            timeStrTimer.interval = 5000;
        } else {
            const h = Math.floor(m / 60);
            const d = Math.floor(h / 24);

            if (d > 0) {
                timeStr = `${d}d`;
                timeStrTimer.interval = 3600000;
            } else if (h > 0) {
                timeStr = `${h}h`;
                timeStrTimer.interval = 300000;
            } else {
                timeStr = `${m}m`;
                timeStrTimer.interval = m < 10 ? 30000 : 60000;
            }
        }
    }

    // Converts a Markdown subset to Text.StyledText HTML. StyledText has no
    // monospace tag, so code spans keep their content unstyled (backticks
    // stripped). Headings render bold: StyledText's <h1>-<h6> sizes are
    // oversized for a notification card.
    function markdownToStyledText(md: string): string {
        let s = md.replace(/&/g, "&amp;").replace(/</g, "&lt;").replace(/>/g, "&gt;");
        s = s.replace(/`([^`\n]+)`/g, "$1");
        s = s.replace(/\*\*([^*\n]+)\*\*/g, "<b>$1</b>");
        s = s.replace(/__([^_\n]+)__/g, "<b>$1</b>");
        // Italic content must not start/end with whitespace ("2 * 3 * 4" stays plain).
        s = s.replace(/\*(\S(?:[^*\n]*\S)?)\*/g, "<i>$1</i>");
        s = s.replace(/\[([^\]\n]+)\]\(([^)\s]+)\)/g, '<a href="$2">$1</a>');
        s = s.replace(/^#{1,6}\s+(.+)$/gm, "<b>$1</b>");
        s = s.replace(/^[-*]\s+/gm, "\u2022 ");
        return s.replace(/\n/g, "<br/>");
    }

    function lock(item: Item): void {
        locks.add(item);
    }

    function unlock(item: Item): void {
        locks.delete(item);
        if (closed)
            close();
    }

    function close(): void {
        closed = true;
        if (locks.size === 0 && Notifications.list.includes(this)) {
            Notifications.list = Notifications.list.filter(n => n !== this);
            notification?.dismiss();
            destroy();
        }
    }

    Component.onCompleted: {
        if (!notification) {
            return;
        }

        notificationId = notification.id;
        summary = notification.summary;
        body = notification.body;
        urgency = notification.urgency;
    }
}
