#!/usr/bin/env nu
#MISE description="tauri ios dev — hot-reload on connected device or simulator (macOS only)"
def main [...args] {
  if (sys host | get name) != "Darwin" {
    print --stderr "✗ iOS builds require macOS"
    exit 1
  }
  let cmd = ($env.TAURI_CMD? | default "tauri")
  ^$cmd ios dev ...$args
}
