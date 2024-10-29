# Required parameters:
# @raycast.schemaVersion 1
# @raycast.title scrcpy
# @raycast.mode silent

# Optional parameters:
# @raycast.icon 📲
# @raycast.packageName Android Dev

# Documentation:
# @raycast.description Attemps to mirror currently plugged in device with scrcpy
# @raycast.author Charly Delay


scrcpy --video-bit-rate 64M --show-touches --stay-awake --disable-screensaver &
disown
