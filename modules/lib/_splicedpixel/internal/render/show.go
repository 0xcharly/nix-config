package render

import (
	"fmt"
	"io"
	"slices"
	"strconv"
	"strings"

	"github.com/0xcharly/nix-config/splicedpixel/internal/color"
	"github.com/0xcharly/nix-config/splicedpixel/internal/theme"
)

// Show writes a human-readable preview of the resolved theme. When colorize
// is true, samples are rendered with truecolor ANSI escapes; otherwise only
// names and hex values are printed.
func Show(w io.Writer, res *theme.Resolved, colorize bool) error {
	s := &shower{w: w, res: res, color: colorize}
	s.palette()
	s.tokens()
	s.pairs()
	s.textOnSurfaces()
	return s.err
}

type shower struct {
	w     io.Writer
	res   *theme.Resolved
	color bool
	err   error
}

func (s *shower) printf(format string, args ...any) {
	if s.err == nil {
		_, s.err = fmt.Fprintf(s.w, format, args...)
	}
}

func (s *shower) fg(c color.Color) string {
	if !s.color {
		return ""
	}
	r, g, b := c.SRGB()
	return fmt.Sprintf("\x1b[38;2;%d;%d;%dm", r, g, b)
}

func (s *shower) bg(c color.Color) string {
	if !s.color {
		return ""
	}
	r, g, b := c.SRGB()
	return fmt.Sprintf("\x1b[48;2;%d;%d;%dm", r, g, b)
}

func (s *shower) reset() string {
	if !s.color {
		return ""
	}
	return "\x1b[0m"
}

// swatch renders a bg-colored cell labeled with text, in a legible fg.
func (s *shower) swatch(c color.Color, label string) string {
	fg := color.FromSRGB(0, 0, 0)
	if c.L < 0.6 {
		fg = color.FromSRGB(255, 255, 255)
	}
	return s.bg(c) + s.fg(fg) + " " + label + " " + s.reset()
}

func (s *shower) header(name string) {
	s.printf("%s\n", name)
}

// familyShades returns the shade suffixes of family present in the base
// palette, sorted numerically (50, 100, ..., 950).
func (s *shower) familyShades(family string) []string {
	var shades []string
	for name := range s.res.Base {
		if rest, ok := strings.CutPrefix(name, family+"-"); ok {
			shades = append(shades, rest)
		}
	}
	slices.SortFunc(shades, func(a, b string) int {
		ai, _ := strconv.Atoi(a)
		bi, _ := strconv.Atoi(b)
		return ai - bi
	})
	return shades
}

func (s *shower) palette() {
	s.header("palette")
	for _, alias := range s.res.FamilyOrder {
		family := s.res.Families[alias]
		s.printf("  %-20s", fmt.Sprintf("%s (%s)", alias, family))
		for _, shade := range s.familyShades(family) {
			c := s.res.Base[family+"-"+shade]
			s.printf(" %s", s.swatch(c, fmt.Sprintf("%s %s", shade, c.Hex())))
		}
		s.printf("\n")
	}
	for _, name := range s.res.PaletteOrder {
		c := s.res.Palette[name]
		s.printf("  %-20s %s #%s\n", name, s.swatch(c, "      "), c.Hex())
	}
	s.printf("\n")
}

func (s *shower) tokens() {
	s.header("tokens")
	width := 0
	for _, name := range s.res.TokenOrder {
		width = max(width, len(name))
	}
	for _, name := range s.res.TokenOrder {
		c := s.res.Tokens[name]
		s.printf("  %-*s #%s %sthe quick brown fox%s\n", width, name, c.Hex(), s.fg(c), s.reset())
	}
	s.printf("\n")
}

func (s *shower) pairs() {
	s.header("pairs")
	for _, name := range s.res.TokenOrder {
		on, ok := s.res.Tokens["on_"+name]
		if !ok {
			continue
		}
		bg := s.res.Tokens[name]
		s.printf("  %-28s %s%s on_%s on %s (#%s on #%s) %s\n",
			name, s.bg(bg), s.fg(on), name, name, on.Hex(), bg.Hex(), s.reset())
	}
	s.printf("\n")
}

func (s *shower) textOnSurfaces() {
	s.header("text on surfaces")
	surfaces := []string{"surface_dark", "surface", "surface_cursorline", "surface_menu"}
	for _, name := range s.res.TokenOrder {
		if !strings.HasPrefix(name, "text") {
			continue
		}
		fg := s.res.Tokens[name]
		s.printf("  %-24s", name)
		for _, surface := range surfaces {
			bg, ok := s.res.Tokens[surface]
			if !ok {
				continue
			}
			s.printf(" %s%s %s %s", s.bg(bg), s.fg(fg), name, s.reset())
		}
		s.printf("\n")
	}
}
