pragma ComponentBehavior: Bound

import qs.components
import qs.services
import qs.config
import qs.config.tokens.component as ComponentTokens
import Quickshell
import QtQuick
import QtQuick.Layouts

Rectangle {
    id: root

    property ComponentTokens.Launcher theme: Config.tokens.component.launcher
    property var results: []
    // First character routes the mode: "." unicode/emoji search, "=" qalc
    // calculator, "$" run a shell command in a terminal, "!" run a $PATH
    // binary in a terminal, anything else application search.
    readonly property bool glyphMode: input.text.startsWith(".")
    readonly property bool calcMode: input.text.startsWith("=")
    readonly property bool shellMode: input.text.startsWith("$")
    readonly property bool binMode: input.text.startsWith("!")
    readonly property string query: (glyphMode || calcMode || shellMode || binMode ? input.text.slice(1) : input.text).trim()
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
        // Read input.text directly: this runs from onTextChanged, which can
        // fire before the mode/query bindings re-evaluate.
        const text = input.text;
        const glyph = text.startsWith(".");
        const calc = text.startsWith("=");
        const shell = text.startsWith("$");
        const bin = text.startsWith("!");
        const q = (glyph || calc || shell || bin ? text.slice(1) : text).trim();
        root.results = glyph ? GlyphSearch.query(q) : calc ? CalcSearch.query(q) : shell ? ShellSearch.query(q) : bin ? BinSearch.query(q) : AppSearch.query(q);
        list.currentIndex = root.results.length > 0 ? 0 : -1;
    }

    function launchSelected(): void {
        if (list.currentIndex < 0)
            return;
        const item = root.results[list.currentIndex];
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

    // Fallback: dismiss on Escape if focus somehow leaves the text field.
    Keys.onEscapePressed: UiState.showLauncher = false

    // Focus the text field whenever the launcher opens.
    Component.onCompleted: if (UiState.showLauncher) input.forceActiveFocus()
    Connections {
        target: UiState

        function onShowLauncherChanged() {
            if (UiState.showLauncher)
                input.forceActiveFocus();
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

            text: "Launcher"
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
                color: root.theme.input.colors.content
                font.family: root.theme.input.typography.family
                font.pointSize: root.theme.input.typography.fontSize
                font.weight: root.theme.input.typography.weight

                onTextChanged: root.requery()

                Keys.onUpPressed: list.currentIndex = Math.max(list.currentIndex - 1, 0)
                Keys.onDownPressed: list.currentIndex = Math.min(list.currentIndex + 1, root.results.length - 1)
                Keys.onReturnPressed: root.launchSelected()
                Keys.onEnterPressed: root.launchSelected()

                Keys.onEscapePressed: UiState.showLauncher = false
            }

            ArcText {
                anchors.left: parent.left
                anchors.leftMargin: root.theme.input.padding.left
                anchors.verticalCenter: parent.verticalCenter
                visible: input.text.length === 0
                text: "Search"
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

                // Leading cell: app icon, the glyph itself, "=" for a
                // calculator result, "$" for a shell command, or "!" for a
                // binary.
                readonly property string symbol: modelData.glyph ?? (modelData.result !== undefined ? "=" : modelData.shellCommand !== undefined ? "$" : modelData.binary !== undefined ? "!" : "")

                width: list.width
                height: root.theme.resultRowHeight
                radius: root.theme.resultShape
                color: ListView.isCurrentItem ? root.theme.resultSelected.surface : "transparent"

                RowLayout {
                    anchors.fill: parent
                    anchors.leftMargin: root.theme.input.padding.left
                    anchors.rightMargin: root.theme.input.padding.right
                    spacing: root.theme.spacedBy

                    Image {
                        visible: row.symbol === ""
                        Layout.preferredWidth: root.theme.resultIconSize
                        Layout.preferredHeight: root.theme.resultIconSize
                        sourceSize.width: root.theme.resultIconSize
                        sourceSize.height: root.theme.resultIconSize
                        asynchronous: true
                        source: row.symbol === "" ? Quickshell.iconPath(row.modelData.icon, "application-x-executable") : ""
                    }

                    ArcText {
                        visible: row.symbol !== ""
                        Layout.preferredWidth: root.theme.resultIconSize
                        horizontalAlignment: Text.AlignHCenter
                        text: row.symbol
                        style: root.theme.resultTypography
                        color: root.theme.resultContentColor
                    }

                    ArcText {
                        Layout.fillWidth: true
                        elide: Text.ElideRight
                        text: row.modelData.name
                        style: root.theme.resultTypography
                        color: row.ListView.isCurrentItem ? root.theme.resultSelected.content : root.theme.resultContentColor
                    }
                }

                MouseArea {
                    anchors.fill: parent
                    onClicked: {
                        list.currentIndex = row.index;
                        root.launchSelected();
                    }
                }
            }
        }

        ArcText {
            visible: !root.queryEmpty && root.results.length === 0
            Layout.fillWidth: true
            Layout.preferredHeight: root.theme.resultRowHeight
            leftPadding: root.theme.input.padding.left
            verticalAlignment: Text.AlignVCenter
            text: "No match"
            style: root.theme.resultTypography
            color: root.theme.inputPlaceholderColor
        }
    }
}
