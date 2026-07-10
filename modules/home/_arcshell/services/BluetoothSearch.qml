pragma Singleton

import Quickshell
import Quickshell.Bluetooth

Singleton {
    function query(text: string): var {
        const adapter = Bluetooth.defaultAdapter;
        if (!adapter)
            return [];
        const q = text.trim().toLowerCase();
        return adapter.devices.values
            .filter(d => (d.paired || d.bonded) && (q.length === 0 || d.name.toLowerCase().includes(q)))
            .sort((a, b) => (b.connected - a.connected) || a.name.localeCompare(b.name));
    }
}
