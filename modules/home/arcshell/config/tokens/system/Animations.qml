import Quickshell.Io

JsonObject {
    property Durations durations: Durations {}
    property Curves curves: Curves {}

    component Curves: JsonObject {
        // Time-reverse of `emphasizedOut` (every point p mapped to 1 - p,
        // segment order flipped): slow build, fast finish. Pairs with
        // `emphasizedOut` for open/close animations that mirror each other.
        property list<real> emphasizedIn: [0.75, 0, 19 / 24, 0.18, 5 / 6, 0.6, 13 / 15, 0.94, 0.95, 1, 1, 1]
        property list<real> emphasizedOut: [0.05, 0, 2 / 15, 0.06, 1 / 6, 0.4, 5 / 24, 0.82, 0.25, 1, 1, 1]
        property list<real> emphasizedAccel: [0.3, 0, 0.8, 0.15, 1, 1]
        property list<real> emphasizedDecel: [0.05, 0.7, 0.1, 1, 1, 1]
        property list<real> standard: [0.2, 0, 0, 1, 1, 1]
        property list<real> standardAccel: [0.3, 0, 1, 1, 1, 1]
        property list<real> standardDecel: [0, 0, 0, 1, 1, 1]
        property list<real> expressiveFastSpatial: [0.42, 1.67, 0.21, 0.9, 1, 1]
        property list<real> expressiveDefaultSpatial: [0.38, 1.21, 0.22, 1, 1, 1]
        property list<real> expressiveEffects: [0.34, 0.8, 0.34, 1, 1, 1]
    }

    component Durations: JsonObject {
        property real scale: 1
        property int small: 120 * scale
        property int medium: 200 * scale
        property int large: 400 * scale
        property int extraLarge: 600 * scale
        property int twoExtraLarge: 800 * scale
        property int threeExtraLarge: 800 * scale
        property int expressiveFastSpatial: 350 * scale
        property int expressiveDefaultSpatial: 500 * scale
        property int expressiveEffects: 200 * scale
        // Idle time before an auto-opened panel hides — a UX timeout, not an
        // animation, so deliberately unscaled.
        property int linger: 2000
    }
}
