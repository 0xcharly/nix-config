package tui

import (
	"fmt"
	"image/color"
	"strings"
	"time"

	tea "charm.land/bubbletea/v2"
	"charm.land/lipgloss/v2"

	"github.com/0xcharly/nix-config/nightride/internal/art"
)

// nightride.fm palette (static/css/main.css): neon purple, magenta, and hot
// pink over black, with mint and aqua accents.
var (
	purple  = lipgloss.Color("#7F00FF")
	magenta = lipgloss.Color("#CC00FF")
	hotpink = lipgloss.Color("#FD0090")
	mint    = lipgloss.Color("#3dcd9a")
	aqua    = lipgloss.Color("#7bfde0")
	sunset  = lipgloss.Color("#FFD319")
	ember   = lipgloss.Color("#FF901F")
	electro = lipgloss.Color("#00B3FE")

	brandStyle   = lipgloss.NewStyle().Foreground(magenta).Bold(true)
	liveStyle    = lipgloss.NewStyle().Foreground(mint).Bold(true)
	offlineStyle = lipgloss.NewStyle().Foreground(hotpink).Bold(true)
	tunedStyle   = lipgloss.NewStyle().Foreground(magenta).Bold(true)
	artistStyle  = lipgloss.NewStyle().Foreground(aqua).Bold(true)
	elapsedStyle = lipgloss.NewStyle().Faint(true)
	frameStyle   = lipgloss.NewStyle().Foreground(purple)
	titleStyle   = lipgloss.NewStyle().Foreground(magenta).Bold(true)
	playStyle    = lipgloss.NewStyle().Foreground(mint)
	pauseStyle   = lipgloss.NewStyle().Foreground(hotpink)
	volumeStyle  = lipgloss.NewStyle().Foreground(mint)
	dimStyle     = lipgloss.NewStyle().Faint(true)
	errStyle     = lipgloss.NewStyle().Foreground(hotpink)
)

// stationPalette colors the listeners-bar segments and station bullets,
// indexed by display order. Hue families alternate so adjacent bar
// segments stay distinguishable.
var stationPalette = [...]color.Color{
	magenta, mint, hotpink, aqua, sunset, purple, ember, electro,
}

// placeholderArt stands in while a cover is loading or none exists.
var placeholderArt = func() []string {
	lines := make([]string, art.Rows)
	for i := range lines {
		row := []rune(strings.Repeat("░", art.Cols))
		if i == art.Rows/2 {
			row[art.Cols/2] = '♪'
		}
		lines[i] = frameStyle.Render(string(row))
	}
	return lines
}()

const (
	volumeBarCells = 10
	historyLimit   = 10
	defaultWidth   = 80
)

// View implements tea.Model.
func (m Model) View() tea.View {
	width := m.width
	if width <= 0 {
		width = defaultWidth
	}

	var b strings.Builder

	// Header.
	b.WriteString(brandStyle.Render("▞▞ NIGHTRIDE FM"))
	if m.connected {
		b.WriteString("  " + liveStyle.Render("● LIVE"))
	} else {
		b.WriteString("  " + offlineStyle.Render("○ OFFLINE"))
	}
	if m.listeners != nil {
		b.WriteString(dimStyle.Render(fmt.Sprintf("   %d listening", m.totalListeners())))
	}
	b.WriteString("\n" + m.listenersBar(width) + "\n\n")

	// Stations, laid out vertically: cover, station, track, listeners.
	for i, s := range m.stations {
		b.WriteString(m.stationCard(i, s) + "\n\n")
	}

	// Player line.
	b.WriteString(m.playerLine() + "\n")

	// History (client-derived; empty right after connect).
	if hist := m.history[m.station]; len(hist) > 0 {
		b.WriteString("\n" + dimStyle.Render("recently played") + "\n")
		for _, t := range hist {
			b.WriteString(dimStyle.Render("  "+t.Artist+" — "+t.Title) + "\n")
		}
	}

	// Footer.
	b.WriteString("\n" + m.help.View(m.keys))
	if m.metaErr != nil {
		b.WriteString("\n" + errStyle.Render("meta feed lost: "+m.metaErr.Error()+" — retrying"))
	}
	if m.playerErr != nil {
		b.WriteString("\n" + errStyle.Render(m.playerErr.Error()))
	}

	v := tea.NewView(b.String())
	v.AltScreen = true
	return v
}

// totalListeners sums the poll counts over the displayed stations.
func (m Model) totalListeners() int {
	total := 0
	for _, s := range m.stations {
		total += m.listeners[s]
	}
	return total
}

// listenersBar renders one full-width segment per displayed station, sized
// by its share of the total listener count. Cumulative rounding keeps the
// segment widths summing exactly to width.
func (m Model) listenersBar(width int) string {
	total := m.totalListeners()
	if total == 0 {
		return dimStyle.Render(strings.Repeat("░", width))
	}
	var b strings.Builder
	acc, prev := 0, 0
	for i, s := range m.stations {
		acc += m.listeners[s]
		edge := acc * width / total
		if seg := edge - prev; seg > 0 {
			b.WriteString(lipgloss.NewStyle().
				Foreground(stationPalette[i%len(stationPalette)]).
				Render(strings.Repeat("█", seg)))
		}
		prev = edge
	}
	return b.String()
}

// stationCard renders one station entry: the cover (or placeholder) beside
// the station name, track title, artist, and listener count. The tuned
// station is highlighted and shows the track's elapsed time when known.
func (m Model) stationCard(idx int, station string) string {
	np, ok := m.now[station]

	cover := placeholderArt
	if ok {
		switch {
		case m.kittyOK:
			// Placeholder cells are drawn only once the slot holds this
			// track's cover; half-blocks are never mixed in.
			if m.kittySlots[station] == np.track.TrackID {
				cover = art.Placeholder(idx + 1)
			}
		default:
			if c := m.artCache[np.track.TrackID]; c.Cells != nil {
				cover = c.Cells
			}
		}
	}

	var name string
	if station == m.station {
		name = tunedStyle.Render("▶ " + station)
		if ok && np.sinceKnown {
			if elapsed := time.Since(np.since); elapsed >= 0 {
				name += elapsedStyle.Render("  " + formatElapsed(elapsed))
			}
		}
	} else {
		name = dimStyle.Render("  " + station)
	}

	title, artist := m.spin.View()+dimStyle.Render(" tuning…"), ""
	if ok {
		if station == m.station {
			title = titleStyle.Render(np.track.Title)
			artist = artistStyle.Render(np.track.Artist)
		} else {
			title = np.track.Title
			artist = dimStyle.Render(np.track.Artist)
		}
	}

	bullet := lipgloss.NewStyle().Foreground(stationPalette[idx%len(stationPalette)]).Render("●")
	listens := bullet + dimStyle.Render(" …")
	if m.listeners != nil {
		listens = bullet + fmt.Sprintf(" %d listening", m.listeners[station])
	}

	text := name + "\n  " + title + "\n  " + artist + "\n  " + listens
	return lipgloss.JoinHorizontal(lipgloss.Top, strings.Join(cover, "\n"), "  ", text)
}

func (m Model) playerLine() string {
	var state string
	switch {
	case m.starting:
		state = m.spin.View() + " connecting"
	case m.player == nil:
		return dimStyle.Render("■ stopped — press space to reconnect")
	case m.paused:
		state = pauseStyle.Render("⏸ paused")
	default:
		state = playStyle.Render("▶ playing")
	}
	if m.muted {
		return state + "   " + dimStyle.Render("vol muted")
	}
	filled := m.volume * volumeBarCells / 100
	bar := volumeStyle.Render(strings.Repeat("█", filled)) +
		frameStyle.Render(strings.Repeat("░", volumeBarCells-filled))
	return fmt.Sprintf("%s   vol %s %d%%", state, bar, m.volume)
}

func formatElapsed(d time.Duration) string {
	d = d.Round(time.Second)
	h := int(d.Hours())
	mn := int(d.Minutes()) % 60
	s := int(d.Seconds()) % 60
	if h > 0 {
		return fmt.Sprintf("%d:%02d:%02d", h, mn, s)
	}
	return fmt.Sprintf("%02d:%02d", mn, s)
}
