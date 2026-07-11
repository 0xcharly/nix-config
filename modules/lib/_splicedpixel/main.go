// Command splicedpixel resolves the splicedpixel theme definition
// (theme.toml) against the vendored Tailwind OKLCH palette and emits
// consumer-ready outputs (JSON for nix, Lua for nvim, an ANSI preview).
package main

import (
	_ "embed"
	"flag"
	"fmt"
	"io"
	"net/http"
	"os"
	"regexp"
	"sort"
	"strconv"
	"strings"

	"github.com/0xcharly/nix-config/splicedpixel/internal/render"
	"github.com/0xcharly/nix-config/splicedpixel/internal/theme"
)

//go:embed tailwind.json
var embeddedPalette []byte

const themeCSSURL = "https://raw.githubusercontent.com/tailwindlabs/tailwindcss/main/packages/tailwindcss/theme.css"

func main() {
	if len(os.Args) < 2 {
		usage()
		os.Exit(2)
	}
	var err error
	switch os.Args[1] {
	case "render":
		err = cmdRender(os.Args[2:])
	case "show":
		err = cmdShow(os.Args[2:])
	case "update-palette":
		err = cmdUpdatePalette(os.Args[2:])
	case "-h", "--help", "help":
		usage()
		return
	default:
		fmt.Fprintf(os.Stderr, "splicedpixel: unknown command %q\n", os.Args[1])
		usage()
		os.Exit(2)
	}
	if err != nil {
		fmt.Fprintf(os.Stderr, "splicedpixel: %v\n", err)
		os.Exit(1)
	}
}

func usage() {
	fmt.Fprint(os.Stderr, `usage:
  splicedpixel render --config PATH --format {json|lua} [--palette PATH] [-o PATH]
  splicedpixel show   [--config PATH] [--palette PATH]
  splicedpixel update-palette [-o PATH]
`)
}

// loadResolved loads and resolves a theme against the embedded palette (or
// the override at palettePath).
func loadResolved(configPath, palettePath string) (*theme.Resolved, error) {
	data := embeddedPalette
	if palettePath != "" {
		var err error
		if data, err = os.ReadFile(palettePath); err != nil {
			return nil, err
		}
	}
	base, err := theme.ParsePalette(data)
	if err != nil {
		return nil, err
	}
	t, err := theme.Load(configPath)
	if err != nil {
		return nil, err
	}
	return t.Resolve(base)
}

// openOutput returns the write target for -o (stdout when empty).
func openOutput(path string) (io.WriteCloser, error) {
	if path == "" || path == "-" {
		return os.Stdout, nil
	}
	return os.Create(path)
}

func cmdRender(args []string) error {
	fs := flag.NewFlagSet("render", flag.ExitOnError)
	config := fs.String("config", "", "path to theme.toml")
	format := fs.String("format", "", "output format: json or lua")
	palette := fs.String("palette", "", "override the embedded palette JSON")
	out := fs.String("o", "", "output path (default: stdout)")
	if err := fs.Parse(args); err != nil {
		return err
	}
	if *config == "" {
		return fmt.Errorf("render: --config is required")
	}
	if *format != "json" && *format != "lua" {
		return fmt.Errorf("render: --format must be json or lua")
	}
	res, err := loadResolved(*config, *palette)
	if err != nil {
		return err
	}
	w, err := openOutput(*out)
	if err != nil {
		return err
	}
	if *format == "json" {
		err = render.JSON(w, res)
	} else {
		err = render.Lua(w, res)
	}
	if err != nil {
		return err
	}
	return closeOutput(w)
}

func cmdShow(args []string) error {
	fs := flag.NewFlagSet("show", flag.ExitOnError)
	config := fs.String("config", "theme.toml", "path to theme.toml")
	palette := fs.String("palette", "", "override the embedded palette JSON")
	if err := fs.Parse(args); err != nil {
		return err
	}
	res, err := loadResolved(*config, *palette)
	if err != nil {
		return err
	}
	return render.Show(os.Stdout, res, colorizeStdout())
}

