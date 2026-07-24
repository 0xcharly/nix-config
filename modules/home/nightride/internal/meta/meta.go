// Package meta subscribes to nightride.fm's server-sent-events metadata
// feed and maps station names to their Icecast stream mounts.
package meta

import (
	"bufio"
	"context"
	"encoding/json"
	"fmt"
	"net/http"
	"strings"
	"time"
)

const (
	defaultURL     = "https://nightride.fm/meta"
	streamBase     = "https://stream.nightride.fm"
	reconnectDelay = 5 * time.Second
)

// Stations is the public cycle order (stations page order). The feed also
// carries side channels (rekt, rektory, rektify, d-notive) reachable via
// -station but deliberately kept out of the cycle.
var Stations = [...]string{
	"nightride",
	"chillsynth",
	"datawave",
	"spacesynth",
	"darksynth",
	"horrorsynth",
	"ebsm",
}

// StreamURL returns the Icecast MP3 mount for a station.
func StreamURL(station string) string {
	return streamBase + "/" + station + ".mp3"
}

// Track is one now-playing entry from the feed.
type Track struct {
	Station string `json:"station"`
	Title   string `json:"title"`
	Artist  string `json:"artist"`
	TrackID string `json:"track_id"`
}

// Msg is one event on the subscription channel. Exactly one field group is
// set: Connected=true on (re)connect, Err on connection loss (the client
// retries itself), Tracks on a data event.
type Msg struct {
	Tracks    []Track
	Err       error
	Connected bool
}

// Client subscribes to the SSE metadata feed.
type Client struct {
	URL string // "" → https://nightride.fm/meta
}

// Subscribe launches a goroutine owning connect/reconnect; it sends on the
// returned channel until ctx is cancelled, then closes it.
func (c *Client) Subscribe(ctx context.Context) <-chan Msg {
	url := c.URL
	if url == "" {
		url = defaultURL
	}
	// Buffered so a briefly slow UI never wedges the reader.
	ch := make(chan Msg, 8)
	go func() {
		defer close(ch)
		for ctx.Err() == nil {
			err := stream(ctx, url, ch)
			if ctx.Err() != nil {
				return
			}
			if !send(ctx, ch, Msg{Err: err}) {
				return
			}
			select {
			case <-ctx.Done():
				return
			case <-time.After(reconnectDelay):
			}
		}
	}()
	return ch
}

// stream runs one SSE connection until the stream ends or ctx is cancelled.
func stream(ctx context.Context, url string, ch chan<- Msg) error {
	req, err := http.NewRequestWithContext(ctx, http.MethodGet, url, nil)
	if err != nil {
		return err
	}
	req.Header.Set("Accept", "text/event-stream")
	// http.DefaultClient has no Timeout: required — the body is a
	// long-lived stream; cancellation comes from ctx.
	resp, err := http.DefaultClient.Do(req)
	if err != nil {
		return err
	}
	defer resp.Body.Close()
	if resp.StatusCode != http.StatusOK {
		return fmt.Errorf("meta feed: unexpected status %s", resp.Status)
	}
	if !send(ctx, ch, Msg{Connected: true}) {
		return ctx.Err()
	}
	scanner := bufio.NewScanner(resp.Body)
	for scanner.Scan() {
		payload, found := strings.CutPrefix(scanner.Text(), "data: ")
		if !found {
			continue // blank separators and other SSE fields
		}
		tracks, ok := parseData(payload)
		if !ok {
			continue // keepalive heartbeat or malformed payload
		}
		if !send(ctx, ch, Msg{Tracks: tracks}) {
			return ctx.Err()
		}
	}
	if err := scanner.Err(); err != nil {
		return err
	}
	return fmt.Errorf("meta feed: stream closed")
}

func send(ctx context.Context, ch chan<- Msg, m Msg) bool {
	select {
	case ch <- m:
		return true
	case <-ctx.Done():
		return false
	}
}

// parseData parses one SSE data payload; ok=false for the "keepalive"
// heartbeat or malformed JSON (skipped silently, reading continues).
func parseData(payload string) (tracks []Track, ok bool) {
	if payload == "keepalive" {
		return nil, false
	}
	if err := json.Unmarshal([]byte(payload), &tracks); err != nil {
		return nil, false
	}
	return tracks, true
}
