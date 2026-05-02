#!/usr/bin/env nu
#MISE description="tauri android build — release APK/AAB"
def main [...args] {
  let cmd = ($env.TAURI_CMD? | default "tauri")
  ^$cmd android build ...$args
}
