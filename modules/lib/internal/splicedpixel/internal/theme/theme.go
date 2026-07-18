// Package theme loads a splicedpixel theme.toml, resolves its expressions
// against a base palette, and exposes the resolved tokens.
package theme

import (
	"fmt"
	"slices"
	"strings"

	"github.com/0xcharly/nix-config/splicedpixel/internal/color"
	"github.com/BurntSushi/toml"
)

// Theme is the raw, unresolved content of a theme.toml.
type Theme struct {
	Name     string
	Families map[string]string // family alias -> base palette family
	Palette  map[string]string // custom color name -> expression
	Tokens   map[string]string // token name -> expression

	// File-order key lists (TOML tables are unordered maps otherwise).
	FamilyOrder  []string
	PaletteOrder []string
	TokenOrder   []string
}

type rawTheme struct {
	Name     string            `toml:"name"`
	Families map[string]string `toml:"families"`
	Palette  map[string]string `toml:"palette"`
	Tokens   map[string]string `toml:"tokens"`
}

// Load parses a theme.toml file.
func Load(path string) (*Theme, error) {
	var raw rawTheme
	md, err := toml.DecodeFile(path, &raw)
	if err != nil {
		return nil, err
	}
	if undec := md.Undecoded(); len(undec) > 0 {
		return nil, fmt.Errorf("unknown key %q in %s", undec[0], path)
	}
	if raw.Name == "" {
		return nil, fmt.Errorf("missing 'name' in %s", path)
	}
	t := &Theme{
		Name:     raw.Name,
		Families: orDefault(raw.Families),
		Palette:  orDefault(raw.Palette),
		Tokens:   orDefault(raw.Tokens),
	}
	for _, key := range md.Keys() {
		parts := key
		if len(parts) != 2 {
			continue
		}
		switch parts[0] {
		case "families":
			t.FamilyOrder = append(t.FamilyOrder, parts[1])
		case "palette":
			t.PaletteOrder = append(t.PaletteOrder, parts[1])
		case "tokens":
			t.TokenOrder = append(t.TokenOrder, parts[1])
		}
	}
	return t, nil
}

func orDefault(m map[string]string) map[string]string {
	if m == nil {
		return map[string]string{}
	}
	return m
}

// Resolved is a fully evaluated theme.
type Resolved struct {
	Name    string
	Tokens  map[string]color.Color
	Palette map[string]color.Color // resolved [palette] customs

	FamilyOrder  []string
	PaletteOrder []string
	TokenOrder   []string
	Families     map[string]string
	Base         map[string]color.Color
}

// Resolve evaluates every [palette] and [tokens] expression against the base
// palette. Base maps full color names (e.g. "zinc-300", "white") to colors.
func (t *Theme) Resolve(base map[string]color.Color) (*Resolved, error) {
	for name := range t.Palette {
		if _, clash := t.Tokens[name]; clash {
			return nil, fmt.Errorf("%q defined in both [palette] and [tokens]", name)
		}
	}
	for alias, target := range t.Families {
		if hasFamily(base, alias) {
			return nil, fmt.Errorf("family alias %q shadows the base palette family of the same name", alias)
		}
		if !hasFamily(base, target) {
			return nil, fmt.Errorf("family alias %q targets unknown palette family %q", alias, target)
		}
	}

	r := &resolver{
		theme: t,
		base:  base,
		memo:  map[string]color.Color{},
	}
	res := &Resolved{
		Name:         t.Name,
		Tokens:       map[string]color.Color{},
		Palette:      map[string]color.Color{},
		FamilyOrder:  t.FamilyOrder,
		PaletteOrder: t.PaletteOrder,
		TokenOrder:   t.TokenOrder,
		Families:     t.Families,
		Base:         base,
	}
	for _, name := range sortedKeys(t.Palette) {
		c, err := r.resolveName(name, false)
		if err != nil {
			return nil, err
		}
		res.Palette[name] = c
	}
	for _, name := range sortedKeys(t.Tokens) {
		c, err := r.resolveName(name, true)
		if err != nil {
			return nil, err
		}
		res.Tokens[name] = c
	}
	return res, nil
}

func hasFamily(base map[string]color.Color, family string) bool {
	for name := range base {
		if rest, ok := strings.CutPrefix(name, family+"-"); ok && rest != "" {
			return true
		}
	}
	return false
}

func sortedKeys(m map[string]string) []string {
	keys := make([]string, 0, len(m))
	for k := range m {
		keys = append(keys, k)
	}
	slices.Sort(keys)
	return keys
}

type resolver struct {
	theme *Theme
	base  map[string]color.Color
	memo  map[string]color.Color // key: "t:"+name or "p:"+name
	stack []string
}

// resolveName evaluates a [tokens] (tokenScope) or [palette] entry by name.
func (r *resolver) resolveName(name string, tokenScope bool) (color.Color, error) {
	key := "p:" + name
	src := r.theme.Palette
	if tokenScope {
		key = "t:" + name
		src = r.theme.Tokens
	}
	if c, ok := r.memo[key]; ok {
		return c, nil
	}
	if slices.Contains(r.stack, key) {
		chain := append(slices.Clone(r.stack[slices.Index(r.stack, key):]), key)
		for i, k := range chain {
			chain[i] = k[2:]
		}
		return color.Color{}, fmt.Errorf("reference cycle: %s", strings.Join(chain, " -> "))
	}
	expr := src[name]
	n, err := parseExpr(expr)
	if err != nil {
		return color.Color{}, fmt.Errorf("%s = %q: %w", name, expr, err)
	}
	r.stack = append(r.stack, key)
	c, err := r.eval(n, tokenScope)
	r.stack = r.stack[:len(r.stack)-1]
	if err != nil {
		return color.Color{}, fmt.Errorf("%s = %q: %w", name, expr, err)
	}
	r.memo[key] = c
	return c, nil
}

