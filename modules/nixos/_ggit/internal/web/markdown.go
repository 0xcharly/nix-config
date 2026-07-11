package web

import (
	"bytes"
	"html/template"
	"net/url"
	"path"
	"strings"

	"github.com/yuin/goldmark"
	"github.com/yuin/goldmark/ast"
	"github.com/yuin/goldmark/extension"
	"github.com/yuin/goldmark/parser"
	"github.com/yuin/goldmark/text"
)

// markdown is the shared converter: GFM (tables, strikethrough, autolinks,
// task lists) plus auto heading IDs so intra-document #fragment links work.
// Raw HTML is omitted by goldmark's default renderer, so the output is safe
// to emit as template.HTML without a sanitizer.
var markdown = goldmark.New(
	goldmark.WithExtensions(extension.GFM),
	goldmark.WithParserOptions(parser.WithAutoHeadingID()),
)

// mdResolver rewrites relative markdown destinations onto ggit pages so
// intra-repo links keep working: anchors get tree URLs, image sources get
// raw blob URLs.
type mdResolver struct {
	owner, repo string
	refParam    url.Values // {"ref": {ref}} when ?ref= was explicit, else nil
	dir         string     // slash-separated directory of the document, "" at repo root
}

// resolve maps a relative link destination to a tree URL. Absolute URLs,
// root-relative paths, pure fragments, and paths escaping the repo root are
// returned unchanged.
func (m mdResolver) resolve(dest string) string { return m.rewrite(dest, "tree") }

// resolveImage maps a relative image source to a raw blob URL so inline
// images render; the raw endpoint serves image/* with the sniffed type.
func (m mdResolver) resolveImage(dest string) string { return m.rewrite(dest, "raw") }

func (m mdResolver) rewrite(dest, pageName string) string {
	if dest == "" || strings.HasPrefix(dest, "#") || strings.HasPrefix(dest, "/") {
		return dest
	}
	if u, err := url.Parse(dest); err != nil || u.Scheme != "" || u.Host != "" {
		return dest
	}
	target, frag, _ := strings.Cut(dest, "#")
	target, err := url.PathUnescape(target)
	if err != nil {
		return dest
	}
	cleaned := path.Clean(path.Join(m.dir, target))
	if cleaned == ".." || strings.HasPrefix(cleaned, "../") {
		return dest
	}
	q := url.Values{}
	for k, v := range m.refParam {
		q[k] = v
	}
	if cleaned == "." {
		if pageName == "raw" {
			return dest // a directory cannot be served raw
		}
	} else {
		q.Set("path", cleaned)
	}
	u := repoURL(m.owner, m.repo, pageName, q)
	if frag != "" {
		u += "#" + frag
	}
	return u
}

// markdownHTML converts src to HTML with intra-repo links and image sources
// rewritten through res. The renderer writing to a bytes.Buffer cannot
// realistically fail; the escaped-<pre> fallback only guards against future
// renderer changes.
func markdownHTML(src []byte, res mdResolver) template.HTML {
	root := markdown.Parser().Parse(text.NewReader(src))
	_ = ast.Walk(root, func(n ast.Node, entering bool) (ast.WalkStatus, error) {
		if entering {
			switch n := n.(type) {
			case *ast.Link:
				n.Destination = []byte(res.resolve(string(n.Destination)))
			case *ast.Image:
				n.Destination = []byte(res.resolveImage(string(n.Destination)))
			}
		}
		return ast.WalkContinue, nil
	})
	var buf bytes.Buffer
	if err := markdown.Renderer().Render(&buf, src, root); err != nil {
		return template.HTML("<pre>" + template.HTMLEscapeString(string(src)) + "</pre>")
	}
	return template.HTML(buf.String())
}
