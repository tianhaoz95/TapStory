#!/usr/bin/env bash
#
# Bumps MARKETING_VERSION in project.yml, regenerates the Xcode project,
# commits and pushes the change, and creates a published GitHub release via gh.
# Creating the release automatically triggers the TestFlight release workflow.
#
# Usage:
#   ./Scripts/release.sh [patch|minor|major|<version>]
#
# Examples:
#   ./Scripts/release.sh          # bumps patch: 0.1.0 -> 0.1.1
#   ./Scripts/release.sh patch    # bumps patch: 0.1.0 -> 0.1.1
#   ./Scripts/release.sh minor    # bumps minor: 0.1.0 -> 0.2.0
#   ./Scripts/release.sh 0.2.0    # sets explicit version: 0.2.0

set -euo pipefail

REPO_ROOT="$(cd "$(dirname "$0")/.." && pwd)"
cd "$REPO_ROOT"

# Preflight checks
if ! command -v gh >/dev/null 2>&1; then
  echo "Error: GitHub CLI (gh) is not installed." >&2
  exit 1
fi

if ! gh auth status >/dev/null 2>&1; then
  echo "Error: gh is not authenticated. Please run 'gh auth login' first." >&2
  exit 1
fi

if ! command -v xcodegen >/dev/null 2>&1; then
  echo "Error: xcodegen is not installed." >&2
  exit 1
fi

CURRENT_BRANCH="$(git rev-parse --abbrev-ref HEAD)"
if [ "$CURRENT_BRANCH" != "main" ]; then
  echo "Error: Releases must be created from the 'main' branch (currently on '$CURRENT_BRANCH')." >&2
  exit 1
fi

# Ensure working directory is clean
if [ -n "$(git status --porcelain)" ]; then
  echo "Error: Working directory has uncommitted changes. Please commit or stash them first." >&2
  git status -s >&2
  exit 1
fi

# Ensure up-to-date with remote
echo "Checking remote status..."
git fetch origin main
LOCAL_HASH="$(git rev-parse HEAD)"
REMOTE_HASH="$(git rev-parse origin/main)"
if [ "$LOCAL_HASH" != "$REMOTE_HASH" ]; then
  echo "Error: Local branch differs from origin/main. Run git pull or git push first." >&2
  exit 1
fi

# Compute new version using Python
TARGET="${1:-patch}"

NEW_VERSION="$(python3 - "$TARGET" << 'PYEOF'
import sys
import re

target = sys.argv[1]

with open('project.yml', 'r') as f:
    content = f.read()

m = re.search(r'MARKETING_VERSION:\s*"([^"]+)"', content)
if not m:
    sys.exit("Error: Could not find MARKETING_VERSION in project.yml")

current = m.group(1)
parts = current.split('.')
if len(parts) != 3 or not all(p.isdigit() for p in parts):
    sys.exit(f"Error: Current MARKETING_VERSION '{current}' is not valid semver (X.Y.Z)")

major, minor, patch = map(int, parts)

if target == 'patch':
    patch += 1
elif target == 'minor':
    minor += 1
    patch = 0
elif target == 'major':
    major += 1
    minor = 0
    patch = 0
else:
    ver_m = re.match(r'^\d+\.\d+\.\d+$', target)
    if not ver_m:
        sys.exit(f"Error: Target version '{target}' must be 'patch', 'minor', 'major', or 'X.Y.Z'")
    major, minor, patch = map(int, target.split('.'))

new_ver = f"{major}.{minor}.{patch}"
print(new_ver)
PYEOF
)"

OLD_VERSION="$(python3 -c "import re; print(re.search(r'MARKETING_VERSION:\s*\"([^\"]+)\"', open('project.yml').read()).group(1))")"
echo "Bumping version from $OLD_VERSION to $NEW_VERSION..."

# Update project.yml (both TapStory and TapStoryWatch targets)
python3 - "$NEW_VERSION" << 'PYEOF'
import sys
import re

new_ver = sys.argv[1]
with open('project.yml', 'r') as f:
    content = f.read()

updated = re.sub(r'MARKETING_VERSION:\s*"[^"]+"', f'MARKETING_VERSION: "{new_ver}"', content)

with open('project.yml', 'w') as f:
    f.write(updated)
PYEOF

# Regenerate Xcode project
echo "Regenerating Xcode project..."
xcodegen generate

# Commit and push
echo "Committing version bump..."
git add project.yml
git commit -m "Bump version to v$NEW_VERSION"

echo "Pushing commit to origin main..."
git push origin main

# Create GitHub Release
TAG="v$NEW_VERSION"
echo "Creating GitHub Release $TAG..."
gh release create "$TAG" --title "$TAG" --generate-notes

echo ""
echo "============================================================"
echo "Release $TAG created successfully!"
echo "This has triggered the 'Release to TestFlight' GitHub Action."
echo "Track the workflow run with:"
echo "  gh run list --workflow=testflight.yml"
echo "  gh run watch"
echo "============================================================"
