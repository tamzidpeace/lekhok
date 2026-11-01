# Lekhok

Lekhok is a free and open-source markdown editor for **Intel (x86_64) Macs**.
It is a fork of [Writer Computer](https://github.com/joelbqz/writer-computer)
by joelbqz — a ~6 MB download, starts faster than Apple Notes and Obsidian,
and opens very large workspaces instantly. Upstream ships Apple Silicon
builds only; Lekhok exists so Intel Macs get the same editor. The app keeps
documents on disk, respects workspace `.gitignore` rules, supports multiple
windows, and renders extended markdown such as tables and Mermaid diagrams.

## Install (macOS 10.15+, Intel)

1. Grab `Lekhok_<version>_x64.dmg` from
   [Releases](../../releases).
2. Open the DMG and drag **Lekhok** into **Applications**.
3. The build is ad-hoc signed (no Apple Developer account), so macOS will
   block the first launch with an "unidentified developer" warning. On
   **macOS 15 and later the right-click → Open bypass no longer works**.
   Either run this in Terminal after dragging the app over:
   ```bash
   xattr -dr com.apple.quarantine /Applications/Lekhok.app
   ```
   …or open **System Settings → Privacy & Security**, scroll down, and click
   **Open Anyway** next to the "Lekhok.app was blocked" notice. After the
   first successful launch it opens normally.

Releases include the sha256 of the DMG.

## Why a fork

Upstream [writer-computer](https://github.com/joelbqz/writer-computer) is an
excellent, actively developed editor — but it is released for Apple Silicon
(`aarch64`) only, with no CI and no x86_64 pipeline. Lekhok starts from the
`v0.8.0` tag and adds what upstream is missing for Intel:

- x86_64 release builds (`scripts/release-intel.sh`, guard-checked)
- Deletions move to Trash via `NSFileManager` instead of a Finder
  AppleEvent, which stalls on some Intel Macs and would prompt for
  automation permissions on unsigned builds (cost: no Finder "Put Back")
- The auto-updater is removed: upstream's update feed serves arm64
  artifacts and would brick an Intel install. A per-platform updater may
  return in a later release.

Everything else is upstream v0.8.0: same Tauri v2 + Rust + React +
CodeMirror stack, same features, same local-first behavior. Telemetry is
not compiled into these builds at all.

## Build from source

Prerequisites: an Intel Mac, Node.js ≥ 22.12 (nvm works), pnpm 10.32.1
(`corepack enable && corepack prepare pnpm@10.32.1 --activate`), and Rust
stable (`rustup`). The release script refuses to run on non-Intel hosts.

```bash
pnpm install
pnpm run dev                    # develop
./scripts/release-intel.sh      # build Lekhok_<version>_x64.dmg
```

Validation:

```bash
cd apps/desktop/src-tauri && cargo test && cargo clippy
cd apps/desktop && pnpm exec tsc
```

Note: keep the `@tauri-apps/api` and `@tauri-apps/plugin-dialog` npm
versions on the **same minor** as their Rust crates (`tauri`,
`tauri-plugin-dialog` in `Cargo.lock`) — `tauri build` enforces the match.

## Roadmap

- [x] v0.8.0-l1 — Intel (x86_64) Mac release
- [ ] Windows build (NSIS installer) — the codebase already carries
      Windows branches for most platform code
- [ ] Linux build (AppImage / .deb) — ditto
- [ ] Per-platform auto-updater pointed at this repo's releases
- [ ] Periodic merges from upstream

## License

GPL-3.0, same as upstream. See [LICENSE](./LICENSE).
