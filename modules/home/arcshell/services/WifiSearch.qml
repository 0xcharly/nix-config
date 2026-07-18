pragma Singleton

import qs.services
import Quickshell

Singleton {
    function query(text: string): var {
        const device = Network.wifiDevice;
        if (!device)
            return [];
        const q = text.trim().toLowerCase();
        return device.networks.values
            .filter(n => n.name.length > 0 && (q.length === 0 || n.name.toLowerCase().includes(q)))
            .sort((a, b) => (b.connected - a.connected) || (b.signalStrength - a.signalStrength) || a.name.localeCompare(b.name));
    }
}
