# blur [![Build Status](https://travis-ci.org/splintah/blur.svg?branch=master)](https://travis-ci.org/splintah/blur)
This is a plugin for [chunkwm](https://github.com/koekeishiya/chunkwm) that blurs your wallpaper when you open an application or a window.

![Demonstration](demo.gif)

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

- `wallpaper` (string [path]): path to your wallpaper. Default: path to your current wallpaper. This is the 'global' wallpaper.

- `<space>_wallpaper` (string [path]): path to a wallpaper. This wallpaper will be used on space `<space>`.

- `wallpaper_blur` (float): changes the blur intensity. Default: `0.0` (imagemagick selects a suitable value when `0.0` is used).

- `wallpaper_mode` (`fill`, `fit`, `stretch` or `center`): the way a wallpaper is displayed. Default: `fill`.

- `wallpaper_tmp_path` (string [path]): where to store the blurred wallpaper. Default: `/tmp/`.

## Runtime commands
These commands can be used while chunkwm is running, whithout the need of reloading the plugin. The syntax is `chunkc blur::[command] [args]`.
Example: `chunkc blur::wallpaper ~/Pictures/wallpaper.jpg`

- `help`: show help about the settings and commands.

- `wallpaper` (string [path]): path to you wallpaper.

- `enable`: enable blurring. Blurring is enabled by default.

- `disable`: disable blurring. Every desktop will get its wallpaper specified with `<space>_wallpaper`, but not blurred.

- `reset`: reset wallpaper on all spaces. This also disables blurring.

## How to install
### With Homebrew
Thanks to [crisidev](https://github.com/crisidev) for providing a homebrew formula.

```bash
# Clone the tap.
brew tap crisidev/homebrew-chunkwm

# Install the plugin.
brew install chunkwm-blur --HEAD

# Get info about the plugin (e.g. loading it from your chunkwmrc).
brew info chunkwm-blur
```

### Downloading from GitHub
The precompiled releases can often be found on the GitHub releases page.

- [Download the file](https://github.com/splintah/blur/releases)
- Place it into your plugin directory
    - This is the directory specified in your `chunkwmrc` file after `chunkc core::plugin_dir`.
    - It may be convenient to create a folder for your plugins in your home directory (e.g. `~/.chunkwm_plugins`).
- Load it in you `chunkwmrc` file: `chunkc core::load blur.so`.

## How to build from source
### Required
- xcode-8 command line tools
- imagemagick

### Build process
- Clone this repo.
- Run `make` in this folder.
- The binary can be found in `./bin`.

## Changelog
[CHANGELOG.md](https://github.com/splintah/blur/blob/master/CHANGELOG.md)
