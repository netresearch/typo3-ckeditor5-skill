#!/usr/bin/env bash
# SPDX-License-Identifier: MIT
# SPDX-FileCopyrightText: Netresearch DTT GmbH
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

echo "empty directory"

dir=$(fixture empty)
run "$dir"
expect_exit "a directory without ext_localconf.php exits 1" 1
expect_headers "every section runs after the first finding"
expect_line "missing RTE directory is a warning" "No Configuration/RTE directory found"
expect_line "missing ext_localconf.php is an error" "❌ No ext_localconf.php found"
expect_line "missing documentation is a warning" "No README.md or Documentation/Index.rst found"
expect_line "the error is counted" "Errors: 1"
expect_line "the other two findings are warnings" "Warnings: 2"
expect_line "an error fails the run" "Verification FAILED"
expect_no_line "an error does not pass" "Verification PASSED"

echo "CKEditor 4 remnants"

dir=$(fixture cke4)
mkdir -p "$dir/Configuration/RTE" "$dir/Configuration/TsConfig" "$dir/Resources/Public/JavaScript/Ckeditor"
printf 'editor:\n  config:\n    toolbar: [bold]\n    extraPlugins: [old]\nprocessing:\n  allowTags: [p]\n' >"$dir/Configuration/RTE/Default.yaml"
printf 'RTE.default.proc.allowTags = p\n' >"$dir/Configuration/TsConfig/Page.tsconfig"
printf 'import { Plugin } from "@ckeditor/ckeditor5-core";\nCKEDITOR.plugins.add("x");\nexport default class X extends Plugin {}\n' >"$dir/Resources/Public/JavaScript/Ckeditor/x.js"
printf '<?php\n' >"$dir/ext_localconf.php"
printf '# Docs\n' >"$dir/README.md"
run "$dir"
expect_exit "several CKEditor 4 remnants still exit 0" 0
expect_headers "every section runs"
expect_line "CKEDITOR. global in JavaScript is reported" "Found CKEditor 4 global namespace usage in 1 file(s)"
expect_line "extraPlugins in RTE YAML is reported" "Found CKEditor 4 configuration patterns in YAML"
expect_line "RTE.default.proc in TsConfig is reported" "Found CKEditor 4 PageTSConfig patterns"
expect_no_line "no all-clear when remnants exist" "No CKEditor 4 patterns detected"
expect_line "each remnant counts as one warning" "Warnings: 3"
expect_line "three warnings still pass" "Verification PASSED"

echo "four warnings"

dir=$(fixture four)
cp -R "$WORK/cke4/." "$dir/"
printf 'import { Plugin } from "@ckeditor/ckeditor5-core";\n' >"$dir/Resources/Public/JavaScript/Ckeditor/y.js"
run "$dir"
expect_exit "four warnings still exit 0" 0
expect_line "a JavaScript file without exports adds the fourth warning" "Warnings: 4"
expect_line "four warnings are called significant" "Verification completed with significant warnings"
expect_no_line "four warnings do not pass" "Verification PASSED"

echo "complete extension"

dir=$(fixture complete)
mkdir -p "$dir/Configuration/RTE" "$dir/Configuration/TCA" "$dir/Documentation" \
    "$dir/Resources/Public/JavaScript/CKEditor" "$dir/Resources/Public/Css/CKEditor"
cat >"$dir/Configuration/RTE/Default.yaml" <<'YAML'
imports:
  - { resource: 'EXT:rte_ckeditor/Configuration/RTE/Processing.yaml' }
editor:
  config:
    importModules:
      - '@vendor/ext/highlight.js'
    toolbar:
      items: [bold, highlight]
processing:
  allowTags: [p, mark]
  allowAttributes: [class]
  denyTags: [script, iframe, object]
YAML
cat >"$dir/Resources/Public/JavaScript/CKEditor/highlight.js" <<'JS'
import { Plugin, Command } from '@ckeditor/ckeditor5-core';
export class HighlightCommand extends Command {}
export default class Highlight extends Plugin {}
JS
printf '.ck mark {}\n' >"$dir/Resources/Public/Css/CKEditor/a.css"
printf '.ck p {}\n' >"$dir/Resources/Public/Css/CKEditor/b.css"
cat >"$dir/ext_localconf.php" <<'PHP'
<?php
$GLOBALS['TYPO3_CONF_VARS']['RTE']['Presets']['default'] = 'EXT:ext/Configuration/RTE/Default.yaml';
$GLOBALS['TYPO3_CONF_VARS']['EXTCONF']['CKEditor5']['plugins'][] = 'highlight';
PHP
printf "<?php\nreturn ['columns' => ['x' => ['config' => ['enableRichtext' => true, 'richtextConfiguration' => 'default']]]];\n" \
    >"$dir/Configuration/TCA/tt_content.php"
