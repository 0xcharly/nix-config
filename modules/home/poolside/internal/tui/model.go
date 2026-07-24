// Package tui implements the poolside bubbletea interface.
package tui

import (
	"context"
	"time"

	"charm.land/bubbles/v2/help"
	"charm.land/bubbles/v2/key"
	"charm.land/bubbles/v2/spinner"
	tea "charm.land/bubbletea/v2"
	"charm.land/lipgloss/v2"

	"github.com/0xcharly/nix-config/poolside/internal/player"
	"github.com/0xcharly/nix-config/poolside/internal/station"
)

const (
	statusInterval = 15 * time.Second
	fetchTimeout   = 10 * time.Second
	volumeStep     = 5
)

// Model is the top-level bubbletea model.
type Model struct {
	client  *station.Client
	mpvPath string

	status     station.Status
	haveStatus bool
	statusErr  error
	lastFetch  time.Time

	player    *player.Player // nil when stopped
	starting  bool           // startPlayerCmd in flight
	playerErr error
	paused    bool
	muted     bool
	volume    int

	width, height int
	spin          spinner.Model
	help          help.Model
	keys          keyMap
}

// New builds the initial model for the given station.
func New(stationID, mpvPath string) Model {
	return Model{
		client:  &station.Client{StationID: stationID},
		mpvPath: mpvPath,
		volume:  100,
		spin: spinner.New(
			spinner.WithSpinner(spinner.Dot),
			spinner.WithStyle(lipgloss.NewStyle().Foreground(teal)),
		),
		help:    help.New(),
		keys:    defaultKeyMap(),
	}
}

// Cleanup tears down the mpv subprocess. Called by main after the program
// exits, using the final model returned by Program.Run.
func (m Model) Cleanup() {
	if m.player != nil {
		_ = m.player.Close()
	}
}

type (
	statusMsg        struct{ status station.Status }
	statusErrMsg     struct{ err error }
	statusTickMsg    struct{}
	tickMsg          time.Time
	playerStartedMsg struct{ p *player.Player }
	playerErrMsg     struct{ err error }
	playerExitedMsg  struct{ err error }
)

func (m Model) fetchCmd() tea.Cmd {
	client := m.client
	return func() tea.Msg {
		ctx, cancel := context.WithTimeout(context.Background(), fetchTimeout)
		defer cancel()
		s, err := client.Fetch(ctx)
		if err != nil {
			return statusErrMsg{err}
		}
		return statusMsg{s}
	}
}

func statusTickCmd() tea.Cmd {
	return tea.Tick(statusInterval, func(time.Time) tea.Msg { return statusTickMsg{} })
}

func tickCmd() tea.Cmd {
	return tea.Tick(time.Second, func(t time.Time) tea.Msg { return tickMsg(t) })
}

func (m Model) startPlayerCmd() tea.Cmd {
	mpvPath := m.mpvPath
	url := m.client.StreamURL(m.status)
	return func() tea.Msg {
		p, err := player.Start(mpvPath, url)
		if err != nil {
			return playerErrMsg{err}
		}
		return playerStartedMsg{p}
	}
}

func watchPlayerCmd(p *player.Player) tea.Cmd {
	return func() tea.Msg {
		return playerExitedMsg{err: <-p.Done()}
	}
}

// playerCmd runs one player IPC call off the update loop, surfacing failures
// as playerErrMsg.
func playerCmd(fn func() error) tea.Cmd {
	return func() tea.Msg {
		if err := fn(); err != nil {
			return playerErrMsg{err}
		}
		return nil
	}
}

// Init implements tea.Model.
func (m Model) Init() tea.Cmd {
	return tea.Batch(m.fetchCmd(), tickCmd(), m.spin.Tick)
}

// Update implements tea.Model.
func (m Model) Update(msg tea.Msg) (tea.Model, tea.Cmd) {
	switch msg := msg.(type) {
	case tea.WindowSizeMsg:
		m.width, m.height = msg.Width, msg.Height
		m.help.SetWidth(msg.Width)
		return m, nil

	case tea.KeyPressMsg:
		return m.handleKey(msg)

	case statusMsg:
		firstStatus := !m.haveStatus
		m.status = msg.status
		m.haveStatus = true
		m.statusErr = nil
		m.lastFetch = time.Now()
		cmds := []tea.Cmd{statusTickCmd()}
		if firstStatus && m.player == nil && !m.starting {
			m.starting = true
			cmds = append(cmds, m.startPlayerCmd())
		}
		return m, tea.Batch(cmds...)

	case statusErrMsg:
		// Keep the last good status; retry on the next interval tick.
		m.statusErr = msg.err
		return m, statusTickCmd()

	case statusTickMsg:
		return m, m.fetchCmd()

	case tickMsg:
		// Re-render only: drives the elapsed-time display.
		return m, tickCmd()

	case playerStartedMsg:
		m.starting = false
		m.player = msg.p
		m.playerErr = nil
		m.paused = false
		p := msg.p
		cmds := []tea.Cmd{watchPlayerCmd(p)}
		// Re-apply volume/mute chosen before this (re)connect.
		if vol := m.volume; vol != 100 {
			cmds = append(cmds, playerCmd(func() error { return p.SetVolume(vol) }))
		}
		if m.muted {
			cmds = append(cmds, playerCmd(func() error { return p.SetMute(true) }))
		}
		return m, tea.Batch(cmds...)

	case playerErrMsg:
		m.starting = false
		m.playerErr = msg.err
		return m, nil

	case playerExitedMsg:
		m.player = nil
		m.starting = false
		m.playerErr = msg.err // nil on clean exit
		return m, nil

	case spinner.TickMsg:
		var cmd tea.Cmd
		m.spin, cmd = m.spin.Update(msg)
		return m, cmd
	}
	return m, nil
}

func (m Model) handleKey(msg tea.KeyPressMsg) (tea.Model, tea.Cmd) {
	switch {
	case key.Matches(msg, m.keys.Quit):
		return m, tea.Quit

	case key.Matches(msg, m.keys.Pause):
		if m.player == nil {
			if m.starting {
				return m, nil
			}
			if !m.haveStatus {
				return m, m.fetchCmd() // no stream URL yet
			}
			m.starting = true
			m.playerErr = nil
			return m, m.startPlayerCmd()
		}
		m.paused = !m.paused
		p, paused := m.player, m.paused
		return m, playerCmd(func() error { return p.SetPause(paused) })

	case key.Matches(msg, m.keys.VolUp):
		return m.adjustVolume(volumeStep)

	case key.Matches(msg, m.keys.VolDown):
		return m.adjustVolume(-volumeStep)

	case key.Matches(msg, m.keys.Mute):
		m.muted = !m.muted
		if m.player == nil {
			return m, nil
		}
		p, muted := m.player, m.muted
		return m, playerCmd(func() error { return p.SetMute(muted) })

	case key.Matches(msg, m.keys.Refresh):
		return m, m.fetchCmd()
	}
	return m, nil
}

func (m Model) adjustVolume(delta int) (tea.Model, tea.Cmd) {
	vol := min(max(m.volume+delta, 0), 100)
	m.volume = vol
	if m.player == nil {
		return m, nil
	}
	p := m.player
	return m, playerCmd(func() error { return p.SetVolume(vol) })
}
