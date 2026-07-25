package art

import (
	"encoding/base64"
	"fmt"
	"io"
	"strings"
)

// Kitty graphics protocol, Unicode-placeholder flavor
// (https://sw.kovidgoyal.net/kitty/graphics-protocol/#unicode-placeholders):
// image data is transmitted once per slot id, a virtual placement (U=1)
// defines its Cols×Rows grid, and the view marks ordinary text cells with
// U+10EEEE plus row/column diacritics. The terminal draws the image over
// those cells, so covers survive bubbletea's cell-diff renderer and tmux
// (via the passthrough envelope; requires `allow-passthrough on`).

// placeholder marks a cell as part of an image placement.
const placeholder = '\U0010EEEE'

// chunkSize is the maximum base64 payload per graphics escape (spec: 4096).
const chunkSize = 4096

// diacritics encode row/column indices on placeholder cells — the first 16
// entries of kitty's rowcolumn-diacritics table, enough for Cols and Rows.
var diacritics = [...]rune{
	0x0305, 0x030D, 0x030E, 0x0310, 0x0312, 0x033D, 0x033E, 0x033F,
	0x0346, 0x034A, 0x034B, 0x034C, 0x0350, 0x0351, 0x0352, 0x0357,
}

// Transmit writes png into kitty image slot id (1–255) and (re)creates its
// Cols×Rows virtual placement. Transmitting to an existing id replaces the
// image, so placeholder cells pick up the new cover with no extra
// bookkeeping.
func Transmit(w io.Writer, id int, png []byte, tmux bool) error {
	var b strings.Builder
	data := base64.StdEncoding.EncodeToString(png)
	first := true
	for len(data) > 0 {
		n := min(len(data), chunkSize)
		chunk, rest := data[:n], data[n:]
		more := 0
		if len(rest) > 0 {
			more = 1
		}
		if first {
			writeAPC(&b, fmt.Sprintf("Ga=t,f=100,t=d,i=%d,q=2,m=%d;%s", id, more, chunk), tmux)
			first = false
		} else {
			writeAPC(&b, fmt.Sprintf("Gm=%d;%s", more, chunk), tmux)
		}
		data = rest
	}
	writeAPC(&b, fmt.Sprintf("Ga=p,i=%d,U=1,c=%d,r=%d,q=2", id, Cols, Rows), tmux)
	_, err := io.WriteString(w, b.String())
	return err
}

// Query writes the graphics-capability probe: terminals speaking the
// protocol answer with an APC G response carrying id and "OK".
func Query(w io.Writer, id int, tmux bool) error {
	var b strings.Builder
	writeAPC(&b, fmt.Sprintf("Gi=%d,s=1,v=1,a=q,t=d,f=24;AAAA", id), tmux)
	_, err := io.WriteString(w, b.String())
	return err
}

// Placeholder returns the Rows view lines of placeholder cells for image
// slot id (1–255): the foreground color carries the id, diacritics the
// cell's row/column. The terminal substitutes the placed image.
func Placeholder(id int) []string {
	lines := make([]string, Rows)
	var b strings.Builder
	for row := range Rows {
		b.Reset()
		fmt.Fprintf(&b, "\x1b[38;5;%dm", id)
		for col := range Cols {
			b.WriteRune(placeholder)
			b.WriteRune(diacritics[row])
			b.WriteRune(diacritics[col])
		}
		b.WriteString("\x1b[39m")
		lines[row] = b.String()
	}
	return lines
}

// writeAPC emits one APC sequence, wrapped in a tmux passthrough envelope
// (ESC doubled per tmux(1)) when requested.
func writeAPC(b *strings.Builder, payload string, tmux bool) {
	seq := "\x1b_" + payload + "\x1b\\"
	if tmux {
		seq = "\x1bPtmux;" + strings.ReplaceAll(seq, "\x1b", "\x1b\x1b") + "\x1b\\"
	}
	b.WriteString(seq)
}
