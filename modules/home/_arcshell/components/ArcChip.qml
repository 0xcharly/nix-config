import qs.config
import qs.config.tokens.types
import QtQuick

ArcRectangle {
    id: root

    required property string text
    property SurfaceTokens theme: Config.theme.defaults.chips

    implicitWidth: text.implicitWidth + root.theme.padding.left + root.theme.padding.right
    implicitHeight: text.implicitHeight + root.theme.padding.top + root.theme.padding.bottom

    radius: root.theme.shape
    color: root.theme.colors.surface

    ArcText {
        id: text

        anchors.centerIn: parent
        text: root.text
        color: root.theme.colors.content
        style: root.theme.typography
    }
}
