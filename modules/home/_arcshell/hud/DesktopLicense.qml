pragma ComponentBehavior: Bound

import qs.config.tokens.feature as FeatureTokens
import qs.components
import QtQuick
import QtQuick.Layouts

ArcRectangle {
    id: root

    property int absX
    property int absY
    property FeatureTokens.DesktopLicense theme

    implicitWidth: layout.implicitWidth
    implicitHeight: layout.implicitHeight

    anchors.leftMargin: root.theme.relativeX
    anchors.bottomMargin: root.theme.relativeY

    ColumnLayout {
        id: layout

        spacing: root.theme.spacedBy

        ArcText {
            id: title

            horizontalAlignment: Text.AlignRight

            tabularFigures: true
            color: root.theme.colors.content
            style: root.theme.titleTypography
            text: "Activate Linux"
        }

        ArcText {
            id: body

            horizontalAlignment: Text.AlignRight

            tabularFigures: true
            color: root.theme.bodyContentColor
            style: root.theme.bodyTypography
            text: "Go to Settings to activate Linux."
        }
    }
}
