package web

import (
	"embed"
	"fmt"
	"html/template"
	"time"
)

//go:embed templates/*.html
var templateFS embed.FS

var templateFuncs = template.FuncMap{
	"reltime":  reltime,
	"bytesize": bytesize,
	"tabs":     func() []string { return []string{"about", "summary", "refs", "log", "tree"} },
}

var pageNames = []string{"index", "summary", "about", "refs", "log", "tree", "commit", "error"}

func parseTemplates() map[string]*template.Template {
	layout := template.Must(
		template.New("layout.html").Funcs(templateFuncs).ParseFS(templateFS, "templates/layout.html"),
	)
	m := make(map[string]*template.Template, len(pageNames))
	for _, name := range pageNames {
		m[name] = template.Must(
			template.Must(layout.Clone()).ParseFS(templateFS, "templates/"+name+".html"),
		)
	}
	return m
}

// reltime renders a cgit-style largest-unit relative age ("27 hours",
// "3 days"). Zero or negative timestamps render as an em dash.
func reltime(unix int64) string {
	if unix <= 0 {
		return "—"
	}
	secs := int64(time.Since(time.Unix(unix, 0)).Seconds())
	if secs < 0 {
		secs = 0
	}
	units := []struct {
		span int64
		name string
	}{
		{365 * 24 * 3600, "year"},
		{30 * 24 * 3600, "month"},
		{7 * 24 * 3600, "week"},
		{24 * 3600, "day"},
		{3600, "hour"},
		{60, "min"},
	}
	for _, u := range units {
		// cgit style: switch to a unit once two of it have elapsed, so ages
		// read "27 hours" rather than "1 day".
		if secs >= 2*u.span {
			n := secs / u.span
			if n == 1 {
				return fmt.Sprintf("1 %s", u.name)
			}
			return fmt.Sprintf("%d %ss", n, u.name)
		}
	}
	return fmt.Sprintf("%d sec", secs)
}

func bytesize(n int64) string {
	const unit = 1024
	if n < unit {
		return fmt.Sprintf("%d B", n)
	}
	div, exp := int64(unit), 0
	for m := n / unit; m >= unit; m /= unit {
		div *= unit
		exp++
	}
	return fmt.Sprintf("%.1f %ciB", float64(n)/float64(div), "KMGTPE"[exp])
}
