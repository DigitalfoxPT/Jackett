# Bootstrap 3 security maintenance

The dashboard uses Bootstrap **3.4.1 with security backports**, preserving its
existing Bootstrap 3 markup, plugins, glyphicons and Light/Dark/System themes.
The upstream 3.4.1 release alone does not fix all known Bootstrap 3 advisories.
Version scanners may still report 3.4.1 because the upstream version is retained.

`bootstrap.min.css` comes from the official `bootstrap@3.4.1` npm package.
`bootstrap.min.js` is rebuilt from that package's sources with these unmodified
Debian patches, retained in `security-patches/`:

- `0002-CVE-2024-6484.patch`: prevent unsafe carousel navigation.
- `0003-CVE-2024-6485.patch`: escape data-provided button labels.
- `CVE-2025-1647.patch`: sanitize tooltip/popover HTML using DOMParser and validate
  the fallback DOM implementation.

Source: [Debian twitter-bootstrap3 3.4.1+dfsg-7](https://deb.debian.org/debian/pool/main/t/twitter-bootstrap3/twitter-bootstrap3_3.4.1+dfsg-7.debian.tar.xz).
Archive SHA-256: `1972e68d055cbdbba2455a80cdfa7389d5ac80a488c63c729a36b40d48cd82e9`.

To rebuild, verify the npm archive against its registry `dist.integrity`, extract
the package, apply the three patches with `git apply`, and concatenate the
original `dist/js/bootstrap.js` jQuery checks followed by the patched source files
in this order: transition, alert, button, carousel, collapse, dropdown, modal,
tooltip, popover, scrollspy, tab, affix. Minify with Terser 5.51.2, preserving
license comments, and retain the security-backport banner. Node/Terser are only
needed when regenerating this vendored file, not for normal Jackett builds.

Serve the repository locally and open `.github/tests/frontend-security.html` in a
browser to check the backports, sanitization, templates and table behavior.
Check the dashboard and modals in both light and dark mode after regeneration.

Bootstrap remains MIT licensed; the original license notices are retained.
