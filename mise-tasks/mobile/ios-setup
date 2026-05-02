#!/usr/bin/env nu
#MISE description="Assert iOS toolchain: macOS + Xcode CLI tools + CocoaPods. Run once per machine."

def main [] {
  if (sys host | get name) != "Darwin" {
    print --stderr "✗ iOS builds require macOS (Xcode is macOS-only)"
    exit 1
  }

  let xcode_check = (^xcode-select -p | complete)
  if $xcode_check.exit_code != 0 {
    print --stderr "✗ Xcode CLI tools not installed."
    print --stderr "  Run: xcode-select --install"
    print --stderr "  Or install Xcode from the App Store (includes CLI tools)."
    exit 1
  }
  let xcode_path = ($xcode_check.stdout | str trim)
  print $"✓ Xcode: ($xcode_path)"

  if ($xcode_path | str contains "CommandLineTools") {
    print --stderr "⚠  CLI tools only — iOS simulator builds need full Xcode."
    print --stderr "   Install Xcode from the App Store, then: sudo xcode-select -s /Applications/Xcode.app"
  }

  if (which pod | is-empty) {
    print "→ installing CocoaPods..."
    ^gem install cocoapods
  }
  let pod_ver = (^pod --version | str trim)
  print $"✓ CocoaPods ($pod_ver)"

  print "→ adding Rust iOS targets..."
  ^rustup target add aarch64-apple-ios aarch64-apple-ios-sim x86_64-apple-ios

  print ""
  print "✓ iOS toolchain ready."
  print "  Next: mise run init:ios   (first time only)"
  print "        mise run dev:ios    (requires connected device or simulator)"
}
