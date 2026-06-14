import QtQuick
import Quickshell.Io
import qs.config
import qs.config.tokens.types

JsonObject {
    property int width: 30
    property int height: 200
    property int thumbHeight: 4
    property int thumbWidth: 36
    property int thumbSpacing: 4
    property int trackShapeOut: Config.tokens.system.shapes.cornerSmall
    property int trackShapeIn: Config.tokens.system.shapes.cornerExtraSmall

    property color inactiveTrackColor: Config.tokens.system.colors.surface_control_slider_inactive_track
    property color activeTrackColor: Config.tokens.system.colors.surface_control_slider_active_track
    property color thumbColor: Config.tokens.system.colors.surface_control_slider_thumb

    property color inactiveTrackContentColor: Config.tokens.system.colors.surface_control_slider_active_track
    property color activeTrackContentColor: Config.tokens.system.colors.surface

    property TypographyValues iconTypography: Config.tokens.system.typography.icon
    property TypographyValues textTypography: Config.tokens.system.typography.body

    property int labelTypographyAnimationDelay: 500
    property AnimationValues labelAnimation: AnimationValues {
        duration: Config.tokens.system.animations.durations.small
        curveIn: Config.tokens.system.animations.curves.standardAccel
        curveOut: Config.tokens.system.animations.curves.standardDecel
    }
}
