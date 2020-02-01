# Porting Shadow to NixOS

The goal of this project is to provide Shadow on NixOS with a dynamic derivation to handle frequent updates.

**This project is not affiliated with the company providing Shadow in any way.**

## How to use

### Install

#### As a home-manager package

In your `home.nix` :

```
imports = [
  (fetchGit { url = "https://github.com/Elyhaka/shadow-nix"; ref = "drv-v0.9.0"; } + "/home-manager.nix")
];

programs.shadow-client = {
  enable = true;
};
```

#### As a system package

In your `configuration.nix` :

```
imports = [
  (fetchGit { url = "https://github.com/Elyhaka/shadow-nix"; ref = "drv-v0.9.0"; } + "/system.nix")
];

programs.shadow-client = {
    enable = true;
};
```

## Options

 - `channel` : Choose a channel for the Shadow application. `prod` is the stable channel, `preprod` is the beta channel.
 - `enableDesktopLauncher` : `bool` / default `true` : Provides the desktop file for launching Shadow from current session (only works with Xorg sessions).
 - `enableDiagnostics` : `bool` / default `false` : The command used to execute the client will be output in a file in /tmp. The client will output its strace in /tmp. This is mainly used for diagnostics purposes (when an update breaks something).
 - `provideXSession` : `bool` / default `false` (requires system mode) : Provides a XSession desktop file for Shadow Launcher. Useful if you want to autostart it without any DE/WM.
 - `preferredScreens` : `bool` / default `[]` :  Name of preferred screens, ordered by name. If one screen currently plugged matches the listed screens in this options, it shutdowns all other screens. This feature use xrandr, thus you must use xrandr screen names. This can be useful for laptops with changing multi-heads setups.

## I want to add an option

 - Issues and PR are welcome ! I'll do my best to make this works for everyone !

