# Lekhok 0.8.0-l1 — Intel Mac

Lekhok is a GPL-3.0 fork of [writer-computer](https://github.com/joelbqz/writer-computer)
v0.8.0 (by joelbqz), released for **Intel (x86_64) Macs** — the platforms
upstream does not ship for.

## What changed vs upstream v0.8.0

1. **Rebrand** — product name _Lekhok_, bundle id `com.lekhok.desktop`,
   shell command `lekhok`, env override `LEKHOK_APP_PATH`. The `writer_cli`
   Rust module keeps its upstream name as an internal identifier.
2. **Trash via NSFileManager** — upstream uses the trash crate's Finder
   AppleEvent method, which stalls for 120 s on some Intel Macs and asks
   for Finder-automation permission on unsigned builds. Deletions now use
   `NSFileManager.trashItemAtURL` (no permissions). Cost: no Finder
   "Put Back" on trashed items.
3. **Auto-updater removed** — upstream's feed serves arm64-only artifacts;
   letting an Intel install self-update from it would brick the app. No
   updater ships in v1; a per-platform one may return later, pointed at
   this repo.
4. **Release pipeline** — `scripts/release-intel.sh` builds on an Intel
   Mac and hard-fails unless the host is `x86_64-apple-darwin`, the binary
   verifies as x86_64, the DMG is under 10 MB, and no telemetry key is set.
   The app is ad-hoc signed so quarantined downloads stay openable via
   right-click → Open.
5. **Version alignment** — `@tauri-apps/api` ~2.11 and
   `@tauri-apps/plugin-dialog` ~2.7 pinned to the Rust crates' minors
   (tauri build enforces this).

Telemetry is not compiled in. No PostHog key ships.

## Verification

- `cargo test`: 169/169 pass on x86_64
- Built binary: `Mach-O 64-bit executable x86_64`, codesign `adhoc`
- Installed from DMG and smoke-tested on the Intel build host

## sha256

    2bab2a4d211eb9485366faba627d0fc6287ce2e3775343a83f7ebf1372a0aeef  Lekhok_0.8.0-l1_x64.dmg

## Roadmap

Windows and Linux builds next — the upstream codebase already carries
platform branches for both; what is missing is bundling and CI. After
that, a per-platform updater and periodic upstream merges.
