# Archived scripts (historical only)

**Do not use for nativeFull releases or CI.** Kept for repository history.

| File | Note |
|------|------|
| `commit-msg-*.txt` | Old commit message templates |
| `rewrite-*.bat` / `rollback-*.bat` | One-time git history rewrites |
| `push-release.bat` | Legacy release (0.1.x) |
| `push_to_github.ps1` / `strip-cursor-coauthor.py` | Maintainer-only git helpers |

**Current workflow**

- CI: [`.github/workflows/ci.yml`](../../.github/workflows/ci.yml)
- Local CI: [`../run-ci-github-like.ps1`](../run-ci-github-like.ps1)
- Releases: [`../create-github-release.ps1`](../create-github-release.ps1) + [doc/releases/](../../doc/releases/)
