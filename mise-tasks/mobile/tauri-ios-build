#!/usr/bin/env nu
#MISE description="tauri ios build — release IPA (macOS only)"
def main [...args] {
  if (sys host | get name) != "Darwin" {
    print --stderr "✗ iOS builds require macOS"
    exit 1
  }
  let cmd = ($env.TAURI_CMD? | default "tauri")
  ^$cmd ios build ...$args
}
