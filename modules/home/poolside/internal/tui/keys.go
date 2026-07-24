package tui

import "charm.land/bubbles/v2/key"

type keyMap struct {
	Pause   key.Binding
	VolUp   key.Binding
	VolDown key.Binding
	Mute    key.Binding
	Refresh key.Binding
	Quit    key.Binding
}

func defaultKeyMap() keyMap {
	return keyMap{
		Pause:   key.NewBinding(key.WithKeys("space", "p"), key.WithHelp("space", "pause")),
		VolUp:   key.NewBinding(key.WithKeys("up", "+", "="), key.WithHelp("↑/+", "vol up")),
		VolDown: key.NewBinding(key.WithKeys("down", "-"), key.WithHelp("↓/-", "vol down")),
		Mute:    key.NewBinding(key.WithKeys("m"), key.WithHelp("m", "mute")),
		Refresh: key.NewBinding(key.WithKeys("r"), key.WithHelp("r", "refresh")),
		Quit:    key.NewBinding(key.WithKeys("q", "ctrl+c"), key.WithHelp("q", "quit")),
	}
}

// ShortHelp implements help.KeyMap.
func (k keyMap) ShortHelp() []key.Binding {
	return []key.Binding{k.Pause, k.VolUp, k.VolDown, k.Mute, k.Refresh, k.Quit}
}

// FullHelp implements help.KeyMap.
func (k keyMap) FullHelp() [][]key.Binding {
	return [][]key.Binding{k.ShortHelp()}
}
