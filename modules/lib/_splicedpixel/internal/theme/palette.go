package theme

import (
	"encoding/json"
	"fmt"

	"github.com/0xcharly/nix-config/splicedpixel/internal/color"
)

// ParsePalette decodes a base palette JSON: a flat map of full color name to
// [L, C, H] OKLCH triples (L in 0-1, H in degrees).
func ParsePalette(data []byte) (map[string]color.Color, error) {
	var raw map[string][3]float64
	if err := json.Unmarshal(data, &raw); err != nil {
		return nil, fmt.Errorf("invalid palette JSON: %w", err)
	}
	palette := make(map[string]color.Color, len(raw))
	for name, lch := range raw {
		palette[name] = color.FromOKLCH(lch[0], lch[1], lch[2])
	}
	return palette, nil
}
