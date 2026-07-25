// Command nightride plays nightride.fm through mpv and shows an interactive
// TUI: live SSE metadata, per-station listener counts, album art (kitty
// graphics with an ANSI fallback), client-derived history, station
// switching, and pause/volume/mute controls.
package main

import (
	"flag"
	"fmt"
	"os"
	"os/exec"

	tea "charm.land/bubbletea/v2"

	"github.com/0xcharly/nix-config/nightride/internal/tui"
)

func main() {
	stationID := flag.String("station", "nightride", "nightride.fm station name")
	mpvBin := flag.String("mpv", "mpv", "path to the mpv binary")
	flag.Usage = func() {
		fmt.Fprintf(flag.CommandLine.Output(), "usage: %s [flags]\n", os.Args[0])
		flag.PrintDefaults()
	}
	flag.Parse()

	resolvedMpv, err := exec.LookPath(*mpvBin)
	if err != nil {
		fmt.Fprintf(os.Stderr, "nightride: mpv binary %q not found: %v\n", *mpvBin, err)
		os.Exit(2)
	}

	final, err := tea.NewProgram(tui.New(*stationID, resolvedMpv)).Run()
	if m, ok := final.(tui.Model); ok {
		m.Cleanup()
	}
	if err != nil {
		fmt.Fprintf(os.Stderr, "nightride: %v\n", err)
		os.Exit(1)
	}
}
