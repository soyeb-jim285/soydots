pragma ComponentBehavior: Bound

import Quickshell
import Quickshell.Io
import Quickshell.Hyprland
import Quickshell.Wayland
import QtQuick
import QtQuick.Layouts
import "icons"
import "quill" as Quill

Scope {
    id: root

    property bool visible: false
    property bool closing: false
    property string searchText: ""

    // Filter out system/network tools that shouldn't appear in a launcher
    property var hiddenApps: Config.launcherHiddenApps

    // Sequential match score: chars in query appear in order in target
    // Returns 0-1 score, 0 means no match
    function sequentialScore(query, target) {
        if (query.length === 0) return 0;
        let qi = 0;
        let score = 0;
        let consecutive = 0;
        let lastMatchPos = -1;

        for (let ti = 0; ti < target.length && qi < query.length; ti++) {
            if (target[ti] === query[qi]) {
                consecutive++;
                score += consecutive;
                if (ti === 0 || target[ti - 1] === ' ' || target[ti - 1] === '-')
                    score += 3;
                // Gap penalty: penalize large distances between matched chars
                if (lastMatchPos >= 0) {
                    let gap = ti - lastMatchPos - 1;
                    if (gap > 0) score -= gap * 0.5;
                }
                lastMatchPos = ti;
                qi++;
            } else {
                consecutive = 0;
            }
        }
        if (qi < query.length) return 0;
        let maxScore = query.length * (query.length + 1) / 2 + 3 * query.length;
        return Math.max(0, score / maxScore);
    }

    function ngrams(str, n) {
        let set = new Set();
        for (let i = 0; i <= str.length - n; i++)
            set.add(str.substring(i, i + n));
        return set;
    }

    function ngramSimilarity(query, target) {
        let n = query.length <= 3 ? 2 : 3;
        if (query.length < n || target.length < n) return 0;
        let qSet = ngrams(query, n);
        let tSet = ngrams(target, n);
        let intersection = 0;
        qSet.forEach(g => { if (tSet.has(g)) intersection++; });
        let union = qSet.size + tSet.size - intersection;
        return union === 0 ? 0 : intersection / union;
    }

    function fuzzyScore(query, target) {
        let seq = sequentialScore(query, target);
        let ngram = ngramSimilarity(query, target);
        return seq * 0.7 + ngram * 0.3;
    }

    // Levenshtein edit distance between two strings
    function editDistance(a, b) {
        let m = a.length, n = b.length;
        let prev = new Array(n + 1);
        let curr = new Array(n + 1);
        for (let j = 0; j <= n; j++) prev[j] = j;
        for (let i = 1; i <= m; i++) {
            curr[0] = i;
            for (let j = 1; j <= n; j++) {
                if (a[i - 1] === b[j - 1])
                    curr[j] = prev[j - 1];
                else
                    curr[j] = 1 + Math.min(prev[j - 1], prev[j], curr[j - 1]);
            }
            let tmp = prev; prev = curr; curr = tmp;
        }
        return prev[n];
    }

    // Edit distance score: check query against each word in target
    // Returns 0-1 score, higher = closer match
    function editDistanceScore(query, target) {
        let words = target.split(/[\s\-]+/);
        let bestScore = 0;
        for (let word of words) {
            if (word.length === 0) continue;
            let dist = editDistance(query, word);
            let maxLen = Math.max(query.length, word.length);
            let score = 1 - dist / maxLen;
            if (score > bestScore) bestScore = score;
        }
        return bestScore;
    }

    function scoreApp(app, query) {
        let name = (app.name ?? "").toLowerCase();
        let generic = (app.genericName ?? "").toLowerCase();
        let comment = (app.comment ?? "").toLowerCase();
        let keywords = (app.keywords ?? []).join(" ").toLowerCase();
        return Math.max(
            fuzzyScore(query, name),
            fuzzyScore(query, generic),
            fuzzyScore(query, comment),
            fuzzyScore(query, keywords)
        );
    }

    // Fallback: score app by edit distance against name only
    function scoreAppTypo(app, query) {
        let name = (app.name ?? "").toLowerCase();
        return editDistanceScore(query, name);
    }

    // Calculator: detect and evaluate math expressions.
    // Supports digits, operators (+ - * / % ^ **), parens, e-notation,
    // whitelisted functions (sin, cos, tan, sqrt, log, ln, abs, pow, ...),
    // and constants (pi, e, tau). Unknown identifiers are rejected so the
    // evaluator cannot reach anything outside Math.*.
    readonly property var mathFuncs: ({
        sin: 1, cos: 1, tan: 1, asin: 1, acos: 1, atan: 1, atan2: 1,
        sinh: 1, cosh: 1, tanh: 1, asinh: 1, acosh: 1, atanh: 1,
        exp: 1, sqrt: 1, cbrt: 1, abs: 1, sign: 1,
        floor: 1, ceil: 1, round: 1, trunc: 1,
        min: 1, max: 1, pow: 1, hypot: 1, log2: 1
    })
    readonly property var mathConsts: ({
        pi: "Math.PI", e: "Math.E", tau: "(2*Math.PI)", inf: "Infinity"
    })

    function isMathExpression(query) {
        if (!query) return false;
        // Leading "/" forces explicit calc mode: "/sin 30", "/sqrt 16"
        let explicit = query.startsWith("/");
        let body = explicit ? query.substring(1).trim() : query;
        if (!body) return false;
        if (!/^[0-9a-zA-Z_+\-*/%().,\s^!]+$/.test(body)) return false;
        if (explicit) return true;
        // Implicit mode: must look math-y — operator/paren present, OR starts
        // with a known function name (so bare "sin 30" triggers).
        let funcNames = root.implicitFuncs.concat(Object.keys(root.mathFuncs)).join("|");
        let funcStart = new RegExp("^(" + funcNames + ")\\b", "i");
        if (!/[+\-*/%^()!]/.test(body) && !funcStart.test(body)) return false;
        if (!/[0-9]/.test(body) && !/\b(pi|e|tau|inf)\b/i.test(body)) return false;
        return true;
    }

    // Split a comma-separated arg list by top-level commas only (ignoring
    // commas inside nested parens). Returns an array of raw arg strings.
    function splitArgs(s) {
        let args = [], depth = 0, cur = "";
        for (let ch of s) {
            if (ch === '(') depth++;
            else if (ch === ')') depth--;
            if (ch === ',' && depth === 0) { args.push(cur); cur = ""; }
            else cur += ch;
        }
        args.push(cur);
        return args;
    }

    // Tokenize and substitute: numbers pass through, identifiers are looked up
    // in the whitelist. Returns null on any unknown identifier. `extraIdents`
    // lets the caller pass in loop variables allowed inside sum/prod bodies.
    function transformMathExpr(expr, extraIdents) {
        extraIdents = extraIdents || {};
        let out = "";
        let i = 0;
        while (i < expr.length) {
            let c = expr[i];
            if (/[0-9.]/.test(c)) {
                // Consume number, including optional scientific exponent
                let j = i;
                while (j < expr.length && /[0-9.]/.test(expr[j])) j++;
                if (j < expr.length && (expr[j] === 'e' || expr[j] === 'E')) {
                    let k = j + 1;
                    if (k < expr.length && (expr[k] === '+' || expr[k] === '-')) k++;
                    if (k < expr.length && /[0-9]/.test(expr[k])) {
                        j = k;
                        while (j < expr.length && /[0-9]/.test(expr[j])) j++;
                    }
                }
                out += expr.substring(i, j);
                i = j;
            } else if (/[a-zA-Z_]/.test(c)) {
                let j = i;
                while (j < expr.length && /[a-zA-Z0-9_]/.test(expr[j])) j++;
                let rawName = expr.substring(i, j);
                let name = rawName.toLowerCase();

                // sum/prod: parse balanced-paren arg list, recurse on each arg,
                // and emit a closure form the eval step can run.
                if (name === "sum" || name === "prod") {
                    let k = j;
                    while (k < expr.length && /\s/.test(expr[k])) k++;
                    if (k >= expr.length || expr[k] !== '(') return null;
                    let depth = 1, m = k + 1;
                    while (m < expr.length && depth > 0) {
                        if (expr[m] === '(') depth++;
                        else if (expr[m] === ')') depth--;
                        if (depth > 0) m++;
                    }
                    if (depth !== 0) return null;
                    let argText = expr.substring(k + 1, m);
                    let args = root.splitArgs(argText);
                    if (args.length !== 4) return null;
                    let varName = args[0].trim();
                    if (!/^[a-zA-Z_]\w*$/.test(varName)) return null;
                    let vLower = varName.toLowerCase();
                    if (root.mathFuncs[vLower] || root.mathConsts[vLower]
                        || vLower === "sum" || vLower === "prod"
                        || vLower === "ln" || vLower === "log") return null;
                    let fromT = root.transformMathExpr(args[1], extraIdents);
                    let toT = root.transformMathExpr(args[2], extraIdents);
                    let bodyExtra = Object.assign({}, extraIdents);
                    bodyExtra[vLower] = varName;
                    let bodyT = root.transformMathExpr(args[3], bodyExtra);
                    if (fromT === null || toT === null || bodyT === null) return null;
                    let fn = name === "sum" ? "_sum" : "_prod";
                    out += fn + "((" + fromT + "),(" + toT + "),function(" + varName + "){return (" + bodyT + ");})";
                    i = m + 1;
                    continue;
                }

                if (name === "_fact" || name === "_sum" || name === "_prod") {
                    out += rawName;
                } else if (name === "ln") {
                    out += "Math.log";
                } else if (name === "log") {
                    out += "Math.log10";
                } else if (root.mathFuncs[name]) {
                    out += "Math." + name;
                } else if (root.mathConsts[name]) {
                    out += root.mathConsts[name];
                } else if (extraIdents[name]) {
                    out += extraIdents[name];
                } else {
                    return null;
                }
                i = j;
            } else {
                out += c;
                i++;
            }
        }
        return out;
    }

    // Whitelisted unary functions for implicit-parens shorthand ("sin 30").
    // Multi-arg functions (pow, min, max, atan2, hypot) need explicit parens.
    readonly property var implicitFuncs: [
        "sin","cos","tan","asin","acos","atan",
        "sinh","cosh","tanh","asinh","acosh","atanh",
        "exp","sqrt","cbrt","abs","sign",
        "floor","ceil","round","trunc",
        "log","log2","ln"
    ]

    function evaluateMath(query) {
        try {
            // Strip optional "/" prefix for explicit calc mode
            let src = query.startsWith("/") ? query.substring(1).trim() : query;
            if (!src) return null;
            let expr = src.replace(/\^/g, "**");
            // Strip thousands separators only when the input has no parens —
            // otherwise a comma inside a function call like pow(2,100) would
            // be ambiguous with 2,100. Iterate so 1,000,000 fully collapses.
            if (!/[()]/.test(expr)) {
                let prev;
                do { prev = expr; expr = expr.replace(/(\d),(\d{3})(?=\D|$)/g, "$1$2"); } while (expr !== prev);
            }
            // Factorials: wrap atoms preceding "!" as _fact(...). Iterate so
            // (2+3)!, sin(30)!, and 5!! all unwind.
            let factAtom = "(\\d+(?:\\.\\d+)?(?:[eE][+-]?\\d+)?|[a-zA-Z_]\\w*(?:\\([^()]*\\))?|\\([^()]*\\))!";
            let factRe = new RegExp(factAtom, "g");
            let prevF;
            do { prevF = expr; expr = expr.replace(factRe, "_fact($1)"); } while (expr !== prevF);
            // Collapse "sin (x)" → "sin(x)" (drop whitespace before paren)
            let funcAlt = root.implicitFuncs.join("|");
            expr = expr.replace(new RegExp("\\b(" + funcAlt + ")\\s+(\\()", "gi"), "$1$2");
            // Implicit parens: "sin 30" → "sin(30)". Atom = number, identifier,
            // or identifier(simple_parens). Lookahead ensures we only wrap when
            // the atom is followed by an operator/paren/end, so "sin sqrt 16"
            // iteratively becomes "sin(sqrt(16))".
            let atomPat = "(-?(?:\\d+(?:\\.\\d*)?|\\.\\d+)(?:[eE][+-]?\\d+)?|-?[a-zA-Z_]\\w*(?:\\([^()]*\\))?)";
            let funcRe = new RegExp("\\b(" + funcAlt + ")\\s+" + atomPat + "(?=\\s*([-+*/%^)]|$))", "gi");
            let prev2;
            do { prev2 = expr; expr = expr.replace(funcRe, "$1($2)"); } while (expr !== prev2);

            let transformed = transformMathExpr(expr);
            if (transformed === null) return null;
            function _fact(n) {
                n = Math.round(n);
                if (n < 0) return NaN;
                let r = 1;
                for (let i = 2; i <= n; i++) {
                    r *= i;
                    if (!isFinite(r)) return Infinity;
                }
                return r;
            }
            function _sum(a, b, fn) {
                a = Math.round(a); b = Math.round(b);
                if (!isFinite(a) || !isFinite(b) || b - a > 1e6) return NaN;
                let r = 0;
                for (let i = a; i <= b; i++) {
                    r += fn(i);
                    if (!isFinite(r)) return r > 0 ? Infinity : -Infinity;
                }
                return r;
            }
            function _prod(a, b, fn) {
                a = Math.round(a); b = Math.round(b);
                if (!isFinite(a) || !isFinite(b) || b - a > 1e6) return NaN;
                let r = 1;
                for (let i = a; i <= b; i++) {
                    r *= fn(i);
                    if (!isFinite(r)) return r > 0 ? Infinity : -Infinity;
                }
                return r;
            }
            let result = Function("_fact", "_sum", "_prod",
                '"use strict"; return (' + transformed + ')')(_fact, _sum, _prod);
            if (typeof result !== "number" || isNaN(result)) return null;
            return result;
        } catch (e) {
            return null;
        }
    }

    function formatCalcResult(n) {
        let decimals = Math.max(0, Math.min(15, Config.launcherCalculatorDecimals));
        if (Number.isInteger(n) && Math.abs(n) < 1e16)
            return n.toLocaleString("en-US");
        let s = parseFloat(n.toFixed(decimals)).toString();
        if (s.includes("e")) return s;
        let parts = s.split(".");
        let intPart = parseInt(parts[0], 10).toLocaleString("en-US");
        return parts[1] ? intPart + "." + parts[1] : intPart;
    }

    property var calcValue: {
        if (!Config.launcherCalculatorEnabled) return null;
        let q = searchText.trim();
        return isMathExpression(q) ? evaluateMath(q) : null;
    }
    property bool calcOverflow: calcValue === Infinity || calcValue === -Infinity
    property string calcDisplay: {
        if (calcValue === null) return "";
        if (calcOverflow) return calcValue < 0 ? "negative number too large to display" : "number too large to display";
        return formatCalcResult(calcValue);
    }
    property string calcRaw: (calcValue === null || calcOverflow) ? "" : String(calcValue)

    function copyCalcResult() {
        if (calcRaw === "") return;
        Quickshell.execDetached(["wl-copy", "--", calcRaw]);
        root.closing = true;
    }

    // Web search: engines are stored as "keyword|name|url" strings with "%s"
    // as the query placeholder. URLs may contain "|" so we rejoin after slot 2.
    // Engines are stored as "keyword|name|url[|icon]". No "|" allowed in any
    // field; icon is an optional basename resolved to icons/engines/<icon>.svg.
    function parsedEngines() {
        let out = [];
        for (let s of Config.launcherWebSearchEngines) {
            let parts = String(s).split("|");
            if (parts.length < 3) continue;
            out.push({
                keyword: parts[0].trim(),
                name: parts[1].trim(),
                url: parts[2].trim(),
                icon: (parts[3] ?? "").trim()
            });
        }
        return out;
    }

    property var keywordSearchMatch: {
        if (!Config.launcherWebSearchEnabled) return null;
        let q = searchText;
        let spaceIdx = q.indexOf(" ");
        if (spaceIdx <= 0) return null;
        let kw = q.substring(0, spaceIdx);
        let rest = q.substring(spaceIdx + 1).trim();
        if (!rest) return null;
        let engines = parsedEngines();
        for (let e of engines) {
            if (e.keyword.toLowerCase() === kw.toLowerCase())
                return { engine: e, query: rest };
        }
        return null;
    }

    function openSearch(engine, query) {
        if (!engine || !engine.url) return;
        let url = engine.url.replace("%s", encodeURIComponent(query));
        let cls = Config.launcherWebSearchBrowserClass;
        if (cls) {
            // Open, wait briefly for the browser to process the URL, then
            // raise/focus the window via Hyprland. Args passed positionally
            // so the URL/class don't need shell-escaping.
            Quickshell.execDetached([
                "bash", "-c",
                'xdg-open "$1" && sleep 0.3 && hyprctl dispatch focuswindow "class:$2"',
                "launcher-search", url, cls
            ]);
        } else {
            Quickshell.execDetached(["xdg-open", url]);
        }
        root.closing = true;
    }

    function getFrecencyData() {
        try {
            return JSON.parse(Config.launcherFrecencyData);
        } catch (e) {
            return {};
        }
    }

    function recordLaunch(appId) {
        let data = getFrecencyData();
        let now = Math.floor(Date.now() / 1000);
        let entry = data[appId] || { score: 0, lastLaunch: now };
        let daysSince = (now - entry.lastLaunch) / 86400;
        let decay = Math.pow(0.5, daysSince / 7);
        entry.score = entry.score * decay + 100;
        entry.lastLaunch = now;
        data[appId] = entry;
        Config.set("launcher", "frecencyData", JSON.stringify(data));
    }

    function getFrecencyScore(appId) {
        let data = getFrecencyData();
        let entry = data[appId];
        if (!entry) return 0;
        let now = Math.floor(Date.now() / 1000);
        let daysSince = (now - entry.lastLaunch) / 86400;
        let decay = Math.pow(0.5, daysSince / 7);
        return entry.score * decay;
    }

    function isPinned(appId) {
        return Config.launcherPinnedApps.indexOf(appId) >= 0;
    }

    function togglePin(appId) {
        let apps = Config.launcherPinnedApps.slice();
        let idx = apps.indexOf(appId);
        if (idx >= 0)
            apps.splice(idx, 1);
        else
            apps.push(appId);
        Config.set("launcher", "pinnedApps", apps);
    }

    property list<DesktopEntry> allApps: {
        let apps = Array.from(DesktopEntries.applications.values);
        let filtered = apps.filter(app => {
            let id = (app.id ?? "").toLowerCase();
            let name = (app.name ?? "").toLowerCase();
            for (let hidden of hiddenApps) {
                if (id.includes(hidden) || name.includes(hidden))
                    return false;
            }
            return true;
        });
        filtered.sort((a, b) => {
            let pinA = isPinned(a.id ?? "") ? 1 : 0;
            let pinB = isPinned(b.id ?? "") ? 1 : 0;
            if (pinA !== pinB) return pinB - pinA;
            if (pinA && pinB) {
                let nameA = (a.name ?? "").toLowerCase();
                let nameB = (b.name ?? "").toLowerCase();
                return nameA < nameB ? -1 : nameA > nameB ? 1 : 0;
            }
            let scoreA = getFrecencyScore(a.id ?? a.name ?? "");
            let scoreB = getFrecencyScore(b.id ?? b.name ?? "");
            if (scoreA !== scoreB) return scoreB - scoreA;
            let nameA = (a.name ?? "").toLowerCase();
            let nameB = (b.name ?? "").toLowerCase();
            return nameA < nameB ? -1 : nameA > nameB ? 1 : 0;
        });
        return filtered;
    }

    property var filteredApps: {
        let query = searchText.toLowerCase().trim();
        if (query === "") return allApps;
        // Primary: sequential + trigram
        let scored = allApps.map(app => ({ app: app, score: scoreApp(app, query) }));
        scored = scored.filter(item => item.score >= 0.1);
        if (scored.length === 0 && query.length >= 3) {
            // Fallback: Levenshtein edit distance against app names
            // Max distance threshold: 2 for short queries, 3 for longer
            let maxDist = query.length <= 4 ? 2 : 3;
            let threshold = 1 - maxDist / Math.max(query.length, 3);
            scored = allApps.map(app => ({ app: app, score: scoreAppTypo(app, query) }));
            scored = scored.filter(item => item.score >= threshold);
        }
        scored.sort((a, b) => {
            if (Math.abs(a.score - b.score) > 0.01) return b.score - a.score;
            let freqA = getFrecencyScore(a.app.id ?? a.app.name ?? "");
            let freqB = getFrecencyScore(b.app.id ?? b.app.name ?? "");
            return freqB - freqA;
        });
        return scored.map(item => item.app);
    }

    // Mixed results model: apps and web-search entries. Web-search entries
    // appear when the user types a keyword-prefixed query (hides apps) or
    // as a fallback when zero apps match a non-empty query.
    property var filteredResults: {
        if (keywordSearchMatch) {
            return [{ type: "search", engine: keywordSearchMatch.engine, query: keywordSearchMatch.query }];
        }
        let items = filteredApps.map(app => ({ type: "app", app: app }));
        let q = searchText.trim();
        if (items.length === 0 && calcValue === null && q.length > 0 && Config.launcherWebSearchEnabled) {
            for (let e of parsedEngines()) {
                items.push({ type: "search", engine: e, query: q });
            }
        }
        return items;
    }

    function toggle() {
        if (root.visible && !root.closing) {
            root.closing = true;
        } else if (!root.visible) {
            root.closing = false;
            root.visible = true;
            root.searchText = "";
        }
    }

    function launch(app) {
        recordLaunch(app.id ?? app.name ?? "");
        if (app.runInTerminal) {
            Quickshell.execDetached([Config.launcherTerminal].concat(app.command));
        } else {
            app.execute();
        }
        root.closing = true;
    }

    function activateResult(item) {
        if (!item) return;
        if (item.type === "app") root.launch(item.app);
        else if (item.type === "search") root.openSearch(item.engine, item.query);
    }

    IpcHandler {
        target: "launcher"
        function toggle(): void {
            root.toggle();
        }
    }

    GlobalShortcut {
        name: "launcherToggle"
        description: "Toggle app launcher"
        onPressed: root.toggle()
    }

    LazyLoader {
        id: launcherLoader
        active: root.visible

        PanelWindow {
            id: window

            WlrLayershell.layer: WlrLayer.Overlay
            WlrLayershell.keyboardFocus: WlrKeyboardFocus.Exclusive
            WlrLayershell.namespace: "quickshell-launcher"

            anchors {
                top: true
                left: true
                right: true
                bottom: true
            }

            color: "transparent"

            // Background overlay fade — use color alpha (not element opacity)
            // so Hyprland ignore_alpha can distinguish backdrop from panel
            Rectangle {
                id: backdrop
                anchors.fill: parent
                property real fadeIn: 0
                color: Qt.rgba(0, 0, 0, fadeIn * Config.launcherBackdropOpacity)

                Behavior on fadeIn {
                    NumberAnimation {
                        duration: Config.animLauncherFadeDuration
                        easing.type: Easing.OutCubic
                    }
                }

                MouseArea {
                    anchors.fill: parent
                    onClicked: root.toggle()
                }

                Component.onCompleted: {
                    Qt.callLater(() => {
                        backdrop.fadeIn = Qt.binding(() => root.closing ? 0 : 1);
                    });
                }
            }

            // Centered launcher container
            Rectangle {
                id: container
                anchors.centerIn: parent
                width: Config.launcherWidth
                height: Math.min(Config.launcherMaxHeight, searchBox.height + resultsView.contentHeight + 40 + (root.calcValue !== null ? Config.launcherItemHeight + 8 : 0))
                color: Theme.launcherBg
                radius: Config.launcherRadius
                border.color: Config.surface1
                border.width: 1

                scale: Config.animLauncherScaleFrom
                opacity: 0

                Behavior on scale {
                    NumberAnimation {
                        duration: Config.animLauncherScaleDuration
                        easing.type: root.closing ? Easing.InBack : Easing.OutBack
                        easing.overshoot: Config.animLauncherOvershoot
                    }
                }
                Behavior on opacity {
                    NumberAnimation {
                        duration: Config.animLauncherFadeDuration
                        easing.type: Easing.OutCubic
                    }
                }

                onOpacityChanged: {
                    if (root.closing && opacity === 0) {
                        root.visible = false;
                        root.closing = false;
                    }
                }

                Component.onCompleted: {
                    Qt.callLater(() => {
                        container.scale = Qt.binding(() => root.closing ? Config.animLauncherScaleFrom : 1.0);
                        container.opacity = Qt.binding(() => root.closing ? 0 : 1.0);
                    });
                }

                Behavior on height {
                    NumberAnimation {
                        duration: 150
                        easing.type: Easing.OutCubic
                    }
                }

                MouseArea {
                    anchors.fill: parent
                    onClicked: (event) => event.accepted = true
                }

                ColumnLayout {
                    anchors.fill: parent
                    anchors.margins: 12
                    spacing: 8

                    Quill.TextField {
                        id: searchBox
                        Layout.fillWidth: true
                        variant: "filled"
                        placeholder: "Search apps..."
                        autoFocus: root.visible
                        onTextEdited: (val) => {
                            root.searchText = val;
                            resultsView.currentIndex = 0;
                        }

                        function cycleResults(dir, wrap) {
                            let count = root.filteredResults.length;
                            if (count === 0) return;
                            resultsView.keyboardNav = true;
                            let next = resultsView.currentIndex + dir;
                            if (wrap) {
                                next = (next + count) % count;
                            } else {
                                if (next < 0) next = 0;
                                if (next > count - 1) next = count - 1;
                            }
                            resultsView.currentIndex = next;
                        }

                        Component.onCompleted: {
                            inputItem.Keys.escapePressed.connect(() => root.toggle());
                            inputItem.Keys.downPressed.connect((event) => {
                                searchBox.cycleResults(1, false);
                                event.accepted = true;
                            });
                            inputItem.Keys.upPressed.connect((event) => {
                                searchBox.cycleResults(-1, false);
                                event.accepted = true;
                            });
                            inputItem.Keys.tabPressed.connect((event) => {
                                searchBox.cycleResults(1, true);
                                event.accepted = true;
                            });
                            inputItem.Keys.backtabPressed.connect((event) => {
                                searchBox.cycleResults(-1, true);
                                event.accepted = true;
                            });
                            inputItem.Keys.returnPressed.connect((event) => {
                                if (root.calcValue !== null && Config.launcherCalculatorCopyOnEnter) {
                                    root.copyCalcResult();
                                    return;
                                }
                                if (root.filteredResults.length === 0) return;
                                let idx = Math.max(0, Math.min(resultsView.currentIndex, root.filteredResults.length - 1));
                                let item = root.filteredResults[idx];
                                if ((event.modifiers & Qt.ControlModifier) && item.type === "app")
                                    root.togglePin(item.app.id ?? "");
                                else
                                    root.activateResult(item);
                            });
                        }
                    }

                    Rectangle {
                        id: calcRow
                        Layout.fillWidth: true
                        Layout.preferredHeight: Config.launcherItemHeight
                        visible: root.calcValue !== null
                        radius: Config.launcherItemRadius
                        color: Config.surface1
                        border.color: Config.yellow
                        border.width: 1

                        RowLayout {
                            anchors.fill: parent
                            anchors.leftMargin: 12
                            anchors.rightMargin: 12
                            spacing: 12

                            IconCalculator {
                                size: Config.launcherIconSize * 0.8
                                color: Config.yellow
                                Layout.preferredWidth: Config.launcherIconSize
                                Layout.preferredHeight: Config.launcherIconSize
                                Layout.alignment: Qt.AlignVCenter
                            }

                            Text {
                                text: root.calcDisplay
                                color: Config.text
                                font.pixelSize: 16
                                font.family: Config.fontFamily
                                Layout.fillWidth: true
                                elide: Text.ElideRight
                            }

                            Text {
                                visible: !root.calcOverflow
                                text: Config.launcherCalculatorCopyOnEnter ? "⏎ copy" : "click to copy"
                                color: Config.overlay0
                                font.pixelSize: 11
                                font.family: Config.fontFamily
                            }
                        }

                        MouseArea {
                            anchors.fill: parent
                            cursorShape: Qt.PointingHandCursor
                            onClicked: root.copyCalcResult()
                        }
                    }

                    ListView {
                        id: resultsView
                        Layout.fillWidth: true
                        Layout.fillHeight: true
                        clip: true
                        spacing: 2
                        model: root.filteredResults
                        currentIndex: 0
                        property bool keyboardNav: false
                        property real lastMouseX: -1
                        property real lastMouseY: -1

                        highlightFollowsCurrentItem: false
                        onCurrentIndexChanged: {
                            if (currentItem)
                                positionViewAtIndex(currentIndex, ListView.Contain);
                        }
                        highlight: Rectangle {
                            width: resultsView.width
                            height: Config.launcherItemHeight
                            radius: Config.launcherItemRadius
                            color: Config.surface1
                            y: resultsView.currentItem ? resultsView.currentItem.y : 0
                            z: 0
                            Behavior on y {
                                NumberAnimation {
                                    duration: 150
                                    easing.type: Easing.InOutCubic
                                }
                            }
                        }

                        delegate: Rectangle {
                            id: resultItem
                            required property var modelData
                            required property int index
                            readonly property bool isApp: modelData.type === "app"
                            readonly property bool isSearch: modelData.type === "search"
                            readonly property var appData: isApp ? modelData.app : null

                            width: resultsView.width
                            height: Config.launcherItemHeight
                            radius: Config.launcherItemRadius
                            color: "transparent"
                            z: 1

                            RowLayout {
                                anchors.fill: parent
                                anchors.leftMargin: 12
                                anchors.rightMargin: 12
                                spacing: 12

                                Item {
                                    Layout.preferredWidth: Config.launcherIconSize
                                    Layout.preferredHeight: Config.launcherIconSize

                                    Image {
                                        anchors.fill: parent
                                        visible: resultItem.isApp
                                        property string _icon: resultItem.isApp ? (resultItem.appData.icon ?? "") : ""
                                        property string _primary: resultItem.isApp ? Quickshell.iconPath(_icon, "application-x-executable") : ""
                                        property string _svgFallback: "file:///usr/share/icons/hicolor/scalable/apps/" + _icon + ".svg"
                                        property string _genericFallback: Quickshell.iconPath("application-x-executable", "")
                                        source: resultItem.isApp ? (_primary !== "" ? _primary : _svgFallback) : ""
                                        sourceSize: Qt.size(Config.launcherIconSize, Config.launcherIconSize)
                                        onStatusChanged: {
                                            if (status === Image.Error && source !== _svgFallback && source !== _genericFallback)
                                                source = _svgFallback;
                                            else if (status === Image.Error && source === _svgFallback)
                                                source = _genericFallback;
                                        }
                                    }

                                    Image {
                                        id: engineIcon
                                        anchors.fill: parent
                                        visible: resultItem.isSearch && status === Image.Ready
                                        property string _iconName: resultItem.isSearch ? (resultItem.modelData.engine.icon ?? "") : ""
                                        source: _iconName !== "" ? Qt.resolvedUrl("icons/engines/" + _iconName + ".svg") : ""
                                        sourceSize: Qt.size(Config.launcherIconSize, Config.launcherIconSize)
                                        smooth: true
                                        mipmap: true
                                    }

                                    IconSearch {
                                        anchors.centerIn: parent
                                        visible: resultItem.isSearch && !engineIcon.visible
                                        size: Config.launcherIconSize * 0.7
                                        color: Config.blue
                                    }
                                }

                                Text {
                                    text: resultItem.isApp
                                        ? (resultItem.appData.name ?? "")
                                        : resultItem.isSearch
                                            ? ("Search " + resultItem.modelData.engine.name + " for \u201C" + resultItem.modelData.query + "\u201D")
                                            : ""
                                    color: Config.text
                                    font.pixelSize: 14
                                    font.family: Config.fontFamily
                                    Layout.fillWidth: true
                                    elide: Text.ElideRight
                                }

                                Text {
                                    text: resultItem.isApp
                                        ? (resultItem.appData.genericName ?? "")
                                        : resultItem.isSearch
                                            ? resultItem.modelData.engine.keyword
                                            : ""
                                    color: Config.overlay0
                                    font.pixelSize: 12
                                    font.family: Config.fontFamily
                                    elide: Text.ElideRight
                                    Layout.maximumWidth: 180
                                }

                                IconStar {
                                    visible: resultItem.isApp && root.isPinned(resultItem.appData.id ?? "")
                                    size: 14
                                    color: Config.yellow
                                    Layout.preferredWidth: visible ? 14 : 0
                                    Layout.preferredHeight: 14
                                }
                            }

                            MouseArea {
                                id: appMouse
                                anchors.fill: parent
                                hoverEnabled: true
                                acceptedButtons: Qt.LeftButton | Qt.RightButton
                                onClicked: (mouse) => {
                                    if (mouse.button === Qt.RightButton) {
                                        if (resultItem.isApp)
                                            root.togglePin(resultItem.appData.id ?? "");
                                    } else {
                                        root.activateResult(resultItem.modelData);
                                    }
                                }
                                onPositionChanged: (mouse) => {
                                    let screenX = resultItem.mapToItem(null, mouse.x, mouse.y).x;
                                    let screenY = resultItem.mapToItem(null, mouse.x, mouse.y).y;
                                    if (Math.abs(screenX - resultsView.lastMouseX) > 1 || Math.abs(screenY - resultsView.lastMouseY) > 1) {
                                        resultsView.lastMouseX = screenX;
                                        resultsView.lastMouseY = screenY;
                                        resultsView.keyboardNav = false;
                                        resultsView.currentIndex = resultItem.index;
                                    }
                                }
                                onContainsMouseChanged: {
                                    if (containsMouse && !resultsView.keyboardNav)
                                        resultsView.currentIndex = resultItem.index;
                                }
                            }
                        }

                        Keys.onReturnPressed: (event) => {
                            if (currentIndex >= 0 && currentIndex < root.filteredResults.length) {
                                let item = root.filteredResults[currentIndex];
                                if ((event.modifiers & Qt.ControlModifier) && item.type === "app")
                                    root.togglePin(item.app.id ?? "");
                                else
                                    root.activateResult(item);
                            }
                        }
                        Keys.onEscapePressed: root.toggle()
                        Keys.onUpPressed: {
                            keyboardNav = true;
                            if (currentIndex === 0)
                                searchBox.inputItem.forceActiveFocus();
                            else
                                currentIndex--;
                        }
                        Keys.onDownPressed: {
                            keyboardNav = true;
                            if (currentIndex < count - 1)
                                currentIndex++;
                        }
                        Keys.onPressed: (event) => {
                            if (event.key === Qt.Key_Tab) {
                                let n = resultsView.count;
                                if (n > 0) {
                                    resultsView.keyboardNav = true;
                                    resultsView.currentIndex = (resultsView.currentIndex + 1) % n;
                                }
                                event.accepted = true;
                            } else if (event.key === Qt.Key_Backtab) {
                                let n = resultsView.count;
                                if (n > 0) {
                                    resultsView.keyboardNav = true;
                                    resultsView.currentIndex = (resultsView.currentIndex - 1 + n) % n;
                                }
                                event.accepted = true;
                            } else if (!event.modifiers && event.text && event.text.length > 0) {
                                searchBox.inputItem.forceActiveFocus();
                                searchBox.text += event.text;
                                event.accepted = true;
                            }
                        }
                    }
                }
            }
        }
    }
}
