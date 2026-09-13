(function () {
    'use strict';

    var storageKey = 'jackett-theme';
    var mediaQuery = window.matchMedia('(prefers-color-scheme: dark)');

    function readPreference() {
        try {
            var value = localStorage.getItem(storageKey);
            return value === 'light' || value === 'dark' || value === 'system' ? value : 'system';
        } catch (e) {
            return 'system';
        }
    }

    function resolveTheme(preference) {
        return preference === 'system' ? (mediaQuery.matches ? 'dark' : 'light') : preference;
    }

    function applyTheme(preference) {
        var theme = resolveTheme(preference);
        document.documentElement.setAttribute('data-theme', theme);
        document.documentElement.setAttribute('data-theme-preference', preference);
    }

    function savePreference(preference) {
        try {
            localStorage.setItem(storageKey, preference);
        } catch (e) {
            // Local storage may be unavailable in hardened/private browser modes.
        }
        applyTheme(preference);
    }

    function createSelector() {
        if (document.getElementById('jackett-theme-select')) {
            return;
        }

        var container = document.createElement('div');
        container.className = 'jackett-theme-control';

        var label = document.createElement('label');
        label.className = 'sr-only';
        label.htmlFor = 'jackett-theme-select';
        label.textContent = 'Theme';

        var select = document.createElement('select');
        select.id = 'jackett-theme-select';
        select.className = 'form-control input-sm';
        select.title = 'Theme';
        select.setAttribute('aria-label', 'Theme');

        [['system', 'System'], ['light', 'Light'], ['dark', 'Dark']].forEach(function (item) {
            var option = document.createElement('option');
            option.value = item[0];
            option.textContent = item[1];
            select.appendChild(option);
        });

        select.value = readPreference();
        select.addEventListener('change', function () {
            savePreference(select.value);
        });

        container.appendChild(label);
        container.appendChild(select);

        var page = document.getElementById('page');
        var apiKey = document.querySelector('.jackett-apikey');

        if (page && apiKey) {
            var headerTools = document.querySelector('.jackett-header-tools');
            if (!headerTools) {
                headerTools = document.createElement('div');
                headerTools.className = 'jackett-header-tools';
                page.insertBefore(headerTools, apiKey);
            }

            apiKey.classList.remove('pull-right');
            headerTools.appendChild(container);
            headerTools.appendChild(apiKey);
        } else if (page) {
            page.insertBefore(container, page.firstChild);
        }
    }

    function createWhiteTransparentFavicon() {
        var source = new Image();

        source.onload = function () {
            try {
                var size = 64;
                var padding = 4;
                var canvas = document.createElement('canvas');
                canvas.width = size;
                canvas.height = size;

                var context = canvas.getContext('2d');
                if (!context) {
                    return;
                }

                var availableSize = size - (padding * 2);
                var scale = Math.min(availableSize / source.naturalWidth, availableSize / source.naturalHeight);
                var width = Math.max(1, Math.round(source.naturalWidth * scale));
                var height = Math.max(1, Math.round(source.naturalHeight * scale));
                var x = Math.round((size - width) / 2);
                var y = Math.round((size - height) / 2);

                context.clearRect(0, 0, size, size);
                context.drawImage(source, x, y, width, height);

                var pixels = context.getImageData(0, 0, size, size);
                var data = pixels.data;

                // Convert the existing black-on-white Jackett mark into the same
                // jacket silhouette in white, with the white background removed.
                for (var i = 0; i < data.length; i += 4) {
                    var sourceAlpha = data[i + 3] / 255;
                    var luminance = (0.2126 * data[i] + 0.7152 * data[i + 1] + 0.0722 * data[i + 2]) / 255;
                    var alpha = Math.round(255 * sourceAlpha * (1 - luminance));

                    data[i] = 255;
                    data[i + 1] = 255;
                    data[i + 2] = 255;
                    data[i + 3] = alpha < 6 ? 0 : alpha;
                }

                context.putImageData(pixels, 0, 0);
                var faviconUrl = canvas.toDataURL('image/png');
                var links = document.querySelectorAll('link[rel~="icon"]');

                if (!links.length) {
                    var link = document.createElement('link');
                    link.rel = 'icon';
                    document.head.appendChild(link);
                    links = [link];
                }

                Array.prototype.forEach.call(links, function (link) {
                    link.type = 'image/png';
                    link.sizes = '64x64';
                    link.href = faviconUrl;
                });
            } catch (e) {
                // Keep the packaged favicon as a harmless fallback if canvas is unavailable.
            }
        };

        source.src = '../jacket_medium.png?changed=2026091303';
    }

    function initializeThemeUi() {
        createSelector();
        createWhiteTransparentFavicon();
    }

    var preference = readPreference();
    applyTheme(preference);

    if (mediaQuery.addEventListener) {
        mediaQuery.addEventListener('change', function () {
            if (readPreference() === 'system') {
                applyTheme('system');
            }
        });
    } else if (mediaQuery.addListener) {
        mediaQuery.addListener(function () {
            if (readPreference() === 'system') {
                applyTheme('system');
            }
        });
    }

    if (document.readyState === 'loading') {
        document.addEventListener('DOMContentLoaded', initializeThemeUi);
    } else {
        initializeThemeUi();
    }
})();
