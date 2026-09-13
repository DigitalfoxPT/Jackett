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
        document.addEventListener('DOMContentLoaded', createSelector);
    } else {
        createSelector();
    }
})();
