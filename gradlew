#!/usr/bin/env bash
set -euo pipefail

GRADLE_VERSION=8.6
WRAPPER_DIR="$(cd "$(dirname "$0")" && pwd)/.gradle-wrapper"
DIST_DIR="$WRAPPER_DIR/gradle-$GRADLE_VERSION"
ZIP="$WRAPPER_DIR/gradle-$GRADLE_VERSION-bin.zip"

if [ ! -d "$DIST_DIR" ]; then
  echo "Downloading Gradle $GRADLE_VERSION..."
  mkdir -p "$WRAPPER_DIR"
  if command -v curl >/dev/null 2>&1; then
    curl -L -o "$ZIP" "https://services.gradle.org/distributions/gradle-${GRADLE_VERSION}-bin.zip"
  elif command -v wget >/dev/null 2>&1; then
    wget -O "$ZIP" "https://services.gradle.org/distributions/gradle-${GRADLE_VERSION}-bin.zip"
  else
    echo "Please install curl or wget to download Gradle"
    exit 1
  fi

  if command -v unzip >/dev/null 2>&1; then
    unzip -q "$ZIP" -d "$WRAPPER_DIR"
  elif command -v python3 >/dev/null 2>&1; then
    python3 - <<PY
import zipfile
zipfile.ZipFile(r"$ZIP").extractall(r"$WRAPPER_DIR")
PY
  elif command -v python >/dev/null 2>&1; then
    python - <<PY
import zipfile
zipfile.ZipFile(r"$ZIP").extractall(r"$WRAPPER_DIR")
PY
  else
    echo "No unzip or python available to extract Gradle zip"
    exit 1
  fi
  rm -f "$ZIP"
fi

exec "$DIST_DIR/bin/gradle" "$@"
