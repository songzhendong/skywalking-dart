# GitHub Releases

Release notes for tags live here. When publishing on GitHub:

```bash
gh release create v0.2.2 --title "v0.2.2" --notes-file doc/releases/v0.2.2.md
```

Or paste the markdown from `doc/releases/v<version>.md` in the GitHub **Releases → Draft** UI.

| Tag | Notes file |
|-----|------------|
| v0.2.3 | [v0.2.3.md](v0.2.3.md) |
| v0.2.2 | [v0.2.2.md](v0.2.2.md) |

## Local CI (mirror GitHub Actions)

**Closest to GitHub** (Linux `dart:stable` in Docker, no Flutter — same as `ubuntu-latest` + `setup-dart`):

```powershell
# Windows
.\scripts\run-ci-github-like.ps1
.\scripts\run-ci-github-like.ps1 -SkipSmoke
```

```bash
# Linux / macOS / Git Bash
chmod +x scripts/run-ci-github-like.sh
./scripts/run-ci-github-like.sh
./scripts/run-ci-github-like.sh --skip-smoke
```

**Faster on host** (uses your installed Dart; `pub get --no-example` still skips `example/`):

```powershell
.\scripts\run-ci-local.ps1
.\scripts\run-ci-local.ps1 -SkipSmoke
```

CI uses `dart pub get --no-example` because `example/` is a Flutter app (GitHub `setup-dart` has no Flutter SDK). A plain `dart pub get` without `--no-example` also touches `example/` when Flutter is on `PATH`.
