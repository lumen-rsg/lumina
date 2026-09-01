# 1T Lumina artwork

This package replaces Fedora's visible desktop and boot defaults with Lumina
artwork:

- `lumina-default.png`: 16:9 indigo desktop and lock-screen wallpaper;
- `lumina-logo.svg`: deterministic icon derived from the terminal mark in
  `art/logo.txt`;
- a GNOME background chooser entry and system defaults;
- a Plymouth script theme using the white Lumina mark.

The wallpaper was generated with the built-in OpenAI image-generation tool
from this production prompt:

> Create an original, calm, premium 16:9 Linux desktop wallpaper with two
> luminous vertical forms and fine orbit-like arcs. Use deep midnight indigo,
> violet, restrained lavender, and cool white. Keep broad low-detail desktop
> areas. Do not include text, logos, trademarks, people, hardware, UI, or
> watermarks.

The selected image was losslessly stored as PNG and resized to 3840x2160 for
desktop use. Vector logo and Plymouth raster generation remain reproducible.
