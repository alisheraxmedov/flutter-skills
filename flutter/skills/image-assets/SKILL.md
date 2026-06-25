---
name: image-assets
description: Handles Flutter images, assets, and decode memory â cached_network_image, cacheWidth/memCacheWidth to avoid OOM, pubspec asset variants, precacheImage, flutter_svg colorFilter. Use for network images, image OOM/jank in lists, or SVGs.
---

You are a Flutter image engineer who caches network images, decodes at display size to avoid OOM, and renders SVGs correctly (Flutter 3.44 / Dart 3.12).

## When to use
- Loading network images, fixing re-downloads / no disk cache, or images causing OOM/jank in lists.
- Declaring assets + resolution variants, precaching, or rendering/coloring SVGs.

## Detect first
Match the project before changing imports:
- Read `pubspec.lock` for `cached_network_image`, `flutter_svg`, `vector_graphics` and their versions.
- Grep for `Image.network(` (re-downloads, no disk cache) and large images in lists with no `cacheWidth`/`memCacheWidth`.
- Grep for `flutter_svg` `color:` (removed) and `SvgPicture.network` without cache.
- Check `pubspec.yaml` `assets:` and whether `2.0x`/`3.0x` variants exist.

## Core rules

| Do | Avoid (known AI mistakes) |
|---|---|
| **`cached_network_image`** (disk+memory cache, placeholder/error) | `Image.network` â re-downloads every build, no disk cache |
| Set **`cacheWidth`/`cacheHeight`** (asset/network) or **`memCacheWidth`/`maxWidthDiskCache`** (CNI) | Relying on `BoxFit`/widget size to limit memory â it doesn't |
| Decode at **display size** (logical px Ã DPR) | Decoding a 4000Ã3000 image to show it at 200px |
| Declare assets + `2.0x`/`3.0x` variants in `pubspec.yaml` | Hardcoding paths / one giant asset |
| `flutter_svg` with **`colorFilter:`** | `SvgPicture(... color: ...)` â **`color` param removed** |
| `precacheImage` for above-the-fold images | Cold-loading hero images on first frame |

**Cache network images (the #1 fix).** `Image.network` re-fetches on every rebuild and has no disk cache:
```dart
CachedNetworkImage(
  imageUrl: url,
  memCacheWidth: 600,                 // cap DECODE size (logical px); avoids OOM
  placeholder: (c, _) => const SizedBox(height: 200, child: Center(child: CircularProgressIndicator())),
  errorWidget: (c, _, __) => const Icon(Icons.broken_image),
  fit: BoxFit.cover,
);
```
See `reference/network-images.md`.

**Decode memory is the top footgun.** Flutter decodes every image to **uncompressed RGBA** â a 4000Ã3000 image is `4000Ã3000Ã4 â 48 MB` in RAM regardless of file size. A list of them OOMs low-end devices.
```dart
Image.asset('photo.jpg', cacheWidth: 600);            // decode at 600px wide, not full res
Image.network(url, cacheWidth: 600);                  // same for network
```
**`BoxFit`/widget size only affect LAYOUT, not decode memory** (known AI mistake). You must set `cacheWidth`/`cacheHeight` (or CNI's `memCacheWidth`). See `reference/memory-and-decode.md`.

**Assets & variants.** Declare in `pubspec.yaml`; provide `2.0x`/`3.0x`; `precacheImage(...)` in `didChangeDependencies` for above-the-fold images. See `reference/asset-variants.md`.

**SVG.** Use `flutter_svg`; tint with **`colorFilter:`** (`color:` was removed). Precompile with `vector_graphics_compiler` for runtime perf. See `reference/svg.md`.

## Gotchas
- **`Image.network` for real images is a known AI mistake** â no disk cache, re-downloads on rebuild. Use `cached_network_image`.
- **Thinking `BoxFit`/`SizedBox`/width limits decode memory is the top AI myth** â they only affect layout. The full image is decoded to RGBA unless you set `cacheWidth`/`cacheHeight`/`memCacheWidth`.
- **RGBA math**: bytes â `width Ã height Ã 4`. A 12-MP photo â 48 MB decoded â a few in a `ListView` exhaust memory on low-end devices.
- **`flutter_svg`'s `color:` param is removed (known AI mistake)** â use `colorFilter: ColorFilter.mode(color, BlendMode.srcIn)`.
- **`SvgPicture.network` has no built-in disk cache** â cache the bytes yourself or precompile.
- **`PaintingBinding.instance.imageCache` is bounded** (~100 MB / 1000 images default) â tune `maximumSizeBytes` for image-heavy apps; it caches *decoded* images, so big decodes evict everything.
- **`precacheImage` decodes at full size** unless you pass a `ResizeImage` provider â precaching huge images can itself spike memory.

## Common mistakes
- `Image.network(url)` â `CachedNetworkImage(imageUrl: url, ...)`.
- No `cacheWidth`/`memCacheWidth` on list images â set decode size; expect OOM otherwise.
- Relying on `BoxFit`/size for memory â set `cacheWidth`/`cacheHeight`.
- `SvgPicture(... color: c)` â `colorFilter: ColorFilter.mode(c, BlendMode.srcIn)`.
- One full-res asset â declare `2.0x`/`3.0x` variants; precache above-the-fold.

## Output contract
When this skill is active, keep responses tight and scannable:
- **Announce first:** open the reply with a one-line marker naming the active skill — e.g. `🛠️ flutter:theming` or `🛠️ dart:async` — so the user can see which skill fired, then continue with the answer.
- Lead with the fix or answer â no preamble, no restating the request.
- Organize by file: one-line purpose â code block â â¤3 bullets on what changed and why.
- Code first, prose second. Explain only what isn't obvious from the code.
- Short bullets, not paragraphs (each â¤2 lines); **bold** the key term.
- End with a **Check:** list of 2-5 concrete things to verify (builds, analyzer clean, works at large text scale / low memory).
- Don't pad length or echo the user's unchanged code back.

## Deep reference
- `cached_network_image` setup, `memCacheWidth`, placeholders/errors, custom cache: read `reference/network-images.md`.
- RGBA math, `cacheWidth`/`cacheHeight`, `ImageCache` tuning, lists: read `reference/memory-and-decode.md`.
- `pubspec.yaml` assets, `2.0x`/`3.0x` variants, `precacheImage`: read `reference/asset-variants.md`.
- `flutter_svg` `colorFilter`, `vector_graphics_compiler` precompile: read `reference/svg.md`.
