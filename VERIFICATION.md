# ImageMagick snippet verification

This repository includes `scripts/verify-snippets.sh`, which exercises command patterns that appear in the docs (resize geometry, `mogrify -path`, composite watermark pipeline, `jpeg:extent`, and related flows).

## Run locally

From the directory that contains `docs.json` (repository root for this project):

```bash
bash scripts/verify-snippets.sh
```

- If **`magick`** (ImageMagick 7) is on your `PATH`, the script uses it.
- Otherwise it uses **Docker** (`docker info` must succeed). On WSL, enable Docker Desktop’s WSL integration or install ImageMagick inside the distro.

## CI

GitHub Actions workflow `.github/workflows/verify-docs-snippets.yml` pulls `dpokidov/imagemagick:latest` and runs the same script on every push/PR that touches MDX, `docs.json`, or `scripts/`.

## Manual matrix (Lead sign-off)

Use this table when you need rubric-level “tested on each platform” evidence beyond the automated script.

| Snippet / page | Linux | macOS | Windows (PowerShell) | Notes |
|----------------|-------|-------|----------------------|-------|
| Quickstart install tabs | ☐ | ☐ | ☐ | AppImage URL is release-specific |
| `magick mogrify` + `-path` + `-format` | ☐ | ☐ | ☐ | Confirm output filenames under `web/` |
| Tutorial composite pipeline | ☐ | ☐ | ☐ | Requires `bash` or one-line equivalent |
| `jpeg:extent` ceiling | ☐ | ☐ | ☐ | Confirm byte size with `wc -c` / `(Get-Item).Length` |

Record ImageMagick version (`magick --version`) for each column.
