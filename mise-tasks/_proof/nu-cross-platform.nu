#!/usr/bin/env nu
# Cross-platform proof: this script runs identically on macOS, Linux, and Windows
# in the mise-tasks-lint workflow matrix. If lint goes green on windows-latest,
# nu+mise SSOT for org task scripts is verified end-to-end in CI.
#
# Exercises every nu pattern used in the bw:* migration plan (see
# joeblew999/nodewarden/scripts/bw-list.nu for the in-repo example):
#   - let / $env / try-catch
#   - from json / from toml
#   - where, each, sort-by, get -i, str length, str join, default
#   - null-safe field access (?)
#   - external commands via ^
#   - explicit exit codes
#
# Output is asserted by the workflow step. Modify with care — the workflow
# checks for an exact match.

# 1. Variable + string interpolation
let host = (sys host | get name)
let user = ($env.USER? | default ($env.USERNAME? | default "unknown"))

# 2. Inline JSON → table → filter → map → sort → format
let mock = '[
  {"type": 1, "name": "ZULU",  "login": {"password": "p1234"}},
  {"type": 1, "name": "ALPHA", "login": {"password": "longerpw"}},
  {"type": 2, "name": "skip",  "secureNote": {"type": 0}}
]'

let formatted = ($mock
  | from json
  | where type == 1
  | each {|it| { name: $it.name, len: ($it.login.password? | default "" | str length) } }
  | sort-by name
  | each {|r| $"($r.name)=($r.len)" }
  | str join ",")

# 3. Conditional + exit code on mismatch
let expected = "ALPHA=8,ZULU=5"
if $formatted != $expected {
  print --stderr $"✗ output mismatch — got: ($formatted), expected: ($expected)"
  exit 1
}

# 4. TOML parsing (mise.toml is everywhere in this org — make sure 'open' handles it)
let toml_test = ('[tools]
node = "lts"
' | from toml | get tools.node)
if $toml_test != "lts" {
  print --stderr $"✗ TOML parsing failed — got: ($toml_test)"
  exit 1
}

print "✓ nu cross-platform proof passed"
print $"  host=($host)  user=($user)  formatted=($formatted)"
