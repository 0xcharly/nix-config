package theme

import (
	"os"
	"path/filepath"
	"strings"
	"testing"

	"github.com/0xcharly/nix-config/splicedpixel/internal/color"
)

func testBase() map[string]color.Color {
	return map[string]color.Color{
		"zinc-300":  color.FromOKLCH(0.871, 0.006, 286.286), // d4d4d8
		"zinc-900":  color.FromOKLCH(0.21, 0.006, 285.885),  // 18181b
		"slate-300": color.FromOKLCH(0.869, 0.022, 252.894), // cad5e2
		"blue-400":  color.FromOKLCH(0.707, 0.165, 254.624),
		"black":     color.FromOKLCH(0, 0, 0),
		"white":     color.FromOKLCH(1, 0, 0),
	}
}

func loadTheme(t *testing.T, body string) *Theme {
	t.Helper()
	path := filepath.Join(t.TempDir(), "theme.toml")
	if err := os.WriteFile(path, []byte(body), 0o644); err != nil {
		t.Fatal(err)
	}
	th, err := Load(path)
	if err != nil {
		t.Fatalf("Load: %v", err)
	}
	return th
}

func resolveOne(t *testing.T, body, token string) string {
	t.Helper()
	res, err := loadTheme(t, body).Resolve(testBase())
	if err != nil {
		t.Fatalf("Resolve: %v", err)
	}
	return res.Tokens[token].Hex()
}

func TestFamilyAlias(t *testing.T) {
	base := `name = "test"
[families]
base = "zinc"
[tokens]
text = "base-300"
`
	if got := resolveOne(t, base, "text"); got != "d4d4d8" {
		t.Errorf("base=zinc: text = %s, want d4d4d8", got)
	}
	slate := strings.Replace(base, `base = "zinc"`, `base = "slate"`, 1)
	if got := resolveOne(t, slate, "text"); got != "cad5e2" {
		t.Errorf("base=slate: text = %s, want cad5e2", got)
	}
}

func TestErrorFamilyAliasShadowsPaletteFamily(t *testing.T) {
	body := `name = "test"
[families]
neutral = "zinc"
[tokens]
text = "neutral-300"
`
	shadowed := testBase()
	shadowed["neutral-300"] = color.FromOKLCH(0.87, 0, 0)
	_, err := loadTheme(t, body).Resolve(shadowed)
	if err == nil || !strings.Contains(err.Error(), "shadows") {
		t.Fatalf("want alias-shadows-family error, got %v", err)
	}
}

func TestTokenReferenceAndNestedCall(t *testing.T) {
	body := `name = "test"
[families]
base = "zinc"
[tokens]
surface = "base-900"
a = "darken(blend(blue-400/20, surface), 5%)"
b = "a"
`
	res, err := loadTheme(t, body).Resolve(testBase())
	if err != nil {
		t.Fatalf("Resolve: %v", err)
	}
	if res.Tokens["a"] != res.Tokens["b"] {
		t.Errorf("token ref: b = %s, want a = %s", res.Tokens["b"].Hex(), res.Tokens["a"].Hex())
	}
	// blend(blue-400/20, 18181b) in gamma sRGB then darken 5% must be darker
	// than the plain blend.
	blend := color.Blend(testBase()["blue-400"], 0.2, testBase()["zinc-900"])
	if res.Tokens["a"].L >= blend.L {
		t.Errorf("darken did not reduce lightness: %v >= %v", res.Tokens["a"].L, blend.L)
	}
}

func TestErrorCycle(t *testing.T) {
	body := `name = "test"
[tokens]
a = "b"
b = "a"
`
	_, err := loadTheme(t, body).Resolve(testBase())
	if err == nil {
		t.Fatal("want cycle error")
	}
	msg := err.Error()
	if !strings.Contains(msg, "cycle") || !strings.Contains(msg, "a") || !strings.Contains(msg, "b") {
		t.Errorf("cycle error should name both tokens: %q", msg)
	}
}

func TestErrorUnknownIdent(t *testing.T) {
	body := `name = "test"
[tokens]
text = "no-such-color"
`
	_, err := loadTheme(t, body).Resolve(testBase())
	if err == nil || !strings.Contains(err.Error(), "no-such-color") {
		t.Fatalf("want unknown identifier error, got %v", err)
	}
}

func TestErrorBlendArity(t *testing.T) {
	body := `name = "test"
[tokens]
text = "blend(white/10)"
`
	_, err := loadTheme(t, body).Resolve(testBase())
	if err == nil || !strings.Contains(err.Error(), "blend") {
		t.Fatalf("want blend arity error, got %v", err)
	}
}

func TestErrorPaletteReferencingToken(t *testing.T) {
	body := `name = "test"
[palette]
custom = "text"
[tokens]
text = "zinc-300"
`
	_, err := loadTheme(t, body).Resolve(testBase())
	if err == nil || !strings.Contains(err.Error(), "token") {
		t.Fatalf("want palette-references-token error, got %v", err)
	}
}

func TestErrorPercentRange(t *testing.T) {
	body := `name = "test"
[tokens]
text = "darken(zinc-300, 250%)"
`
	_, err := loadTheme(t, body).Resolve(testBase())
	if err == nil || !strings.Contains(err.Error(), "[0, 100]") {
		t.Fatalf("want percent range error, got %v", err)
	}
}

func TestHexLiteral(t *testing.T) {
	body := `name = "test"
[tokens]
magenta = "#ff00ff"
`
	if got := resolveOne(t, body, "magenta"); got != "ff00ff" {
		t.Errorf("hex literal: got %s, want ff00ff", got)
	}
}

func TestFileOrderPreserved(t *testing.T) {
	body := `name = "test"
[tokens]
zz = "zinc-300"
aa = "zinc-900"
mm = "zz"
`
	th := loadTheme(t, body)
	want := []string{"zz", "aa", "mm"}
	if len(th.TokenOrder) != len(want) {
		t.Fatalf("TokenOrder = %v, want %v", th.TokenOrder, want)
	}
	for i, name := range want {
		if th.TokenOrder[i] != name {
			t.Fatalf("TokenOrder = %v, want %v", th.TokenOrder, want)
		}
	}
}