// colorizeStdout reports whether stdout is a terminal and NO_COLOR is unset.
func colorizeStdout() bool {
	if _, noColor := os.LookupEnv("NO_COLOR"); noColor {
		return false
	}
	info, err := os.Stdout.Stat()
	return err == nil && info.Mode()&os.ModeCharDevice != 0
}

var oklchDecl = regexp.MustCompile(`--color-([a-z]+)-(\d+):\s*oklch\(([\d.]+)% ([\d.]+) ([\d.]+|none)\)`)

func cmdUpdatePalette(args []string) error {
	fs := flag.NewFlagSet("update-palette", flag.ExitOnError)
	out := fs.String("o", "", "output path (default: stdout)")
	if err := fs.Parse(args); err != nil {
		return err
	}
	resp, err := http.Get(themeCSSURL)
	if err != nil {
		return err
	}
	defer resp.Body.Close()
	if resp.StatusCode != http.StatusOK {
		return fmt.Errorf("GET %s: %s", themeCSSURL, resp.Status)
	}
	body, err := io.ReadAll(resp.Body)
	if err != nil {
		return err
	}
	palette, err := extractPalette(string(body))
	if err != nil {
		return err
	}
	w, err := openOutput(*out)
	if err != nil {
		return err
	}
	if err := writePalette(w, palette); err != nil {
		return err
	}
	return closeOutput(w)
}

// extractPalette pulls every --color-<family>-<shade> OKLCH declaration out
// of the upstream theme.css and validates the expected shape (>= 26 families
// of exactly 11 shades each).
func extractPalette(css string) (map[string][3]float64, error) {
	palette := map[string][3]float64{
		"black": {0, 0, 0},
		"white": {1, 0, 0},
	}
	families := map[string]int{}
	for _, m := range oklchDecl.FindAllStringSubmatch(css, -1) {
		family, shade := m[1], m[2]
		l, err1 := strconv.ParseFloat(m[3], 64)
		c, err2 := strconv.ParseFloat(m[4], 64)
		h := 0.0
		var err3 error
		if m[5] != "none" {
			h, err3 = strconv.ParseFloat(m[5], 64)
		}
		if err1 != nil || err2 != nil || err3 != nil {
			return nil, fmt.Errorf("unparseable declaration %q (palette format changed?)", m[0])
		}
		palette[family+"-"+shade] = [3]float64{l / 100, c, h}
		families[family]++
	}
	if len(families) < 26 {
		return nil, fmt.Errorf("only %d color families found (palette format changed?)", len(families))
	}
	for family, count := range families {
		if count != 11 {
			return nil, fmt.Errorf("family %q has %d shades, want 11 (palette format changed?)", family, count)
		}
	}
	return palette, nil
}

// writePalette emits the flat palette JSON with stable key sorting.
func writePalette(w io.Writer, palette map[string][3]float64) error {
	names := make([]string, 0, len(palette))
	for name := range palette {
		names = append(names, name)
	}
	sort.Strings(names)
	var sb strings.Builder
	sb.WriteString("{\n")
	for i, name := range names {
		lch := palette[name]
		sep := ","
		if i == len(names)-1 {
			sep = ""
		}
		fmt.Fprintf(&sb, "  %q: [%s, %s, %s]%s\n", name,
			formatFloat(lch[0]), formatFloat(lch[1]), formatFloat(lch[2]), sep)
	}
	sb.WriteString("}\n")
	_, err := io.WriteString(w, sb.String())
	return err
}

// formatFloat renders a float with a decimal point kept (so achromatic hues
// stay "0.0", not "0").
func formatFloat(f float64) string {
	s := strconv.FormatFloat(f, 'f', -1, 64)
	if !strings.Contains(s, ".") {
		s += ".0"
	}
	return s
}

func closeOutput(w io.WriteCloser) error {
	if w == os.Stdout {
		return nil
	}
	return w.Close()
}
