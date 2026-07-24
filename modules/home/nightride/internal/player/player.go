// Package player runs mpv as a subprocess and drives it over its JSON IPC
// unix socket.
package player

import (
	"bufio"
	"encoding/json"
	"fmt"
	"net"
	"os"
	"os/exec"
	"path/filepath"
	"sync"
	"time"
)

const (
	dialRetryInterval = 100 * time.Millisecond
	dialTimeout       = 5 * time.Second
	replyTimeout      = 3 * time.Second
	quitGracePeriod   = 2 * time.Second
)

// Player is a handle on a running mpv process. All methods are safe for
// concurrent use.
type Player struct {
	cmd  *exec.Cmd
	conn net.Conn
	sock string

	mu      sync.Mutex // guards conn writes, reqID, pending
	reqID   int
	pending map[int]chan error

	done      chan error // receives mpv's exit error once, then closes
	closeOnce sync.Once
}

// Start spawns mpv playing streamURL and connects to its IPC socket.
func Start(mpvPath, streamURL string) (*Player, error) {
	dir := os.Getenv("XDG_RUNTIME_DIR")
	if dir == "" {
		dir = os.TempDir()
	}
	sock := filepath.Join(dir, fmt.Sprintf("nightride-mpv-%d.sock", os.Getpid()))

	// --no-config keeps behavior deterministic regardless of the user's
	// mpv.conf; audio output (PipeWire) is auto-detected without it.
	cmd := exec.Command(mpvPath,
		"--no-video",
		"--really-quiet",
		"--no-config",
		"--volume=100",
		"--input-ipc-server="+sock,
		streamURL,
	)
	if err := cmd.Start(); err != nil {
		return nil, fmt.Errorf("starting mpv: %w", err)
	}

	var conn net.Conn
	deadline := time.Now().Add(dialTimeout)
	for {
		var err error
		conn, err = net.Dial("unix", sock)
		if err == nil {
			break
		}
		if time.Now().After(deadline) {
			_ = cmd.Process.Kill()
			_ = cmd.Wait()
			_ = os.Remove(sock)
			return nil, fmt.Errorf("connecting to mpv IPC socket: %w", err)
		}
		time.Sleep(dialRetryInterval)
	}

	p := &Player{
		cmd:     cmd,
		conn:    conn,
		sock:    sock,
		pending: map[int]chan error{},
		done:    make(chan error, 1),
	}
	go p.readLoop()
	go func() {
		err := cmd.Wait()
		_ = p.conn.Close() // wakes readLoop, which fails pending requests
		_ = os.Remove(p.sock)
		p.done <- err
		close(p.done)
	}()
	return p, nil
}

// Load replaces the playing stream in place.
func (p *Player) Load(streamURL string) error {
	return p.request("loadfile", streamURL, "replace")
}

// SetPause pauses or resumes playback.
func (p *Player) SetPause(paused bool) error {
	return p.request("set_property", "pause", paused)
}

// SetVolume sets the softvol level; callers clamp to 0-100.
func (p *Player) SetVolume(vol int) error {
	return p.request("set_property", "volume", vol)
}

// SetMute mutes or unmutes playback.
func (p *Player) SetMute(muted bool) error {
	return p.request("set_property", "mute", muted)
}

// Done receives mpv's exit error (nil on clean exit) once, then is closed.
func (p *Player) Done() <-chan error {
	return p.done
}

// Close asks mpv to quit, escalating to SIGKILL after a grace period, and
// waits for the process to be reaped.
func (p *Player) Close() error {
	p.closeOnce.Do(func() {
		// Best-effort fire-and-forget quit: mpv exits without replying.
		payload, _ := json.Marshal(map[string]any{"command": []any{"quit"}})
		p.mu.Lock()
		_, _ = p.conn.Write(append(payload, '\n'))
		p.mu.Unlock()

		select {
		case <-p.done:
		case <-time.After(quitGracePeriod):
			_ = p.cmd.Process.Kill()
			<-p.done
		}
	})
	return nil
}

type response struct {
	Error     string `json:"error"`
	RequestID int    `json:"request_id"`
	Event     string `json:"event"`
}

func (p *Player) readLoop() {
	scanner := bufio.NewScanner(p.conn)
	for scanner.Scan() {
		var r response
		if err := json.Unmarshal(scanner.Bytes(), &r); err != nil {
			continue
		}
		if r.Event != "" {
			continue // property/playback events are unused
		}
		p.mu.Lock()
		ch := p.pending[r.RequestID]
		delete(p.pending, r.RequestID)
		p.mu.Unlock()
		if ch == nil {
			continue
		}
		if r.Error == "success" {
			ch <- nil
		} else {
			ch <- fmt.Errorf("mpv: %s", r.Error)
		}
	}
	// Connection gone (mpv exited): fail everything still in flight.
	p.mu.Lock()
	for id, ch := range p.pending {
		delete(p.pending, id)
		ch <- fmt.Errorf("mpv IPC connection closed")
	}
	p.mu.Unlock()
}

// request sends one command and waits for mpv's matching reply.
func (p *Player) request(args ...any) error {
	p.mu.Lock()
	p.reqID++
	id := p.reqID
	ch := make(chan error, 1)
	p.pending[id] = ch
	payload, err := json.Marshal(map[string]any{"command": args, "request_id": id})
	if err == nil {
		_, err = p.conn.Write(append(payload, '\n'))
	}
	if err != nil {
		delete(p.pending, id)
	}
	p.mu.Unlock()
	if err != nil {
		return fmt.Errorf("writing to mpv: %w", err)
	}

	select {
	case err := <-ch:
		return err
	case <-time.After(replyTimeout):
		p.mu.Lock()
		delete(p.pending, id)
		p.mu.Unlock()
		return fmt.Errorf("mpv did not reply within %s", replyTimeout)
	}
}
