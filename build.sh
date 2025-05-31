#!/bin/bash
set -e # Exit immediately if a command exits with a non-zero status.

echo "Downloading Flutter SDK 3.32.0..."
curl https://storage.googleapis.com/flutter_infra_release/releases/stable/linux/flutter_linux_3.32.0-stable.tar.xz | tar -Jxf -

echo "Setting safe directory for Git..."
git config --global --add safe.directory /vercel/path0/flutter

echo "Running flutter pub get..."
flutter/bin/flutter pub get

echo "Running flutter build web..."
flutter/bin/flutter build web

echo "Build script finished."
