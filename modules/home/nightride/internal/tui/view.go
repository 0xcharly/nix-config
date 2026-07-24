package tui

import (
	"fmt"
	"strings"
	"time"

	tea "charm.land/bubbletea/v2"
	"charm.land/lipgloss/v2"

	"github.com/0xcharly/nix-config/nightride/internal/meta"
)

// nightride.fm palette (static/css/main.css): neon purple, magenta, and hot
// pink over black, with mint and aqua accents.
var (
	purple  = lipgloss.Color("#7F00FF")
	magenta = lipgloss.Color("#CC00FF")
	hotpink = lipgloss.Color("#FD0090")
	mint    = lipgloss.Color("#3dcd9a")
	aqua    = lipgloss.Color("#7bfde0")

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

const (
	volumeBarCells = 10
	historyLimit   = 10
)

// View implements tea.Model.
func (m Model) View() tea.View {
	var b strings.Builder

	// Header.
	b.WriteString(brandStyle.Render("▞▞ NIGHTRIDE FM"))
	if m.connected {
		b.WriteString("  " + liveStyle.Render("● LIVE"))
	} else {
		b.WriteString("  " + offlineStyle.Render("○ OFFLINE"))
	}
	b.WriteString("\n" + m.stationStrip() + "\n\n")

	// Now playing, in a neon-framed window.
	if np, ok := m.now[m.station]; ok {
		lines := []string{
			artistStyle.Render(np.track.Artist),
			np.track.Title,
		}
		// Snapshot entries have an unknowable start; no elapsed line.
		if np.sinceKnown {
			if elapsed := time.Since(np.since); elapsed >= 0 {
				lines = append(lines, elapsedStyle.Render(formatElapsed(elapsed)))
			}
		}
		b.WriteString(window("NOW PLAYING", lines) + "\n\n")
	} else {
		b.WriteString(m.spin.View() + " tuning…\n\n")
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

// stationStrip renders the cycle list with the tuned station highlighted; a
// custom -station outside the cycle is appended.
func (m Model) stationStrip() string {
	parts := make([]string, 0, len(meta.Stations)+1)
	tunedInCycle := false
	for _, s := range meta.Stations {
		if s == m.station {
			tunedInCycle = true
			parts = append(parts, tunedStyle.Render(s))
		} else {
			parts = append(parts, dimStyle.Render(s))
		}
	}
	if !tunedInCycle {
		parts = append(parts, tunedStyle.Render(m.station))
	}
	return strings.Join(parts, " ")
}

// window renders a square frame with a pinstriped title bar and a centered
// label.
func window(title string, lines []string) string {
	labelW := lipgloss.Width(title) + 2 // spaces around the label
	inner := labelW + 8                 // minimum room for the pinstripes
	for _, l := range lines {
		if w := lipgloss.Width(l); w > inner {
			inner = w
		}
	}

	leftW := (inner - labelW) / 2
	rightW := inner - labelW - leftW
	hbar := strings.Repeat("─", inner+2)

	var b strings.Builder
	b.WriteString(frameStyle.Render("┌"+hbar+"┐") + "\n")
	b.WriteString(frameStyle.Render("│ "+strings.Repeat("─", leftW)) +
		" " + titleStyle.Render(title) + " " +
		frameStyle.Render(strings.Repeat("─", rightW)+" │") + "\n")
	b.WriteString(frameStyle.Render("├"+hbar+"┤") + "\n")
	for _, l := range lines {
		pad := strings.Repeat(" ", inner-lipgloss.Width(l))
		b.WriteString(frameStyle.Render("│ ") + l + pad + frameStyle.Render(" │") + "\n")
	}
	b.WriteString(frameStyle.Render("└" + hbar + "┘"))
	return b.String()
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
