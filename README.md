# Porting Shadow to NixOS

The goal of this project is to provide Shadow on NixOS with a dynamic derivation to handle frequent updates.

**This project is not affiliated with the company providing Shadow in any way.**

## Features

 - Providing a session command to launch a Xorg Server (`shadow-beta-session`)
 - Providing a XSession for display managers (`GDM`, `SDDM`)
 - Enable `strace` on internal Shadow Client (for diagnostics purposes)

Check `cfg.nix` to see all options.

## How to use

### Install

#### As a home-manager package

In your `home.nix` :

```
imports = [
  (fetchGit { url = "https://github.com/Elyhaka/shadow-nix"; ref = "drv-v0.3.0"; } + "/home-manager.nix")
];

programs.shadow-client = {
  enable = true;
};
```

#### As a system package

In your `configuration.nix` :

```
imports = [
  (fetchGit { url = "https://github.com/Elyhaka/shadow-nix"; ref = "drv-v0.3.0"; } + "/system.nix")
];

programs.shadow-client = {
    enable = true;
};
```
