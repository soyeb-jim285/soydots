/* Privileged Experiment API — dynamically injects CSS into browser chrome */

"use strict";

/* global ExtensionAPI, Cc, Ci, Services */

this.themeHelper = class extends ExtensionAPI {
  getAPI(_context) {
    const sss = Cc["@mozilla.org/content/style-sheet-service;1"]
      .getService(Ci.nsIStyleSheetService);
    let currentURI = null;

    return {
      themeHelper: {
        async applyCSS(cssText) {
          // Unregister previous stylesheet
          if (currentURI) {
            try {
              if (sss.sheetRegistered(currentURI, sss.USER_SHEET)) {
                sss.unregisterSheet(currentURI, sss.USER_SHEET);
              }
            } catch (e) {
              // Ignore errors from stale URIs
            }
          }

          // Register new stylesheet (takes effect immediately on all windows)
          const uri = Services.io.newURI(
            "data:text/css;charset=UTF-8," + encodeURIComponent(cssText)
          );
          sss.loadAndRegisterSheet(uri, sss.USER_SHEET);
          currentURI = uri;
        },
      },
    };
  }
};
