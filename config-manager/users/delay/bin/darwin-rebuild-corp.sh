# Wrapper around `darwin-rebuild` to hide system-specific kinks.
# Example usage: darwin-rebuild swich --flake .

# Move policy enforced files out of the way. These are overwritten periodically
# so it's fine to simply move them away to avoid issues during `darwin-rebuild`.
# TODO: Find a better way to handle this, e.g. by not overwritting them during
# installation?
for rc in bashrc zshrc
do
  rc_path="/etc/$rc"
  [[ -f "$rc_path" ]] && sudo mv "$rc_path" "$rc_path.before-nix-darwin"
done

# Rebuild config.
darwin-rebuild "$@"