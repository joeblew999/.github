#!/usr/bin/env nu
#MISE description="Assert Android toolchain: Java 17+, ANDROID_HOME, NDK. Run once per machine."

def main [] {
  if (which java | is-empty) {
    print --stderr "✗ java not found — run: mise use java@temurin-17"
    exit 1
  }
  let ver_raw = (^java -version | complete | get stderr | lines | first)
  let java_ver = ($ver_raw | parse --regex '"([0-9]+)' | get capture0?.0? | default "0" | into int)
  if $java_ver < 17 {
    print --stderr $"✗ Java 17+ required, found: ($ver_raw)"
    exit 1
  }
  print $"✓ Java ($java_ver)"

  mut android_home = ($env.ANDROID_HOME? | default "")
  if ($android_home | is-empty) {
    let mac_default = $"($env.HOME)/Library/Android/sdk"
    let linux_default = $"($env.HOME)/Android/Sdk"
    if ($mac_default | path exists) {
      $android_home = $mac_default
      print $"→ auto-detected ANDROID_HOME=($android_home) \(Android Studio default\)"
      print $"  Add to .mise.toml [env]: ANDROID_HOME = \"($android_home)\""
    } else if ($linux_default | path exists) {
      $android_home = $linux_default
      print $"→ auto-detected ANDROID_HOME=($android_home)"
    } else {
      print --stderr "✗ ANDROID_HOME not set and no SDK found at default paths."
      print --stderr "  Install Android Studio, or set ANDROID_HOME in .mise.toml [env]."
      exit 1
    }
    $env.ANDROID_HOME = $android_home
  }
  print $"✓ ANDROID_HOME=($android_home)"

  let ndk_base = $"($android_home)/ndk"
  if ($ndk_base | path exists) and (ls $ndk_base | length) > 0 {
    let ndk_ver = (ls $ndk_base | get name | each { |p| $p | path basename } | sort | last)
    let ndk_dir = $"($ndk_base)/($ndk_ver)"
    print $"✓ NDK ($ndk_ver) \(($ndk_dir)\)"
    $env.ANDROID_NDK_HOME = $ndk_dir
  } else {
    let sdkmgr = $"($android_home)/cmdline-tools/latest/bin/sdkmanager"
    if not ($sdkmgr | path exists) {
      print --stderr $"✗ sdkmanager not found at ($sdkmgr)"
      print --stderr "  Install 'Command-line tools' from Android Studio → SDK Manager → SDK Tools."
      exit 1
    }
    print "→ installing NDK 27 + platform 34 via sdkmanager..."
    ^$sdkmgr --install "ndk;27.0.12077973" "platforms;android-34" "build-tools;34.0.0"
    $env.ANDROID_NDK_HOME = $"($ndk_base)/27.0.12077973"
    print $"✓ NDK installed: ($env.ANDROID_NDK_HOME)"
  }

  print "→ adding Rust Android targets..."
  ^rustup target add aarch64-linux-android armv7-linux-androideabi i686-linux-android x86_64-linux-android

  print ""
  print "✓ Android toolchain ready."
  print "  Next: mise run init:android   (first time only)"
  print "        mise run dev:android    (requires device or emulator)"
}
