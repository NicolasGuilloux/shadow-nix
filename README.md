# Porting Shadow to NixOS

The goal of this project is to provide Shadow on NixOS with a dynamic derivation to handle frequent updates.

**This project is not affiliated with the company providing Shadow in any way.**

## Current status

It works ! But this is still a work in progress, remaining tasks are :

 - [X] Providing diagnostics options (for `strace`) 
 - [X] Supporting imports from `home-manager`
 - [ ] Providing a Xorg Wrapper (if a flag is enabled, start the client in a dedicated Xorg server on another TTY : usefull for wayland only setups).

## How to use

### Install

#### As a home-manager package

In your `home.nix` :

```
  imports = [
    (fetchGit { url = "https://github.com/Elyhaka/shadow-nix"; ref = "drv-v0.1"; } + "/home-manager.nix")
  ];

  programs.shadow-client = {
    enable = true;
  };
```

#### As a system package

In your `configuration.nix` :

```
  imports = [
    (fetchGit { url = "https://github.com/Elyhaka/shadow-nix"; ref = "drv-v0.1"; } + "/system.nix")
  ];

  programs.shadow-client = {
    enable = true;
  };
```
