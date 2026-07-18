package color

import "testing"

// OKLCH values copied from the vendored Tailwind v4 palette.
func TestFromOKLCHTailwindHex(t *testing.T) {
	cases := []struct {
		name    string
		l, c, h float64
		hex     string
	}{
		{"zinc-900", 0.21, 0.006, 285.885, "18181b"},
		{"zinc-300", 0.871, 0.006, 286.286, "d4d4d8"},
		{"slate-900", 0.208, 0.042, 265.755, "0f172b"},
	}
	for _, tc := range cases {
		if got := FromOKLCH(tc.l, tc.c, tc.h).Hex(); got != tc.hex {
			t.Errorf("%s: got %s, want %s", tc.name, got, tc.hex)
		}
	}
}

func TestSRGBRoundTrip(t *testing.T) {
	for v := 0; v <= 255; v += 5 {
		for _, rgb := range [][3]uint8{
			{uint8(v), 0, 0}, {0, uint8(v), 0}, {0, 0, uint8(v)},
			{uint8(v), uint8(v), uint8(v)}, {uint8(v), 128, 255 - uint8(v)},
		} {
			r, g, b := FromSRGB(rgb[0], rgb[1], rgb[2]).SRGB()
			if absDiff(r, rgb[0]) > 1 || absDiff(g, rgb[1]) > 1 || absDiff(b, rgb[2]) > 1 {
				t.Fatalf("round-trip %v: got (%d, %d, %d)", rgb, r, g, b)
			}
		}
	}
}

func absDiff(a, b uint8) uint8 {
	if a > b {
		return a - b
	}
	return b - a
}

func TestBlendExtremes(t *testing.T) {
	fg := FromSRGB(0xff, 0xd2, 0x30) // amber-300
	bg := FromSRGB(0x18, 0x18, 0x1b) // zinc-900
	if got := Blend(fg, 0, bg).Hex(); got != bg.Hex() {
		t.Errorf("Blend(fg, 0, bg) = %s, want bg %s", got, bg.Hex())
	}
	if got := Blend(fg, 1, bg).Hex(); got != fg.Hex() {
		t.Errorf("Blend(fg, 1, bg) = %s, want fg %s", got, fg.Hex())
	}
}

func TestMixDarkenIdentity(t *testing.T) {
	a := FromSRGB(0x8e, 0xc5, 0xff)
	b := FromSRGB(0x18, 0x18, 0x1b)
	if got := Mix(a, b, 0); got != a {
		t.Errorf("Mix(a, b, 0) = %+v, want %+v", got, a)
	}
	if got := Darken(a, 0); got != a {
		t.Errorf("Darken(a, 0) = %+v, want %+v", got, a)
	}
}
