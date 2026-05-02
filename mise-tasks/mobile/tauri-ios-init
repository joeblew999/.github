#!/usr/bin/env nu
#MISE description="tauri ios init — generate the Xcode project (macOS only, run once per clone)"
def main [...args] {
  if (sys host | get name) != "Darwin" {
    print --stderr "✗ iOS builds require macOS"
    exit 1
  }
  let cmd = ($env.TAURI_CMD? | default "tauri")
  ^$cmd ios init ...$args
}
