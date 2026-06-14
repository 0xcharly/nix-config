import Quickshell.Io
import qs.config

JsonObject {
    property list<real> curveIn: Config.tokens.system.animations.curves.standard
    property list<real> curveOut: Config.tokens.system.animations.curves.standard
    property int duration: Config.tokens.system.animations.durations.normal
}
