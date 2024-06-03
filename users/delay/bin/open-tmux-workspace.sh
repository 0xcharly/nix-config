# Use FZF to get user input.
selected_workspace=$(hg citc --list | fzf --print-query | tail -n 1)

# Exit if the input is empty.
if [ -z "$selected_workspace" ]; then
    exit 0
fi

# Check if the session exists already, or create it otherwise.
if ! tmux has-session -t "$selected_workspace" 2>/dev/null; then
    # Create a detached session that we'll join below, creating the workspace if it doesn't exist.
    tmux new-session -ds "$selected_workspace" -c "$(hg hgd -f "$selected_workspace")"
fi

# Update the terminal window name.
echo -ne "\033]0;$selected_workspace\007"

if [ -z "$TMUX" ]; then
    # If we're not running in a tmux client, attach to the session.
    tmux attach-session -t "$selected_workspace"
else
    # If we're already running in a tmux client, just switch the client.
    tmux switch-client -t "$selected_workspace"
fi
