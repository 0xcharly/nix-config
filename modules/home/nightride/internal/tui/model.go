// Package tui implements the nightride bubbletea interface.
package tui

import (
	"context"
	"time"

	"charm.land/bubbles/v2/help"
	"charm.land/bubbles/v2/key"
	"charm.land/bubbles/v2/spinner"
	tea "charm.land/bubbletea/v2"
	"charm.land/lipgloss/v2"

	"github.com/0xcharly/nix-config/nightride/internal/meta"
	"github.com/0xcharly/nix-config/nightride/internal/player"
)

const volumeStep = 5

// nowPlaying is the latest track seen for one station.
type nowPlaying struct {
	track      meta.Track
	since      time.Time // when the update arrived
	sinceKnown bool      // false for snapshot entries (start unknowable)
}

// Model is the top-level bubbletea model.
type Model struct {
	station string // tuned station name
	mpvPath string

	metaCh    <-chan meta.Msg         // SSE subscription, created in New
	connected bool                    // feed state → LIVE/OFFLINE badge
	metaErr   error                   // last SSE error, cleared on Connected
	now       map[string]nowPlaying   // latest track per station
	history   map[string][]meta.Track // per station, newest first, cap historyLimit

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

// New builds the initial model for the given station. The SSE subscription
// goroutine lives for the whole process (killed at exit); no explicit
// cancellation is needed.
func New(station, mpvPath string) Model {
	return Model{
		station: station,
		mpvPath: mpvPath,
		metaCh:  (&meta.Client{}).Subscribe(context.Background()),
		now:     map[string]nowPlaying{},
		history: map[string][]meta.Track{},
		volume:  100,
		spin: spinner.New(
			spinner.WithSpinner(spinner.Dot),
			spinner.WithStyle(lipgloss.NewStyle().Foreground(mint)),
		),
		help: help.New(),
		keys: defaultKeyMap(),
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
	metaMsg          meta.Msg
	tickMsg          time.Time
	playerStartedMsg struct{ p *player.Player }
	playerErrMsg     struct{ err error }
	playerExitedMsg  struct{ err error }
)

// waitForMeta delivers the next SSE message; re-armed on every metaMsg.
func waitForMeta(ch <-chan meta.Msg) tea.Cmd {
	return func() tea.Msg {
		m, ok := <-ch
		if !ok {
			return nil
		}
		return metaMsg(m)
	}
}

func tickCmd() tea.Cmd {
	return tea.Tick(time.Second, func(t time.Time) tea.Msg { return tickMsg(t) })
}

func (m Model) startPlayerCmd() tea.Cmd {
	mpvPath := m.mpvPath
	url := meta.StreamURL(m.station)
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
	return tea.Batch(waitForMeta(m.metaCh), tickCmd(), m.spin.Tick)
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

	case metaMsg:
		return m.handleMeta(meta.Msg(msg))

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

func (m Model) handleMeta(msg meta.Msg) (tea.Model, tea.Cmd) {
	cmds := []tea.Cmd{waitForMeta(m.metaCh)}
	switch {
	case msg.Connected:
		m.connected = true
		m.metaErr = nil

	case msg.Err != nil:
		m.connected = false
		m.metaErr = msg.Err

	default:
		firstTracks := len(m.now) == 0
		for _, t := range msg.Tracks {
			prev, ok := m.now[t.Station]
			switch {
			case !ok:
				// Snapshot entry: the track started at an unknowable time.
				m.now[t.Station] = nowPlaying{track: t, since: time.Now()}
			case prev.track.TrackID != t.TrackID:
				hist := append([]meta.Track{prev.track}, m.history[t.Station]...)
				if len(hist) > historyLimit {
					hist = hist[:historyLimit]
				}
				m.history[t.Station] = hist
				m.now[t.Station] = nowPlaying{track: t, since: time.Now(), sinceKnown: true}
			}
		}
		// First track batch starts playback (mirrors poolside's first
		// status fetch); later batches never restart a stopped player.
		if firstTracks && len(m.now) > 0 && m.player == nil && !m.starting {
			m.starting = true
			cmds = append(cmds, m.startPlayerCmd())
		}
	}
	return m, tea.Batch(cmds...)
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
			m.starting = true
			m.playerErr = nil
			return m, m.startPlayerCmd()
		}
		m.paused = !m.paused
		p, paused := m.player, m.paused
		return m, playerCmd(func() error { return p.SetPause(paused) })

	case key.Matches(msg, m.keys.StationPrev):
		return m.switchStation(-1)

	case key.Matches(msg, m.keys.StationNext):
		return m.switchStation(1)

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
	}
	return m, nil
}

// switchStation cycles meta.Stations with wraparound. A custom -station not
// in the cycle jumps to the nearest end of the list.
func (m Model) switchStation(delta int) (tea.Model, tea.Cmd) {
	idx := -1
	for i, s := range meta.Stations {
		if s == m.station {
			idx = i
			break
		}
	}
	if idx < 0 {
		if delta > 0 {
			idx = 0
		} else {
			idx = len(meta.Stations) - 1
		}
	} else {
		idx = (idx + delta + len(meta.Stations)) % len(meta.Stations)
	}
	m.station = meta.Stations[idx]
	if m.player == nil {
		// Just retune the display; space reconnects to the new station.
		return m, nil
	}
	// Switching stations implies wanting to hear the new one: force-unpause
	// to remove any ambiguity about loadfile's interaction with a paused mpv.
	m.paused = false
	p, url := m.player, meta.StreamURL(m.station)
	return m, tea.Batch(
		playerCmd(func() error { return p.Load(url) }),
		playerCmd(func() error { return p.SetPause(false) }),
	)
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
