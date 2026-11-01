# Lekhok 0.8.0-l2 — Intel Mac (security update)

Same app as [0.8.0-l1](../releases/tag/v0.8.0-l1) with every Dependabot
alert that had a patched release fixed (123 of 124), plus two bug fixes
found after the first release. Upgrade by replacing Lekhok.app; your
workspaces and settings are untouched.

## Security updates

Runtime packages shipped in the app:

- **dompurify 3.4.7 → 3.4.17** — fixes 10 advisories incl. a critical
  SAFE_FOR_TEMPLATES bypass and an IN_PLACE event-handler fix
- **katex 0.16 → 0.18.10** — fixes a ReDoS-grade parsing advisory

Build/toolchain (not compiled into the app): vite-plus 0.1 → 1.4 (with its
bundled vite ≥ 8.1.6 / esbuild 0.28.2), undici 6.29.1, ws 8.21.0,
minimatch 11.0.3, brace-expansion 1.1.21/2.1.7, js-yaml 4.3.2,
ip-address 10.7.4, seroval 1.6.8, zod 4.6.6, shell-quote 1.11.0,
launch-editor 2.14.2, postcss 8.5.23, browserslist 4.28.7, and the rest
of the Dependabot list — enforced as version floors in
`pnpm-workspace.yaml` `overrides:` so future installs cannot regress them.
Website stack: @tanstack/react-start 1.169.4 (+ start-server-core 1.169.45,
react-router 1.170.46) — fixes a critical reflected XSS in server-function
responses.

**Known-remaining (2):**

- `extract-zip@2.0.1` (dev-only, e2e tooling) — no patched release exists
  upstream; it never ships in the app.
- `glib@0.18.5` (Cargo) — Linux-only GTK chain pinned by tauri 2.11's
  gtk 0.18 requirement; it is never compiled into the macOS artifact.
  Unblocks when upstream tauri/muda move to gtk ≥ 0.20.

## Bug fixes since 0.8.0-l1

- The 0.8.0-l1 DMG never opened a window: the bundle binary was named
  `Lekhok`, which collided with the case-insensitive `lekhok` CLI dispatch
  and made every launch exit as a CLI call. The bundle binary is back to
  `desktop` and two new tests pin the invariant (`main.rs`).
- README/release notes now give the correct macOS 15+ first-launch steps
  (`xattr -dr com.apple.quarantine` or System Settings → Privacy &
  Security → Open Anyway) — the right-click → Open bypass is gone.

## Verification

- `cargo test` 169 + 2 dispatch/config tests pass on x86_64
- frontend suite 766/766 pass on the upgraded stack
- desktop and website production builds pass (vite-plus 1.4)
- installed from the DMG on the Intel build host: GUI stable, `lekhok`
  CLI dispatch verified, clean quit

## sha256

    468f79b954e9a72505e43be52313d32e054c16535a17d3a866cc02af94faf9bb  Lekhok_0.8.0-l2_x64.dmg
