# Porting Shadow to NixOS

The goal of this project is to provide Shadow on NixOS with a dynamic derivation to handle frequent updates.

**This project is not affiliated with Blade, the company providing Shadow, in any way.**

## How to use

### Install

Note that the ref value (`drv-v*.*.*`) should point to the lastest release. Checkout the tags to know it.

If you want the latest package derivation, use `ref = "master"` instead.

#### As a home-manager package

In your `home.nix` :

```nix
{
  imports = [
    (fetchGit { url = "https://github.com/Elyhaka/shadow-nix"; ref = "drv-v0.14.0"; } + "/home-manager.nix")
  ];

  programs.shadow-client = {
    enable = true;
    channel = "preprod";
  };
}
```

#### As a system package

In your `configuration.nix` :

```nix
{
  imports = [
    (fetchGit { url = "https://github.com/Elyhaka/shadow-nix"; ref = "drv-v0.14.0"; } + "/system.nix")
  ];

  programs.shadow-client = {
    enable = true;
    channel = "prod";
  };
}
```

## Options

 - `channel` : Choose a channel for the Shadow application. `prod` is the stable channel, `preprod` is the beta channel and `testing` is the alpha channel.
 - `enableDesktopLauncher` : `bool` / default `true` : Provides the desktop file for launching Shadow from current session (only works with Xorg sessions).
 - `enableDiagnostics` : `bool` / default `false` : The command used to execute the client will be output in a file in /tmp. The client will output its strace in /tmp. This is mainly used for diagnostics purposes (when an update breaks something).
 - `provideXSession` : `bool` / default `false` (requires system mode) : Provides a XSession desktop file for Shadow Launcher. Useful if you want to autostart it without any DE/WM.
 - `preferredScreens` : `bool` / default `[]` : Name of preferred screens, ordered by name. If one screen currently plugged matches the listed screens in this options, it shutdowns all other screens. This feature use xrandr, thus you must use xrandr screen names. This can be useful for laptops with changing multi-heads setups.
 - `forceDriver` : `enum` / default `""` : Force the VA driver used by Shadow using the LIBVA_DRIVER_NAME environment variable.
 - `disableGpuFix` : `bool` / default `false` : Disable the GPU fixes for Shadow related to the color bit size.


## A word on vaapi

It is important to have `vaapi` enabled to make Shadow works correctly. You can find information on this [NixOS wiki page](https://nixos.wiki/wiki/Accelerated_Video_Playback). 


#### An example for Intel and AMD GPU

The following example should work for both AMD and Intel GPU. This is just an example, there is no guarantee that it will work.

```nix
{
  # Provides the `vainfo` command
  environment.systemPackages = with pkgs; [ libva-utils ];

  # Hardware hybrid decoding
  nixpkgs.config.packageOverrides = pkgs: {
    vaapiIntel = pkgs.vaapiIntel.override { enableHybridCodec = true; };
  };

  # Hardware drivers
  hardware.opengl = {
    enable = true;
    extraPackages = with pkgs; [
      vaapiIntel
      vaapiVdpau
      libvdpau-va-gl
      intel-media-driver
    ];
  };
}
```

#### Black screen issue with official Nvidia drivers

As stated previously, you need the `vaapiVdpau` extra package. However, if you get a black screen when streaming from Shadow and are using a Nvidia graphic card, you might need to patch the [libva-vdpau-driver](https://gitlab.com/aar642/libva-vdpau-driver).

Thankfully, it's quite easy to straightforward to apply a custom patch on NixOS. You can, for example, edit your `/etc/nixos/configuration.nix/` so that it looks like this:

```nix
  nixpkgs.overlays = [
      (self: super: {
          vaapiVdpau = super.vaapiVdpau.overrideAttrs (oldAttrs: rec {
            name = "libva-vdpau-driver-nvidia-patched";
            patches = oldAttrs.patches ++ [
            (self.fetchpatch {
                url = "https://gist.githubusercontent.com/tcheneau/702ce1376181aa4562443681830a3408/raw/26b78137bc62d4560f7fed336a504a81c9933a42/reflow-arekinath-nvidia-v2.patch";
                sha256 = "0w7n83lf61fjksqaxblpzqjhj9m6cpzny29c3bp3r0ladxbkhnw7";
            })
            ];
          });
      })
  ];
```

Note that this patch has been reworked by tcheneau as the original patch did not apply.

## I want to add an option

 - Issues and PR are welcome! I'll do my best to make this works for everyone!

