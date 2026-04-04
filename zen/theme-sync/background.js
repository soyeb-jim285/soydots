function applyTheme(data) {
  const c = data.colors;
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
      tab_loading: c.blue
    }
  });
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
