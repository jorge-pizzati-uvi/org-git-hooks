#!/bin/bash

# Java Pre-commit Hook Installation Script
# Installs pre-commit hook for Java projects

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Configuration
HOOKS_REPO_URL="${HOOKS_REPO_URL:-https://github.com/YOUR-ORG/org-git-hooks.git}"
JAVA_HOOKS_DIR="hooks/java"

echo -e "${GREEN}☕ Java Pre-commit Hook Installer${NC}"
echo "=================================="

# Check if we're in a git repository
if ! git rev-parse --git-dir > /dev/null 2>&1; then
    echo -e "${RED}❌ Error: Not in a git repository${NC}"
    echo "Please run this script from the root of your git repository"
    exit 1
fi

# Check if this is a Java project
is_java_project=false
if [ -f "pom.xml" ]; then
    is_java_project=true
    build_tool="maven"
elif [ -f "build.gradle" ] || [ -f "build.gradle.kts" ]; then
    is_java_project=true
    build_tool="gradle"
fi

if [ "$is_java_project" = false ]; then
    echo -e "${YELLOW}⚠️  Warning: No pom.xml or build.gradle found${NC}"
    echo "This doesn't appear to be a Java project."
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

# Function to create Java pre-commit hook
create_java_pre_commit() {
    local target_file="$1"
    
    # Create the Java pre-commit hook content
    cat > "$target_file" << 'EOF'
#!/bin/sh

echo "☕ Java pre-commit hook triggered" >&2

# Detect build tool
if [ -f "pom.xml" ]; then
    BUILD_TOOL="maven"
    BUILD_CMD="mvn"
elif [ -f "build.gradle" ] || [ -f "build.gradle.kts" ]; then
    BUILD_TOOL="gradle"
    BUILD_CMD="./gradlew"
else
    echo "❌ No supported build tool found (Maven or Gradle)" >&2
    exit 1
fi

# Run code formatting check
echo "🎨 Checking code formatting..." >&2
if [ "$BUILD_TOOL" = "maven" ]; then
    if grep -q "spotless-maven-plugin" pom.xml 2>/dev/null; then
        $BUILD_CMD spotless:check
        FORMAT_RESULT=$?
    elif grep -q "fmt-maven-plugin" pom.xml 2>/dev/null; then
        $BUILD_CMD fmt:check
        FORMAT_RESULT=$?
    else
        echo "ℹ️  No formatting plugin found, skipping format check" >&2
        FORMAT_RESULT=0
    fi
else
    # Gradle
    if $BUILD_CMD tasks --all | grep -q "spotlessCheck" 2>/dev/null; then
        $BUILD_CMD spotlessCheck
        FORMAT_RESULT=$?
    else
        echo "ℹ️  No formatting task found, skipping format check" >&2
        FORMAT_RESULT=0
    fi
fi

if [ $FORMAT_RESULT -ne 0 ]; then
    echo "❌ Code formatting check failed. Run formatting:" >&2
    if [ "$BUILD_TOOL" = "maven" ]; then
        echo "   mvn spotless:apply" >&2
    else
        echo "   ./gradlew spotlessApply" >&2
    fi
    exit 1
fi

# Run compilation
echo "🔨 Compiling code..." >&2
if [ "$BUILD_TOOL" = "maven" ]; then
    $BUILD_CMD compile test-compile
else
    $BUILD_CMD compileJava compileTestJava
fi
COMPILE_RESULT=$?

if [ $COMPILE_RESULT -ne 0 ]; then
    echo "❌ Compilation failed. Please fix the errors and try again." >&2
    exit 1
fi

# Run static analysis if available
echo "🔍 Running static analysis..." >&2
if [ "$BUILD_TOOL" = "maven" ]; then
    if grep -q "maven-pmd-plugin" pom.xml 2>/dev/null; then
        $BUILD_CMD pmd:check
        PMD_RESULT=$?
    else
        PMD_RESULT=0
    fi
    
    if grep -q "spotbugs-maven-plugin" pom.xml 2>/dev/null; then
        $BUILD_CMD spotbugs:check
        SPOTBUGS_RESULT=$?
    else
        SPOTBUGS_RESULT=0
    fi
else
    # Gradle
    if $BUILD_CMD tasks --all | grep -q "pmdMain" 2>/dev/null; then
        $BUILD_CMD pmdMain
        PMD_RESULT=$?
    else
        PMD_RESULT=0
    fi
    
    if $BUILD_CMD tasks --all | grep -q "spotbugsMain" 2>/dev/null; then
        $BUILD_CMD spotbugsMain
        SPOTBUGS_RESULT=$?
    else
        SPOTBUGS_RESULT=0
    fi
fi

if [ $PMD_RESULT -ne 0 ] || [ $SPOTBUGS_RESULT -ne 0 ]; then
    echo "❌ Static analysis failed. Please fix the issues and try again." >&2
    exit 1
fi

# Run tests
echo "🧪 Running tests..." >&2
if [ "$BUILD_TOOL" = "maven" ]; then
    $BUILD_CMD test
else
    $BUILD_CMD test
fi
TEST_RESULT=$?

if [ $TEST_RESULT -ne 0 ]; then
    echo "❌ Tests failed. Please fix the failing tests and try again." >&2
    exit 1
fi

echo "✅ Java pre-commit checks passed" >&2
exit 0
EOF
    
    chmod +x "$target_file"
}

