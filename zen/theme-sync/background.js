function buildChromeCSS(c) {
  const isLight = c.base.toLowerCase() > "#888888";

  return `
    /* Zen Browser Chrome — injected by Quickshell Theme Sync */
    :root {
      --zen-colors-primary: ${c.surface0} !important;
      --zen-primary-color: ${c.blue} !important;
      --zen-colors-secondary: ${c.surface0} !important;
      --zen-colors-tertiary: ${c.mantle} !important;
      --zen-colors-border: ${c.blue} !important;
      --toolbarbutton-icon-fill: ${c.blue} !important;
      --lwt-text-color: ${c.text} !important;
      --toolbar-field-color: ${c.text} !important;
      --tab-selected-textcolor: ${c.blue} !important;
      --toolbar-field-focus-color: ${c.text} !important;
      --toolbar-color: ${c.text} !important;
      --newtab-text-primary-color: ${c.text} !important;
      --arrowpanel-color: ${c.text} !important;
      --arrowpanel-background: ${c.base} !important;
      --sidebar-text-color: ${c.text} !important;
      --lwt-sidebar-text-color: ${c.text} !important;
      --lwt-sidebar-background-color: ${c.crust} !important;
      --toolbar-bgcolor: ${c.surface0} !important;
      --newtab-background-color: ${c.base} !important;
      --zen-themed-toolbar-bg: ${c.mantle} !important;
      --zen-main-browser-background: ${c.mantle} !important;
      --toolbox-bgcolor-inactive: ${c.mantle} !important;
    }

    #permissions-granted-icon { color: ${c.mantle} !important; }
    .sidebar-placesTree { background-color: ${c.base} !important; }
    #zen-workspaces-button { background-color: ${c.base} !important; }
    #TabsToolbar { background-color: ${c.mantle} !important; }
    .urlbar-background { background-color: ${c.base} !important; }
    .content-shortcuts { background-color: ${c.base} !important; border-color: ${c.blue} !important; }
    .urlbarView-url { color: ${c.blue} !important; }
    #zenEditBookmarkPanelFaviconContainer { background: ${c.crust} !important; }
    hbox#titlebar { background-color: ${c.mantle} !important; }
    #zen-appcontent-navbar-container { background-color: ${c.mantle} !important; }

    #zen-media-controls-toolbar #zen-media-progress-bar::-moz-range-track {
      background: ${c.surface0} !important;
    }

    toolbar .toolbarbutton-1:not([disabled]):is([open], [checked]) > .toolbarbutton-icon,
    toolbar .toolbarbutton-1:not([disabled]):is([open], [checked]) > .toolbarbutton-text,
    toolbar .toolbarbutton-1:not([disabled]):is([open], [checked]) > .toolbarbutton-badge-stack {
      fill: ${c.crust};
    }

    .identity-color-blue { --identity-tab-color: ${c.blue} !important; --identity-icon-color: ${c.blue} !important; }
    .identity-color-turquoise { --identity-tab-color: ${c.teal} !important; --identity-icon-color: ${c.teal} !important; }
    .identity-color-green { --identity-tab-color: ${c.green} !important; --identity-icon-color: ${c.green} !important; }
    .identity-color-yellow { --identity-tab-color: ${c.yellow} !important; --identity-icon-color: ${c.yellow} !important; }
    .identity-color-orange { --identity-tab-color: ${c.peach} !important; --identity-icon-color: ${c.peach} !important; }
    .identity-color-red { --identity-tab-color: ${c.red} !important; --identity-icon-color: ${c.red} !important; }
    .identity-color-pink { --identity-tab-color: ${c.pink} !important; --identity-icon-color: ${c.pink} !important; }
    .identity-color-purple { --identity-tab-color: ${c.mauve} !important; --identity-icon-color: ${c.mauve} !important; }
  `;
}

function buildContentCSS(c) {
  return `
    /* Zen internal pages — injected by Quickshell Theme Sync */
    @-moz-document url-prefix("about:") {
      :root {
        --in-content-page-color: ${c.text} !important;
        --color-accent-primary: ${c.blue} !important;
        background-color: ${c.base} !important;
        --in-content-page-background: ${c.base} !important;
      }
    }

    @-moz-document url("about:newtab"), url("about:home") {
      :root {
        --newtab-background-color: ${c.base} !important;
        --newtab-background-color-secondary: ${c.surface0} !important;
        --newtab-element-hover-color: ${c.surface0} !important;
        --newtab-text-primary-color: ${c.text} !important;
        --newtab-wordmark-color: ${c.text} !important;
        --newtab-primary-action-background: ${c.blue} !important;
      }
      .icon { color: ${c.blue} !important; }
    }

    @-moz-document url-prefix("about:preferences") {
      :root {
        --zen-colors-tertiary: ${c.mantle} !important;
        --in-content-text-color: ${c.text} !important;
        --link-color: ${c.blue} !important;
        --zen-colors-primary: ${c.surface0} !important;
        --in-content-box-background: ${c.surface0} !important;
        --zen-primary-color: ${c.blue} !important;
      }
      groupbox, moz-card { background: ${c.base} !important; }
      button, groupbox menulist { background: ${c.surface0} !important; color: ${c.text} !important; }
      .main-content { background-color: ${c.crust} !important; }
    }

    @-moz-document url-prefix("about:addons") {
      :root {
        --zen-dark-color-mix-base: ${c.mantle} !important;
        --background-color-box: ${c.base} !important;
      }
    }
  `;
}

function applyTheme(data) {
  const c = data.colors;

  // 1. Website appearance (dark/light for web content)
  const colorScheme = data.mode === "dark" ? "dark" : "light";
  browser.browserSettings.overrideContentColorScheme.set({ value: colorScheme });

  // 2. Standard theme properties (basic coverage)
  browser.theme.update({
    colors: {
      frame: c.crust,
      frame_inactive: c.mantle,
      tab_background_text: c.text,
      tab_selected: c.base,
      tab_text: c.text,
      tab_line: c.blue,
      toolbar: c.base,
      toolbar_text: c.text,
      toolbar_field: c.surface0,
      toolbar_field_text: c.text,
      toolbar_field_border: c.surface1,
      toolbar_field_focus: c.surface0,
      toolbar_top_separator: c.crust,
      toolbar_bottom_separator: c.crust,
      popup: c.surface0,
      popup_text: c.text,
      popup_border: c.surface1,
      popup_highlight: c.blue,
      popup_highlight_text: c.crust,
      sidebar: c.mantle,
      sidebar_text: c.text,
      sidebar_border: c.surface0,
      sidebar_highlight: c.blue,
      sidebar_highlight_text: c.crust,
      ntp_background: c.base,
      ntp_text: c.text,
      button_background_hover: c.surface1,
      button_background_active: c.surface2,
      icons: c.text,
      icons_attention: c.peach,
      tab_loading: c.blue,
    },
  });

  // 3. Full CSS injection for Zen-specific variables (instant effect via nsIStyleSheetService)
  const fullCSS = buildChromeCSS(c) + "\n" + buildContentCSS(c);
  browser.themeHelper.applyCSS(fullCSS);
}

function connectNative() {
  const port = browser.runtime.connectNative("quickshell_theme");
  port.onMessage.addListener((msg) => {
    if (msg && msg.colors) {
      applyTheme(msg);
    }
  });
  port.onDisconnect.addListener(() => {
    setTimeout(connectNative, 5000);
  });
}

connectNative();
