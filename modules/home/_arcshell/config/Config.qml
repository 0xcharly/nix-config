pragma Singleton

import qs.config
import qs.config.tokens
import Quickshell
import Quickshell.Io

Singleton {
    id: root

    property alias theme: adapter.theme

    property alias tokens: adapter.tokens
    property alias services: adapter.services

    FileView {
        path: `${FileSystem.config}/shell.json`
        watchChanges: true
        onFileChanged: {
            reload();
        }
        onLoaded: {
            try {
                JSON.parse(text());
                // Toaster.toast(qsTr("Config hot reload"), qsTr("Config changes now available"), "rule_settings");
            } catch (e)
            // Toaster.toast(qsTr("Config reload failed"), e.message, "settings_alert", Toast.Error);
            {}
        }
        onLoadFailed: err => {
            // Toaster.toast(qStr("Failed to road config"), FileViewError.toString(err), "settings_alert", Toast.Warning);
            if (err !== FileViewError.FileNotFound) {}
        }

        JsonAdapter {
            id: adapter

            property ThemeConfig theme: ThemeConfig {}

            property Tokens tokens: Tokens {}
            property ServicesConfig services: ServicesConfig {}
        }
    }
}
