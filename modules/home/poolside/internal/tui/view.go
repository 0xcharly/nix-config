package tui

import (
	"fmt"
	"strings"
	"time"

	tea "charm.land/bubbletea/v2"
	"charm.land/lipgloss/v2"

	"github.com/0xcharly/nix-config/poolside/internal/station"
)

// Poolsuite palette (poolsuite.net, formerly Poolside FM): teal and coral
// pink over the cream/blush chrome of its classic Mac OS desktop.
var (
	teal  = lipgloss.Color("#49C5B6")
	coral = lipgloss.Color("#FF9398")
	cream = lipgloss.Color("#F9EFE4")
	blush = lipgloss.Color("#F6D5D5")

	brandStyle   = lipgloss.NewStyle().Foreground(coral).Bold(true)
	liveStyle    = lipgloss.NewStyle().Foreground(teal).Bold(true)
	offlineStyle = lipgloss.NewStyle().Foreground(coral).Bold(true)
	artistStyle  = lipgloss.NewStyle().Foreground(cream).Bold(true)
	elapsedStyle = lipgloss.NewStyle().Foreground(blush).Faint(true)
	frameStyle   = lipgloss.NewStyle().Foreground(blush)
	titleStyle   = lipgloss.NewStyle().Foreground(coral).Bold(true)
	playStyle    = lipgloss.NewStyle().Foreground(teal)
	pauseStyle   = lipgloss.NewStyle().Foreground(coral)
	volumeStyle  = lipgloss.NewStyle().Foreground(teal)
	dimStyle     = lipgloss.NewStyle().Faint(true)
	errStyle     = lipgloss.NewStyle().Foreground(coral)
)

const (
	volumeBarCells = 10
	historyLimit   = 10
)

// View implements tea.Model.
func (m Model) View() tea.View {
	var b strings.Builder

	// Header.
	b.WriteString(brandStyle.Render("☼ POOLSIDE FM"))
	if m.status.Status == "online" {
		b.WriteString("  " + liveStyle.Render("● LIVE"))
	} else {
		b.WriteString("  " + offlineStyle.Render("○ OFFLINE"))
	}
	b.WriteString("  " + dimStyle.Render(m.client.StationID) + "\n\n")

	if !m.haveStatus {
		b.WriteString(m.spin.View() + " fetching station status…\n")
	} else {
		// Now playing, in a classic Mac OS window.
		artist, track := station.SplitTitle(m.status.CurrentTrack.Title)
		var lines []string
		if artist != "" {
			lines = append(lines, artistStyle.Render(artist))
		}
		lines = append(lines, track)
		if started, ok := m.status.CurrentTrack.Started(); ok {
			if elapsed := time.Since(started); elapsed >= 0 {
				lines = append(lines, elapsedStyle.Render(formatElapsed(elapsed)))
			}
		}
		b.WriteString(window("NOW PLAYING", lines) + "\n\n")

		// Player line.
		b.WriteString(m.playerLine() + "\n")

		// History; entry 0 duplicates the current track.
		if len(m.status.History) > 1 {
			hist := m.status.History[1:]
			if len(hist) > historyLimit {
				hist = hist[:historyLimit]
			}
			b.WriteString("\n" + dimStyle.Render("recently played") + "\n")
			for _, t := range hist {
				b.WriteString(dimStyle.Render("  "+t.Title) + "\n")
			}
		}
	}

	// Footer.
	b.WriteString("\n" + m.help.View(m.keys))
	if m.haveStatus && m.statusErr != nil {
		b.WriteString("\n" + errStyle.Render("status stale: "+m.statusErr.Error()))
	} else if !m.haveStatus && m.statusErr != nil {
		b.WriteString("\n" + errStyle.Render("status fetch failed: "+m.statusErr.Error()))
	}
	if m.playerErr != nil {
		b.WriteString("\n" + errStyle.Render(m.playerErr.Error()))
	}

	v := tea.NewView(b.String())
	v.AltScreen = true
	return v
}

// window renders a classic Mac OS style window: square chrome and a
// pinstriped title bar with a centered label.
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
