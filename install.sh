#!/bin/bash

# GO-Auto Installation Script
# Installs GO-Auto to Claude Code plugins directory

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PLUGIN_DIR="$HOME/.claude/plugins/go-auto"
COMMANDS_DIR="$HOME/.claude/commands/go-auto"

echo "Installing GO-Auto..."

# Create plugin directory
mkdir -p "$PLUGIN_DIR"

# Copy all directories
for dir in agents templates sections discovery; do
    if [ -d "$SCRIPT_DIR/$dir" ]; then
        echo "  Copying $dir/"
        cp -r "$SCRIPT_DIR/$dir" "$PLUGIN_DIR/"
    fi
done

# Copy root files
echo "  Copying SKILL.md"
cp "$SCRIPT_DIR/SKILL.md" "$PLUGIN_DIR/"

echo "  Copying README.md"
cp "$SCRIPT_DIR/README.md" "$PLUGIN_DIR/"

# Create commands directory and copy commands
mkdir -p "$COMMANDS_DIR"
echo "  Copying commands/"
cp "$SCRIPT_DIR/commands/"*.md "$COMMANDS_DIR/"

echo ""
echo "GO-Auto installed successfully!"
echo ""
echo "Plugin location: $PLUGIN_DIR"
echo "Commands location: $COMMANDS_DIR"
echo ""
echo "Available commands:"
echo "  /go-auto:auto [N]    - Run N phases autonomously"
echo "  /go-auto:discover    - Run discovery"
echo "  /go-auto:preflight   - Run preflight checks"
echo "  /go-auto:verify      - Run final verification"
echo ""
echo "Or use with GO-Build commands if both installed:"
echo "  /go:auto [N]         - If commands aliased to /go:"
