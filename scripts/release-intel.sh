#!/usr/bin/env bash
# Build the Lekhok Intel (x86_64) DMG from this Intel Mac.
#
# Guards refuse to ship anything but an ad-hoc-signed x86_64 artifact built
# without telemetry. Replaces upstream's scripts/distribute.sh for v1; the
# signed, notarized flow stays there for when Apple Developer signing is
# added. Ad-hoc signing (identity "-") keeps Gatekeeper's downloaded-app
# warning recoverable via right-click -> Open; fully unsigned binaries get
# rejected as damaged on newer macOS.
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "$0")/.." && pwd)"
SIZE_BUDGET_BYTES=10485760  # 10 MB; upstream arm64 DMG is 5.8 MB

# Toolchain: use whatever is on PATH; fall back to nvm/rustup locations.
if ! command -v node >/dev/null 2>&1; then
  [ -s "$HOME/.nvm/nvm.sh" ] && . "$HOME/.nvm/nvm.sh" && nvm use --silent 24
fi
if ! command -v rustc >/dev/null 2>&1; then
  [ -f "$HOME/.cargo/env" ] && . "$HOME/.cargo/env"
fi

# Guard 1: telemetry must never ship compiled in. A keyless release is inert;
# a keyed one is a decision, not an accident.
if [ -n "${WRITER_POSTHOG_KEY:-}" ]; then
  echo "refusing: WRITER_POSTHOG_KEY is set — unset it to ship telemetry-free" >&2
  exit 1
fi

# Guard 2: this script builds the host architecture on purpose. Building the
# Intel DMG must happen ON an Intel Mac.
HOST_ARCH="$(rustc -vV | awk '/^host:/ {print $2}')"
if [ "$HOST_ARCH" != "x86_64-apple-darwin" ]; then
  echo "refusing: rustc host is $HOST_ARCH — run this on an Intel Mac" >&2
  exit 1
fi

cd "$ROOT_DIR"

pnpm install --frozen-lockfile

# Release build: LTO + opt-level=s per Cargo.toml [profile.release].
cd apps/desktop
pnpm exec tauri build --target x86_64-apple-darwin

APP="src-tauri/target/x86_64-apple-darwin/release/bundle/macos/Lekhok.app"
BIN="$(ls "$APP/Contents/MacOS/" | head -1)"
BIN_PATH="$APP/Contents/MacOS/$BIN"

# Guard 3: the artifact must really be x86_64 — an arm64 DMG would not run
# on the machines this release targets. `file -b` prints only the verdict,
# never the path, so a wrong-path error cannot false-positive here.
if [ ! -f "$BIN_PATH" ]; then
  echo "refusing: app binary not found at $BIN_PATH" >&2
  exit 1
fi
ARCH_VERDICT="$(file -b "$BIN_PATH")"
if ! grep -q "x86_64" <<<"$ARCH_VERDICT"; then
  echo "refusing: $BIN_PATH is not x86_64: $ARCH_VERDICT" >&2
  exit 1
fi

# Ad-hoc sign. Without any signature, macOS Gatekeeper refuses quarantined
# downloads outright ("damaged"); an ad-hoc signature keeps the regular
# right-click -> Open escape hatch.
codesign --force --deep -s - "$APP"
codesign --verify --deep --strict "$APP"

# The dmg bundler ran before signing, so package the signed app ourselves.
VERSION="$(python3 -c "import json;print(json.load(open('src-tauri/tauri.conf.json'))['version'])")"
DMG_NAME="Lekhok_${VERSION}_x64.dmg"
DMG="src-tauri/target/x86_64-apple-darwin/release/bundle/dmg/$DMG_NAME"
STAGING="$(mktemp -d)"
trap 'rm -rf "$STAGING"' EXIT
cp -R "$APP" "$STAGING/Lekhok.app"
rm -f "$DMG"
hdiutil create -volname Lekhok -srcfolder "$STAGING/Lekhok.app" -ov -format UDZO "$DMG" >/dev/null

DMG_SIZE="$(stat -f%z "$DMG")"
if [ "$DMG_SIZE" -ge "$SIZE_BUDGET_BYTES" ]; then
  echo "refusing: $DMG is $DMG_SIZE bytes (budget $SIZE_BUDGET_BYTES)" >&2
  exit 1
fi

echo
echo "=== Release artifact ==="
echo "binary: $BIN ($ARCH_VERDICT)"
codesign -dv "$APP" 2>&1 | head -2
echo "DMG: $DMG ($(du -h "$DMG" | awk '{print $1}'))"
shasum -a 256 "$DMG"