# Function to install pre-commit hook
install_java_pre_commit() {
    local source_file="$1"
    local target_file="$HOOKS_TARGET_DIR/pre-commit"
    
    # Create hooks directory if it doesn't exist
    mkdir -p "$HOOKS_TARGET_DIR"
    
    # Backup existing hook if it exists
    if [ -f "$target_file" ]; then
        echo -e "${YELLOW}⚠️  Backing up existing pre-commit to pre-commit.backup${NC}"
        cp "$target_file" "$target_file.backup"
    fi
    
    if [ -f "$source_file" ]; then
        # Copy existing hook
        cp "$source_file" "$target_file"
        chmod +x "$target_file"
    else
        # Create new Java pre-commit hook
        echo -e "${YELLOW}Creating new Java pre-commit hook...${NC}"
        create_java_pre_commit "$target_file"
    fi
    
    echo -e "${GREEN}✅ Installed: Java pre-commit hook${NC}"
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
    
    # Check if Java-specific hook exists
    if [ -f "$temp_dir/$JAVA_HOOKS_DIR/pre-commit" ]; then
        install_java_pre_commit "$temp_dir/$JAVA_HOOKS_DIR/pre-commit"
    else
        # Create a new Java pre-commit hook
        echo -e "${YELLOW}No Java-specific hook found in repository${NC}"
        install_java_pre_commit ""
    fi
    
    # Cleanup
    rm -rf "$temp_dir"
}

# Main installation logic
if [ "$1" == "--local" ]; then
    # Install from local directory
    SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
    
    # Check for Java-specific hook first
    if [ -f "$SCRIPT_DIR/$JAVA_HOOKS_DIR/pre-commit" ]; then
        install_java_pre_commit "$SCRIPT_DIR/$JAVA_HOOKS_DIR/pre-commit"
    else
        # Create a new Java pre-commit hook
        install_java_pre_commit ""
    fi
else
    # Install from remote repository
    install_from_remote
fi

# Check for common Java tools
echo ""
echo -e "${YELLOW}📋 Checking Java environment...${NC}"

missing_tools=()

# Check for Java
if ! command -v java &> /dev/null; then
    missing_tools+=("Java JDK")
fi

# Check for build tools
if [ "$build_tool" = "maven" ] && ! command -v mvn &> /dev/null; then
    missing_tools+=("Maven")
elif [ "$build_tool" = "gradle" ] && [ ! -f "./gradlew" ] && ! command -v gradle &> /dev/null; then
    missing_tools+=("Gradle wrapper (./gradlew)")
fi

if [ ${#missing_tools[@]} -gt 0 ]; then
    echo -e "${YELLOW}⚠️  Missing tools:${NC}"
    for tool in "${missing_tools[@]}"; do
        echo "   - $tool"
    done
fi

echo ""
echo -e "${GREEN}🎉 Java pre-commit hook installed successfully!${NC}"
echo ""
echo "The hook will:"
echo "  - Check code formatting (if configured)"
echo "  - Compile the code"
echo "  - Run static analysis (if configured)"
echo "  - Run tests"
echo ""
echo "To bypass the hook temporarily, use: git commit --no-verify"