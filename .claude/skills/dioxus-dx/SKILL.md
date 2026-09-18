---
name: dioxus-dx
description: Build, serve and bundle a Dioxus app with the dx CLI — platforms and renderers, package types, what Dioxus.toml actually reads, iOS/Android signing and icons, and where the real docs are. Use when writing or debugging a dx invocation, choosing a --platform or --package-types, editing Dioxus.toml, or explaining why a mobile bundle came out wrong.
---

# dx, the Dioxus CLI

## Ask the binary, not your memory

dx embeds its own config schema, so the installed binary is the only source that
cannot be out of date. Two commands answer most questions:

    dx serve --help          # platforms, renderers, --device, --package
    dx bundle --help         # --package-types and what each produces

For what `Dioxus.toml` accepts, read the serde field lists out of the binary —
this is how to settle "does dx support X" without guessing:

    strings "$(command -v dx)" | grep -o 'deployment_targetinfo_plist.\{0,260\}'
    strings "$(command -v dx)" | grep -o 'signingmin_sdk.\{0,240\}'
    strings "$(command -v dx)" | grep -o 'asset_dirout_dir.\{0,300\}'

## Platforms and renderers

`--platform` takes `web, macos, windows, linux, ios, android, server, liveview,
desktop`, and there is a bare flag for each (`--web`, `--ios`, …). The noun IS
the flag — no translation table is needed.

The renderer is usually inferred. The exception worth knowing:

    dx serve --platform desktop --renderer native   # Blitz on the GPU
    dx serve --platform desktop                     # system webview (wry)

Do not pass `--features` for the platform. dx enables the matching client
feature itself (`web` / `desktop` / `mobile`) and the renderer's feature with
it, so naming them again only lets the two disagree.

## Bundling

`dx bundle --package-types` takes `macos, dmg, ios, ipa, msi, nsis, deb, rpm,
appimage, apk, aab`. Not every type is valid for every platform. With no
`--package-types`, the host's defaults apply — on macOS a bare `bundle desktop`
gives both the `.app` and the `.dmg`.

**iOS without a signing identity:** the default is `.ipa`, which must be
codesigned and so wants a provisioning profile. `--package-types ios` gives the
raw `.app`, which needs none and installs to the Simulator.

**Never pass `--device` on an iOS serve.** It sets dx's `should_codesign` and
the build then demands a profile. dx uploads to whichever Simulator is already
booted, so boot one first (`xcrun simctl boot '<name>'`) and leave `--device`
off. Android is the mirror image: left alone dx picks the first AVD on the
machine, so pass `--device` there when more than one could match.

## Icons: dx has no mobile path

`[bundle].icon` in `Dioxus.toml` is read **only by the desktop bundlers** —
macOS takes the `.icns`, Windows the `.ico`, Linux the PNGs — and only by
`dx bundle`, never by `dx build` or `dx serve`. A served app therefore has no
custom icon at all, and cannot be given one: dx wipes and rewrites the whole
bundle on every build.

There is **no icon field for iOS or Android**. Verified against 0.7.10 and
0.8.0-alpha.1: `ApplicationConfig` carries `ios_info_plist`, `macos_info_plist`,
`ios_entitlements`, `android_manifest`, `android_main_activity`,
`android_min_sdk_version` and no icon; `[ios]` has `deployment_target`,
`info_plist`, `plist`, `raw`, `url_schemes`, `document_types`,
`widget_extensions` (plus `background_modes` in 0.8); `[android]` has `signing`,
`min_sdk`, `target_sdk`, `compile_sdk`, `gradle_dependencies`, `gradle_plugins`,
`proguard_rules`, `intent_filters`, `queries`, `theme`. No icon in any of them.

dx ships its own `ic_launcher.webp`, `mipmap-anydpi-v26/ic_launcher.xml` and the
five mipmap densities baked into the binary, and writes `CFBundleIconFile` for
iOS. So a project that wants its own mobile icon must apply it **after** dx has
produced the bundle, and re-run gradle for Android because dx regenerates `res/`
from its template every invocation. Re-check with the `strings` commands above
before assuming a newer dx has fixed this.

## Two flags that bite

- `--debug-symbols` defaults to **true** and overrides `[web.wasm_opt] debug =
  false`. Left on, wasm-opt gets `--debuginfo`, can crash rewriting rustc's
  DWARF, and dx still reports success — so what ships is unoptimised wasm. Pass
  `--debug-symbols false` for a release web build.
- `dx bundle` refuses without `[bundle].publisher`; `dx build` and `dx serve`
  never ask for it.

## The full docs

Dioxus publishes the whole documentation as one file per minor version. Fetch
the part you need rather than keeping a copy:

    https://dioxuslabs.com/learn/<major.minor>/llms.txt        # index, ~60KB
    https://dioxuslabs.com/learn/<major.minor>/llms-full.txt   # prose, ~1.9MB

`llms.txt` lists every page with its own lead paragraph, which is how to pick a
page; `llms-full.txt` is where an answer actually is. Match the version to the
`dioxus` dependency in `Cargo.toml`, because dx refuses a project whose dioxus
differs from its own.
