package meta

import (
	"context"
	"net/http"
	"net/http/httptest"
	"reflect"
	"testing"
)

func TestFetchListeners(t *testing.T) {
	// Mounts sum per station across formats; fallback mounts without a
	// listenurl are skipped.
	const status = `{"icestats":{"source":[
		{"listenurl":"http://lissen.to:8000/chillsynth.mp3","listeners":11},
		{"listenurl":"http://lissen.to:8000/chillsynth.ogg","listeners":1},
		{"listeners":3},
		{"listenurl":"http://lissen.to:8000/nightride.mp3","listeners":4}
	]}}`
	srv := httptest.NewServer(http.HandlerFunc(func(w http.ResponseWriter, r *http.Request) {
		w.Write([]byte(status))
	}))
	defer srv.Close()

	got, err := FetchListeners(context.Background(), srv.URL)
	if err != nil {
		t.Fatalf("FetchListeners: %v", err)
	}
	want := map[string]int{"chillsynth": 12, "nightride": 4}
	if !reflect.DeepEqual(got, want) {
		t.Fatalf("FetchListeners = %v, want %v", got, want)
	}
}

func TestFetchListenersSingleSource(t *testing.T) {
	// Icecast serves "source" as a bare object when only one mount is live.
	const status = `{"icestats":{"source":
		{"listenurl":"http://lissen.to:8000/datawave.mp3","listeners":7}
	}}`
	srv := httptest.NewServer(http.HandlerFunc(func(w http.ResponseWriter, r *http.Request) {
		w.Write([]byte(status))
	}))
	defer srv.Close()

	got, err := FetchListeners(context.Background(), srv.URL)
	if err != nil {
		t.Fatalf("FetchListeners: %v", err)
	}
	want := map[string]int{"datawave": 7}
	if !reflect.DeepEqual(got, want) {
		t.Fatalf("FetchListeners = %v, want %v", got, want)
	}
}

func TestMountStation(t *testing.T) {
	for _, tc := range []struct {
		url, want string
	}{
		{"http://lissen.to:8000/chillsynth.mp3", "chillsynth"},
		{"http://lissen.to:8000/rektory.ogg", "rektory"},
		{"", ""},
	} {
		if got := mountStation(tc.url); got != tc.want {
			t.Errorf("mountStation(%q) = %q, want %q", tc.url, got, tc.want)
		}
	}
}
