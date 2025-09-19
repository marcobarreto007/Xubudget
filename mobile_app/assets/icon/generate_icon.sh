#!/bin/bash
# Script to generate app icons from SVG

echo "Generating app icons from SVG..."

cd "$(dirname "$0")"

# Check if we have the SVG file
if [ ! -f "app_icon.svg" ]; then
    echo "❌ app_icon.svg not found"
    exit 1
fi

# Try different tools to convert SVG to PNG
if command -v convert >/dev/null 2>&1; then
    # ImageMagick
    echo "Using ImageMagick convert..."
    convert app_icon.svg -resize 192x192 app_icon.png
    echo "✅ Generated app_icon.png (192x192)"
elif command -v magick >/dev/null 2>&1; then
    # ImageMagick 7+
    echo "Using ImageMagick magick..."
    magick app_icon.svg -resize 192x192 app_icon.png
    echo "✅ Generated app_icon.png (192x192)"
elif command -v inkscape >/dev/null 2>&1; then
    # Inkscape
    echo "Using Inkscape..."
    inkscape app_icon.svg --export-type=png --export-filename=app_icon.png --export-width=192 --export-height=192
    echo "✅ Generated app_icon.png (192x192)"
elif command -v rsvg-convert >/dev/null 2>&1; then
    # librsvg
    echo "Using rsvg-convert..."
    rsvg-convert -w 192 -h 192 app_icon.svg -o app_icon.png
    echo "✅ Generated app_icon.png (192x192)"
elif command -v cairosvg >/dev/null 2>&1; then
    # CairoSVG (Python)
    echo "Using CairoSVG..."
    cairosvg app_icon.svg -o app_icon.png -W 192 -H 192
    echo "✅ Generated app_icon.png (192x192)"
else
    echo "⚠️  No SVG converter found. Install one of:"
    echo "   - ImageMagick: sudo apt install imagemagick"
    echo "   - Inkscape: sudo apt install inkscape"  
    echo "   - librsvg: sudo apt install librsvg2-bin"
    echo "   - CairoSVG: pip install cairosvg"
    echo ""
    echo "For now, using the SVG file directly."
    echo "Note: Flutter may not support SVG assets without additional packages."
fi

echo "Done!"