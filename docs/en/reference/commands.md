---
title: Commands and checks
description: "The make targets, and what each of the three post-build checks guards."
source_sha256: 12c5c16b3e7e97b5f7321fc98ebbbe5a9b89981fac3383034c68ac4375ef8365
translated: 2026-01-01
icon: lucide/terminal
tags: ["build"]
# ⚠️ 由 tools/docsgen.py 从 content/reference/commands.en.md 生成，请勿手改；要改请改 content/ 下的源文件。
---

# Commands and checks

<p class="kicker">COMMANDS & CHECKS</p>

```bash
make gen       # content/ → docs/, and regenerate the navigation
make check     # translation coverage check only
make links     # built-output link check only (build first)
make build     # gen → build → link check → archive check → i18n check
make serve     # local preview (from a config that only swaps site_url)
make watch     # regenerate docs/ whenever content/ changes
make offline   # package a whole site you can open straight from disk
make sync      # create skeletons for missing translations, then regenerate
make clean     # remove site/ and the offline output
```

## What each check guards

| Script | Guards | Why source validation cannot see it |
| --- | --- | --- |
| `tools/linkcheck.py` | internal references, directory trailing slashes, redirect stub targets, the address-fixing script | these links only take their final shape after the build |
| `tools/i18n_check.py` | missing, stale, or structurally mismatched translations, missing output | it needs to look at content and output at the same time |
| `tools/chunker.py --check` | split parts against the manifest, page buttons against the manifest | the parts are finished goods in the repo; only the build system knows what references them |
| `tools/offline_check.py` | every reference and anchor inside the offline package | the offline build has a different address shape, which the online checks cannot measure |

The tag index is not in that table: `tools/docsgen.py` writes one per (version, language)
instead of filtering the output after the fact, which is also why the preview matches
production.

`i18n_check.py` also asserts that certain things really are present in the built output
(SMOKE). When a template condition is permanently false, output **silently** loses a
block — no error, no warning.
