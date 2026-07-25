// Package tui implements the nightride bubbletea interface.
package tui

import (
	"context"
	"os"
	"slices"
	"strings"
	"time"

	"charm.land/bubbles/v2/help"
	"charm.land/bubbles/v2/key"
	"charm.land/bubbles/v2/spinner"
	tea "charm.land/bubbletea/v2"
	"charm.land/lipgloss/v2"
	uv "github.com/charmbracelet/ultraviolet"

	"github.com/0xcharly/nix-config/nightride/internal/art"
	"github.com/0xcharly/nix-config/nightride/internal/meta"
	"github.com/0xcharly/nix-config/nightride/internal/player"
)

const (
	volumeStep = 5
	// listenersInterval paces the Icecast listener-count poll.
	listenersInterval = 15 * time.Second
	// kittyProbeID tags the graphics-capability query so its response is
	// distinguishable from image-slot traffic (slots use 1..len(stations)).
	kittyProbeID = 99
)

// nowPlaying is the latest track seen for one station.
type nowPlaying struct {
	track      meta.Track
	since      time.Time // when the update arrived
	sinceKnown bool      // false for snapshot entries (start unknowable)
}

// Model is the top-level bubbletea model.
type Model struct {
	station  string   // tuned station name
	stations []string // displayed order: cycle + custom -station, fixed at startup
	mpvPath  string

	metaCh    <-chan meta.Msg         // SSE subscription, created in New
	connected bool                    // feed state → LIVE/OFFLINE badge
	metaErr   error                   // last SSE error, cleared on Connected
	now       map[string]nowPlaying   // latest track per station
	history   map[string][]meta.Track // per station, newest first, cap historyLimit
	listeners map[string]int          // per-station listener counts, nil until first poll
	artCache  map[string]art.Cover    // trackID → fetched cover (zero value = no art)
	artBusy   map[string]bool         // trackID → cover fetch in flight

	kittyOK     bool              // terminal renders kitty Unicode placeholders
	kittyProbed bool              // capability query sent
	tmux        bool              // wrap graphics escapes in a passthrough envelope
	kittySlots  map[string]string // station → trackID held by its image slot

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
	stations := meta.Stations[:]
	if !slices.Contains(stations, station) {
		stations = append(stations[:len(stations):len(stations)], station)
	}
	return Model{
		station:    station,
		stations:   stations,
		mpvPath:    mpvPath,
		metaCh:     (&meta.Client{}).Subscribe(context.Background()),
		now:        map[string]nowPlaying{},
		history:    map[string][]meta.Track{},
		artCache:   map[string]art.Cover{},
		artBusy:    map[string]bool{},
		kittySlots: map[string]string{},
		tmux:       insideTmux(),
		volume:     100,
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
	listenersMsg     map[string]int
	listenersTickMsg time.Time
	artMsg           struct {
		station string
		trackID string
		cover   art.Cover
	}
	playerStartedMsg struct{ p *player.Player }
	playerErrMsg     struct{ err error }
	playerExitedMsg  struct{ err error }
)

// insideTmux reports whether graphics escapes must be wrapped in a tmux
// passthrough envelope.
func insideTmux() bool {
	term := os.Getenv("TERM")
	return os.Getenv("TMUX") != "" ||
		strings.HasPrefix(term, "tmux") ||
		strings.HasPrefix(term, "screen")
}

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

// fetchListenersCmd polls the Icecast status endpoint once. Failures keep
// the previous counts; the next tick retries.
func fetchListenersCmd() tea.Cmd {
	return func() tea.Msg {
		ctx, cancel := context.WithTimeout(context.Background(), 10*time.Second)
		defer cancel()
		counts, err := meta.FetchListeners(ctx, "")
		if err != nil {
			return listenersMsg(nil)
		}
		return listenersMsg(counts)
	}
}

func listenersTickCmd() tea.Cmd {
	return tea.Tick(listenersInterval, func(t time.Time) tea.Msg { return listenersTickMsg(t) })
}

// requestArt starts one cover fetch for a station's current track,
// deduplicated via artBusy/artCache. Only displayed stations fetch.
func (m Model) requestArt(t meta.Track) tea.Cmd {
	if !slices.Contains(m.stations, t.Station) {
		return nil
	}
	if _, done := m.artCache[t.TrackID]; done || m.artBusy[t.TrackID] {
		return nil
	}
	m.artBusy[t.TrackID] = true
	return fetchArtCmd(t.Station, t.TrackID)
}

func fetchArtCmd(station, trackID string) tea.Cmd {
	return func() tea.Msg {
		ctx, cancel := context.WithTimeout(context.Background(), 15*time.Second)
		defer cancel()
		cover, err := art.Fetch(ctx, trackID)
		if err != nil {
			return artMsg{station: station, trackID: trackID} // zero cover → placeholder, no refetch
		}
		return artMsg{station: station, trackID: trackID, cover: cover}
	}
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

// probeKitty sends the graphics-capability query once. Inside tmux the
// response is not reliably routed back to the pane, so outer-terminal env
// hints (kitty and ghostty both implement Unicode placeholders) enable the
// protocol directly; the probe response handles the direct case.
func (m *Model) probeKitty() {
	m.kittyProbed = true
	if m.tmux && (os.Getenv("KITTY_WINDOW_ID") != "" || os.Getenv("GHOSTTY_RESOURCES_DIR") != "") {
		m.enableKitty()
	}
	_ = art.Query(os.Stdout, kittyProbeID, m.tmux)
}

// enableKitty switches covers to kitty graphics and transmits every cover
// already cached for an on-air track.
func (m *Model) enableKitty() {
	m.kittyOK = true
	for i, s := range m.stations {
		np, ok := m.now[s]
		if !ok {
			continue
		}
		if cover, ok := m.artCache[np.track.TrackID]; ok && cover.PNG != nil {
			m.transmitCover(i, s, np.track.TrackID, cover.PNG)
		}
	}
}

// transmitCover pushes a cover into a station's kitty image slot. Runs on
// the update goroutine — bubbletea renders frames on the same goroutine,
// so the escape bytes never interleave with a frame.
func (m *Model) transmitCover(idx int, station, trackID string, png []byte) {
	if err := art.Transmit(os.Stdout, idx+1, png, m.tmux); err != nil {
		return
	}
	m.kittySlots[station] = trackID
}

// Init implements tea.Model.
func (m Model) Init() tea.Cmd {
	return tea.Batch(waitForMeta(m.metaCh), tickCmd(), fetchListenersCmd(), m.spin.Tick)
}

// Update implements tea.Model.
func (m Model) Update(msg tea.Msg) (tea.Model, tea.Cmd) {
	switch msg := msg.(type) {
	case tea.WindowSizeMsg:
		m.width, m.height = msg.Width, msg.Height
		m.help.SetWidth(msg.Width)
		if !m.kittyProbed {
			(&m).probeKitty()
		}
		return m, nil

	case uv.KittyGraphicsEvent:
		if !m.kittyOK && msg.Options.ID == kittyProbeID && strings.HasPrefix(string(msg.Payload), "OK") {
			(&m).enableKitty()
		}
		return m, nil

	case tea.KeyPressMsg:
		return m.handleKey(msg)

	case metaMsg:
		return m.handleMeta(meta.Msg(msg))

	case tickMsg:
		// Re-render only: drives the elapsed-time display.
		return m, tickCmd()

	case listenersMsg:
		if msg != nil {
			m.listeners = msg
		}
		return m, listenersTickCmd()

	case listenersTickMsg:
		return m, fetchListenersCmd()

	case artMsg:
		delete(m.artBusy, msg.trackID)
		m.artCache[msg.trackID] = msg.cover
		if m.kittyOK && msg.cover.PNG != nil {
			if np, ok := m.now[msg.station]; ok && np.track.TrackID == msg.trackID {
				if idx := slices.Index(m.stations, msg.station); idx >= 0 {
					(&m).transmitCover(idx, msg.station, msg.trackID, msg.cover.PNG)
				}
			}
		}
		return m, nil

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
				// The replaced track's cover can never be shown again.
				delete(m.artCache, prev.track.TrackID)
			default:
				continue // same track re-announced
			}
			if cmd := m.requestArt(t); cmd != nil {
				cmds = append(cmds, cmd)
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
