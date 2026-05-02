#!/usr/bin/env nu
#MISE description="tauri android dev — hot-reload on connected device or emulator"
def main [...args] {
  let cmd = ($env.TAURI_CMD? | default "tauri")
  ^$cmd android dev ...$args
}
