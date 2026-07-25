// Package art fetches cover art for tracks and renders it for the
// terminal: kitty-graphics PNG placements where supported, ANSI half-block
// cells otherwise. Covers live on the stream host, keyed by track_id
// (300×300 PNG); some tracks have none.
package art

import (
	"bytes"
	"context"
	"fmt"
	"image"
	_ "image/jpeg"
	_ "image/png" // covers are PNG
	"io"
	"net/http"
	"strings"
)

const (
	// Cols and Rows are the rendered size in terminal cells. Half blocks
	// pack two pixels per row and a cell is about half as wide as it is
	// tall, so 8×4 cells displays a square 8×8-pixel cover.
	Cols = 8
	Rows = 4

	coverURL = "https://lissen.to/files/covers/%s.png"
)

// maxCoverBytes bounds a cover download (covers are ~100 KiB).
const maxCoverBytes = 4 << 20

// Cover is one fetched cover in both render forms: raw PNG for kitty
// graphics transmission and pre-rendered half-block cells for terminals
// without it.
type Cover struct {
	PNG   []byte
	Cells []string
}

// Fetch downloads the cover for trackID. An error means "no art" (tracks
// without a cover serve an empty body): callers fall back to a placeholder.
func Fetch(ctx context.Context, trackID string) (Cover, error) {
	req, err := http.NewRequestWithContext(ctx, http.MethodGet, fmt.Sprintf(coverURL, trackID), nil)
	if err != nil {
		return Cover{}, err
	}
	resp, err := http.DefaultClient.Do(req)
	if err != nil {
		return Cover{}, err
	}
	defer resp.Body.Close()
	if resp.StatusCode != http.StatusOK {
		return Cover{}, fmt.Errorf("art: unexpected status %s for %s", resp.Status, trackID)
	}
	png, err := io.ReadAll(io.LimitReader(resp.Body, maxCoverBytes))
	if err != nil {
		return Cover{}, err
	}
	img, _, err := image.Decode(bytes.NewReader(png))
	if err != nil {
		return Cover{}, fmt.Errorf("art: %s: %w", trackID, err)
	}
	return Cover{PNG: png, Cells: render(img)}, nil
}

// render downscales the cover to Cols × 2·Rows pixels by box averaging and
// emits half-block lines: each ▀ carries the upper pixel as foreground and
// the lower one as background.
func render(img image.Image) []string {
	const pxRows = 2 * Rows
	bounds := img.Bounds()
	lines := make([]string, Rows)
	var b strings.Builder
	for row := range Rows {
		b.Reset()
		for col := range Cols {
			tr, tg, tb := boxAvg(img, bounds, col, 2*row, Cols, pxRows)
			br, bg, bb := boxAvg(img, bounds, col, 2*row+1, Cols, pxRows)
			fmt.Fprintf(&b, "\x1b[38;2;%d;%d;%dm\x1b[48;2;%d;%d;%dm▀", tr, tg, tb, br, bg, bb)
		}
		b.WriteString("\x1b[0m")
		lines[row] = b.String()
	}
	return lines
}

// boxAvg averages the source pixels mapping to cell (cx, cy) of a gw×gh
// grid over the image bounds.
func boxAvg(img image.Image, b image.Rectangle, cx, cy, gw, gh int) (r, g, bl uint8) {
	x0 := b.Min.X + cx*b.Dx()/gw
	x1 := max(b.Min.X+(cx+1)*b.Dx()/gw, x0+1)
	y0 := b.Min.Y + cy*b.Dy()/gh
	y1 := max(b.Min.Y+(cy+1)*b.Dy()/gh, y0+1)
	var sr, sg, sb, n uint64
	for y := y0; y < y1; y++ {
		for x := x0; x < x1; x++ {
			pr, pg, pb, _ := img.At(x, y).RGBA()
			sr += uint64(pr)
			sg += uint64(pg)
			sb += uint64(pb)
			n++
		}
	}
	return uint8(sr / n >> 8), uint8(sg / n >> 8), uint8(sb / n >> 8)
}
