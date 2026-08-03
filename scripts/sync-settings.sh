#!/usr/bin/env bash
# sync-settings.sh: Pull live Caelestia config back into the repo.

REPO_ROOT=$(git rev-parse --show-toplevel)
CONFIG_FILE="$HOME/.config/caelestia/shell.json"
CLI_CONFIG="$HOME/.config/caelestia/cli.json"

if [ -f "$CONFIG_FILE" ]; then
    echo "Syncing $CONFIG_FILE to repo..."
    # Here the user would manually update their flake.nix or we could 
    # provide a way to store it in a tracked json file.
    cp "$CONFIG_FILE" "$REPO_ROOT/configs/shell.json"
fi

if [ -f "$CLI_CONFIG" ]; then
    echo "Syncing $CLI_CONFIG to repo..."
    cp "$CLI_CONFIG" "$REPO_ROOT/configs/cli.json"
fi

echo "Done. Please review changes and commit."
