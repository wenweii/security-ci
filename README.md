# GitHub Free public demo: centralized Security CI

This repository contains a reusable GitHub Actions workflow and a composite action
adapted from the original Enterprise/Organization Ruleset deliverable.

**Important:** GitHub Free does NOT support Organization Required Workflow Rulesets.
Each consumer repository must include its own short calling workflow; public
repository branch protection is configured independently per repository.

First replace `wenweii` in
`.github/workflows/laravel-security-required.yml`.

Scan policy:
- Composer Audit: blocking for vulnerable locked dependencies
- Gitleaks: blocking for current tree and PR commit history
- Semgrep ERROR: blocking
- Semgrep WARNING: advisory finding, scanner runtime failures block

Original action/config/scripts retained as supplied; not yet validated in a live GitHub run.
**Do not treat this zip as already accepted**. Follow the manual and save 7 test records.
