# blur
This is a plugin for [chunkwm](https://github.com/koekeishiya/chunkwm) that blurs your wallpaper when you open an application or a window.

![Demonstration](demo.gif)

It currently does not support space-specific wallpapers;
all spaces will have the same wallpaper.

## Content
- [Content](#content)
- [Settings](#settings)
- [Runtime commands](#runtime-commands)
- [How to install](#how-to-install)
- [How to build from source](#how-to-build-from-source)
- [Changelog](#changelog)

## Settings
These settings can be set in your `.chunkwmrc` file.
The syntax is `chunkc set [setting] [value]`.
Example: `chunkc set wallpaper ~/Pictures/wallpaper.jpg`

- `wallpaper` (string [path]): path to your wallpaper. Default: path to your current wallpaper.

- `wallpaper_blur` (float): changes the blur intensity. Default: `2.5`.

- `wallpaper_mode` (`fill`, `fit`, `stretch` or `center`): the way a wallpaper is displayed. Default: `fill`.

- `wallpaper_tmp_path` (string [path]): where to store the blurred wallpaper. Default: `/tmp/`.

## Runtime commands
These commands can be used while chunkwm is running, whithout the need of reloading the plugin. The syntax is `chunkc blur::[command] [args]`.
Example: `chunkc blur::wallpaper ~/Pictures/wallpaper.jpg`

- `wallpaper` (string [path]): path to you wallpaper.

## How to install
- [Download the file](https://github.com/splintah/blur/releases)
- Place it into your plugin directory
    - This is the directory specified in your `chunkwmrc` file after `chunkc core::plugin_dir`.
    - It may be convenient to create a folder for your plugins in your home directory (e.g. `~/.chunkwm_plugins`).
- Load it in you `chunkwmrc` file: `chunkc core::load blur.so`.

## How to build from source
### Required
- xcode-8 command line tools
- imagemagick
- chunkwm

### Build process
- Clone the chunkwm repo into your home directory.
- Clone this repo into ~/chunkwm/src/plugins.
- Run `make` in this folder (~/chunkwm/src/plugins).

## Changelog
[CHANGELOG.md](https://github.com/splintah/blur/blob/master/CHANGELOG.md)
