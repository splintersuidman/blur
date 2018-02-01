# Changelog

## [Unreleased]
### Added
- Reset wallpaper on all spaces on unload, and with `chunkc blur::reset`.

---

## [0.2.1]
### Added
- Runtime commands to enable/disable blurring. Use `chunkc blur::enable` to enable blurring; use `chunkc blur::disable` to disable blurring.
- Help message. Run `chunkc blur::help` for help about variables and commands.
- @crisidev created a brew formula!

### Changed
- Fix: setting wallpaper on correct screen when working with more than one screen.
- Fix: count windows on _active_ space, instead of on all _visible_ spaces.

---

## [0.2.0]
### Added
- chunkwm as submodule.
- Space specific wallpapers with the rule `<space>_wallpaper`.

### Changed
- Fix: change wallpaper on deminimize.

---

## [0.1.4]
### Changed
- Fix: deleting temporary blurred walllpapers.
- Better error printing.

---

## [0.1.3]
### Changed
- Fix: deleting temporary blurred wallpapers.

### Added
- Runtime command: `chunkc blur::wallpaper [picture]` to change your wallpaper.

---

## [0.1.2]
### Changed
- Fix: blurred wallpaper stays the same after changing wallpaper and restarting chunkwm.
- CVar `wallpaper_tmp_file` changed to `wallpaper_tmp_path`.

---

## [0.1.1]
### Added
- License
- Changelog
- Feature: restore wallpaper on current space to not-blurred version on unload.

### Changed
- Fix: remove wallpaper on load/unload.

---

## [0.1.0]
### Initial release
