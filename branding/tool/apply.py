"""Stamp branding/ masters onto every Flutter platform folder that exists.

    python branding/tool/apply.py

Run after `generate.py`, and after `flutter create` (which restores the
template Flutter logo). Requires Pillow. Missing platforms are skipped.
"""

from __future__ import annotations

import json
import shutil
from pathlib import Path

ROOT = Path(__file__).resolve().parents[2]
BRAND = ROOT / "branding"
FRONTEND = ROOT / "frontend"

DENSITIES = (
    ("mdpi", 1),
    ("hdpi", 1.5),
    ("xhdpi", 2),
    ("xxhdpi", 3),
    ("xxxhdpi", 4),
)

LIGHT = "#FFFFFF"
DARK = "#0A1236"
PRIMARY = "#2662EB"


def _pil():
    try:
        from PIL import Image
    except ImportError as error:
        raise SystemExit(
            "Pillow is required to rasterise launcher icons. "
            "Install it, then re-run python branding/tool/apply.py"
        ) from error
    return Image


def _open(path: Path):
    return _pil().open(path).convert("RGBA")


def _resize(src: Path, size: int):
    Image = _pil()
    return _open(src).resize((size, size), Image.LANCZOS)


def _save(img, dest: Path) -> None:
    dest.parent.mkdir(parents=True, exist_ok=True)
    img.save(dest)


def _write(src: Path, dest: Path, size: int) -> None:
    img = _resize(src, size)
    extrema = img.getchannel("A").getextrema()
    if extrema == (255, 255):
        img = img.convert("RGB")
    _save(img, dest)


def _copy(src: Path, dest: Path) -> None:
    dest.parent.mkdir(parents=True, exist_ok=True)
    shutil.copy2(src, dest)


def _composite(background: Path, foreground: Path, size: int):
    bg = _resize(background, size)
    fg = _resize(foreground, size)
    bg.alpha_composite(fg)
    return bg


def _write_text(dest: Path, text: str) -> None:
    dest.parent.mkdir(parents=True, exist_ok=True)
    dest.write_text(text, encoding="utf-8")


def apply_android() -> None:
    res = FRONTEND / "android" / "app" / "src" / "main" / "res"
    if not res.is_dir():
        return

    icon = BRAND / "icon" / "app-icon-1024.png"
    fg = BRAND / "icon" / "adaptive-foreground-1024.png"
    bg = BRAND / "icon" / "adaptive-background-1024.png"
    mono = BRAND / "icon" / "adaptive-monochrome-1024.png"
    splash_light = BRAND / "splash" / "splash-light-1152.png"
    splash_dark = BRAND / "splash" / "splash-dark-1152.png"

    for name, scale in DENSITIES:
        _write(icon, res / f"mipmap-{name}" / "ic_launcher.png", round(48 * scale))
        _write(
            fg,
            res / f"drawable-{name}" / "ic_launcher_foreground.png",
            round(108 * scale),
        )
        _write(
            bg,
            res / f"drawable-{name}" / "ic_launcher_background.png",
            round(108 * scale),
        )
        _write(
            mono,
            res / f"drawable-{name}" / "ic_launcher_monochrome.png",
            round(108 * scale),
        )
        _write(
            splash_light,
            res / f"drawable-{name}" / "splash_mark.png",
            round(288 * scale),
        )
        _write(
            splash_dark,
            res / f"drawable-night-{name}" / "splash_mark.png",
            round(288 * scale),
        )

    _write_text(
        res / "mipmap-anydpi-v26" / "ic_launcher.xml",
        """<?xml version="1.0" encoding="utf-8"?>
<adaptive-icon xmlns:android="http://schemas.android.com/apk/res/android">
    <background android:drawable="@drawable/ic_launcher_background"/>
    <foreground android:drawable="@drawable/ic_launcher_foreground"/>
    <monochrome android:drawable="@drawable/ic_launcher_monochrome"/>
</adaptive-icon>
""",
    )
    _write_text(
        res / "values" / "colors.xml",
        f"""<?xml version="1.0" encoding="utf-8"?>
<resources>
    <color name="splash_background">{LIGHT}</color>
</resources>
""",
    )
    _write_text(
        res / "values-night" / "colors.xml",
        f"""<?xml version="1.0" encoding="utf-8"?>
<resources>
    <color name="splash_background">{DARK}</color>
</resources>
""",
    )
    splash_xml = """<?xml version="1.0" encoding="utf-8"?>
<layer-list xmlns:android="http://schemas.android.com/apk/res/android">
    <item android:drawable="@color/splash_background" />
    <item>
        <bitmap
            android:gravity="center"
            android:src="@drawable/splash_mark" />
    </item>
</layer-list>
"""
    _write_text(res / "drawable" / "launch_background.xml", splash_xml)
    _write_text(res / "drawable-v21" / "launch_background.xml", splash_xml)

    manifest = FRONTEND / "android" / "app" / "src" / "main" / "AndroidManifest.xml"
    text = manifest.read_text(encoding="utf-8")
    if "android:roundIcon" not in text:
        text = text.replace(
            'android:icon="@mipmap/ic_launcher">',
            'android:icon="@mipmap/ic_launcher"\n'
            '        android:roundIcon="@mipmap/ic_launcher">',
        )
        manifest.write_text(text, encoding="utf-8")


