#!/usr/bin/env nu
#MISE description="tauri android init — generate the Android project (run once per clone)"
def main [...args] {
  let cmd = ($env.TAURI_CMD? | default "tauri")
  ^$cmd android init ...$args
}
