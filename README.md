# blur
This is a plugin for [chunkwm](https://github.com/koekeishiya/chunkwm) that blurs your wallpaper when you open an application or a window.

![Demonstration](demo.gif)

It currently does not support space-specific wallpapers;
all spaces will have the same wallpaper.

- [Settings](#Settings)
- [How to install](#How-to-install)
- [How to build from source](#How-to-build-from-source)

## Settings
`wallpaper` (string [path]): path to your wallpaper. Default: path to your current wallpaper.

`wallpaper_blur` (float): changes the blur intensity. Default: `2.5`.

`wallpaper_mode` (`fill`, `fit`, `stretch` or `center`): the way a wallpaper is displayed. Default: `fill`.

`wallpaper_tmp_file` (string [path]): where to store the blurred wallpaper. Default: `/tmp/chunkwm-tmp-blur.jpg`.

## How to install
- [Download the file]()
- Place it into your plugin directory
    - This is the directory specified in your `chunkwmrc` file after `chunkc core::plugin_dir`.
    - It can be convenient to create a folder for your plugins in your home directory (e.g. `~/.chunkwm_plugins`).
- Load it in you `chunkwmrc` file: `chunkc core::load blur.so`.

If this method does not work, you can try building it from source.

## How to build from source
Required:
- xcode-8 command line tools,
- imagemagick,
- chunkwm

- Install [chunkwm](https://github.com/koekeishiya/chunkwm).
- Clone the chunkwm repo into your home directory.
- Clone this repo into ~/chunkwm/src/plugins
- Run `make` in this folder (~/chunkwm/src/plugins)/

