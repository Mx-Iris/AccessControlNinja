<img width="30%" src= "AccessControlNinja/Assets.xcassets/AppIcon.appiconset/icon_512x512@2x.png">

# AccessControlNinja

Xcode extension to change the access control level of Swift code selection

This project was inspired by (AccessControlKitty)[https://github.com/zoejessica/AccessControlKitty].

> [!NOTE]
The current project is still in the development stage. If there are any issues, please submit an issue.

## Motivation

Due to `AccessControlKitty` being outdated and no longer maintained by the author, and Swift being a constantly evolving language, the original version used regex matching to parse code, which leads to a large number of syntax recognition errors in the latest version of Swift.

`AccessControlNinja` uses `swift-syntax` to parse Swift code, ensuring it can understand every line of Swift code.

`AccessControlNinja` also supports `package` access control level and `import` statements.

## Features

- Works on selected Swift code to switch between `public`, `private`, `fileprivate`, `internal`, `open`, `package` or no access control modifier. Choose an option from the new Access Level of Selection item at the bottom of Xcode's Editor menu:

- Increment access levels in selected code. So, fileprivate code becomes internal, internal becomes public.

- Decrement access levels. private code stays as is, fileprivate become private, and public code becomes internal.

- Set all appropriate access modifiers to one level

- Remove access notation entirely

## Caveats

Since `swift-syntax` only parses Swift syntax and does not understand the code, it will not determine whether this access control can be applied in the current context.



