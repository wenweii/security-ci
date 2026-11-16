#!/usr/bin/env bash
set -Eeuo pipefail

# Official Gitleaks v8.30.1 linux_x64 release checksum (2026-03-21).
VERSION='8.30.1'
SHA256='551f6fc83ea457d62a0d98237cbad105af8d557003051f41f3e7ca7b3f2470eb'
ASSET="gitleaks_${VERSION}_linux_x64.tar.gz"
URL="https://github.com/gitleaks/gitleaks/releases/download/v${VERSION}/${ASSET}"

if [[ "$(uname -s)" != Linux || "$(uname -m)" != x86_64 ]]; then
  echo 'This installer targets GitHub-hosted ubuntu-latest x86_64 only.' >&2
  exit 2
fi

TMP_DIR="$(mktemp -d)"
trap 'rm -rf "$TMP_DIR"' EXIT
curl --fail --silent --show-error --location --retry 3 "$URL" --output "$TMP_DIR/$ASSET"
printf '%s  %s\n' "$SHA256" "$TMP_DIR/$ASSET" | sha256sum --check --status || {
  echo 'Gitleaks SHA-256 mismatch. Refusing to install.' >&2
  exit 1
}
tar -xzf "$TMP_DIR/$ASSET" -C "$TMP_DIR" gitleaks
install -m 0755 "$TMP_DIR/gitleaks" "$TMP_DIR/gitleaks-bin"
if [[ -n "${RUNNER_TEMP:-}" && -n "${GITHUB_PATH:-}" ]]; then
  mkdir -p "$RUNNER_TEMP/security-bin"
  install -m 0755 "$TMP_DIR/gitleaks-bin" "$RUNNER_TEMP/security-bin/gitleaks"
  printf '%s\n' "$RUNNER_TEMP/security-bin" >> "$GITHUB_PATH"
  "$RUNNER_TEMP/security-bin/gitleaks" version
else
  mkdir -p "$HOME/.local/bin"
  install -m 0755 "$TMP_DIR/gitleaks-bin" "$HOME/.local/bin/gitleaks"
  echo "Installed to $HOME/.local/bin/gitleaks; add it to PATH when needed."
fi
