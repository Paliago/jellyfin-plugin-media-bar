#!/bin/bash
set -e

echo "🔨 Building Media Bar (Performance) Plugin..."
echo ""

# Colors
GREEN='\033[0;32m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Set DOTNET_ROOT if not set
if [ -z "$DOTNET_ROOT" ]; then
    if [ -d "$HOME/.dotnet" ]; then
        export DOTNET_ROOT=$HOME/.dotnet
        export PATH=$PATH:$DOTNET_ROOT
    fi
fi

# Use explicit path to dotnet if available
if [ -x "$HOME/.dotnet/dotnet" ]; then
    DOTNET_CMD="$HOME/.dotnet/dotnet"
elif command -v dotnet &> /dev/null; then
    DOTNET_CMD="dotnet"
else
    echo "❌ .NET SDK is not installed!"
    echo "Install it from: https://dotnet.microsoft.com/download"
    exit 1
fi

# Default to Jellyfin 10.11.x
JELLYFIN_VERSION="${1:-10.11.2}"

echo -e "${BLUE}Building for Jellyfin ${JELLYFIN_VERSION}${NC}"
echo ""

# Clean previous builds
echo "🧹 Cleaning previous builds..."
cd src/Jellyfin.Plugin.MediaBar
$DOTNET_CMD clean -c Release > /dev/null 2>&1 || true

# Build
echo "🔨 Building plugin..."
if [ "$JELLYFIN_VERSION" = "10.10.7" ]; then
    $DOTNET_CMD build -c Release -p:JellyfinVersion=10.10.7
else
    $DOTNET_CMD build -c Release
fi

# Determine output path
if [[ "$JELLYFIN_VERSION" == 10.11* ]]; then
    OUTPUT_DIR="bin/Release/net9.0"
else
    OUTPUT_DIR="bin/Release/net8.0"
fi

if [ ! -f "$OUTPUT_DIR/Jellyfin.Plugin.MediaBar.dll" ]; then
    echo "❌ Build failed! DLL not found."
    exit 1
fi

echo ""
echo -e "${GREEN}✅ Build successful!${NC}"
echo ""
echo "📦 Plugin DLL location:"
echo "   $(pwd)/$OUTPUT_DIR/Jellyfin.Plugin.MediaBar.dll"
echo ""

# Calculate checksum
echo "🔐 Checksum (SHA256):"
sha256sum "$OUTPUT_DIR/Jellyfin.Plugin.MediaBar.dll" | awk '{print "   " $1}'
echo ""
echo "📋 Next steps:"
echo "   1. Upload the DLL to GitHub release v2.5.0"
echo "   2. Update manifest.json with the checksum above"
echo "   3. Push manifest.json to GitHub"
echo ""
