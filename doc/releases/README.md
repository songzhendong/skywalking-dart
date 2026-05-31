# GitHub Releases

Release notes for tags live here. When publishing on GitHub:

```bash
gh release create v0.2.2 --title "v0.2.2" --notes-file doc/releases/v0.2.2.md
```

Or paste the markdown from `doc/releases/v<version>.md` in the GitHub **Releases → Draft** UI.

| Tag | Notes file |
|-----|------------|
| v0.2.2 | [v0.2.2.md](v0.2.2.md) |

## Local CI (mirror GitHub Actions)

```powershell
.\scripts\run-ci-local.ps1          # analyze + test + Docker OAP smoke
.\scripts\run-ci-local.ps1 -SkipSmoke
```

CI uses `dart pub get --no-example` because `example/` is a Flutter app (GitHub `setup-dart` has no Flutter SDK). Locally, plain `dart pub get` also resolves `example/` when Flutter is on `PATH`.