printf 'Docs\n' >"$dir/Documentation/Index.rst"
run "$dir"
expect_exit "a complete extension exits 0" 0
expect_headers "every section runs"
expect_line "the RTE preset is counted" "Found 1 RTE YAML configuration file(s)"
expect_line "the editor section is found" "Has 'editor' configuration"
expect_line "the processing section is found" "Has 'processing' configuration"
expect_line "the toolbar is found" "Has toolbar configuration"
expect_line "importModules is found" "Has module imports configured"
expect_line "the CKEditor spelling of the JavaScript directory is found" "Resources/Public/JavaScript/CKEditor"
expect_line "the Plugin class is found" "Uses CKEditor 5 Plugin class"
expect_line "the Command class is found" "Uses CKEditor 5 Command class"
expect_line "exports are found" "Has exports"
expect_line "both stylesheets are counted" "Found 2 CSS file(s)"
expect_line "the preset registration is found" "RTE preset registration found"
expect_line "the plugin registration is found" "CKEditor 5 plugin registration found"
expect_line "the RTE field in TCA is counted" "Found 1 TCA file(s) with RTE configuration"
expect_line "the preset assignment in TCA is found" "Custom RTE preset assignments found"
expect_line "no CKEditor 4 remnant is reported" "No CKEditor 4 patterns detected"
expect_line "allowTags is found" "Default.yaml: Has allowTags configuration"
expect_line "allowAttributes is found" "Default.yaml: Has allowAttributes configuration"
expect_line "denyTags next to script/iframe/object is accepted" "Default.yaml: Has denyTags configuration"
expect_line "Documentation/Index.rst counts as documentation" "Documentation found"
expect_line "nothing is a warning" "Warnings: 0"
expect_line "the run passes" "Verification PASSED"

echo "empty configuration directories"

dir=$(fixture hollow)
mkdir -p "$dir/Configuration/RTE" "$dir/Configuration/TCA" "$dir/Resources/Public/JavaScript/ckeditor"
printf '<?php\n' >"$dir/ext_localconf.php"
printf "<?php\nreturn [];\n" >"$dir/Configuration/TCA/tt_content.php"
printf '# Docs\n' >"$dir/README.md"
run "$dir"
expect_exit "empty configuration directories exit 0" 0
expect_headers "every section runs"
expect_line "an RTE directory without YAML is a warning" "No YAML configuration files found in Configuration/RTE/"
expect_line "the lower-case JavaScript directory is found" "Resources/Public/JavaScript/ckeditor"
expect_line "a JavaScript directory without files is a warning" "No JavaScript files found"
expect_line "no CSS directory is only information" "No CKEditor CSS directory found (optional)"
expect_line "a missing preset registration is only information" "No RTE preset registration in ext_localconf.php"
expect_line "a missing plugin registration is only information" "No CKEditor 5 plugin registration in ext_localconf.php"
expect_line "TCA without enableRichtext is only information" "No TCA files with RTE configuration found"
expect_line "two warnings are counted" "Warnings: 2"
expect_line "two warnings pass" "Verification PASSED"

echo "weak preset and plugin"

dir=$(fixture weak)
mkdir -p "$dir/Configuration/RTE" "$dir/Resources/Public/JavaScript/Ckeditor"
printf 'custom:\n  embed: iframe\n' >"$dir/Configuration/RTE/Weak.yaml"
printf 'console.log("plugin");\n' >"$dir/Resources/Public/JavaScript/Ckeditor/legacy.js"
printf '<?php\n' >"$dir/ext_localconf.php"
run "$dir"
expect_exit "significant warnings still exit 0" 0
expect_headers "every section runs"
expect_line "a preset without editor is a warning" "Missing 'editor' section"
expect_line "a preset without processing is a warning" "Missing 'processing' section (HTML sanitization)"
expect_line "a preset without toolbar is a warning" "Missing toolbar configuration"
expect_line "a JavaScript file without imports is a warning" "No ES module imports found"
expect_line "a JavaScript file without exports is a warning" "No exports found - may not be loadable"
expect_line "iframe without denyTags is a warning" "Weak.yaml: May allow dangerous tags without denyTags"
expect_line "no TCA directory is only information" "No TCA directory found"
expect_line "no error is counted" "Errors: 0"
expect_line "seven warnings are counted" "Warnings: 7"
expect_line "more than three warnings are called significant" "Verification completed with significant warnings"
expect_no_line "more than three warnings do not pass" "Verification PASSED"

echo
if [ "$fail" -ne 0 ]; then
    echo "verify-ckeditor5: FAILED ($count checks)"
    exit 1
fi
echo "verify-ckeditor5: all $count checks passed"
