package station

import (
	"encoding/json"
	"testing"
)

// Trimmed copy of a real https://public.radio.co/stations/sc9cb59935/status
// response (fetched 2026-07-24).
const fixture = `{
  "status": "online",
  "source": { "type": "automated", "collaborator": null, "relay": null },
  "collaborators": [],
  "relays": [],
  "current_track": {
    "title": "Halogenix - Independent",
    "start_time": "2026-07-24T09:17:13+00:00",
    "artwork_url": "https://images.radio.co/station_logos/sc9cb59935.1707425388.jpg",
    "artwork_url_large": "https://images.radio.co/station_logos/sc9cb59935.1707425388.jpg"
  },
  "history": [
    { "title": "Halogenix - Independent" },
    { "title": "Skeptical - Mecca" },
    { "title": "Alix Perez - Burning Babylon" }
  ],
  "logo_url": "https://images.radio.co/station_logos/sc9cb59935.1707425388.jpg",
  "streaming_hostname": "s5.radio.co",
  "outputs": [ { "name": "listen", "format": "MP3", "bitrate": 192 } ]
}`

func TestDecodeStatus(t *testing.T) {
	var s Status
	if err := json.Unmarshal([]byte(fixture), &s); err != nil {
		t.Fatalf("decoding fixture: %v", err)
	}
	if s.Status != "online" {
		t.Errorf("Status = %q, want %q", s.Status, "online")
	}
	if got, want := s.CurrentTrack.Title, "Halogenix - Independent"; got != want {
		t.Errorf("CurrentTrack.Title = %q, want %q", got, want)
	}
	if _, ok := s.CurrentTrack.Started(); !ok {
		t.Errorf("CurrentTrack.Started() not ok, want parsable start_time")
	}
	if _, ok := s.History[1].Started(); ok {
		t.Errorf("History[1].Started() ok, want false for missing start_time")
	}
	if len(s.History) != 3 {
		t.Errorf("len(History) = %d, want 3", len(s.History))
	}
	if s.StreamingHostname != "s5.radio.co" {
		t.Errorf("StreamingHostname = %q, want %q", s.StreamingHostname, "s5.radio.co")
	}
}

func TestStreamURL(t *testing.T) {
	c := &Client{StationID: "sc9cb59935"}
	if got, want := c.StreamURL(Status{StreamingHostname: "s5.radio.co"}), "https://s5.radio.co/sc9cb59935/listen"; got != want {
		t.Errorf("StreamURL = %q, want %q", got, want)
	}
	if got, want := c.StreamURL(Status{}), "https://s5.radio.co/sc9cb59935/listen"; got != want {
		t.Errorf("StreamURL fallback = %q, want %q", got, want)
	}
}

func TestSplitTitle(t *testing.T) {
	cases := []struct {
		title, artist, track string
	}{
		{"A - B", "A", "B"},
		{"NoSeparator", "", "NoSeparator"},
		{"A - B - C", "A", "B - C"},
	}
	for _, tc := range cases {
		artist, track := SplitTitle(tc.title)
		if artist != tc.artist || track != tc.track {
			t.Errorf("SplitTitle(%q) = (%q, %q), want (%q, %q)",
				tc.title, artist, track, tc.artist, tc.track)
		}
	}
}
