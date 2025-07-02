#!/bin/bash

# Global Commit Hook Installation Script
# Installs commit-msg hook that applies to all projects

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Configuration
HOOKS_REPO_URL="${HOOKS_REPO_URL:-https://github.com/YOUR-ORG/org-git-hooks.git}"
HOOKS_DIR="hooks"

echo -e "${GREEN}🌍 Global Commit Hook Installer${NC}"
echo "================================"

# Check if we're in a git repository
if ! git rev-parse --git-dir > /dev/null 2>&1; then
    echo -e "${RED}❌ Error: Not in a git repository${NC}"
    echo "Please run this script from the root of your git repository"
    exit 1
fi

# Get the .git directory path
GIT_DIR=$(git rev-parse --git-dir)
HOOKS_TARGET_DIR="$GIT_DIR/hooks"

# Function to install commit-msg hook
install_commit_hook() {
    local source_file="$1/commit-msg"
    local target_file="$HOOKS_TARGET_DIR/commit-msg"
    
    if [ ! -f "$source_file" ]; then
        echo -e "${RED}❌ Error: commit-msg hook not found at $source_file${NC}"
        return 1
    fi
    
    # Create hooks directory if it doesn't exist
    mkdir -p "$HOOKS_TARGET_DIR"
    
    # Backup existing hook if it exists
    if [ -f "$target_file" ]; then
        echo -e "${YELLOW}⚠️  Backing up existing commit-msg to commit-msg.backup${NC}"
        cp "$target_file" "$target_file.backup"
    fi
    
    # Copy and make executable
    cp "$source_file" "$target_file"
    chmod +x "$target_file"
    echo -e "${GREEN}✅ Installed: commit-msg hook${NC}"
}

# Function to install from remote repository
install_from_remote() {
    local temp_dir=$(mktemp -d)
    
    echo -e "${YELLOW}📥 Cloning hooks from: $HOOKS_REPO_URL${NC}"
    
    # Clone the repository
    if ! git clone --depth 1 "$HOOKS_REPO_URL" "$temp_dir" 2>/dev/null; then
        echo -e "${RED}❌ Failed to clone hooks repository${NC}"
        echo "Please check the repository URL and your access permissions"
        rm -rf "$temp_dir"
        exit 1
    fi
    
    # Install hook
    install_commit_hook "$temp_dir/$HOOKS_DIR"
    
    # Cleanup
    rm -rf "$temp_dir"
}

# Main installation logic
if [ "$1" == "--local" ]; then
    # Install from local directory
    SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
    install_commit_hook "$SCRIPT_DIR/$HOOKS_DIR"
else
    # Install from remote repository
    install_from_remote
fi

echo ""
echo -e "${GREEN}🎉 Global commit hook installed successfully!${NC}"
echo ""
echo "The commit-msg hook will now validate your commit messages."
echo "To bypass the hook temporarily, use: git commit --no-verify"