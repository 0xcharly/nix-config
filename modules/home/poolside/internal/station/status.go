// Package station is a minimal client for the public radio.co station
// status API.
package station

import (
	"context"
	"encoding/json"
	"fmt"
	"net/http"
	"strings"
	"time"
)

// Track is a single entry from the status payload. StartTime is kept as the
// raw string because radio.co omits it for history entries; Started reports
// whether it parses.
type Track struct {
	Title     string `json:"title"`
	StartTime string `json:"start_time"`
}

// Started returns the track start time, and false when the field is absent
// or unparsable.
func (t Track) Started() (time.Time, bool) {
	ts, err := time.Parse(time.RFC3339, t.StartTime)
	if err != nil {
		return time.Time{}, false
	}
	return ts, true
}

// Status is the subset of the radio.co status payload poolside renders.
type Status struct {
	Status            string  `json:"status"` // "online", anything else is offline
	CurrentTrack      Track   `json:"current_track"`
	History           []Track `json:"history"` // newest first; entry 0 == current track
	StreamingHostname string  `json:"streaming_hostname"`
}

// Client fetches station status. A zero HTTP client gets a 10s timeout.
type Client struct {
	StationID string
	HTTP      *http.Client
}

// Fetch GETs and decodes the station status document.
func (c *Client) Fetch(ctx context.Context) (Status, error) {
	url := fmt.Sprintf("https://public.radio.co/stations/%s/status", c.StationID)
	req, err := http.NewRequestWithContext(ctx, http.MethodGet, url, nil)
	if err != nil {
		return Status{}, err
	}
	httpClient := c.HTTP
	if httpClient == nil {
		httpClient = &http.Client{Timeout: 10 * time.Second}
	}
	resp, err := httpClient.Do(req)
	if err != nil {
		return Status{}, err
	}
	defer resp.Body.Close()
	if resp.StatusCode < 200 || resp.StatusCode > 299 {
		return Status{}, fmt.Errorf("status endpoint returned %d", resp.StatusCode)
	}
	var s Status
	if err := json.NewDecoder(resp.Body).Decode(&s); err != nil {
		return Status{}, fmt.Errorf("decoding status: %w", err)
	}
	return s, nil
}

// StreamURL builds the MP3 stream URL for the station, falling back to the
// canonical radio.co edge host when the status document lacks one.
func (c *Client) StreamURL(s Status) string {
	host := s.StreamingHostname
	if host == "" {
		host = "s5.radio.co"
	}
	return fmt.Sprintf("https://%s/%s/listen", host, c.StationID)
}

// SplitTitle splits a radio.co "Artist - Track" title on the first " - "
// separator. Without a separator the whole title is the track.
func SplitTitle(title string) (artist, track string) {
	if i := strings.Index(title, " - "); i >= 0 {
		return title[:i], title[i+len(" - "):]
	}
	return "", title
}