// lookup resolves an identifier: token (token scope only), then custom
// palette entry, then family-alias rewrite, then direct base palette.
func (r *resolver) lookup(name string, tokenScope bool) (color.Color, error) {
	if tokenScope {
		if _, ok := r.theme.Tokens[name]; ok {
			return r.resolveName(name, true)
		}
	}
	if _, ok := r.theme.Palette[name]; ok {
		return r.resolveName(name, false)
	}
	if !tokenScope {
		if _, isToken := r.theme.Tokens[name]; isToken {
			return color.Color{}, fmt.Errorf("[palette] entries cannot reference token %q", name)
		}
	}
	if i := strings.LastIndexByte(name, '-'); i > 0 {
		if family, ok := r.theme.Families[name[:i]]; ok {
			rewritten := family + name[i:]
			if c, ok := r.base[rewritten]; ok {
				return c, nil
			}
			return color.Color{}, fmt.Errorf("%q (via family alias %q) not in palette", rewritten, name[:i])
		}
	}
	if c, ok := r.base[name]; ok {
		return c, nil
	}
	return color.Color{}, fmt.Errorf("unknown identifier %q", name)
}

func (r *resolver) eval(n node, tokenScope bool) (color.Color, error) {
	switch n := n.(type) {
	case identNode:
		return r.lookup(n.name, tokenScope)
	case hexNode:
		return color.FromSRGB(n.rgb[0], n.rgb[1], n.rgb[2]), nil
	case callNode:
		return r.evalCall(n, tokenScope)
	}
	return color.Color{}, fmt.Errorf("unhandled expression node %T", n)
}

// colorArg evaluates args[i], requiring a plain color (no alpha, no percent).
func (r *resolver) colorArg(call callNode, i int, tokenScope bool) (color.Color, error) {
	a := call.args[i]
	if a.percent != nil {
		return color.Color{}, fmt.Errorf("%s: argument %d must be a color, got a percentage", call.fn, i+1)
	}
	if a.alpha != nil {
		return color.Color{}, fmt.Errorf("%s: alpha suffix only valid on blend's first argument", call.fn)
	}
	return r.eval(a.expr, tokenScope)
}

// percentArg returns args[i] as a 0-1 fraction, requiring a PERCENT arg.
func percentArg(call callNode, i int) (float64, error) {
	a := call.args[i]
	if a.percent == nil {
		return 0, fmt.Errorf("%s: argument %d must be a percentage (e.g. 15%%)", call.fn, i+1)
	}
	return *a.percent, nil
}

func arity(call callNode, want ...int) error {
	if slices.Contains(want, len(call.args)) {
		return nil
	}
	descr := make([]string, len(want))
	for i, w := range want {
		descr[i] = fmt.Sprint(w)
	}
	return fmt.Errorf("%s: expected %s argument(s), got %d", call.fn, strings.Join(descr, " or "), len(call.args))
}

func (r *resolver) evalCall(call callNode, tokenScope bool) (color.Color, error) {
	switch call.fn {
	case "darken", "lighten", "saturate", "desaturate":
		if err := arity(call, 2); err != nil {
			return color.Color{}, err
		}
		c, err := r.colorArg(call, 0, tokenScope)
		if err != nil {
			return color.Color{}, err
		}
		p, err := percentArg(call, 1)
		if err != nil {
			return color.Color{}, err
		}
		switch call.fn {
		case "darken":
			return color.Darken(c, p), nil
		case "lighten":
			return color.Lighten(c, p), nil
		case "saturate":
			return color.Chroma(c, 1+p), nil
		default: // desaturate
			return color.Chroma(c, 1-p), nil
		}
	case "mix":
		if err := arity(call, 2, 3); err != nil {
			return color.Color{}, err
		}
		a, err := r.colorArg(call, 0, tokenScope)
		if err != nil {
			return color.Color{}, err
		}
		b, err := r.colorArg(call, 1, tokenScope)
		if err != nil {
			return color.Color{}, err
		}
		p := 0.5
		if len(call.args) == 3 {
			if p, err = percentArg(call, 2); err != nil {
				return color.Color{}, err
			}
		}
		return color.Mix(a, b, p), nil
	case "blend":
		if err := arity(call, 2); err != nil {
			return color.Color{}, err
		}
		fgArg := call.args[0]
		if fgArg.percent != nil {
			return color.Color{}, fmt.Errorf("blend: first argument must be a color")
		}
		fg, err := r.eval(fgArg.expr, tokenScope)
		if err != nil {
			return color.Color{}, err
		}
		alpha := 0.5
		if fgArg.alpha != nil {
			alpha = *fgArg.alpha
		}
		bg, err := r.colorArg(call, 1, tokenScope)
		if err != nil {
			return color.Color{}, err
		}
		return color.Blend(fg, alpha, bg), nil
	default:
		return color.Color{}, fmt.Errorf("unknown function %q", call.fn)
	}
}
