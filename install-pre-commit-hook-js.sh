#!/bin/bash

# JavaScript Pre-commit Hook Installation Script
# Installs pre-commit hook for JavaScript/TypeScript projects

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Configuration
HOOKS_REPO_URL="${HOOKS_REPO_URL:-https://github.com/YOUR-ORG/org-git-hooks.git}"
JS_HOOKS_DIR="hooks/js"

echo -e "${GREEN}🟨 JavaScript Pre-commit Hook Installer${NC}"
echo "======================================="

# Check if we're in a git repository
if ! git rev-parse --git-dir > /dev/null 2>&1; then
    echo -e "${RED}❌ Error: Not in a git repository${NC}"
    echo "Please run this script from the root of your git repository"
    exit 1
fi

# Check if this is a JavaScript project
if [ ! -f "package.json" ]; then
    echo -e "${YELLOW}⚠️  Warning: No package.json found${NC}"
    echo "This doesn't appear to be a JavaScript project."
    read -p "Continue anyway? (y/N) " -n 1 -r
    echo
    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
        echo "Installation cancelled."
        exit 0
    fi
fi

# Get the .git directory path
GIT_DIR=$(git rev-parse --git-dir)
HOOKS_TARGET_DIR="$GIT_DIR/hooks"

# Function to install pre-commit hook
install_js_pre_commit() {
    local source_file="$1"
    local target_file="$HOOKS_TARGET_DIR/pre-commit"
    
    if [ ! -f "$source_file" ]; then
        echo -e "${RED}❌ Error: JavaScript pre-commit hook not found at $source_file${NC}"
        return 1
    fi
    
    # Create hooks directory if it doesn't exist
    mkdir -p "$HOOKS_TARGET_DIR"
    
    # Backup existing hook if it exists
    if [ -f "$target_file" ]; then
        echo -e "${YELLOW}⚠️  Backing up existing pre-commit to pre-commit.backup${NC}"
        cp "$target_file" "$target_file.backup"
    fi
    
    # Copy and make executable
    cp "$source_file" "$target_file"
    chmod +x "$target_file"
    echo -e "${GREEN}✅ Installed: JavaScript pre-commit hook${NC}"
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
    
    # Check if JS-specific hook exists
    if [ -f "$temp_dir/$JS_HOOKS_DIR/pre-commit" ]; then
        install_js_pre_commit "$temp_dir/$JS_HOOKS_DIR/pre-commit"
    else
        # Fallback to general pre-commit if it's JS compatible
        echo -e "${YELLOW}No JS-specific hook found, checking general hooks...${NC}"
        install_js_pre_commit "$temp_dir/hooks/pre-commit"
    fi
    
    # Cleanup
    rm -rf "$temp_dir"
}

# Main installation logic
if [ "$1" == "--local" ]; then
    # Install from local directory
    SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
    
    # Check for JS-specific hook first
    if [ -f "$SCRIPT_DIR/$JS_HOOKS_DIR/pre-commit" ]; then
        install_js_pre_commit "$SCRIPT_DIR/$JS_HOOKS_DIR/pre-commit"
    else
        # Fallback to general pre-commit
        install_js_pre_commit "$SCRIPT_DIR/hooks/pre-commit"
    fi
else
    # Install from remote repository
    install_from_remote
fi

# Check for required dependencies
echo ""
echo -e "${YELLOW}📋 Checking JavaScript dependencies...${NC}"

missing_deps=()

# Check for npx
if ! command -v npx &> /dev/null; then
    missing_deps+=("npx (npm)")
fi

# Check for lint-staged in package.json
if [ -f "package.json" ] && ! grep -q "lint-staged" package.json; then
    missing_deps+=("lint-staged")
fi

if [ ${#missing_deps[@]} -gt 0 ]; then
    echo -e "${YELLOW}⚠️  Missing dependencies:${NC}"
    for dep in "${missing_deps[@]}"; do
        echo "   - $dep"
    done
    echo ""
    echo "To install lint-staged:"
    echo "  npm install --save-dev lint-staged"
    echo ""
    echo "Add to package.json:"
    echo '  "lint-staged": {'
    echo '    "*.{js,jsx,ts,tsx}": ['
    echo '      "eslint --fix",'
    echo '      "prettier --write"'
    echo '    ]'
    echo '  }'
fi

echo ""
echo -e "${GREEN}🎉 JavaScript pre-commit hook installed successfully!${NC}"
echo ""
echo "The hook will run linting and tests before each commit."
echo "To bypass the hook temporarily, use: git commit --no-verify"