<!-- SPDX-License-Identifier: CC-BY-SA-4.0 -->
<!-- SPDX-FileCopyrightText: Netresearch DTT GmbH -->

# Security assurance case — typo3-ckeditor5-skill

This document states what a user can expect from this repository in terms of security, and argues why that expectation holds. Every claim names the file that implements it. Reporting a vulnerability: see the [security policy](https://github.com/netresearch/.github/blob/main/SECURITY.md). Components: [ARCHITECTURE.md](ARCHITECTURE.md).

## What the repository ships

| Part | Files | Runs where |
| --- | --- | --- |
| Skill instructions for an AI agent | `skills/typo3-ckeditor5/SKILL.md`, `skills/typo3-ckeditor5/references/*.md` | Read by the agent as instructions; not executed. The agent may write the code and configuration they describe into the user's TYPO3 extension. |
| Verification script | `skills/typo3-ckeditor5/scripts/verify-ckeditor5.sh` | On the user's machine, against a directory the user names. |
| Checkpoints | `skills/typo3-ckeditor5/checkpoints.yaml` | Only when an assessment tool runs its `command` patterns in a user's project. |
| Evaluation runner | `evals/run-ab-test.sh`, `evals/evals.json` | On a maintainer's machine, by hand; it calls the `claude` CLI. |
| Repository checks | `Build/Scripts/check-plugin-version.sh`, `Build/hooks/pre-push`, `scripts/verify-harness.sh`, `tests/*.sh` | In this repository's CI and on contributors' machines. |

The repository ships no server component, no container image and no PHP or JavaScript code that runs in a TYPO3 installation. The code examples in the references are examples; they run only after someone copies them into an extension. The repository stores nothing and handles no accounts or credentials.

## Security requirements

1. `verify-ckeditor5.sh` and the checkpoints only read: they change no file in the checked extension and make no network request.
2. The skill content shows RTE presets with a `processing:` section that lists the allowed tags, tells plugin authors to replace jQuery with native DOM APIs, and warns against building DOM from interpolated HTML.
3. Nothing committed to this repository contains a secret.
4. A release carries the version that `.claude-plugin/plugin.json` states, comes from a signed tag, and its archives can be verified against the build that produced them.

## Actors and trust boundaries

- **Skill user and agent.** The agent reads `SKILL.md` and the references and acts in the user's project with the user's permissions. What it writes or runs is decided by the agent and the user, not by this repository. `SKILL.md` declares no `allowed-tools`.
- **Checked extension.** `verify-ckeditor5.sh` takes one argument, the extension directory (default `.`), and reads files below it with `find` and `grep`. File contents are only searched, never executed or sourced; every path is quoted.
- **Assessment tools.** `checkpoints.yaml` patterns run in the assessed project's working directory with the privileges of whoever starts the tool. The file header documents the constraints of the runner's allowlist that every pattern obeys (no `-exec`, no `||`, `&&`, `;` or command substitution).
- **Contributors.** Changes reach `main` through pull requests, checked by the workflows in `.github/workflows/`. `.envrc` (used by direnv) sets `core.hooksPath` to `Build/hooks`, so a contributor who allows it runs the repository's `pre-push` hook.
- **CI.** Workflows run on GitHub-hosted runners with `permissions: {}` at the top level and grant each job only the scopes its called reusable workflow needs (`.github/workflows/*.yml`). The two `pull_request_target` workflows (`auto-merge-deps.yml`, `labeler.yml`) only call reusables that merge or label and do not check out pull request code; `auto-merge-deps.yml` passes two named secrets instead of `secrets: inherit`.

## Threats and countermeasures

| Threat | Countermeasure | Evidence |
| --- | --- | --- |
| A path argument or a file name in the checked extension is interpreted by the shell (CWE-78) | The directory argument and every path derived from it are quoted; JavaScript file names are read NUL-separated from `find -print0`, so spaces or glob characters in a name stay part of one name | `verify-ckeditor5.sh`; `tests/verify-ckeditor5.sh` ("file names with spaces") |
| The verifier changes the checked extension | The script only runs `find`, `grep`, `wc` and `basename` against it and writes nothing but its own output | `verify-ckeditor5.sh` |
| A check stops half way and reports a partial result as the outcome | Counters use `X=$((X + 1))`, which cannot end a `set -e` script; the tests check that all ten section lines and the summary are printed | `verify-ckeditor5.sh`; `tests/verify-ckeditor5.sh` |
| An RTE preset lets `script`, `iframe` or `object` through (CWE-79) | The verifier warns when a preset mentions one of these words without a `denyTags:` key, and warns on a preset without a `processing:` section; the references show presets whose `processing` lists `allowTags` | `verify-ckeditor5.sh` ("Processing Configuration Check"); `references/typo3-integration.md`, `references/plugin-development.md`, `references/migration-guide.md` |
| A migrated plugin builds DOM from interpolated values (CWE-79) | The migration guide shows `createElement` and `textContent` instead of `innerHTML`/`insertAdjacentHTML` with template strings | `references/migration-guide.md` ("XSS Prevention") |
| Legacy CKEditor 4 or jQuery code stays in a migrated extension | The verifier reports `CKEDITOR.` globals, CKEditor 4 YAML keys and `RTE.default.proc` TSconfig; checkpoints CK-08, CK-09, CK-12 and CK-13 flag jQuery, `$.Deferred` and jQuery AJAX in CKEditor plugin files | `verify-ckeditor5.sh`; `checkpoints.yaml` |
| A checkpoint modifies the assessed project | Every checkpoint is a file-existence or content check, or a `find … -print` pipeline into `head`, `xargs grep` or `grep -q` that only reads and exits with a status | `checkpoints.yaml` |
| A release is tagged with a version that disagrees with `plugin.json` | The pre-push hook runs `check-plugin-version.sh`, which fails when a semver tag at `HEAD` differs from `.claude-plugin/plugin.json` | `Build/hooks/pre-push`, `Build/Scripts/check-plugin-version.sh`; `tests/check-plugin-version.sh` |
| A released archive is tampered with, or released from an unsigned tag | The release workflow refuses lightweight and unsigned tags, and publishes a Cosign-signed `SHA256SUMS.txt` and build-provenance attestations for the archives | `.github/workflows/release.yml` (calls the skill-repo-skill release reusable) |
| A secret is committed | Betterleaks scans every push to `main` and every pull request to `main` | `.github/workflows/security.yml` |
| A vulnerable or malicious dependency is added | Dependency review fails on vulnerabilities of severity high or above in a pull request; Composer Audit checks the Composer dependencies against known advisories; Renovate proposes updates, including pre-commit hook revisions | `.github/workflows/security.yml`, `renovate.json` |
| Insecure code or workflow patterns | Opengrep fails on findings of severity WARNING or above; zizmor analyses the workflows; ShellCheck runs on every `*.sh` file in Skill Validation | `.github/workflows/security.yml`, `.github/workflows/lint.yml` |

Which of these checks must pass before a pull request can merge is set in the branch protection of `main`, not in this repository.

## Secure design principles applied

- **Least privilege:** the verifier and the checkpoints only read. Workflows start from `permissions: {}` and grant each job the scopes it needs.
- **Economy of mechanism:** the verifier needs bash, `find`, `grep`, `wc` and `basename`, and nothing else; it has no options besides the directory.
- **Complete mediation of input:** file names and contents from the checked extension are passed to `grep` as quoted arguments and never evaluated.

## What a user cannot expect

- The skill gives guidance; it does not enforce it. The agent writes code with the user's permissions; review what it proposes.
- `verify-ckeditor5.sh` is a structure check by text search, not an audit of the RTE's HTML sanitisation. The `script`/`iframe`/`object` test is a substring match: a preset that mentions `description` or `objectives` triggers it, and a preset that allows those tags passes as long as it contains any `denyTags:` key. Its only error, which makes it exit 1, is a missing `ext_localconf.php`; every other finding, including a possibly dangerous preset, is a warning and leaves the exit code at 0.
- The checkpoints run shell commands in the assessed project when an assessment tool executes them; run them only in projects you trust. The LLM review checkpoints (CK-20, CK-21) are judgements by a model and can miss issues.
- `evals/run-ab-test.sh` sends the prompts in `evals/evals.json` to a paid model API through the `claude` CLI, capped at USD 0.50 per call, and trusts its argument, which it interpolates into a Python snippet as the eval index, and the contents of `evals.json`. It is a maintainer tool, not part of the skill.
- The code examples in the references are starting points, not reviewed library code.
- Security fixes follow the supported-versions rules of the organisation's security policy; older releases may not receive them.
