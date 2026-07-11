// Package color implements the minimal OKLab/OKLCH <-> sRGB conversions and
// color operations needed to resolve a splicedpixel theme.
//
// Colors are represented in OKLab. Conversion matrices are Björn Ottosson's
// reference implementation: https://bottosson.github.io/posts/oklab/
package color

import (
	"fmt"
	"math"
)

// Color is a color in OKLab space.
type Color struct {
	L, A, B float64
}

// FromOKLCH builds a Color from OKLCH components (L in 0-1, hue in degrees).
func FromOKLCH(l, c, hDeg float64) Color {
	h := hDeg * math.Pi / 180
	return Color{L: l, A: c * math.Cos(h), B: c * math.Sin(h)}
}

// FromSRGB builds a Color from 8-bit gamma-encoded sRGB channels.
func FromSRGB(r, g, b uint8) Color {
	lr := srgbToLinear(float64(r) / 255)
	lg := srgbToLinear(float64(g) / 255)
	lb := srgbToLinear(float64(b) / 255)
	return fromLinearSRGB(lr, lg, lb)
}

// SRGB returns the 8-bit gamma-encoded sRGB channels, clamping out-of-gamut
// values to [0, 1] before quantization.
func (c Color) SRGB() (r, g, b uint8) {
	lr, lg, lb := c.toLinearSRGB()
	return quantize(linearToSRGB(lr)), quantize(linearToSRGB(lg)), quantize(linearToSRGB(lb))
}

// Hex returns the color as a lowercase "rrggbb" string (no '#').
func (c Color) Hex() string {
	r, g, b := c.SRGB()
	return fmt.Sprintf("%02x%02x%02x", r, g, b)
}

// Mix linearly interpolates from a to b in OKLab; t is the weight of b.
func Mix(a, b Color, t float64) Color {
	return Color{
		L: a.L + (b.L-a.L)*t,
		A: a.A + (b.A-a.A)*t,
		B: a.B + (b.B-a.B)*t,
	}
}

// Blend composites fg over bg with the given alpha in gamma-encoded sRGB
// (browser-style compositing): out = fg*alpha + bg*(1-alpha) per channel.
func Blend(fg Color, alpha float64, bg Color) Color {
	fr, fg8, fb := fg.SRGB()
	br, bg8, bb := bg.SRGB()
	comp := func(f, b uint8) uint8 {
		return quantize((float64(f)*alpha + float64(b)*(1-alpha)) / 255)
	}
	return FromSRGB(comp(fr, br), comp(fg8, bg8), comp(fb, bb))
}

// Darken mixes c toward black by p (0-1).
func Darken(c Color, p float64) Color {
	return Mix(c, Color{}, p)
}

// Lighten mixes c toward white by p (0-1).
func Lighten(c Color, p float64) Color {
	return Mix(c, Color{L: 1}, p)
}

// Chroma scales the OKLCH chroma of c by factor, floored at 0.
func Chroma(c Color, factor float64) Color {
	if factor < 0 {
		factor = 0
	}
	return Color{L: c.L, A: c.A * factor, B: c.B * factor}
}

// fromLinearSRGB converts linear sRGB to OKLab.
func fromLinearSRGB(r, g, b float64) Color {
	l := 0.4122214708*r + 0.5363325363*g + 0.0514459929*b
	m := 0.2119034982*r + 0.6806995451*g + 0.1073969566*b
	s := 0.0883024619*r + 0.2817188376*g + 0.6299787005*b

	l_ := math.Cbrt(l)
	m_ := math.Cbrt(m)
	s_ := math.Cbrt(s)

	return Color{
		L: 0.2104542553*l_ + 0.7936177850*m_ - 0.0040720468*s_,
		A: 1.9779984951*l_ - 2.4285922050*m_ + 0.4505937099*s_,
		B: 0.0259040371*l_ + 0.7827717662*m_ - 0.8086757660*s_,
	}
}

// toLinearSRGB converts OKLab to linear sRGB.
func (c Color) toLinearSRGB() (r, g, b float64) {
	l_ := c.L + 0.3963377774*c.A + 0.2158037573*c.B
	m_ := c.L - 0.1055613458*c.A - 0.0638541728*c.B
	s_ := c.L - 0.0894841775*c.A - 1.2914855480*c.B

	l := l_ * l_ * l_
	m := m_ * m_ * m_
	s := s_ * s_ * s_

	r = +4.0767416621*l - 3.3077115913*m + 0.2309699292*s
	g = -1.2684380046*l + 2.6097574011*m - 0.3413193965*s
	b = -0.0041960863*l - 0.7034186147*m + 1.7076147010*s
	return r, g, b
}

// srgbToLinear applies the inverse sRGB transfer function.
func srgbToLinear(c float64) float64 {
	if c <= 0.04045 {
		return c / 12.92
	}
	return math.Pow((c+0.055)/1.055, 2.4)
}

// linearToSRGB applies the sRGB transfer function.
func linearToSRGB(c float64) float64 {
	if c <= 0.0031308 {
		return 12.92 * c
	}
	return 1.055*math.Pow(c, 1/2.4) - 0.055
}

// quantize clamps to [0, 1] and rounds to an 8-bit channel.
func quantize(c float64) uint8 {
	c = math.Min(1, math.Max(0, c))
	return uint8(math.Round(c * 255))
}
