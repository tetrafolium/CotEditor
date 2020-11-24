# CotEditor

CotEditor is a lightweight plain-text editor for macOS.

- **Requirement**: macOS 10.15 Catalina or later
- **Web Site**: <https://coteditor.com>
- **Mac App Store**: <https://itunes.apple.com/app/coteditor/id1024640650?ls=1>

<img src="screenshot@2x.png" width="750"/>

## Source Code

[![Test Status](https://github.com/coteditor/CotEditor/workflows/Test/badge.svg)](https://github.com/coteditor/CotEditor/actions?query=workflow%3ATest)
[![GitHub release](https://img.shields.io/github/release/coteditor/CotEditor.svg)](https://github.com/coteditor/CotEditor/releases/latest)

CotEditor is a pure document-based Cocoa application written in Swift.

### Development Environment

- macOS 10.15 Catalina
- Xcode 12.2
- Swift 5.3
- Sandbox enabled

## How to Build

### Build for Ad-hoc usage

For those people who just want to build and play with CotEditor locally.

1. Run following commands to resolve dependencies.
   - `git submodule update --init`
1. Open `CotEditor.xcworkspace` in Xcode.
1. Change to ad-hoc build mode:
   1. Open `Configurations/CodeSigning.xcconfig`.
   1. Comment out `#include "CodeSigning-Default.xcconfig"`.
   1. Uncomment `#include "CodeSigning-AdHoc.xcconfig"`.
1. Build "CotEditor" scheme in the workspace.

### Build for distribution (incl. Sparkle version)

1. Run following commands to resolve dependencies.
   - `git submodule update --init`
1. Open `CotEditor.xcworkspace` in Xcode.
1. Run "Sparkle" scheme in CotEditor.xcworkspace
1. Build "CotEditor" scheme in the workspace.

## License

© 2005-2009 nakamuxu,
© 2011, 2014 usami-k,
© 2013-2020 1024jp.

The source code is licensed under the terms of the **Apache License, Version 2.0**. The image resources are licensed under the terms of the [**Creative Commons Attribution-NonCommercial-NoDerivatives 4.0 International License**](https://creativecommons.org/licenses/by-nc-nd/4.0/). See [LICENSE](LICENSE) for details.
