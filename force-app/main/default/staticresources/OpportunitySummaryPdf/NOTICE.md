# Opportunity Summary PDF renderer

Vendored, unmodified browser distribution of pdfmake 0.2.23 (MIT):
https://github.com/bpampuch/pdfmake/releases/tag/0.2.23

Source archive: https://registry.npmjs.org/pdfmake/-/pdfmake-0.2.23.tgz

npm integrity: `sha512-A/IksoKb/ikOZH1edSDJ/2zBbqJKDghD4+fXn3rT7quvCJDlsZMs3NmIB3eajLMMFU9Bd3bZPVvlUMXhvFI+bQ==`

Only `build/pdfmake.min.js`, `build/vfs_fonts.js`, and `LICENSE` are extracted
from the release. Roboto fonts are embedded in the VFS; no runtime CDN or remote
font/image fetching is used. See ROBOTO-LICENSE.txt for the font license.

`lws-global-this.js` is project code, not part of pdfmake. Lightning Web
Security gives scripts loaded with `loadScript` no `globalThis`, which pdfmake
needs while initializing, so the loader runs this shim first.

Keep this resource pinned and review upstream security fixes before upgrades.
