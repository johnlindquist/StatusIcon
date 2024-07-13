#!/bin/bash

# Exit on any error
set -e

# Change to the parent directory
cd "$(dirname "$0")/.."

# Compile the Swift file
swift build -c release

# Create app bundle structure
mkdir -p build/StatusIcon.app/Contents/MacOS
mkdir -p build/StatusIcon.app/Contents/Resources

# Move binary to app bundle
mv .build/release/StatusIcon build/StatusIcon.app/Contents/MacOS/

# Copy Info.plist
cp build/Info.plist build/StatusIcon.app/Contents/

# TODO: Copy icon file
# cp Resources/StatusIcon.icns build/StatusIcon.app/Contents/Resources/

# Move app to Applications
sudo mv build/StatusIcon.app /Applications/

echo "StatusIcon.app has been built and moved to /Applications"