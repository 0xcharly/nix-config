pragma Singleton
pragma ComponentBehavior: Bound

import QtQuick
import Quickshell
import Quickshell.Io
import Quickshell.Services.Notifications
import qs.services.notifications

Singleton {
    id: root

    property list<Notifications> list: []
    readonly property list<Notifications> notClosed: list.filter(n => !n.closed)
    readonly property list<Notifications> popups: list.filter(n => n.popup)
    property alias doNotDisturb: props.doNotDisturb

    property bool loaded

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

        keepOnReload: false
        actionsSupported: true
        bodyHyperlinksSupported: true
        bodyImagesSupported: true
        bodyMarkupSupported: true
        imageSupported: true
        persistenceSupported: true

        onNotification: notif => {
            notif.tracked = true;

            const comp = notificationsC.createObject(root, {
                popup: root.shouldShowPopup(),
                notification: notif
            });
            root.list = [comp, ...root.list];
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

        Notification {}
    }
}
