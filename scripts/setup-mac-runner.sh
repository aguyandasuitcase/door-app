#!/bin/bash
# One-time setup of this Mac as a GitHub Actions runner for aguyandasuitcase/door-app.
# Usage: bash setup-mac-runner.sh <REGISTRATION_TOKEN>
set -euo pipefail
TOKEN="${1:?Paste the token from GitHub: repo Settings, Actions, Runners, New self-hosted runner}"
REPO_URL="https://github.com/aguyandasuitcase/door-app"
DIR="$HOME/actions-runner-door"

echo "== Checking Xcode"
if ! xcodebuild -version >/dev/null 2>&1; then
  echo "Xcode is not installed or not selected. Install Xcode 26 from the App Store, open it once, then run this again."; exit 1
fi
xcodebuild -version
if ! xcodebuild -showsdks | grep -q "iphoneos26"; then
  echo "WARNING: iOS 26 SDK not found. Update Xcode to 26 or newer for Liquid Glass."
fi
sudo xcodebuild -license accept 2>/dev/null || true

echo "== Checking Homebrew tools"
if ! command -v brew >/dev/null; then
  echo "Homebrew is missing. Install it from https://brew.sh then run this again."; exit 1
fi
command -v xcodegen >/dev/null || brew install xcodegen
command -v gh >/dev/null || brew install gh

echo "== Installing the runner"
mkdir -p "$DIR" && cd "$DIR"
ARCH=$([ "$(uname -m)" = "arm64" ] && echo arm64 || echo x64)
VER=$(curl -s https://api.github.com/repos/actions/runner/releases/latest | grep -o '"tag_name": *"v[^"]*"' | head -1 | sed 's/.*"v\(.*\)"/\1/')
curl -sL -o runner.tar.gz "https://github.com/actions/runner/releases/download/v${VER}/actions-runner-osx-${ARCH}-${VER}.tar.gz"
tar xzf runner.tar.gz
./config.sh --unattended --replace --url "$REPO_URL" --token "$TOKEN" \
  --name "$(scutil --get ComputerName 2>/dev/null || hostname)-door" --labels door --work _work
./svc.sh install
./svc.sh start
echo "Done. The runner is online. You can tell Claude now."
