package tui

import "charm.land/bubbles/v2/key"

type keyMap struct {
	Pause       key.Binding
	StationPrev key.Binding
	StationNext key.Binding
	VolUp       key.Binding
	VolDown     key.Binding
	Mute        key.Binding
	Quit        key.Binding
}

func defaultKeyMap() keyMap {
	return keyMap{
		Pause:       key.NewBinding(key.WithKeys("space", "p"), key.WithHelp("space", "pause")),
		StationPrev: key.NewBinding(key.WithKeys("up"), key.WithHelp("↑/↓", "station")),
		StationNext: key.NewBinding(key.WithKeys("down")),
		VolUp:       key.NewBinding(key.WithKeys("right", "+", "="), key.WithHelp("→/+", "vol up")),
		VolDown:     key.NewBinding(key.WithKeys("left", "-"), key.WithHelp("←/-", "vol down")),
		Mute:        key.NewBinding(key.WithKeys("m"), key.WithHelp("m", "mute")),
		Quit:        key.NewBinding(key.WithKeys("q", "ctrl+c"), key.WithHelp("q", "quit")),
	}
}

// ShortHelp implements help.KeyMap. StationNext is deliberately excluded:
// StationPrev's "↑/↓" help entry covers both directions.
func (k keyMap) ShortHelp() []key.Binding {
	return []key.Binding{k.Pause, k.StationPrev, k.VolUp, k.VolDown, k.Mute, k.Quit}
}

// FullHelp implements help.KeyMap.
func (k keyMap) FullHelp() [][]key.Binding {
	return [][]key.Binding{k.ShortHelp()}
}
