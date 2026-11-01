// Prevents additional console window on Windows in release, DO NOT REMOVE!!
#![cfg_attr(not(debug_assertions), windows_subsystem = "windows")]

use std::path::Path;
use std::process::ExitCode;

/// Multi-call dispatch: a symlink named `lekhok` in the user's PATH points
/// at the Lekhok app binary. When invoked through that symlink, argv[0]'s
/// basename is `lekhok` and we run the CLI. Invoked as the bundle binary
/// (`desktop`, the Cargo package name), we run the Tauri app. The bundle
/// binary must never be named `Lekhok`/`lekhok`: the dispatch below is
/// case-insensitive, so that name would route every app launch into the
/// CLI and exit without a window.
fn main() -> ExitCode {
    if is_cli_invocation() {
        let argv: Vec<_> = std::env::args_os().collect();
        let cwd = std::env::current_dir().unwrap_or_else(|_| Path::new(".").into());
        return desktop_lib::writer_cli::run(argv, &cwd, &desktop_lib::writer_cli::SystemLauncher);
    }
    desktop_lib::run();
    ExitCode::SUCCESS
}

fn is_cli_invocation() -> bool {
    let Some(arg0) = std::env::args_os().next() else {
        return false;
    };
    Path::new(&arg0)
        .file_stem()
        .and_then(|s| s.to_str())
        .map(|name| name.eq_ignore_ascii_case("lekhok"))
        .unwrap_or(false)
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn cli_dispatch_matches_the_lekhok_shim_name() {
        fn dispatch_as(argv0: &str) -> bool {
            let arg = std::ffi::OsString::from(argv0);
            // same logic as is_cli_invocation, fed a fixed argv[0]
            Path::new(&arg)
                .file_stem()
                .and_then(|s| s.to_str())
                .map(|name| name.eq_ignore_ascii_case("lekhok"))
                .unwrap_or(false)
        }
        assert!(dispatch_as("lekhok"));
        assert!(dispatch_as("LEKHOK"));
        assert!(dispatch_as("/usr/local/bin/lekhok"));
        assert!(!dispatch_as("desktop"));
        assert!(!dispatch_as("/Applications/Lekhok.app/Contents/MacOS/desktop"));
    }

    /// The bundle binary's name must never CLI-match `lekhok` (case-
    /// insensitively), or every app launch takes the CLI path and exits
    /// without a window. Tauri names the bundle binary from
    /// `mainBinaryName` when set, else from the Cargo package name.
    #[test]
    fn bundle_binary_name_never_cli_matches() {
        let conf = std::fs::read_to_string(concat!(
            env!("CARGO_MANIFEST_DIR"),
            "/tauri.conf.json"
        ))
        .unwrap();
        let parsed: serde_json::Value = serde_json::from_str(&conf).unwrap();
        let bin_name = parsed["mainBinaryName"]
            .as_str()
            .map(str::to_owned)
            .unwrap_or_else(|| env!("CARGO_PKG_NAME").to_owned());
        assert_ne!(
            bin_name.to_ascii_lowercase(),
            "lekhok",
            "bundle binary '{bin_name}' collides with the CLI dispatch name; \
             app launches would exit as CLI invocations"
        );
    }
}
