pragma Singleton
pragma ComponentBehavior: Bound

import QtQuick
import Quickshell
import Quickshell.Io
import Quickshell.Services.Notifications
import qs.services.notifications as Tracked

Singleton {
    id: root

    // Tracked notifications, newest first.
    property list<Tracked.Notification> list: []
    readonly property list<Tracked.Notification> notClosed: list.filter(n => !n.closed)
    readonly property list<Tracked.Notification> popups: list.filter(n => n.popup)
    property alias doNotDisturb: props.doNotDisturb

    // Emitted after an incoming notification has been prepended to `list`.
    signal received()

    PersistentProperties {
        id: props

        property bool doNotDisturb

        reloadableId: "notifications"
    }

    function shouldShowPopup(): bool {
        return !props.doNotDisturb;
    }

    NotificationServer {
        id: server

        keepOnReload: true
        actionsSupported: true
        bodyHyperlinksSupported: true
        bodyImagesSupported: true
        bodyMarkupSupported: true
        imageSupported: true
        persistenceSupported: true

        onNotification: notif => {
            notif.tracked = true;

            const comp = notificationsC.createObject(root, {
                // Re-emitted pre-reload notifications must not re-open the tray.
                popup: root.shouldShowPopup() && !notif.lastGeneration,
                notification: notif
            });
            root.list = [comp, ...root.list];
            if (!notif.lastGeneration)
                root.received();
        }
    }

    IpcHandler {
        function clear(): void {
            for (const notif of root.list.slice())
                notif.close();
        }

        function isDndEnabled(): bool {
            return props.doNotDisturb;
        }

        function toggleDnd(): void {
            props.doNotDisturb = !props.doNotDisturb;
        }

        function enableDnd(): void {
            props.doNotDisturb = true;
        }

        function disableDnd(): void {
            props.doNotDisturb = false;
        }

        target: "notifications"
    }

    Component {
        id: notificationsC

        Tracked.Notification {}
    }
}
