package meta

import (
	"context"
	"net/http"
	"net/http/httptest"
	"reflect"
	"testing"
	"time"
)

const transcript = "data: [" +
	`{"station":"nightride","title":"Enter Horrornauts","artist":"The Horrornauts","track_id":"id-1"},` +
	`{"station":"rekt","title":"Neon Dusk","artist":"Dana Jean Phoenix","track_id":"id-2"}` +
	"]\n\n" +
	"data: keepalive\n\n" +
	"data: [" +
	`{"station":"chillsynth","title":"Waves","artist":"FM-84","track_id":"id-3"}` +
	"]\n\n"

func TestSubscribeSequence(t *testing.T) {
	srv := httptest.NewServer(http.HandlerFunc(func(w http.ResponseWriter, r *http.Request) {
		if got := r.Header.Get("Accept"); got != "text/event-stream" {
			t.Errorf("Accept header = %q, want %q", got, "text/event-stream")
		}
		w.Header().Set("Content-Type", "text/event-stream")
		_, _ = w.Write([]byte(transcript))
	}))
	defer srv.Close()

	ctx, cancel := context.WithCancel(context.Background())
	defer cancel()
	ch := (&Client{URL: srv.URL}).Subscribe(ctx)

	next := func() Msg {
		t.Helper()
		select {
		case m, chOpen := <-ch:
			if !chOpen {
				t.Fatal("channel closed early")
			}
			return m
		case <-time.After(5 * time.Second):
			t.Fatal("timed out waiting for message")
		}
		panic("unreachable")
	}

	if m := next(); !m.Connected {
		t.Fatalf("first msg = %+v, want Connected", m)
	}

	// Keepalive between the two data events must not produce a message:
	// the second and third messages are the two track batches back to back.
	want2 := []Track{
		{Station: "nightride", Title: "Enter Horrornauts", Artist: "The Horrornauts", TrackID: "id-1"},
		{Station: "rekt", Title: "Neon Dusk", Artist: "Dana Jean Phoenix", TrackID: "id-2"},
	}
	if m := next(); !reflect.DeepEqual(m.Tracks, want2) {
		t.Fatalf("second msg tracks = %+v, want %+v", m.Tracks, want2)
	}
	want1 := []Track{
		{Station: "chillsynth", Title: "Waves", Artist: "FM-84", TrackID: "id-3"},
	}
	if m := next(); !reflect.DeepEqual(m.Tracks, want1) {
		t.Fatalf("third msg tracks = %+v, want %+v", m.Tracks, want1)
	}

	// Server closes the stream → one Err message, then the client waits to
	// reconnect; cancelling must close the channel.
	if m := next(); m.Err == nil {
		t.Fatalf("fourth msg = %+v, want Err set", m)
	}
	cancel()
	select {
	case m, chOpen := <-ch:
		if chOpen {
			t.Fatalf("after cancel: got message %+v, want closed channel", m)
		}
	case <-time.After(5 * time.Second):
		t.Fatal("timed out waiting for channel close after cancel")
	}
}

func TestParseData(t *testing.T) {
	tests := []struct {
		name    string
		payload string
		want    []Track
		ok      bool
	}{
		{name: "keepalive", payload: "keepalive", ok: false},
		{name: "malformed", payload: `{"station":"nightride"}`, ok: false},
		{name: "garbage", payload: "not json", ok: false},
		{
			name:    "valid array",
			payload: `[{"station":"ebsm","title":"T","artist":"A","track_id":"x"}]`,
			want:    []Track{{Station: "ebsm", Title: "T", Artist: "A", TrackID: "x"}},
			ok:      true,
		},
	}
	for _, tc := range tests {
		t.Run(tc.name, func(t *testing.T) {
			got, ok := parseData(tc.payload)
			if ok != tc.ok {
				t.Fatalf("ok = %v, want %v", ok, tc.ok)
			}
			if tc.ok && !reflect.DeepEqual(got, tc.want) {
				t.Fatalf("tracks = %+v, want %+v", got, tc.want)
			}
		})
	}
}

func TestStreamURL(t *testing.T) {
	if got, want := StreamURL("chillsynth"), "https://stream.nightride.fm/chillsynth.mp3"; got != want {
		t.Fatalf("StreamURL = %q, want %q", got, want)
	}
}