def apply_web() -> None:
    web = FRONTEND / "web"
    if not web.is_dir():
        return

    icon = BRAND / "icon"
    _copy(icon / "favicon.svg", web / "favicon.svg")
    _copy(icon / "favicon-32.png", web / "favicon.png")
    _copy(icon / "favicon-180.png", web / "icons" / "apple-touch-icon.png")
    _write(icon / "app-icon-1024.png", web / "icons" / "Icon-192.png", 192)
    _write(icon / "app-icon-1024.png", web / "icons" / "Icon-512.png", 512)
    _save(
        _composite(
            icon / "adaptive-background-1024.png",
            icon / "adaptive-foreground-1024.png",
            192,
        ),
        web / "icons" / "Icon-maskable-192.png",
    )
    _save(
        _composite(
            icon / "adaptive-background-1024.png",
            icon / "adaptive-foreground-1024.png",
            512,
        ),
        web / "icons" / "Icon-maskable-512.png",
    )
    _copy(BRAND / "social" / "og-image-1200.png", web / "og-image.png")

    _write_text(
        web / "manifest.json",
        json.dumps(
            {
                "name": "Tapture",
                "short_name": "Tapture",
                "start_url": ".",
                "display": "standalone",
                "background_color": DARK,
                "theme_color": PRIMARY,
                "description": "Tap it. It's data.",
                "orientation": "portrait-primary",
                "prefer_related_applications": False,
                "icons": [
                    {
                        "src": "icons/Icon-192.png",
                        "sizes": "192x192",
                        "type": "image/png",
                    },
                    {
                        "src": "icons/Icon-512.png",
                        "sizes": "512x512",
                        "type": "image/png",
                    },
                    {
                        "src": "icons/Icon-maskable-192.png",
                        "sizes": "192x192",
                        "type": "image/png",
                        "purpose": "maskable",
                    },
                    {
                        "src": "icons/Icon-maskable-512.png",
                        "sizes": "512x512",
                        "type": "image/png",
                        "purpose": "maskable",
                    },
                ],
            },
            indent=4,
        )
        + "\n",
    )

    html_path = web / "index.html"
    html = html_path.read_text(encoding="utf-8")
    html = html.replace(
        '<meta name="description" content="Tapture - local-first field data capture.">',
        '<meta name="description" content="Tap it. It\'s data.">',
    )
    html = html.replace(
        '<meta name="apple-mobile-web-app-status-bar-style" content="black">',
        '<meta name="apple-mobile-web-app-status-bar-style" content="black-translucent">',
    )
    html = html.replace(
        '<link rel="apple-touch-icon" href="icons/Icon-192.png">',
        '<link rel="apple-touch-icon" href="icons/apple-touch-icon.png">',
    )
    html = html.replace(
        '<link rel="icon" type="image/png" href="favicon.png"/>',
        '<link rel="icon" type="image/svg+xml" href="favicon.svg"/>\n  '
        '<link rel="icon" type="image/png" sizes="32x32" href="favicon.png"/>',
    )
    if 'property="og:image"' not in html:
        html = html.replace(
            "<title>Tapture</title>",
            '<meta name="theme-color" content="#2662EB">\n  '
            '<meta property="og:title" content="Tapture">\n  '
            '<meta property="og:description" content="Tap it. It\'s data.">\n  '
            '<meta property="og:image" content="og-image.png">\n  '
            "<title>Tapture</title>",
        )
    html_path.write_text(html, encoding="utf-8")


