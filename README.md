# Chesswave Link Engines

Official chess engine release builds for Chesswave Link.

This repository packages open-source UCI chess engines for the platforms supported by Chesswave Link. Release assets are published as one `.tar.gz` archive per engine and platform.

## Releases

GitHub Actions publishes release assets from `.github/workflows/release-engines.yml`.

Asset names do not include the release version because the GitHub release tag already provides it:

```text
<engine>-<platform>.tar.gz
```

Examples:

```text
stockfish-18-linux-x86_64.tar.gz
caissa-macos-silicon.tar.gz
patricia-windows-x86_64.tar.gz
```

Each archive contains the engine files at the archive root, without an extra wrapping directory or `./` path prefix.

## Platforms

- `linux-x86_64`
- `macos-silicon`
- `windows-x86_64`

Not every engine is available on every platform. See each engine's `engine.yaml` for the exact platform matrix, binary name, and required companion files.

## Build Types

Some engines are built from source in this repository with Docker-backed Makefile targets:

- `caissa`
- `clover`
- `ethereal`
- `patricia`
- `viridithas`

Some engines are packaged from upstream release assets:

- `akimbo`
- `arasan`
- `berserk`
- `avalanche`
- `blackcore`
- `carp`
- `cheers`
- `chess-cpp`
- `clarity`
- `cuckoochess`
- `drofa`
- `equisetum`
- `frozenight`
- `igel`
- `koivisto`
- `lc0-cpu`
- `lc0-gpu`
- `laser`
- `leorik`
- `maia-1100-cpu`
- `maia-1100-gpu`
- `maia-1500-cpu`
- `maia-1500-gpu`
- `maia-1900-cpu`
- `maia-1900-gpu`
- `marvin`
- `minic`
- `monty`
- `motor`
- `nalwald`
- `obsidian`
- `peacekeeper`
- `pedantic`
- `polaris`
- `princhess`
- `renegade`
- `rice`
- `rubichess`
- `seer`
- `serendipity`
- `smallbrain`
- `sirius`
- `starzix`
- `stormphrax`
- `stockfish-16`
- `stockfish-17`
- `stockfish-18`
- `texel`
- `wahoo`
- `weiss`
- `willow`

Release-imported Linux engines use Dockerfiles where available so the CI path is consistent with source-built Linux engines.

## Local Builds

Build one engine:

```bash
./scripts/build_one.sh caissa linux-x86_64 v1.0.0
```

Build every engine directory for a platform:

```bash
./scripts/build_all.sh v1.0.0 linux-x86_64
```

Build outputs are written to:

```text
out/<version>/<platform>/<engine>/
```

## Repository Layout

- `.github/workflows/release-engines.yml` - release workflow
- `engines/<engine>/engine.yaml` - engine metadata consumed by Chesswave Link
- `engines/<engine>/Makefile` - per-engine build or import entrypoint
- `scripts/build_one.sh` - build/import one engine for one platform
- `scripts/build_all.sh` - run `build_one.sh` for all engine directories
- `scripts/import_release_asset.sh` - import an upstream binary release asset

## Licensing

Each engine remains licensed by its upstream project. Engine metadata includes homepage, source repository, license, and release provenance where available.
