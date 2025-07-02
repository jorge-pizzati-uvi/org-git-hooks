# Organization Git Hooks

Centralized Git hooks for maintaining code quality and commit standards across all organization repositories.

## 🚀 Quick Start

### Install hooks based on your project type:

#### Global Hooks (All Projects)
Install commit message validation that works for any project:

```bash
# Using curl
curl -sSL https://raw.githubusercontent.com/YOUR-ORG/org-git-hooks/main/install-commit-hook-global.sh | bash

# Or clone and install locally
git clone https://github.com/YOUR-ORG/org-git-hooks.git
cd org-git-hooks
./install-commit-hook-global.sh --local
```

#### JavaScript/TypeScript Projects
Install pre-commit hooks for Node.js projects:

```bash
# Using curl
curl -sSL https://raw.githubusercontent.com/YOUR-ORG/org-git-hooks/main/install-pre-commit-hook-js.sh | bash

# Or clone and install locally
git clone https://github.com/YOUR-ORG/org-git-hooks.git
cd org-git-hooks
./install-pre-commit-hook-js.sh --local
```

#### Java Projects
Install pre-commit hooks for Maven/Gradle projects:

```bash
# Using curl
curl -sSL https://raw.githubusercontent.com/YOUR-ORG/org-git-hooks/main/install-pre-commit-hook-java.sh | bash

# Or clone and install locally
git clone https://github.com/YOUR-ORG/org-git-hooks.git
cd org-git-hooks
./install-pre-commit-hook-java.sh --local
```

### Install All Hooks (Legacy)
To install both global and tech-specific hooks at once:

```bash
# Using the original installer
curl -sSL https://raw.githubusercontent.com/YOUR-ORG/org-git-hooks/main/install-hooks.sh | bash
```

## 📋 Available Hooks

### commit-msg (Global)
- Validates branch name format: `<type>/<JIRA-KEY>`
- Validates commit message format: `<type>(<JIRA-KEY>): <description>`
- Valid types: `feat`, `fix`, `chore`, `refactor`
- Ensures consistency between branch name and commit message

### pre-commit (JavaScript)
- Runs lint-staged for code formatting and linting
- Executes test suite to ensure code quality
- Prevents commits if either check fails

### pre-commit (Java)
- Checks code formatting (Spotless/Google Java Format)
- Compiles all source code
- Runs static analysis (PMD, SpotBugs if configured)
- Executes test suite
- Supports both Maven and Gradle projects

## 🔧 Requirements

### For JavaScript Projects

1. **package.json** with lint-staged configuration:
```json
{
  "lint-staged": {
    "*.{js,jsx,ts,tsx,css,scss,md,html}": "prettier --write",
    "*.{js,jsx,ts,tsx}": "eslint --fix"
  }
}
```

2. **Test script** in package.json:
```json
{
  "scripts": {
    "test-build": "vitest --run"
  }
}
```

### For Java Projects

1. **Maven** projects should have:
   - Java compiler plugin configured
   - Optionally: Spotless or fmt-maven-plugin for formatting
   - Optionally: PMD or SpotBugs for static analysis

2. **Gradle** projects should have:
   - Java plugin applied
   - Optionally: Spotless plugin for formatting
   - Optionally: PMD or SpotBugs plugins for static analysis

## 🎯 Branch and Commit Message Examples

### Branch Names
✅ Valid branches:
- `feat/SUW-1234`
- `fix/ABC-5678`
- `chore/XYZ-999`
- `refactor/DEF-123`

❌ Invalid branches:
- `feature/ABC-123` (should be 'feat')
- `ABC-123` (missing type prefix)
- `feat-ABC-123` (should use '/' separator)

### Commit Messages
✅ Valid commits:
- `feat(SUW-1234): Add user authentication`
- `fix(ABC-5678): Correct input validation`
- `chore(XYZ-999): Update dependencies`
- `refactor(DEF-123): Simplify payment logic`

❌ Invalid commits:
- `Updated code` (missing type and Jira key)
- `feat: Added new feature` (missing Jira key and wrong format)
- `feat(ABC-123) Fixed bug` (missing colon after Jira key)

## 🚫 Bypassing Hooks (Emergency Only!)

In emergency situations, you can bypass hooks:

```bash
# Bypass pre-commit hook
git commit --no-verify -m "feat: ABC-123 Emergency fix"

# Bypass specific hook
SKIP=lint-staged git commit -m "feat: ABC-123 Skip linting"
```

⚠️ **Use sparingly!** Bypassing hooks should only be done in emergencies.

## 🔄 Updating Hooks

To get the latest version of hooks:

```bash
# Update global hooks
curl -sSL https://raw.githubusercontent.com/YOUR-ORG/org-git-hooks/main/install-commit-hook-global.sh | bash

# Update JavaScript hooks
curl -sSL https://raw.githubusercontent.com/YOUR-ORG/org-git-hooks/main/install-pre-commit-hook-js.sh | bash

# Update Java hooks
curl -sSL https://raw.githubusercontent.com/YOUR-ORG/org-git-hooks/main/install-pre-commit-hook-java.sh | bash
```

## 🤝 Contributing

To update organization hooks:

1. Clone this repository
2. Modify hooks in the appropriate directory:
   - `hooks/` - Global hooks (commit-msg)
   - `hooks/js/` - JavaScript-specific hooks
   - `hooks/java/` - Java-specific hooks
3. Test changes locally using the appropriate installer with `--local` flag
4. Submit a pull request
5. After merge, all teams can update by re-running the installer

## 📝 Customization

Teams can customize behavior by setting environment variables:

```bash
# Skip tests in pre-commit
SKIP_TESTS=1 git commit -m "feat: ABC-123 Quick fix"

# Use different hooks repository
HOOKS_REPO_URL=https://github.com/YOUR-FORK/org-git-hooks.git ./install-hooks.sh
```

## 🐛 Troubleshooting

### Hooks not running?
```bash
# Check if hooks are executable
ls -la .git/hooks/

# Make them executable
chmod +x .git/hooks/*
```

### Lint-staged not found?
```bash
# Install dependencies
npm install
```

### Tests failing?
```bash
# Run tests manually to see errors
npm run test-build
```

## 📞 Support

For issues or questions:
- Open an issue in this repository
- Contact the DevOps team
- Check the [Wiki](https://github.com/YOUR-ORG/org-git-hooks/wiki) for more details