def apply_ios() -> None:
    catalog = FRONTEND / "ios" / "Runner" / "Assets.xcassets" / "AppIcon.appiconset"
    if catalog.is_dir():
        _overwrite_pngs(catalog, BRAND / "icon" / "app-icon-1024.png")
    launch = FRONTEND / "ios" / "Runner" / "Assets.xcassets" / "LaunchImage.imageset"
    if launch.is_dir():
        _overwrite_pngs(launch, BRAND / "splash" / "splash-light-1152.png")


def apply_macos() -> None:
    catalog = FRONTEND / "macos" / "Runner" / "Assets.xcassets" / "AppIcon.appiconset"
    if catalog.is_dir():
        _overwrite_pngs(catalog, BRAND / "icon" / "app-icon-1024.png")


def _overwrite_pngs(folder: Path, source: Path) -> None:
    Image = _pil()
    for png in sorted(folder.glob("*.png")):
        with Image.open(png) as existing:
            size = max(existing.size)
        _write(source, png, size)


def apply_windows() -> None:
    dest = FRONTEND / "windows" / "runner" / "resources" / "app_icon.ico"
    if not dest.parent.is_dir():
        return
    src = _open(BRAND / "icon" / "app-icon-1024.png")
    src.save(
        dest,
        format="ICO",
        sizes=[
            (16, 16),
            (24, 24),
            (32, 32),
            (48, 48),
            (64, 64),
            (128, 128),
            (256, 256),
        ],
    )


def apply_linux() -> None:
    for folder in (
        FRONTEND / "linux" / "runner" / "resources",
        FRONTEND / "linux",
    ):
        if folder.is_dir():
            _write(BRAND / "icon" / "app-icon-1024.png", folder / "tapture.png", 256)
            return


def apply_in_app_assets() -> None:
    dest = FRONTEND / "assets" / "branding"
    dest.mkdir(parents=True, exist_ok=True)
    for relative in (
        "logo/tapture-mark.svg",
        "logo/tapture-mark-inverse.svg",
        "logo/png/tapture-mark-512.png",
        "logo/png/tapture-mark-inverse-512.png",
        "logo/tapture-lockup-horizontal.svg",
        "logo/tapture-lockup-horizontal-inverse.svg",
        "logo/png/tapture-lockup-horizontal-2048.png",
        "logo/tapture-lockup-stacked.svg",
        "icon/favicon.svg",
        "splash/splash-light.svg",
        "splash/splash-dark.svg",
    ):
        _copy(BRAND / relative, dest / Path(relative).name)


def main() -> None:
    if not FRONTEND.is_dir():
        raise SystemExit(f"{FRONTEND} is missing")
    apply_android()
    apply_web()
    apply_ios()
    apply_macos()
    apply_windows()
    apply_linux()
    apply_in_app_assets()
    print("branding applied to frontend/")


if __name__ == "__main__":
    main()
