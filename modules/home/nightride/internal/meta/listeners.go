package meta

import (
	"context"
	"encoding/json"
	"fmt"
	"net/http"
	"strings"
)

const statusURL = streamBase + "/status-json.xsl"

// icecastSource is one mount in the Icecast status document. Fallback
// mounts have no listenurl and are skipped.
type icecastSource struct {
	ListenURL string `json:"listenurl"`
	Listeners int    `json:"listeners"`
}

// icecastSources tolerates Icecast's schema quirk: "source" is a bare
// object when a single mount is live, an array otherwise.
type icecastSources []icecastSource

func (s *icecastSources) UnmarshalJSON(b []byte) error {
	if len(b) > 0 && b[0] == '[' {
		return json.Unmarshal(b, (*[]icecastSource)(s))
	}
	var one icecastSource
	if err := json.Unmarshal(b, &one); err != nil {
		return err
	}
	*s = icecastSources{one}
	return nil
}

// FetchListeners polls the Icecast status endpoint (url "" → the nightride
// stream host) and returns live listener counts per station, summing each
// station's mounts (.mp3 and .ogg).
func FetchListeners(ctx context.Context, url string) (map[string]int, error) {
	if url == "" {
		url = statusURL
	}
	req, err := http.NewRequestWithContext(ctx, http.MethodGet, url, nil)
	if err != nil {
		return nil, err
	}
	resp, err := http.DefaultClient.Do(req)
	if err != nil {
		return nil, err
	}
	defer resp.Body.Close()
	if resp.StatusCode != http.StatusOK {
		return nil, fmt.Errorf("icecast status: unexpected status %s", resp.Status)
	}
	var stats struct {
		Icestats struct {
			Source icecastSources `json:"source"`
		} `json:"icestats"`
	}
	if err := json.NewDecoder(resp.Body).Decode(&stats); err != nil {
		return nil, fmt.Errorf("icecast status: %w", err)
	}
	counts := make(map[string]int, len(stats.Icestats.Source))
	for _, src := range stats.Icestats.Source {
		if station := mountStation(src.ListenURL); station != "" {
			counts[station] += src.Listeners
		}
	}
	return counts, nil
}

// mountStation extracts the station name from a mount URL:
// "http://host:8000/chillsynth.mp3" → "chillsynth".
func mountStation(listenURL string) string {
	base := listenURL[strings.LastIndexByte(listenURL, '/')+1:]
	name, _, _ := strings.Cut(base, ".")
	return name
}
