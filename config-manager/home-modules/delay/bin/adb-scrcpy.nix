{device}: ''
  # Required parameters:
  # @raycast.schemaVersion 1
  # @raycast.title scrcpy (${device.name})
  # @raycast.mode silent

  # Optional parameters:
  # @raycast.icon 📲
  # @raycast.packageName Android Dev

  # Documentation:
  # @raycast.description Mirrors ${device.name} dev device with scrcpy
  # @raycast.author Charly Delay

  scrcpy -s ${device.adbId} -b 64M -t -w --disable-screensaver --keyboard=uhid & disown
''
