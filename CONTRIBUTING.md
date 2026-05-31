# Contributing

## Prerequisites

- Dart SDK 3.x (`dart --version`)
- For `example/`: Flutter SDK (`flutter pub get` in `example/`)
- For OAP smoke locally: Docker (optional)

## CI (same as GitHub Actions)

**Package only** (no Flutter, no OAP):

```bash
dart pub get --no-example
dart analyze lib bin test
dart test
```

**Closest to GitHub** (Linux `dart:stable` in Docker + OAP `10.1.0`):

```powershell
# Windows
.\scripts\run-ci-github-like.ps1
```

```bash
./scripts/run-ci-github-like.sh
```

CI OAP image is pinned in [`.github/workflows/ci.yml`](.github/workflows/ci.yml) (`apache/skywalking-oap-server:10.1.0`). Do not use `10.2.x` with `SW_STORAGE=h2` — H2 was removed in 10.2.

## Pull requests

1. Branch from `main`
2. Run CI commands above
3. Update [CHANGELOG.md](CHANGELOG.md) under `## Unreleased` or the target version
4. Keep `example/` out of `dart analyze` scope unless you change example code (CI uses `lib bin test` only)

## Releases (maintainers)

1. Bump `pubspec.yaml` `version`
2. Add [doc/releases/vX.Y.Z.md](doc/releases/)
3. Tag: `git tag -a vX.Y.Z -m "vX.Y.Z"`
4. `gh release create vX.Y.Z --notes-file doc/releases/vX.Y.Z.md` (or GitHub UI)

See [doc/releases/README.md](doc/releases/README.md).
