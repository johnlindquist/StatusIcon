# StatusIcon

StatusIcon is a macOS application that displays a customizable icon in the status bar. The icon can be dynamically changed using SF Symbols.

## Features

- Displays a status bar icon using SF Symbols
- Allows dynamic icon changes by modifying a file

## Installation

### Prerequisites

- Xcode Command Line Tools
- Swift

### Steps

1. Clone this repository
2. Ensure you have the necessary permissions to write to the `/Applications` folder
3. Run the build script:
   ```
   ./build/build.sh
   ```
4. The application will be built and moved to your `/Applications` folder

Note: The build script uses `sudo` to move the application to `/Applications`. You may be prompted for your password.

## Usage

### Changing the Icon

To change the status bar icon, simply echo the desired SF Symbol name to the `~/.status` file:
