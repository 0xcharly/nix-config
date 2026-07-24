// Command poolside plays Poolside FM (poolsuite.net, radio.co station
// sc9cb59935) through mpv and shows an interactive TUI: live status,
// now-playing track, history, and pause/volume/mute controls.
package main

import (
	"flag"
	"fmt"
	"os"
	"os/exec"

	tea "charm.land/bubbletea/v2"

	"github.com/0xcharly/nix-config/poolside/internal/tui"
)

func main() {
	stationID := flag.String("station", "sc9cb59935", "radio.co station ID")
	mpvBin := flag.String("mpv", "mpv", "path to the mpv binary")
	flag.Usage = func() {
		fmt.Fprintf(flag.CommandLine.Output(), "usage: %s [flags]\n", os.Args[0])
		flag.PrintDefaults()
	}
	flag.Parse()

	resolvedMpv, err := exec.LookPath(*mpvBin)
	if err != nil {
		fmt.Fprintf(os.Stderr, "poolside: mpv binary %q not found: %v\n", *mpvBin, err)
		os.Exit(2)
	}

	final, err := tea.NewProgram(tui.New(*stationID, resolvedMpv)).Run()
	if m, ok := final.(tui.Model); ok {
		m.Cleanup()
	}
	if err != nil {
		fmt.Fprintf(os.Stderr, "poolside: %v\n", err)
		os.Exit(1)
	}
}
