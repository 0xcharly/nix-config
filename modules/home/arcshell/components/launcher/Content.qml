pragma ComponentBehavior: Bound

import qs.components
import qs.services
import qs.config
import qs.config.tokens.component as ComponentTokens
import Quickshell
import Quickshell.Bluetooth
import Quickshell.Networking
import QtQuick
import QtQuick.Layouts

Rectangle {
    id: root

    property ComponentTokens.Launcher theme: Config.tokens.component.launcher
    property var results: []
    // First character routes the mode: "." unicode/emoji search, "=" qalc
    // calculator, "$" run a shell command in a terminal, "!" run a $PATH
    // binary in a terminal, anything else application search.
    // Trimmed view of the input: routing and querying ignore leading and
    // trailing whitespace ("   !  blue" is bin mode), while the field
    // itself accepts and keeps it.
    readonly property string trimmedText: input.text.trim()
    // Selector modes ("wifi"/"bluetooth") disable the prefix routing below:
    // a leading "."/"="/"$"/"!" is a plain filter character there.
    readonly property bool selectorMode: UiState.launcherMode !== "default"
    property var pendingWifiNetwork: null       // WifiNetwork awaiting a PSK
    readonly property bool passwordMode: pendingWifiNetwork !== null
    property string passwordError: ""
    readonly property bool glyphMode: !selectorMode && trimmedText.startsWith(".")
    readonly property bool calcMode: !selectorMode && trimmedText.startsWith("=")
    readonly property bool shellMode: !selectorMode && trimmedText.startsWith("$")
    readonly property bool binMode: !selectorMode && trimmedText.startsWith("!")
    readonly property bool paletteMode: !selectorMode && trimmedText.startsWith(">")
    readonly property string query: (glyphMode || calcMode || shellMode || binMode || paletteMode ? trimmedText.slice(1) : trimmedText).trim()
    readonly property bool queryEmpty: query.length === 0

    // Space left for the results list once the title and input rows are laid
    // out, from the panel's maximum height.
    readonly property real listMaxHeight: root.theme.maxHeight - root.theme.padding.top - root.theme.padding.bottom - title.implicitHeight - root.theme.inputHeight - 2 * column.spacing
    // Whole rows only, so a capped list never cuts a row in half.
    readonly property int visibleRows: Math.min(root.results.length, Math.floor(root.listMaxHeight / root.theme.resultRowHeight))

    // Height with no candidate list shown: title + input + padding. The
    // panel's top border is pinned as if it were always this tall.
    readonly property real chromeHeight: root.theme.padding.top + title.implicitHeight + column.spacing + root.theme.inputHeight + root.theme.padding.bottom

    // The panel sizes to fit its content; the wrapper and border lines follow.
    implicitHeight: column.implicitHeight + root.theme.padding.top + root.theme.padding.bottom

    color: root.theme.colors.surface

    Behavior on implicitHeight {
        AnimatedNumber {}
    }

    function requery(): void {
        if (root.passwordMode) {
            root.passwordError = "";
            root.results = [];
            return;
        }
        if (UiState.launcherMode === "wifi") {
            root.results = WifiSearch.query(input.text);
            list.currentIndex = root.results.length > 0 ? 0 : -1;
            return;
        }
        if (UiState.launcherMode === "bluetooth") {
            root.results = BluetoothSearch.query(input.text);
            list.currentIndex = root.results.length > 0 ? 0 : -1;
            return;
        }
        if (UiState.launcherMode === "exit-node") {
            root.results = ExitNodeSearch.query(input.text);
            list.currentIndex = root.results.length > 0 ? 0 : -1;
            return;
        }
        // Read input.text directly: this runs from onTextChanged, which can
        // fire before the mode/query bindings re-evaluate.
        const text = input.text.trim();
        const glyph = text.startsWith(".");
        const calc = text.startsWith("=");
        const shell = text.startsWith("$");
        const bin = text.startsWith("!");
        const palette = text.startsWith(">");
        const q = (glyph || calc || shell || bin || palette ? text.slice(1) : text).trim();
        root.results = palette ? CommandSearch.query(q) : glyph ? GlyphSearch.query(q) : calc ? CalcSearch.query(q) : shell ? ShellSearch.query(q) : bin ? BinSearch.query(q) : AppSearch.query(q);
        list.currentIndex = root.results.length > 0 ? 0 : -1;
    }

    function launchSelected(): void {
        if (list.currentIndex < 0)
            return;
        if (UiState.launcherMode === "wifi") {
            const network = root.results[list.currentIndex];
            if (network.connected) {            // selecting the active network: no-op
                UiState.showLauncher = false;
            } else if (network.known || network.security === WifiSecurityType.Open) {
                network.connect();
                UiState.showLauncher = false;
            } else {
                // Unknown secured network: NM has no secrets, prompt inline.
                root.pendingWifiNetwork = network;
                input.text = "";
                // Explicit: clearing an already-empty field fires no
                // textChanged, so requery would never see password mode.
                root.requery();
            }
            return;
        }
        if (UiState.launcherMode === "bluetooth") {
            const device = root.results[list.currentIndex];
            device.connected ? device.disconnect() : device.connect();
            UiState.showLauncher = false;
            return;
        }
        if (UiState.launcherMode === "exit-node") {
            const node = root.results[list.currentIndex];
            if (!node.selected)             // selecting the active entry: no-op
                ExitNodeSearch.select(node);
            UiState.showLauncher = false;
            return;
        }
        const item = root.results[list.currentIndex];
        if (item.toggle !== undefined) {
            // Palette command. Selector-entering commands (keepOpen) leave
            // the launcher up: launcherMode has already flipped and
            // onLauncherModeChanged cleared the input.
            item.run();
            if (!item.keepOpen)
                UiState.showLauncher = false;
            return;
        }
        if (item.result !== undefined)
            CalcSearch.copy(item);
        else if (item.glyph !== undefined)
            GlyphSearch.copy(item);
        else if (item.shellCommand !== undefined)
            ShellSearch.run(item);
        else if (item.binary !== undefined)
            BinSearch.run(item);
        else
            AppSearch.launch(item);
        UiState.showLauncher = false;
    }

    function submit(): void {
        if (root.passwordMode) {
            // Ignore Enter while a connect attempt is in flight or empty PSK.
            if (!root.pendingWifiNetwork || root.pendingWifiNetwork.stateChanging || input.text.length === 0)
                return;
            root.passwordError = "";
            root.pendingWifiNetwork.connectWithPsk(input.text);
            return;
        }
        root.launchSelected();
    }

    // Password mode exits back to the network list; everything else closes.
    function dismiss(): void {
        if (root.passwordMode) {
            root.pendingWifiNetwork = null;
            root.passwordError = "";
            input.text = "";
            // Explicit: an untouched (still empty) field fires no
            // textChanged, so the network list would stay stale.
            root.requery();
        } else {
            UiState.showLauncher = false;
        }
    }

    // Fallback: dismiss on Escape if focus somehow leaves the text field.
    Keys.onEscapePressed: root.dismiss()

    // Focus the text field whenever the launcher opens.
    Component.onCompleted: if (UiState.showLauncher) input.forceActiveFocus()
    Connections {
        target: UiState

        function onShowLauncherChanged() {
            if (UiState.showLauncher) {
                // A reopened, not-yet-unloaded Content must not resume a
                // stale password prompt.
                root.pendingWifiNetwork = null;
                root.passwordError = "";
                root.requery();
                input.forceActiveFocus();
            }
        }

        function onLauncherModeChanged() {
            root.pendingWifiNetwork = null;
            root.passwordError = "";
            input.text = "";
            // Explicit: clearing an already-empty field fires no
            // textChanged.
            root.requery();
        }
    }

    // The app set fills in asynchronously right after the launcher first
    // loads, and can change while it is open.
    Connections {
        target: AppSearch

        function onAppsChanged() {
            root.requery();
        }
    }

    // The glyph index rebuilds asynchronously as its data files land.
    Connections {
        target: GlyphSearch

        function onEntriesChanged() {
            root.requery();
        }
    }

    // qalc results land ~100ms after the keystroke that spawned the run.
    Connections {
        target: CalcSearch

        function onResultsChanged() {
            root.requery();
        }
    }

    // The PATH scan re-runs on every launcher open and lands asynchronously.
    Connections {
        target: BinSearch

        function onEntriesChanged() {
            root.requery();
        }
    }

    // Wifi networks appear/disappear while scanning; membership changes
    // push through the ObjectModel. Per-row signalStrength/connected ticks
    // update through direct QObject bindings without a requery (deliberate:
    // resorting on every strength tick makes the list jumpy).
    Connections {
        target: Network.wifiDevice?.networks ?? null

        function onValuesChanged() {
            if (UiState.launcherMode === "wifi")
                root.requery();
        }
    }

    Connections {
        target: Bluetooth.defaultAdapter?.devices ?? null

        function onValuesChanged() {
            if (UiState.launcherMode === "bluetooth")
                root.requery();
        }
    }

    // Exit-node rows and the suggestion land asynchronously after the
    // tailscale CLI calls finish.
    Connections {
        target: ExitNodeSearch

        function onEntriesChanged() {
            if (UiState.launcherMode === "exit-node")
                root.requery();
        }

        function onSuggestedChanged() {
            if (UiState.launcherMode === "exit-node")
                root.requery();
        }
    }

    // Media player arrivals/departures change command availability while the
    // palette is open. Toggle *state* needs no requery: the delegate binds
    // the Command's reactive `checked` directly.
    Connections {
        target: CommandSearch

        function onPlayersChanged() {
            if (root.paletteMode)
                root.requery();
        }
    }

    // Outcome of a connectWithPsk attempt on the pending network.
    Connections {
        target: root.pendingWifiNetwork

        function onConnectedChanged() {
            if (root.pendingWifiNetwork.connected) {
                root.pendingWifiNetwork = null;
                UiState.showLauncher = false;
            }
        }

        function onConnectionFailed(reason: int) {
            root.passwordError = reason === ConnectionFailReason.NoSecrets ? qsTr("Wrong password") : ConnectionFailReason.toString(reason);
        }
    }

    ColumnLayout {
        id: column

        anchors.top: parent.top
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.topMargin: root.theme.padding.top
        anchors.leftMargin: root.theme.padding.left
        anchors.rightMargin: root.theme.padding.right
        spacing: root.theme.spacedBy

        ArcText {
            id: title

            text: root.passwordMode ? qsTr("Connect to \"%1\"").arg(root.pendingWifiNetwork?.name ?? "") : UiState.launcherMode === "wifi" ? qsTr("Select WiFi network") : UiState.launcherMode === "bluetooth" ? qsTr("Select Bluetooth device") : UiState.launcherMode === "exit-node" ? qsTr("Select Exit Node") : "Launcher"
            style: root.theme.titleTypography
            color: root.theme.titleContentColor
        }

        Rectangle {
            Layout.fillWidth: true
            Layout.preferredHeight: root.theme.inputHeight

            color: root.theme.input.colors.surface
            radius: root.theme.input.shape

            TextInput {
                id: input

                anchors.fill: parent
                anchors.leftMargin: root.theme.input.padding.left
                anchors.rightMargin: root.theme.input.padding.right
                verticalAlignment: TextInput.AlignVCenter
                clip: true
                echoMode: root.passwordMode ? TextInput.Password : TextInput.Normal
                color: root.theme.input.colors.content
                font.family: root.theme.input.typography.family
                font.pointSize: root.theme.input.typography.fontSize
                font.weight: root.theme.input.typography.weight

                onTextChanged: root.requery()

                Keys.onUpPressed: list.currentIndex = Math.max(list.currentIndex - 1, 0)
                Keys.onDownPressed: list.currentIndex = Math.min(list.currentIndex + 1, root.results.length - 1)
                Keys.onReturnPressed: root.submit()
                Keys.onEnterPressed: root.submit()

                Keys.onEscapePressed: root.dismiss()
            }

            ArcText {
                anchors.left: parent.left
                anchors.leftMargin: root.theme.input.padding.left
                anchors.verticalCenter: parent.verticalCenter
                visible: input.text.length === 0
                text: root.passwordMode ? "Password" : "Search"
                style: root.theme.input.typography
                color: root.theme.inputPlaceholderColor
            }
        }

        ListView {
            id: list

            visible: root.results.length > 0
            Layout.fillWidth: true
            Layout.preferredHeight: root.visibleRows * root.theme.resultRowHeight
            clip: true
            model: root.results
            currentIndex: root.results.length > 0 ? 0 : -1

            delegate: Rectangle {
                id: row

                required property var modelData
                required property int index

                readonly property bool binary: modelData.binary !== undefined
                readonly property bool command: modelData.toggle !== undefined
                readonly property bool selectorRow: UiState.launcherMode !== "default"
                // Wifi networks that require authentication get the locked
                // signal variant. OWE ("enhanced open") encrypts without
                // authenticating and Unknown means the backend has not
                // resolved the AP yet — neither claims a lock.
                readonly property bool wifiLocked: UiState.launcherMode === "wifi" && modelData.security !== WifiSecurityType.Open && modelData.security !== WifiSecurityType.Owe && modelData.security !== WifiSecurityType.Unknown
                // Text cell content: the glyph itself, "=" for a calculator
                // result, "$" for a shell command. App and binary rows use
                // the boxed leading cell instead.
                readonly property string symbol: modelData.glyph ?? (modelData.result !== undefined ? "=" : modelData.shellCommand !== undefined ? "$" : "")

                width: list.width
                height: root.theme.resultRowHeight
                radius: root.theme.resultShape
                color: ListView.isCurrentItem ? root.theme.resultSelected.surface : "transparent"

                // Declared before the RowLayout so interactive children of
                // the layout (the palette ArcSwitch) stack above the
                // row-activation area; text/icon items don't accept mouse
                // events, so row clicks elsewhere still fall through.
                MouseArea {
                    anchors.fill: parent
                    onClicked: {
                        list.currentIndex = row.index;
                        root.launchSelected();
                    }
                }

                RowLayout {
                    anchors.fill: parent
                    anchors.leftMargin: root.theme.input.padding.left
                    anchors.rightMargin: root.theme.input.padding.right
                    spacing: root.theme.spacedBy

                    Rectangle {
                        id: iconBox

                        // Inner icon fits at 2/3 of the box (user-specified).
                        readonly property int iconSize: Math.round(root.theme.resultIconBoxSize * 2 / 3)

                        Layout.preferredWidth: root.theme.resultIconBoxSize
                        Layout.preferredHeight: root.theme.resultIconBoxSize
                        radius: root.theme.resultIconBoxShape
                        // Boxed backdrop for app icons and the terminal
                        // glyph; transparent behind plain text symbols.
                        color: row.symbol === "" ? root.theme.resultIconBox.surface : "transparent"

                        Image {
                            visible: !row.binary && !row.selectorRow && !row.command && row.symbol === ""
                            anchors.centerIn: parent
                            width: iconBox.iconSize
                            height: iconBox.iconSize
                            sourceSize.width: iconBox.iconSize
                            sourceSize.height: iconBox.iconSize
                            asynchronous: true
                            source: visible ? Quickshell.iconPath(row.modelData.icon, "application-x-executable") : ""
                        }

                        MaterialIcon {
                            visible: (row.binary || row.selectorRow || row.command) && row.symbol === ""
                            anchors.centerIn: parent
                            text: row.command ? row.modelData.icon : row.binary ? "terminal_2" : UiState.launcherMode === "wifi" ? (row.modelData.connected ? "check" : "wifi") : UiState.launcherMode === "exit-node" ? (row.modelData.hostname === "" ? "vpn_key_off" : "language") : IconLibrary.getBluetoothIcon(row.modelData.icon ?? "")
                            color: root.theme.resultIconBox.content
                            // Scale the glyph with the box: QML font resolves
                            // pixelSize over the pointSize ArcText binds.
                            font.pixelSize: iconBox.iconSize
                        }

                        ArcText {
                            visible: row.symbol !== ""
                            anchors.centerIn: parent
                            text: row.symbol
                            style: root.theme.resultTypography
                            color: root.theme.resultContentColor
                            // Emoji symbols (country flags) resolve through a
                            // fallback font with a taller ascent than the UI
                            // face: inside the token-fixed line height the
                            // glyph rides above the visual center. Natural
                            // line height re-centers the run's own metrics.
                            lineHeightMode: Text.ProportionalHeight
                            lineHeight: 1
                        }
                    }

                    ArcText {
                        Layout.fillWidth: true
                        elide: Text.ElideRight
                        text: row.modelData.name
                        style: root.theme.resultTypography
                        color: row.ListView.isCurrentItem ? root.theme.resultSelected.content : root.theme.resultContentColor
                    }

                    MaterialIcon {
                        visible: row.selectorRow
                        Layout.alignment: Qt.AlignVCenter
                        text: !row.selectorRow ? "" : UiState.launcherMode === "wifi" ? IconLibrary.getWifiSignalIcon(row.modelData.signalStrength, row.wifiLocked) : UiState.launcherMode === "exit-node" ? (row.modelData.selected ? "check" : row.modelData.suggested ? "bolt_boost" : "") : row.modelData.batteryAvailable ? IconLibrary.getBatteryIcon(row.modelData.battery) : row.modelData.connected ? "bluetooth_connected" : "bluetooth"
                        color: row.ListView.isCurrentItem ? root.theme.resultSelected.content : root.theme.resultContentColor
                    }

                    // Right-aligned live toggle for boolean commands. Mirrors
                    // the IdleInhibitor pattern: the switch owns its click;
                    // run() derives the new state from the service, so
                    // switch-click and Enter stay coherent.
                    ArcSwitch {
                        visible: row.command && row.modelData.toggle
                        Layout.alignment: Qt.AlignVCenter
                        checked: row.command ? row.modelData.checked : false
                        onToggled: row.modelData.run()
                    }
                }
            }
        }

        ArcText {
            visible: !root.passwordMode && !root.queryEmpty && root.results.length === 0
            Layout.fillWidth: true
            Layout.preferredHeight: root.theme.resultRowHeight
            leftPadding: root.theme.input.padding.left
            verticalAlignment: Text.AlignVCenter
            text: "No match"
            style: root.theme.resultTypography
            color: root.theme.inputPlaceholderColor
        }

        // Password prompt status: an error from the last attempt, or
        // progress while NetworkManager works through the connect.
        ArcText {
            visible: root.passwordMode && text !== ""
            Layout.fillWidth: true
            Layout.preferredHeight: root.theme.resultRowHeight
            leftPadding: root.theme.input.padding.left
            verticalAlignment: Text.AlignVCenter
            text: root.passwordError !== "" ? root.passwordError : root.pendingWifiNetwork?.stateChanging ? qsTr("Connecting…") : ""
            style: root.theme.resultTypography
            color: root.theme.inputPlaceholderColor
        }
    }
}
