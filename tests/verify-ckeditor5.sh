#!/usr/bin/env bash
#
# tests/verify-ckeditor5.sh — behavioural tests for
# skills/typo3-ckeditor5/scripts/verify-ckeditor5.sh.
#
# Each case builds a fixture extension directory, runs the verifier against
# it and checks the exit code and lines of the output. The verifier only
# reads the fixture, so the test runs offline. Requires bash, find and grep.
#
# Usage: bash tests/verify-ckeditor5.sh [path/to/verify-ckeditor5.sh]

set -uo pipefail

HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT="$(cd "$HERE/.." && pwd)"
SCRIPT="${1:-$ROOT/skills/typo3-ckeditor5/scripts/verify-ckeditor5.sh}"

WORK="$(mktemp -d)"
trap 'rm -rf "$WORK"' EXIT

fail=0
count=0
OUT=""
RC=0

# The verifier prints a title line and nine section headers, all starting
# with "===". A run that stops early prints fewer.
HEADERS=10

# run <dir> — runs the verifier, stores its output in OUT and its exit code
# in RC.
run() {
    OUT=$(bash "$SCRIPT" "$@" 2>&1)
    RC=$?
}

report() { # report <description> <ok 0|1> [detail]
    count=$((count + 1))
    if [ "$2" -eq 0 ]; then
        echo "  ok   $1"
    else
        echo "  FAIL $1${3:+ ($3)}"
        printf '%s\n' "$OUT" | sed 's/^/         /'
        fail=1
    fi
}

expect_exit() { # expect_exit <description> <expected exit>
    local ok=0
    [ "$RC" -eq "$2" ] || ok=1
    report "$1" "$ok" "expected exit $2, got $RC"
}

expect_line() { # expect_line <description> <fixed string>
    local ok=0
    grep -qF -- "$2" <<<"$OUT" || ok=1
    report "$1" "$ok" "missing line: $2"
}

expect_no_line() { # expect_no_line <description> <fixed string>
    local ok=0
    if grep -qF -- "$2" <<<"$OUT"; then ok=1; fi
    report "$1" "$ok" "unexpected line: $2"
}

expect_headers() { # expect_headers <description>
    local n ok=0
    n=$(grep -c '^===' <<<"$OUT")
    [ "$n" -eq "$HEADERS" ] || ok=1
    report "$1" "$ok" "expected $HEADERS '===' lines, got $n"
}

# fixture <name> — creates and prints an empty fixture directory.
fixture() {
    mkdir -p "$WORK/$1"
    printf '%s\n' "$WORK/$1"
}

echo "file names with spaces"

dir=$(fixture spaces)
mkdir -p "$dir/Configuration/RTE" "$dir/Resources/Public/JavaScript/Ckeditor"
printf 'editor:\n  config:\n    toolbar: [bold]\nprocessing:\n  allowTags: [p]\n' >"$dir/Configuration/RTE/Default.yaml"
printf 'import { Plugin } from "@ckeditor/ckeditor5-core";\nexport default class X extends Plugin {}\n' >"$dir/Resources/Public/JavaScript/Ckeditor/my plugin.js"
printf '<?php\n' >"$dir/ext_localconf.php"
printf '# Docs\n' >"$dir/README.md"
run "$dir"
expect_exit "a clean extension exits 0" 0
expect_line "a JavaScript file name with a space is checked as one file" "Checking: my plugin.js"
expect_no_line "the name is not split into words" "Checking: plugin.js"
expect_line "its import is found" "Uses ES module imports"
expect_line "its Plugin class is found" "Uses CKEditor 5 Plugin class"
expect_line "no warning is raised" "Warnings: 0"

echo
if [ "$fail" -ne 0 ]; then
    echo "verify-ckeditor5: FAILED ($count checks)"
    exit 1
fi
echo "verify-ckeditor5: all $count checks passed"
