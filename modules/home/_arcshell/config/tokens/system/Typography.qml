import Quickshell.Io
import qs.config.tokens.types

JsonObject {
    id: root

    property real scale: 1
    property Fonts.Family families: Fonts.Family {}
    property Fonts.Weight weights: Fonts.Weight {}

    property TypographyValues icon: TypographyValues {
        family: root.families.icon
        fontSize: 18 * root.scale
        lineHeight: 22 * root.scale
        weight: root.weights.normal
        italic: false
        underline: false
    }
    property DotoTypographyValues doto: DotoTypographyValues {
        family: root.families.doto
        fontSize: 18 * root.scale
        lineHeight: 22 * root.scale
        weight: root.weights.demiBold
        roundness: 40
    }
    property TypographyValues smallLabel: TypographyValues {
        family: root.families.sansSerif
        fontSize: 8 * root.scale
        lineHeight: 12 * root.scale
        weight: root.weights.medium
    }
    property TypographyValues mediumLabel: TypographyValues {
        family: root.families.sansSerif
        fontSize: 10 * root.scale
        lineHeight: 14 * root.scale
        weight: root.weights.medium
    }
    property TypographyValues body: TypographyValues {
        family: root.families.sansSerif
        fontSize: 12 * root.scale
        lineHeight: 16 * root.scale
        weight: root.weights.normal
        italic: false
        underline: false
    }
    property TypographyValues smallTitle: TypographyValues {
        family: root.families.sansSerif
        fontSize: 14 * root.scale
        lineHeight: 18 * root.scale
        weight: root.weights.normal
        italic: false
        underline: false
    }
    property TypographyValues mediumTitle: TypographyValues {
        family: root.families.sansSerif
        fontSize: 16 * root.scale
        lineHeight: 20 * root.scale
        weight: root.weights.normal
        italic: false
        underline: false
    }
    property TypographyValues largeTitle: TypographyValues {
        family: root.families.sansSerif
        fontSize: 24 * root.scale
        lineHeight: 28 * root.scale
        weight: root.weights.normal
        italic: false
        underline: false
    }
}
