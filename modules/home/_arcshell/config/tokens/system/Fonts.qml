import Quickshell.Io

JsonObject {
    component Family: JsonObject {
        property string icon: "Material Symbols Rounded"
        property string doto: "Doto"
        property string monospace: "monospace"
        property string sansSerif: "sansserif"
        property string serif: "serif"
    }

    component Weight: JsonObject {
        readonly property int thin: 100
        readonly property int extraLight: 200
        readonly property int light: 300
        readonly property int normal: 400
        readonly property int medium: 500
        readonly property int demiBold: 600
        readonly property int bold: 700
        readonly property int extraBold: 800
        readonly property int black: 900
    }
}
