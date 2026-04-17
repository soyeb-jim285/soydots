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

    function findEngineByKeyword(kw) {
        if (!kw) return null;
        let lk = String(kw).toLowerCase();
        for (let e of parsedEngines()) {
            if (e.keyword.toLowerCase() === lk) return e;
        }
        return null;
    }

    // Parse the comma-separated order string into [{kind, param}] tokens.
    // Stored as a flat string so it round-trips cleanly through TOML + the
    // TextSetting in the settings dialog (we don't have a list reorder widget).
    function universalOrder() {
        let out = [];
        for (let tok of String(Config.launcherUniversalSearchOrder || "").split(",")) {
            tok = tok.trim();
            if (!tok) continue;
            let parts = tok.split(":");
            out.push({ kind: parts[0].trim(), param: (parts[1] ?? "").trim() });
        }
        return out;
    }

    function universalWants(kind) {
        if (!Config.launcherUniversalSearchEnabled) return false;
        for (let t of universalOrder()) {
            if (t.kind === kind) return true;
            // `packages` is a merged pacman+flatpak slot, so it pulls from both.
            if (t.kind === "packages" && (kind === "pacman" || kind === "flatpak")) return true;
        }
        return false;
    }

    // System actions — power/session commands surfaced as launcher results
    // when the query fuzzy-matches the name or any keyword.
    readonly property var systemActions: [
        { id: "lock",      name: "Lock",      keywords: ["lock", "lockscreen"],
          iconSource: "icons/IconLock.qml",      color: Config.blue,
          command: ["quickshell", "msg", "lockscreen", "lock"] },
        { id: "logout",    name: "Logout",    keywords: ["logout", "signout", "sign out"],
          iconSource: "icons/IconLogOut.qml",    color: Config.yellow,
          command: ["uwsm", "stop"] },
        { id: "suspend",   name: "Suspend",   keywords: ["suspend", "sleep"],
          iconSource: "icons/IconMoon.qml",      color: Config.mauve,
          command: ["systemctl", Config.idleHibernateEnabled ? "suspend-then-hibernate" : "suspend"] },
        { id: "hibernate", name: "Hibernate", keywords: ["hibernate"],
          iconSource: "icons/IconCloud.qml",     color: Config.teal,
          command: ["systemctl", "hibernate"] },
        { id: "reboot",    name: "Reboot",    keywords: ["reboot", "restart"],
          iconSource: "icons/IconRefreshCw.qml", color: Config.peach,
          command: ["systemctl", "reboot"] },
        { id: "shutdown",  name: "Shutdown",  keywords: ["shutdown", "poweroff", "power off"],
          iconSource: "icons/IconPower.qml",     color: Config.red,
          command: ["systemctl", "poweroff"] }
    ]

    function scoreSystemAction(action, query) {
        let best = fuzzyScore(query, action.name.toLowerCase());
        for (let kw of action.keywords) {
            let s = fuzzyScore(query, kw.toLowerCase());
            if (s > best) best = s;
        }
        return best;
    }

    function runSystemAction(action) {
        if (!action || !action.command) return;
        Quickshell.execDetached(action.command);
        root.closing = true;
    }

    // Shell runner: detect the configured prefix (default ">") and treat the
    // rest of the query as a command to exec via the configured shell.
    property var commandMatch: {
        if (!Config.launcherShellRunnerEnabled) return null;
        let prefix = Config.launcherShellRunnerPrefix || ">";
        if (!searchText.startsWith(prefix)) return null;
        let cmd = searchText.substring(prefix.length).replace(/^\s+/, "");
        if (!cmd) return null;
        return { command: cmd };
    }

    function runShellCommand(cmd) {
        if (!cmd) return;
        let shell = Config.launcherShellRunnerShell || "bash";
        Quickshell.execDetached([shell, "-c", cmd]);
        root.closing = true;
    }

    // URL / filesystem path detection. URLs with a scheme (http, https, file,
    // ftp, mailto) and filesystem paths (/, ~/, ./, ../) are routed straight
    // to xdg-open, which picks the right handler (browser, file manager, ...).
    property var urlPathMatch: {
        if (!Config.launcherUrlPathEnabled) return null;
        let q = searchText.trim();
        if (!q) return null;
        if (/^(https?|ftp|file|mailto):/i.test(q)) {
            return { kind: "url", target: q, display: q };
        }
        if (q.startsWith("/") || q === "~" || q.startsWith("~/")
            || q.startsWith("./") || q.startsWith("../")) {
            let expanded = q;
            if (q === "~") expanded = Quickshell.env("HOME") || q;
            else if (q.startsWith("~/")) expanded = (Quickshell.env("HOME") || "") + q.substring(1);
            return { kind: "path", target: expanded, display: q };
        }
        return null;
    }

    function openTarget(target) {
        if (!target) return;
        Quickshell.execDetached(["xdg-open", target]);
        root.closing = true;
    }

    // === Clipboard pull ====================================================
    // Prefix-triggered search over cliphist history. Cache is populated on
    // first `cb` detection per launcher session, then filtered client-side.
    property var clipboardCache: []
    property bool clipboardCacheLoaded: false

    property var clipboardMatch: {
        if (!Config.launcherClipboardEnabled) return null;
        let prefix = Config.launcherClipboardPrefix || "cb";
        if (!searchText.startsWith(prefix)) return null;
        let rest = searchText.substring(prefix.length);
        if (rest.length > 0 && !/^\s/.test(rest)) return null;
        return { filter: rest.replace(/^\s+/, "") };
    }

    property var filteredClipboard: {
        if (!clipboardMatch) return [];
        let filter = clipboardMatch.filter.toLowerCase();
        let max = Math.max(1, Config.launcherClipboardMax || 50);
        let items = filter === ""
            ? clipboardCache
            : clipboardCache.filter(it => (it.text ?? "").toLowerCase().includes(filter));
        return items.slice(0, max);
    }

    function pasteClipboard(item) {
        if (!item || !item.id) return;
        Quickshell.execDetached(["bash", "-c", "cliphist decode " + item.id + " | wl-copy"]);
        root.closing = true;
    }

    Process {
        id: clipboardRefresh
        command: ["cliphist", "list"]
        stdout: StdioCollector {
            onStreamFinished: {
                let lines = this.text.trim().split("\n");
                let items = [];
                for (let line of lines) {
                    let tabIdx = line.indexOf("\t");
                    if (tabIdx <= 0) continue;
                    let id = line.substring(0, tabIdx).trim();
                    let text = line.substring(tabIdx + 1);
                    if (text.length === 0) continue;
                    let isImage = text.startsWith("[[ binary data");
                    items.push({ id: id, text: isImage ? "Image" : text, isImage: isImage });
                }
                root.clipboardCache = items;
                root.clipboardCacheLoaded = true;
            }
        }
    }

    onClipboardMatchChanged: {
        if (clipboardMatch && !clipboardCacheLoaded && !clipboardRefresh.running) {
            clipboardRefresh.running = true;
        }
    }

    // === Emoji picker ======================================================
    // Curated ~140-entry set. Stored as "glyph|keyword1 keyword2 ..." strings
    // so each line is dense and keyword-searching is a simple substring test.
    readonly property var emojiData: [
        "\uD83D\uDE00|grinning face smile happy",
        "\uD83D\uDE03|smile happy grin joy",
        "\uD83D\uDE04|happy smile laugh joy grin",
        "\uD83D\uDE05|sweat smile grin relief",
        "\uD83D\uDE06|laugh squint happy grin",
        "\uD83D\uDE02|joy laugh cry tears",
        "\uD83E\uDD23|rofl laugh roll floor crying",
        "\uD83D\uDE0A|blush smile happy shy",
        "\uD83D\uDE42|slight smile",
        "\uD83D\uDE43|upside down silly",
        "\uD83D\uDE09|wink",
        "\uD83D\uDE0D|heart eyes love adore",
        "\uD83E\uDD70|smiling hearts love adore",
        "\uD83D\uDE18|kiss heart love",
        "\uD83D\uDE0E|cool sunglasses shades",
        "\uD83E\uDD14|thinking hmm consider",
        "\uD83E\uDD28|raised eyebrow skeptical",
        "\uD83D\uDE10|neutral face meh",
        "\uD83D\uDE11|expressionless",
        "\uD83D\uDE36|no mouth quiet",
        "\uD83D\uDE0F|smirk smug",
        "\uD83D\uDE12|unamused",
        "\uD83D\uDE22|cry sad tear",
        "\uD83D\uDE2D|sob crying loud",
        "\uD83D\uDE21|angry mad rage",
        "\uD83E\uDD2F|mind blown shocked",
        "\uD83E\uDD29|star struck amazed",
        "\uD83E\uDD73|party congrats celebrate",
        "\uD83D\uDE34|sleep tired zzz",
        "\uD83E\uDD17|hug embrace",
        "\uD83D\uDE4C|raised hands praise celebrate yay",
        "\uD83D\uDC4D|thumbs up yes good like approve",
        "\uD83D\uDC4E|thumbs down no bad dislike",
        "\uD83D\uDC4F|clap applause bravo",
        "\uD83D\uDE4F|pray thanks please",
        "\uD83D\uDC4B|wave hello hi bye",
        "\u270A|fist power",
        "\u270C|victory peace",
        "\uD83D\uDC4C|ok hand perfect",
        "\uD83E\uDD1D|handshake deal agreement",
        "\uD83E\uDD1E|fingers crossed luck hope",
        "\uD83D\uDC4A|punch fist",
        "\uD83D\uDC40|eyes look see",
        "\uD83E\uDDE0|brain mind smart",
        "\u2764|heart love red",
        "\uD83D\uDC99|blue heart love",
        "\uD83D\uDC9A|green heart love",
        "\uD83D\uDC9B|yellow heart love",
        "\uD83D\uDC9C|purple heart love",
        "\uD83D\uDDA4|black heart love",
        "\uD83E\uDD0D|white heart love",
        "\uD83D\uDC94|broken heart sad",
        "\uD83D\uDCAF|100 perfect hundred",
        "\uD83D\uDD25|fire lit hot",
        "\u2728|sparkles shiny magic",
        "\u2B50|star favorite",
        "\uD83C\uDF1F|glowing star sparkle",
        "\uD83D\uDCA1|idea lightbulb bright",
        "\u26A0|warning caution",
        "\u2705|check tick done yes success ok",
        "\u274C|cross fail no wrong error",
        "\u2753|question",
        "\u2757|exclamation alert",
        "\uD83D\uDCA5|boom explosion",
        "\uD83D\uDC80|skull dead",
        "\uD83D\uDC7B|ghost boo spooky",
        "\uD83D\uDC7D|alien ufo",
        "\uD83C\uDF83|pumpkin halloween",
        "\uD83D\uDC36|dog puppy",
        "\uD83D\uDC31|cat kitty",
        "\uD83E\uDD8A|fox",
        "\uD83D\uDC3B|bear",
        "\uD83D\uDC2F|tiger",
        "\uD83E\uDD81|lion",
        "\uD83D\uDC38|frog",
        "\uD83E\uDD84|unicorn magic",
        "\uD83D\uDC19|octopus squid",
        "\uD83D\uDC27|penguin",
        "\uD83E\uDD86|duck",
        "\uD83C\uDF4E|apple red",
        "\uD83C\uDF4C|banana yellow",
        "\uD83C\uDF55|pizza",
        "\uD83C\uDF54|burger",
        "\uD83C\uDF5F|fries chips",
        "\uD83C\uDF70|cake birthday",
        "\uD83C\uDF69|donut",
        "\uD83C\uDF6A|cookie",
        "\u2615|coffee cafe tea",
        "\uD83C\uDF7A|beer",
        "\uD83C\uDF77|wine",
        "\u26BD|soccer football",
        "\uD83C\uDFC0|basketball",
        "\uD83C\uDFBE|tennis",
        "\uD83C\uDFAE|game controller gaming",
        "\uD83C\uDFAF|dart bullseye target",
        "\uD83C\uDFB8|guitar music",
        "\uD83C\uDFB5|music note",
        "\uD83C\uDFB6|musical notes",
        "\uD83C\uDF89|party tada celebrate confetti",
        "\uD83C\uDF8A|confetti celebrate",
        "\uD83C\uDF81|gift present",
        "\uD83C\uDF82|birthday cake",
        "\uD83D\uDC51|crown king queen",
        "\uD83D\uDC8E|gem diamond",
        "\uD83D\uDCB0|money bag cash rich",
        "\uD83D\uDCB8|money flying spending",
        "\uD83D\uDE97|car vehicle",
        "\uD83D\uDE95|taxi cab",
        "\uD83D\uDEB2|bike bicycle",
        "\u2708|airplane plane flight",
        "\uD83D\uDE80|rocket launch ship",
        "\uD83C\uDFE0|home house",
        "\uD83C\uDFE2|office building",
        "\u2600|sun",
        "\uD83C\uDF19|moon crescent night",
        "\uD83C\uDF1E|sun face",
        "\u2601|cloud",
        "\uD83C\uDF27|rain cloud",
        "\u26C8|thunderstorm lightning",
        "\uD83C\uDF08|rainbow pride lgbt",
        "\u2744|snowflake cold snow",
        "\uD83D\uDCF1|phone mobile cellphone",
        "\uD83D\uDCBB|laptop computer",
        "\u2328|keyboard",
        "\uD83D\uDDA5|desktop monitor computer",
        "\uD83D\uDCF7|camera photo",
        "\uD83D\uDD0B|battery",
        "\uD83D\uDD11|key",
        "\uD83D\uDCCC|pushpin pin",
        "\uD83D\uDCCE|paperclip attach",
        "\u270F|pencil write edit",
        "\uD83D\uDCDD|memo note write",
        "\uD83D\uDCCB|clipboard list",
        "\uD83D\uDCC1|folder directory",
        "\uD83D\uDCC4|document file page",
        "\uD83D\uDD0D|search magnify find",
        "\uD83D\uDD12|lock secure",
        "\uD83D\uDD13|unlock",
        "\uD83D\uDD14|bell notification",
        "\u2709|email mail envelope",
        "\uD83D\uDCC5|calendar date",
        "\u23F0|alarm clock",
        "\u23F1|stopwatch",
        "\u26D4|no entry forbidden",
        "\uD83D\uDEAB|prohibited banned forbidden",
        "\uD83D\uDC40|eyes peek look",
        "\uD83D\uDC41|eye watch"
    ]

    property var emojiMatch: {
        if (!Config.launcherEmojiEnabled) return null;
        let prefix = Config.launcherEmojiPrefix || ":";
        if (!searchText.startsWith(prefix)) return null;
        let rest = searchText.substring(prefix.length).trim();
        return { filter: rest };
    }

    property var filteredEmoji: {
        if (!emojiMatch) return [];
        let filter = emojiMatch.filter.toLowerCase();
        let scored = [];
        for (let entry of emojiData) {
            let sep = entry.indexOf("|");
            if (sep < 0) continue;
            let glyph = entry.substring(0, sep);
            let keywords = entry.substring(sep + 1);
            let kwLower = keywords.toLowerCase();
            let score;
            if (filter === "") {
                score = 1; // no filter — show all, in order
            } else {
                // Prefer whole-word keyword matches, fall back to substring
                let words = kwLower.split(/\s+/);
                let exact = words.indexOf(filter) >= 0 ? 2 : 0;
                let prefix = 0;
                for (let w of words) { if (w.startsWith(filter)) { prefix = 1.5; break; } }
                let sub = kwLower.includes(filter) ? 1 : 0;
                score = Math.max(exact, prefix, sub);
            }
            if (score > 0) scored.push({ glyph: glyph, name: keywords, score: score });
        }
        scored.sort((a, b) => b.score - a.score);
        return scored.slice(0, 80);
    }

    function copyEmoji(glyph) {
        if (!glyph) return;
        Quickshell.execDetached(["wl-copy", "--", glyph]);
        root.closing = true;
    }

    // === Flatpak install/uninstall =========================================
    // `i <query>` searches flathub. Enter installs or removes depending on
    // current state. Install/remove runs detached via notify-send so the user
    // gets feedback after the launcher closes. Icons come from flatpak's
    // appstream cache (populated automatically when flatpak syncs metadata).
    property bool flatpakAvailable: false
    property var flatpakInstalled: ({})
    property bool flatpakInstalledLoaded: false
    property var flatpakSearchResults: []
    property string flatpakLastSearched: ""
    property bool flatpakSearching: false
    // appId → true for flatpaks verified by Flathub (publisher owns the
    // upstream domain/org). Built once from the local appstream cache.
    property var flatpakVerified: ({})

    // Ownership map for regular .desktop apps, powering the per-row
    // uninstall action. Keyed by DesktopEntry.id with values of the form
    //   { type: "flatpak", remote: "flathub" }
    //   { type: "pacman",  pkg: "firefox" }
    // Flatpak ownership is derived from `flatpakInstalled` (O(1)); pacman
    // ownership comes from a one-shot `pacman -Qo` over every .desktop in
    // the standard XDG dirs. Apps not in this map get no uninstall UI.
    property var appOwnership: ({})

    property var flatpakMatch: {
        if (!Config.launcherFlatpakEnabled || !flatpakAvailable) return null;
        let prefix = Config.launcherFlatpakPrefix || "i";
        if (!searchText.startsWith(prefix)) return null;
        let rest = searchText.substring(prefix.length);
        if (rest.length > 0 && !/^\s/.test(rest)) return null;
        return { query: rest.replace(/^\s+/, "") };
    }

    // Returns fallback chain of candidate icon URLs. Image delegate walks this
    // list via onStatusChanged until one loads, then falls back to the
    // generic package icon. User-scope first since `--user` installs land
    // there; system-scope next for pre-populated system caches.
    function flatpakIconCandidates(appId) {
        if (!appId) return [];
        let home = Quickshell.env("HOME") || "";
        let roots = [
            home + "/.local/share/flatpak/appstream/flathub/x86_64/active",
            "/var/lib/flatpak/appstream/flathub/x86_64/active"
        ];
        let sizes = ["128x128", "64x64"];
        let out = [];
        for (let r of roots)
            for (let s of sizes)
                out.push("file://" + r + "/icons/" + s + "/" + appId + ".png");
        return out;
    }

    Process {
        id: flatpakDetect
        running: true
        command: ["sh", "-c", "command -v flatpak >/dev/null 2>&1 && echo yes || echo no"]
        stdout: StdioCollector {
            onStreamFinished: {
                root.flatpakAvailable = this.text.trim() === "yes";
                if (root.flatpakAvailable && !flatpakVerifiedProcess.running)
                    flatpakVerifiedProcess.running = true;
                // Load installed apps up-front so the app-row uninstall
                // button can detect flatpak ownership (and prefix-search
                // can badge installed flatpaks without an initial delay).
                if (root.flatpakAvailable && !flatpakInstalledLoaded && !flatpakListProcess.running)
                    flatpakListProcess.running = true;
            }
        }
    }

    // Extract the set of Flathub-verified app IDs from the local appstream
    // cache. Verification lives in `<custom><value key="flathub::
    // verification::verified">true</value></custom>` per <component>. We
    // scan both user and system scope caches in one awk pass, dedupe, and
    // store as an object for O(1) lookups.
    Process {
        id: flatpakVerifiedProcess
        command: ["sh", "-c",
            "awk 'BEGIN{id=\"\";v=0} " +
            "/<component/{id=\"\";v=0} " +
            "/<id>/{if(match($0,/<id>[^<]+/))id=substr($0,RSTART+4,RLENGTH-4)} " +
            "/flathub::verification::verified\">true/{v=1} " +
            "/<\\/component>/{if(id&&v)print id; id=\"\"; v=0}' " +
            "\"$HOME\"/.local/share/flatpak/appstream/flathub/*/active/appstream.xml " +
            "/var/lib/flatpak/appstream/flathub/*/active/appstream.xml 2>/dev/null | sort -u"]
        stdout: StdioCollector {
            onStreamFinished: {
                let set = {};
                for (let line of this.text.split("\n")) {
                    line = line.trim();
                    if (line) set[line] = true;
                }
                root.flatpakVerified = set;
            }
        }
    }

    Process {
        id: flatpakListProcess
        command: ["flatpak", "list", "--app", "--columns=application,origin,branch,name"]
        stdout: StdioCollector {
            onStreamFinished: {
                let out = {};
                let own = Object.assign({}, root.appOwnership);
                for (let line of this.text.split("\n")) {
                    if (!line) continue;
                    let parts = line.split("\t");
                    if (!parts[0]) continue;
                    out[parts[0]] = {
                        remote: parts[1] || "",
                        branch: parts[2] || "",
                        name: parts[3] || parts[0]
                    };
                    // Flatpak desktop files are published under the appId,
                    // which matches DesktopEntry.id for most apps. Stamp
                    // ownership so the app row can offer uninstall.
                    own[parts[0]] = { type: "flatpak", remote: parts[1] || "flathub" };
                }
                root.flatpakInstalled = out;
                root.flatpakInstalledLoaded = true;
                root.appOwnership = own;
            }
        }
    }

    Process {
        id: flatpakSearchProcess
        stdout: StdioCollector {
            onStreamFinished: {
                let items = [];
                let text = this.text || "";
                for (let line of text.split("\n")) {
                    if (!line || line.indexOf("\t") < 0) continue;
                    if (line.indexOf("No matches found") >= 0) continue;
                    let parts = line.split("\t");
                    if (parts.length < 5) continue;
                    let appId = parts[2];
                    if (!appId) continue;
                    items.push({
                        name: parts[0] || appId,
                        summary: parts[1] || "",
                        appId: appId,
                        version: parts[3] || "",
                        remote: (parts[4] || "flathub").split(",")[0]
                    });
                }
                root.flatpakSearchResults = items.slice(0, Config.launcherFlatpakMaxResults);
                root.flatpakSearching = false;
            }
        }
        onExited: (exitCode) => {
            if (exitCode !== 0) {
                root.flatpakSearchResults = [];
                root.flatpakSearching = false;
            }
        }
    }

    // `flatpakActiveQuery` feeds the search pipeline from either the flatpak
    // prefix OR universal-search mode (when the user has no prefix and the
    // order string includes "flatpak"). One property drives one debounce,
    // so both entry paths stay consistent.
    readonly property string flatpakActiveQuery: {
        if (flatpakMatch) return (flatpakMatch.query ?? "").trim();
        if (universalSearchActive && universalWants("flatpak"))
            return searchText.trim();
        return "";
    }

    Timer {
        id: flatpakDebounce
        interval: 280
        onTriggered: {
            let q = root.flatpakActiveQuery;
            if (q.length < 2) {
                root.flatpakSearchResults = [];
                root.flatpakLastSearched = "";
                root.flatpakSearching = false;
                return;
            }
            if (q === root.flatpakLastSearched && !root.flatpakSearching) return;
            root.flatpakLastSearched = q;
            root.flatpakSearching = true;
            if (flatpakSearchProcess.running) flatpakSearchProcess.running = false;
            flatpakSearchProcess.command = [
                "flatpak", "search",
                "--columns=name,description,application,version,remotes",
                q
            ];
            flatpakSearchProcess.running = true;
        }
    }

    onFlatpakActiveQueryChanged: {
        if (flatpakActiveQuery) {
            if (!flatpakInstalledLoaded && !flatpakListProcess.running)
                flatpakListProcess.running = true;
            // Flip to "searching" the instant the query changes so the UI
            // doesn't show stale "No matches" during the debounce window
            // (the actual `flatpak search` only fires after 280ms).
            if (flatpakActiveQuery.length >= 2 && flatpakActiveQuery !== flatpakLastSearched) {
                flatpakSearchResults = [];
                flatpakSearching = true;
            }
            flatpakDebounce.restart();
        }
    }

    // Spawn a package manager install/remove in a terminal so the user sees
    // real-time progress (downloads, conflicts, build output for AUR). Script
    // stays interactive at the end via `read` so the terminal doesn't vanish
    // before the user can read the outcome — portable across kitty/alacritty/
    // ghostty et al. without relying on terminal-specific flags like --hold.
    //
    // Routes through `hyprctl dispatch exec` so Hyprland spawns the terminal
    // in *its* current-workspace context. `Quickshell.execDetached` forks
    // through our own process tree, and Hyprland then places the new window
    // on whatever workspace its internal pointer last resolved to — which
    // can diverge from the one the user is actually viewing. Letting
    // Hyprland do the spawn keeps the terminal on the focused workspace.
    //
    // --class is a unique token so a follow-up `focuswindow` can raise the
    // terminal if it didn't auto-focus. Honored by kitty/alacritty/ghostty/
    // wezterm; terminals without --class spawn fine, just no focus hop.
    function _spawnPackageTerminal(cls, script, scriptName, scriptArgs) {
        let term = Config.launcherTerminal || "kitty";
        // sh-single-quote: ' → '\''
        function shq(s) { return "'" + String(s).replace(/'/g, "'\\''") + "'"; }
        let parts = [shq(term), "--class", shq(cls), "-e", "bash", "-c", shq(script), shq(scriptName)];
        for (let a of scriptArgs) parts.push(shq(a));
        let shCmd = parts.join(" ")
            + ' & sleep 0.35 && hyprctl dispatch focuswindow ' + shq("class:" + cls)
            + ' >/dev/null 2>&1';
        Quickshell.execDetached(["hyprctl", "dispatch", "exec", shCmd]);
    }

    function flatpakInstall(item) {
        if (!item || !item.appId) return;
        let scope = Config.launcherFlatpakScope === "system" ? "--system" : "--user";
        let remote = item.remote || "flathub";
        let script =
            'printf "\\n\\033[1;34m⬇ Installing %s\\033[0m  \\033[2m(%s)\\033[0m\\n\\n" "$3" "$2"; ' +
            'if flatpak install ' + scope + ' -y "$1" "$2"; then ' +
            '  printf "\\n\\033[1;32m✓ Installed %s\\033[0m\\n" "$3"; ' +
            'else ' +
            '  printf "\\n\\033[1;31m✗ Install failed\\033[0m\\n"; ' +
            'fi; ' +
            'printf "\\n\\033[2mPress any key to close…\\033[0m"; ' +
            'read -n 1 -s -r';
        root._spawnPackageTerminal("soydots-flatpak", script, "flatpak-install", [remote, item.appId, item.name]);
        root.closing = true;
    }

    function flatpakUninstall(item) {
        if (!item || !item.appId) return;
        let scope = Config.launcherFlatpakScope === "system" ? "--system" : "--user";
        let script =
            'printf "\\n\\033[1;31m✗ Removing %s\\033[0m  \\033[2m(%s)\\033[0m\\n\\n" "$2" "$1"; ' +
            'if flatpak uninstall ' + scope + ' -y "$1"; then ' +
            '  printf "\\n\\033[1;32m✓ Removed %s\\033[0m\\n" "$2"; ' +
            'else ' +
            '  printf "\\n\\033[1;31m✗ Remove failed\\033[0m\\n"; ' +
            'fi; ' +
            'printf "\\n\\033[2mPress any key to close…\\033[0m"; ' +
            'read -n 1 -s -r';
        root._spawnPackageTerminal("soydots-flatpak", script, "flatpak-uninstall", [item.appId, item.name]);
        root.closing = true;
    }

    function activateFlatpak(entry) {
        if (!entry || !entry.item) return;
        if (entry.installed) root.flatpakUninstall(entry.item);
        else root.flatpakInstall(entry.item);
    }

    // --- pacman / AUR (via yay) ---------------------------------------
    // Mirrors the flatpak flow: yay handles repo + AUR in one pass, so we
    // don't need a separate appstream-style cache warmup. Install always
    // needs sudo, which yay itself prompts for inside the spawned terminal.
    property bool pacmanAvailable: false
    property var pacmanInstalled: ({})
    property bool pacmanInstalledLoaded: false
    property var pacmanSearchResults: []
    property string pacmanLastSearched: ""
    property bool pacmanSearching: false

    property var pacmanMatch: {
        if (!Config.launcherPacmanEnabled || !pacmanAvailable) return null;
        let prefix = Config.launcherPacmanPrefix || "p";
        if (!searchText.startsWith(prefix)) return null;
        let rest = searchText.substring(prefix.length);
        if (rest.length > 0 && !/^\s/.test(rest)) return null;
        return { query: rest.replace(/^\s+/, "") };
    }

    // Universal search: active when the user types a plain query with no
    // prefix / calc / url active. Merges configured providers in order so
    // web-search, pacman, flatpak, AI etc. can all appear alongside apps.
    readonly property bool universalSearchActive:
        Config.launcherUniversalSearchEnabled
        && searchText.trim().length > 0
        && !commandMatch
        && !emojiMatch
        && !clipboardMatch
        && !pacmanMatch
        && !flatpakMatch
        && !keywordSearchMatch
        && calcValue === null
        && !urlPathMatch

    Process {
        id: pacmanDetect
        running: true
        command: ["sh", "-c", "command -v yay >/dev/null 2>&1 && echo yes || echo no"]
        stdout: StdioCollector {
            onStreamFinished: {
                root.pacmanAvailable = this.text.trim() === "yes";
                // Once pacman is confirmed present, scan ownership of all
                // installed .desktop files so the per-row uninstall button
                // knows which apps we can safely remove via yay -Rns.
                if (root.pacmanAvailable && !appOwnershipProcess.running)
                    appOwnershipProcess.running = true;
                // Also kick the installed-apps list so prefix-search UI
                // can badge installed packages on first keystroke.
                if (root.pacmanAvailable && !pacmanInstalledLoaded && !pacmanListProcess.running)
                    pacmanListProcess.running = true;
            }
        }
    }

    // `pacman -Qe` = explicitly installed (user-requested) packages. Skips
    // the ~1000 dependencies that would otherwise drown the empty-prefix view.
    Process {
        id: pacmanListProcess
        command: ["pacman", "-Qe"]
        stdout: StdioCollector {
            onStreamFinished: {
                let out = {};
                for (let line of this.text.split("\n")) {
                    if (!line) continue;
                    let parts = line.split(/\s+/);
                    if (!parts[0]) continue;
                    out[parts[0]] = { version: parts[1] || "" };
                }
                root.pacmanInstalled = out;
                root.pacmanInstalledLoaded = true;
            }
        }
    }

    // Map DesktopEntry.id → owning pacman/AUR package by batch-querying
    // every .desktop file in the standard XDG dirs. One fork, one parse,
    // populates appOwnership with {type:"pacman", pkg:...}. Unowned files
    // (manual installs, flatpak exports already handled, AppImages) simply
    // don't appear in the map, so their app rows show no uninstall button.
    Process {
        id: appOwnershipProcess
        command: ["sh", "-c",
            "find /usr/share/applications \"$HOME/.local/share/applications\" " +
            "-maxdepth 1 -name '*.desktop' -print0 2>/dev/null | " +
            "xargs -0 --no-run-if-empty pacman -Qo 2>/dev/null | " +
            "awk '/is owned by/{n=split($1,a,\"/\"); id=a[n]; sub(/\\.desktop$/,\"\",id); print id\"\\t\"$5}'"]
        stdout: StdioCollector {
            onStreamFinished: {
                let own = Object.assign({}, root.appOwnership);
                for (let line of this.text.split("\n")) {
                    if (!line) continue;
                    let parts = line.split("\t");
                    if (parts.length < 2 || !parts[0] || !parts[1]) continue;
                    // Don't clobber a flatpak entry if both happened to
                    // match (shouldn't, but be defensive).
                    if (own[parts[0]] && own[parts[0]].type === "flatpak") continue;
                    own[parts[0]] = { type: "pacman", pkg: parts[1] };
                }
                root.appOwnership = own;
            }
        }
    }

    // Unified ranking for pacman (repo + AUR) and flatpak results so they
    // can be merged into one list. Origin-blind — the user asked for the
    // top N regardless of extra/core/aur/flathub. Name matches outrank
    // description-only matches; exact/prefix matches get additive boosts.
    //
    // Multi-word queries: strip whitespace from the query and hyphens/
    // underscores from the name before comparing. Package names use
    // kebab/snake case ("helium-browser-bin"), so "helium browser" must
    // match across the separator to score correctly. fuzzyScore already
    // rewards word boundaries in the raw name, so we keep both paths.
    function scorePackage(item, query, kind) {
        let q = (query || "").toLowerCase().replace(/\s+/g, "");
        if (!q) return 0;
        let name = (item.name || "").toLowerCase();
        let desc = (kind === "flatpak" ? (item.summary || "") : (item.desc || "")).toLowerCase();
        let nameCompact = name.replace(/[-_]/g, "");
        let score = root.fuzzyScore(q, name) * 1.0
                  + root.fuzzyScore(q, desc) * 0.15;
        if (nameCompact === q) score += 2.5;
        else if (nameCompact.startsWith(q)) score += 1.2;
        else if (nameCompact.indexOf(q) >= 0) score += 0.5;

        // AUR popularity: log-scaled so the boost stays bounded (≈0.6 at
        // 10k votes). Kept below the exact/prefix name boosts so match
        // quality still dominates — this only tiebreaks when two packages
        // score similarly on text, e.g. picking the 500-vote canonical
        // package over a 0-vote fork with the same name shape.
        if (kind === "pacman" && item.repo === "aur" && typeof item.votes === "number")
            score += Math.log10(item.votes + 1) * 0.15;

        // Small penalty for AUR packages flagged out-of-date — usually
        // abandoned forks or lagging behind upstream.
        if (kind === "pacman" && item.outOfDate) score -= 0.3;

        return score;
    }

    function scorePacman(item, query) {
        return scorePackage(item, query, "pacman");
    }

    // yay -Ss emits a two-line format per result:
    //   repo/name version [(size)] [(votes pop)] [...] [[installed]]
    //       description (indented)
    // We parse the header line and grab the following indented line as desc.
    Process {
        id: pacmanSearchProcess
        stdout: StdioCollector {
            onStreamFinished: {
                let items = [];
                let lines = (this.text || "").split("\n");
                for (let i = 0; i < lines.length; i++) {
                    let line = lines[i];
                    if (!line || /^\s/.test(line)) continue;
                    let m = line.match(/^([a-zA-Z0-9_.+-]+)\/(\S+)\s+(\S+)(.*)$/);
                    if (!m) continue;
                    let repo = m[1], name = m[2], version = m[3], rest = m[4];
                    let installed = /\[installed/.test(rest);
                    // AUR-only metadata: yay appends "(+<votes> <popularity>)"
                    // after the version for AUR entries. Popularity is AUR's
                    // decay-weighted install estimate; votes is a raw count.
                    let voteMatch = rest.match(/\(\+(\d+)\s+([\d.]+)\)/);
                    let votes = voteMatch ? parseInt(voteMatch[1]) : null;
                    let popularity = voteMatch ? parseFloat(voteMatch[2]) : null;
                    let outOfDate = /\(Out-of-date/.test(rest);
                    let desc = "";
                    if (i + 1 < lines.length && /^\s/.test(lines[i + 1])) {
                        desc = lines[i + 1].trim();
                        i++;
                    }
                    items.push({
                        repo: repo, name: name, version: version, desc: desc,
                        installed: installed, votes: votes, popularity: popularity,
                        outOfDate: outOfDate
                    });
                }
                let q = root.pacmanLastSearched;
                let scored = items.map(it => ({ item: it, score: root.scorePacman(it, q) }));
                scored.sort((a, b) => b.score - a.score);
                root.pacmanSearchResults = scored
                    .slice(0, Config.launcherPacmanMaxResults)
                    .map(s => s.item);
                root.pacmanSearching = false;
            }
        }
        onExited: (exitCode) => {
            if (exitCode !== 0) {
                root.pacmanSearchResults = [];
                root.pacmanSearching = false;
            }
        }
    }

    // Same pattern as flatpakActiveQuery: drive the pacman pipeline from
    // prefix OR universal-search mode. yay -Ss hits the AUR RPC so the
    // debounce matters; we still gate at 2+ chars before spawning.
    readonly property string pacmanActiveQuery: {
        if (pacmanMatch) return (pacmanMatch.query ?? "").trim();
        if (universalSearchActive && universalWants("pacman"))
            return searchText.trim();
        return "";
    }

    Timer {
        id: pacmanDebounce
        interval: 280
        onTriggered: {
            let q = root.pacmanActiveQuery;
            if (q.length < 2) {
                root.pacmanSearchResults = [];
                root.pacmanLastSearched = "";
                root.pacmanSearching = false;
                return;
            }
            if (q === root.pacmanLastSearched && !root.pacmanSearching) return;
            root.pacmanLastSearched = q;
            root.pacmanSearching = true;
            if (pacmanSearchProcess.running) pacmanSearchProcess.running = false;
            // Split on whitespace so yay ANDs the terms ("helium browser"
            // → matches packages with both words). Passed as one arg, yay
            // treats it as a literal regex with a space and returns nothing.
            let terms = q.split(/\s+/).filter(s => s.length > 0);
            pacmanSearchProcess.command = ["yay", "-Ss"].concat(terms);
            pacmanSearchProcess.running = true;
        }
    }

    onPacmanActiveQueryChanged: {
        if (pacmanActiveQuery) {
            if (!pacmanInstalledLoaded && !pacmanListProcess.running)
                pacmanListProcess.running = true;
            if (pacmanActiveQuery.length >= 2 && pacmanActiveQuery !== pacmanLastSearched) {
                pacmanSearchResults = [];
                pacmanSearching = true;
            }
            pacmanDebounce.restart();
        }
    }

    function pacmanInstall(item) {
        if (!item || !item.name) return;
        // yay runs as the user and elevates via sudo when it hits pacman;
        // --needed short-circuits if already up-to-date (defensive — the
        // UI routes installed packages to the remove path).
        let script =
            'printf "\\n\\033[1;34m⬇ Installing %s\\033[0m  \\033[2m(%s)\\033[0m\\n\\n" "$1" "$2"; ' +
            'if yay -S --needed "$1"; then ' +
            '  printf "\\n\\033[1;32m✓ Installed %s\\033[0m\\n" "$1"; ' +
            'else ' +
            '  printf "\\n\\033[1;31m✗ Install failed\\033[0m\\n"; ' +
            'fi; ' +
            'printf "\\n\\033[2mPress any key to close…\\033[0m"; ' +
            'read -n 1 -s -r';
        let tag = item.repo ? (item.repo + " · " + (item.desc || "")) : (item.desc || "");
        root._spawnPackageTerminal("soydots-pacman", script, "pacman-install", [item.name, tag]);
        root.closing = true;
    }

    function pacmanUninstall(item) {
        if (!item || !item.name) return;
        // -Rns: remove + unused deps + configs. Refused by pacman if the
        // package is a dependency of something else, which is visible in
        // the terminal.
        let script =
            'printf "\\n\\033[1;31m✗ Removing %s\\033[0m\\n\\n" "$1"; ' +
            'if yay -Rns "$1"; then ' +
            '  printf "\\n\\033[1;32m✓ Removed %s\\033[0m\\n" "$1"; ' +
            'else ' +
            '  printf "\\n\\033[1;31m✗ Remove failed\\033[0m\\n"; ' +
            'fi; ' +
            'printf "\\n\\033[2mPress any key to close…\\033[0m"; ' +
            'read -n 1 -s -r';
        root._spawnPackageTerminal("soydots-pacman", script, "pacman-remove", [item.name]);
        root.closing = true;
    }

    // Resolve ownership for a DesktopEntry and dispatch to the right
    // uninstall flow. Returns true if an uninstall was triggered, false
    // if we couldn't identify the owning package (no button/shortcut
    // should be shown for those rows in the first place).
    function uninstallApp(app) {
        if (!app) return false;
        let id = app.id ?? "";
        let own = appOwnership[id];
        if (!own) return false;
        if (own.type === "flatpak") {
            let info = flatpakInstalled[id] || {};
            root.flatpakUninstall({
                appId: id,
                name: info.name || app.name || id,
                remote: info.remote || own.remote || "flathub"
            });
            return true;
        }
        if (own.type === "pacman") {
            root.pacmanUninstall({ name: own.pkg });
            return true;
        }
        return false;
    }

    function activatePacman(entry) {
        if (!entry || !entry.item) return;
        if (entry.installed) root.pacmanUninstall(entry.item);
        else root.pacmanInstall(entry.item);
    }

    function openFlathubPage(appId) {
        if (!appId) return;
        Quickshell.execDetached(["xdg-open", "https://flathub.org/apps/" + appId]);
        root.closing = true;
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

    // Mixed results model: apps, system actions, and web-search entries.
    // Web-search keyword mode replaces the list; otherwise strongly-matching
    // system actions appear at the top, followed by apps, followed (only
    // when apps are empty) by web-search fallback entries.
    property var filteredResults: {
        if (commandMatch) {
            return [{ type: "command", command: commandMatch.command }];
        }
        if (emojiMatch) {
            return filteredEmoji.map(e => ({ type: "emoji", glyph: e.glyph, name: e.name }));
        }
        if (clipboardMatch) {
            if (!clipboardCacheLoaded) return [];
            return filteredClipboard.map(c => ({ type: "clipboard", clip: c }));
        }
        if (pacmanMatch) {
            if (!pacmanInstalledLoaded)
                return [{ type: "pacmanInfo", message: "Loading installed packages…" }];
            let q = pacmanMatch.query.trim();
            if (q === "") {
                let items = [];
                for (let name in pacmanInstalled) {
                    items.push({
                        type: "pacman",
                        installed: true,
                        item: {
                            name: name,
                            version: pacmanInstalled[name].version || "",
                            repo: "installed",
                            desc: ""
                        }
                    });
                }
                if (items.length === 0)
                    return [{ type: "pacmanInfo", message: "Type to search pacman + AUR (e.g. " + Config.launcherPacmanPrefix + " steam)" }];
                return items;
            }
            if (q.length < 2)
                return [{ type: "pacmanInfo", message: "Keep typing…" }];
            if (pacmanSearching || q !== pacmanLastSearched)
                return [{ type: "pacmanInfo", message: "Searching pacman + AUR…" }];
            if (pacmanSearchResults.length === 0)
                return [{ type: "pacmanInfo", message: "No package matches for \u201C" + q + "\u201D" }];
            return pacmanSearchResults.map(item => ({
                type: "pacman",
                installed: item.installed || !!pacmanInstalled[item.name],
                item: item
            }));
        }
        if (flatpakMatch) {
            if (!flatpakInstalledLoaded)
                return [{ type: "flatpakInfo", message: "Loading flatpak apps…" }];
            let q = flatpakMatch.query.trim();
            if (q === "") {
                // Empty query inside flatpak mode: list installed apps for quick removal
                let items = [];
                for (let appId in flatpakInstalled) {
                    let info = flatpakInstalled[appId];
                    items.push({
                        type: "flatpak",
                        installed: true,
                        item: {
                            name: info.name || appId,
                            summary: "Installed",
                            appId: appId,
                            version: "",
                            remote: info.remote || "flathub"
                        }
                    });
                }
                if (items.length === 0)
                    return [{ type: "flatpakInfo", message: "Type to search flathub (e.g. " + Config.launcherFlatpakPrefix + " firefox)" }];
                return items;
            }
            if (q.length < 2)
                return [{ type: "flatpakInfo", message: "Keep typing…" }];
            // "Searching" if the process is running OR the current query
            // hasn't been dispatched yet (debounce window / query changed
            // but stdout hasn't landed). Gates against a "No matches" flash.
            if (flatpakSearching || q !== flatpakLastSearched)
                return [{ type: "flatpakInfo", message: "Searching flathub…" }];
            if (flatpakSearchResults.length === 0)
                return [{ type: "flatpakInfo", message: "No flathub matches for \u201C" + q + "\u201D" }];
            return flatpakSearchResults.map(item => ({
                type: "flatpak",
                installed: !!flatpakInstalled[item.appId],
                item: item
            }));
        }
        if (keywordSearchMatch) {
            return [{ type: "search", engine: keywordSearchMatch.engine, query: keywordSearchMatch.query }];
        }
        // URL / path takes precedence over apps but only when it's not being
        // shadowed by an active calc expression (e.g. "/sin 30").
        if (urlPathMatch && calcValue === null) {
            return [{ type: urlPathMatch.kind, target: urlPathMatch.target, display: urlPathMatch.display }];
        }

        // Universal search: merge configured providers in order when the
        // user types a plain query. Pacman/flatpak results appear as soon
        // as yay/flatpak stdout lands (the search ran async via the same
        // debounce the prefix mode uses). If a provider hasn't answered
        // yet for the current query it's just skipped — items grow in as
        // they arrive, instead of a jarring "Searching…" stall.
        if (universalSearchActive) {
            let uq = searchText.trim();
            let items = [];
            for (let tok of universalOrder()) {
                if (tok.kind === "web") {
                    let eng = findEngineByKeyword(tok.param);
                    if (eng) items.push({ type: "search", engine: eng, query: uq });
                } else if (tok.kind === "pacman") {
                    if (!pacmanAvailable) continue;
                    // Debounce only searches at 2+ chars — don't hold a
                    // "Searching…" slot for a query that will never run.
                    if (uq.length < 2) continue;
                    if (pacmanSearching || uq !== pacmanLastSearched) {
                        // Hold the slot so the layout doesn't jump when
                        // pacman stdout lands after apps have already rendered.
                        items.push({ type: "pacmanInfo", message: "Searching pacman + AUR…" });
                        continue;
                    }
                    let n = parseInt(tok.param) || 3;
                    for (let pac of pacmanSearchResults.slice(0, n)) {
                        items.push({
                            type: "pacman",
                            installed: pac.installed || !!pacmanInstalled[pac.name],
                            item: pac
                        });
                    }
                } else if (tok.kind === "flatpak") {
                    if (!flatpakAvailable) continue;
                    if (uq.length < 2) continue;
                    if (flatpakSearching || uq !== flatpakLastSearched) {
                        items.push({ type: "flatpakInfo", message: "Searching flathub…" });
                        continue;
                    }
                    let n = parseInt(tok.param) || 3;
                    for (let fp of flatpakSearchResults.slice(0, n)) {
                        items.push({
                            type: "flatpak",
                            installed: !!flatpakInstalled[fp.appId],
                            item: fp
                        });
                    }
                } else if (tok.kind === "packages") {
                    // Merged pacman + flatpak slot: rescore both with the
                    // same algorithm, sort by score, show top N regardless
                    // of origin. Fill as each backend's stdout lands, so
                    // the UI doesn't block on the slower of the two.
                    if (!pacmanAvailable && !flatpakAvailable) continue;
                    if (uq.length < 2) continue;
                    let n = parseInt(tok.param) || 6;
                    let pacReady = pacmanAvailable && !pacmanSearching && uq === pacmanLastSearched;
                    let fpReady = flatpakAvailable && !flatpakSearching && uq === flatpakLastSearched;
                    let pacPending = pacmanAvailable && !pacReady;
                    let fpPending = flatpakAvailable && !fpReady;
                    if (!pacReady && !fpReady) {
                        items.push({ type: "pacmanInfo", message: "Searching packages…" });
                        continue;
                    }
                    let merged = [];
                    if (pacReady)
                        for (let p of pacmanSearchResults)
                            merged.push({ kind: "pacman", item: p, score: scorePackage(p, uq, "pacman") });
                    if (fpReady)
                        for (let f of flatpakSearchResults)
                            merged.push({ kind: "flatpak", item: f, score: scorePackage(f, uq, "flatpak") });
                    merged.sort((a, b) => b.score - a.score);
                    for (let m of merged.slice(0, n)) {
                        if (m.kind === "pacman") {
                            items.push({
                                type: "pacman",
                                installed: m.item.installed || !!pacmanInstalled[m.item.name],
                                item: m.item
                            });
                        } else {
                            items.push({
                                type: "flatpak",
                                installed: !!flatpakInstalled[m.item.appId],
                                item: m.item
                            });
                        }
                    }
                    if (pacPending || fpPending)
                        items.push({ type: "pacmanInfo", message: "Searching packages…" });
                } else if (tok.kind === "apps") {
                    let n = parseInt(tok.param);
                    let list = (n && n > 0) ? filteredApps.slice(0, n) : filteredApps;
                    for (let app of list) items.push({ type: "app", app: app });
                } else if (tok.kind === "systemActions") {
                    if (!Config.launcherSystemActionsEnabled) continue;
                    let sys = [];
                    for (let a of systemActions) {
                        let s = scoreSystemAction(a, uq.toLowerCase());
                        if (s >= 0.5) sys.push({ action: a, score: s });
                    }
                    sys.sort((a, b) => b.score - a.score);
                    for (let s of sys) items.push({ type: "system", action: s.action });
                }
            }
            return items;
        }

        // Legacy fallback (universal search disabled): system actions then
        // apps, with web-search only when the query matches nothing.
        let q = searchText.trim();
        let items = [];
        if (q.length > 0 && Config.launcherSystemActionsEnabled) {
            let sys = [];
            for (let a of systemActions) {
                let s = scoreSystemAction(a, q.toLowerCase());
                if (s >= 0.5) sys.push({ action: a, score: s });
            }
            sys.sort((a, b) => b.score - a.score);
            for (let s of sys) items.push({ type: "system", action: s.action });
        }
        for (let app of filteredApps) items.push({ type: "app", app: app });
        if (filteredApps.length === 0 && items.length === 0 && calcValue === null
            && q.length > 0 && Config.launcherWebSearchEnabled) {
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
            root.clipboardCacheLoaded = false;
            root.clipboardCache = [];
            root.flatpakInstalledLoaded = false;
            root.flatpakInstalled = ({});
            root.flatpakSearchResults = [];
            root.flatpakLastSearched = "";
            root.flatpakSearching = false;
            root.pacmanInstalledLoaded = false;
            root.pacmanInstalled = ({});
            root.pacmanSearchResults = [];
            root.pacmanLastSearched = "";
            root.pacmanSearching = false;
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
        else if (item.type === "system") root.runSystemAction(item.action);
        else if (item.type === "command") root.runShellCommand(item.command);
        else if (item.type === "url" || item.type === "path") root.openTarget(item.target);
        else if (item.type === "clipboard") root.pasteClipboard(item.clip);
        else if (item.type === "emoji") root.copyEmoji(item.glyph);
        else if (item.type === "flatpak") root.activateFlatpak(item);
        else if (item.type === "pacman") root.activatePacman(item);
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
                                let ctrl = !!(event.modifiers & Qt.ControlModifier);
                                if (ctrl && item.type === "app")
                                    root.togglePin(item.app.id ?? "");
                                else if (ctrl && item.type === "flatpak")
                                    root.openFlathubPage(item.item.appId);
                                else
                                    root.activateResult(item);
                            });
                            // Ctrl+Shift+Backspace on the highlighted app
                            // row → uninstall. Only fires when ownership
                            // is known (flatpak or pacman/AUR); silently
                            // no-op otherwise so we don't delete the last
                            // char of the query as a side effect.
                            inputItem.Keys.pressed.connect((event) => {
                                if (event.key !== Qt.Key_Backspace) return;
                                if (!(event.modifiers & Qt.ControlModifier)) return;
                                if (!(event.modifiers & Qt.ShiftModifier)) return;
                                if (root.filteredResults.length === 0) return;
                                let idx = Math.max(0, Math.min(resultsView.currentIndex, root.filteredResults.length - 1));
                                let item = root.filteredResults[idx];
                                if (item.type !== "app") return;
                                if (root.uninstallApp(item.app)) event.accepted = true;
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
                            readonly property bool isSystem: modelData.type === "system"
                            readonly property bool isCommand: modelData.type === "command"
                            readonly property bool isUrl: modelData.type === "url"
                            readonly property bool isPath: modelData.type === "path"
                            readonly property bool isClipboard: modelData.type === "clipboard"
                            readonly property bool isEmoji: modelData.type === "emoji"
                            readonly property bool isFlatpak: modelData.type === "flatpak"
                            readonly property bool isFlatpakInfo: modelData.type === "flatpakInfo"
                            readonly property bool isPacman: modelData.type === "pacman"
                            readonly property bool isPacmanInfo: modelData.type === "pacmanInfo"
                            readonly property var appData: isApp ? modelData.app : null
                            readonly property var sysAction: isSystem ? modelData.action : null
                            readonly property var flatpakItem: isFlatpak ? modelData.item : null
                            readonly property bool flatpakInstalledState: isFlatpak ? modelData.installed : false
                            readonly property var pacmanItem: isPacman ? modelData.item : null
                            readonly property bool pacmanInstalledState: isPacman ? modelData.installed : false
                            readonly property bool isPacmanAur: isPacman && pacmanItem && pacmanItem.repo === "aur"

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

                                    Loader {
                                        id: sysIconLoader
                                        anchors.centerIn: parent
                                        visible: resultItem.isSystem
                                        source: resultItem.isSystem ? resultItem.sysAction.iconSource : ""
                                        onLoaded: {
                                            item.size = Config.launcherIconSize * 0.75;
                                            item.color = resultItem.sysAction.color;
                                        }
                                    }

                                    IconTerminal {
                                        anchors.centerIn: parent
                                        visible: resultItem.isCommand
                                        size: Config.launcherIconSize * 0.75
                                        color: Config.green
                                    }

                                    IconExternalLink {
                                        anchors.centerIn: parent
                                        visible: resultItem.isUrl
                                        size: Config.launcherIconSize * 0.75
                                        color: Config.blue
                                    }

                                    IconFolder {
                                        anchors.centerIn: parent
                                        visible: resultItem.isPath
                                        size: Config.launcherIconSize * 0.75
                                        color: Config.peach
                                    }

                                    IconClipboard {
                                        anchors.centerIn: parent
                                        visible: resultItem.isClipboard
                                        size: Config.launcherIconSize * 0.75
                                        color: Config.mauve
                                    }

                                    Text {
                                        anchors.centerIn: parent
                                        visible: resultItem.isEmoji
                                        text: resultItem.isEmoji ? modelData.glyph : ""
                                        font.pixelSize: Config.launcherIconSize * 0.9
                                        // No family — let Qt pick up the installed
                                        // emoji font via fontconfig's fallback chain.
                                    }

                                    // Flatpak appstream icon with multi-path fallback.
                                    // Direct source assignment (not binding) so the fallback
                                    // cascade doesn't trip QML's binding-loop detector.
                                    Image {
                                        id: flatpakIcon
                                        anchors.fill: parent
                                        visible: resultItem.isFlatpak && status === Image.Ready
                                        property var _candidates: resultItem.isFlatpak
                                            ? root.flatpakIconCandidates(resultItem.flatpakItem.appId)
                                            : []
                                        property int _idx: 0
                                        sourceSize: Qt.size(Config.launcherIconSize, Config.launcherIconSize)
                                        smooth: true
                                        Component.onCompleted: {
                                            if (_candidates.length > 0) source = _candidates[0];
                                        }
                                        onStatusChanged: {
                                            if (status === Image.Error && _idx + 1 < _candidates.length) {
                                                _idx++;
                                                source = _candidates[_idx];
                                            }
                                        }
                                    }

                                    // Installed-state overlay: small green dot at bottom-right
                                    Rectangle {
                                        visible: resultItem.isFlatpak && resultItem.flatpakInstalledState
                                        width: 9; height: 9; radius: 5
                                        color: Config.green
                                        border.color: Theme.launcherBg
                                        border.width: 1.5
                                        anchors.right: parent.right
                                        anchors.bottom: parent.bottom
                                        anchors.rightMargin: -2
                                        anchors.bottomMargin: -2
                                        z: 2
                                    }

                                    IconPackageOpen {
                                        anchors.centerIn: parent
                                        visible: (resultItem.isFlatpak && !flatpakIcon.visible)
                                            || resultItem.isFlatpakInfo
                                        size: Config.launcherIconSize * 0.78
                                        color: resultItem.isFlatpakInfo ? Config.overlay0
                                            : (resultItem.flatpakInstalledState ? Config.green : Config.blue)
                                    }

                                    // Official repo (core/extra/multilib/...): package box
                                    // in peach. Info-state rows (Loading/Searching/No matches)
                                    // also fall here since we don't know repo vs AUR yet.
                                    IconPackageOpen {
                                        anchors.centerIn: parent
                                        visible: (resultItem.isPacman && !resultItem.isPacmanAur)
                                            || resultItem.isPacmanInfo
                                        size: Config.launcherIconSize * 0.78
                                        color: resultItem.isPacmanInfo ? Config.overlay0
                                            : (resultItem.pacmanInstalledState ? Config.green : Config.peach)
                                    }

                                    // AUR: user-submitted PKGBUILD archive — distinct shape
                                    // (folder-archive) and mauve tint so AUR reads different
                                    // from official repo without needing to read the repo label.
                                    IconFolderArchive {
                                        anchors.centerIn: parent
                                        visible: resultItem.isPacmanAur
                                        size: Config.launcherIconSize * 0.78
                                        color: resultItem.pacmanInstalledState ? Config.green : Config.mauve
                                    }

                                    Rectangle {
                                        visible: resultItem.isPacman && resultItem.pacmanInstalledState
                                        width: 9; height: 9; radius: 5
                                        color: Config.green
                                        border.color: Theme.launcherBg
                                        border.width: 1.5
                                        anchors.right: parent.right
                                        anchors.bottom: parent.bottom
                                        anchors.rightMargin: -2
                                        anchors.bottomMargin: -2
                                        z: 2
                                    }
                                }

                                Text {
                                    text: resultItem.isApp
                                        ? (resultItem.appData.name ?? "")
                                        : resultItem.isSearch
                                            ? ("Search " + resultItem.modelData.engine.name + " for \u201C" + resultItem.modelData.query + "\u201D")
                                            : resultItem.isSystem
                                                ? resultItem.sysAction.name
                                                : resultItem.isCommand
                                                    ? resultItem.modelData.command
                                                    : (resultItem.isUrl || resultItem.isPath)
                                                        ? resultItem.modelData.display
                                                        : resultItem.isClipboard
                                                            ? (resultItem.modelData.clip.text ?? "")
                                                            : resultItem.isEmoji
                                                                ? resultItem.modelData.name
                                                                : resultItem.isFlatpak
                                                                    ? (resultItem.flatpakItem.name
                                                                        + (root.flatpakVerified[resultItem.flatpakItem.appId] ? " \u2713" : "")
                                                                        + (resultItem.flatpakItem.summary
                                                                            ? "  \u00B7  " + resultItem.flatpakItem.summary : ""))
                                                                    : resultItem.isFlatpakInfo
                                                                        ? resultItem.modelData.message
                                                                        : resultItem.isPacman
                                                                            ? (resultItem.pacmanItem.name
                                                                                + "  \u00B7  " + resultItem.pacmanItem.repo
                                                                                + (resultItem.pacmanItem.repo === "aur" && resultItem.pacmanItem.votes != null
                                                                                    ? "  \u00B7  \u2191" + resultItem.pacmanItem.votes : "")
                                                                                + (resultItem.pacmanItem.outOfDate
                                                                                    ? "  \u00B7  \u26A0 out-of-date" : "")
                                                                                + (resultItem.pacmanItem.desc
                                                                                    ? "  \u00B7  " + resultItem.pacmanItem.desc : ""))
                                                                            : resultItem.isPacmanInfo
                                                                                ? resultItem.modelData.message
                                                                                : ""
                                    color: resultItem.isSystem ? resultItem.sysAction.color
                                        : resultItem.isCommand ? Config.green
                                        : resultItem.isUrl ? Config.blue
                                        : resultItem.isPath ? Config.peach
                                        : resultItem.isClipboard ? Config.text
                                        : resultItem.isFlatpakInfo ? Config.overlay0
                                        : resultItem.isPacmanInfo ? Config.overlay0
                                        : Config.text
                                    font.pixelSize: 14
                                    font.family: Config.fontFamily
                                    font.bold: resultItem.isSystem
                                    font.italic: resultItem.isFlatpakInfo || resultItem.isPacmanInfo
                                    Layout.fillWidth: true
                                    elide: Text.ElideRight
                                    maximumLineCount: 1
                                }

                                Text {
                                    text: resultItem.isApp
                                        ? (resultItem.appData.genericName ?? "")
                                        : resultItem.isSearch
                                            ? resultItem.modelData.engine.keyword
                                            : resultItem.isSystem
                                                ? "System"
                                                : resultItem.isCommand
                                                    ? ("⏎ run via " + Config.launcherShellRunnerShell)
                                                    : resultItem.isUrl
                                                        ? "Open in browser"
                                                        : resultItem.isPath
                                                            ? "Open path"
                                                            : resultItem.isClipboard
                                                                ? (resultItem.modelData.clip.isImage ? "Image" : "Clipboard")
                                                                : resultItem.isEmoji
                                                                    ? "Emoji"
                                                                    : resultItem.isFlatpak
                                                                        ? (resultItem.flatpakInstalledState ? "\u23CE Remove" : "\u23CE Install")
                                                                        : resultItem.isPacman
                                                                            ? (resultItem.pacmanInstalledState ? "\u23CE Remove" : "\u23CE Install")
                                                                            : ""
                                    color: resultItem.isFlatpak
                                        ? (resultItem.flatpakInstalledState ? Config.red : Config.blue)
                                        : resultItem.isPacman
                                            ? (resultItem.pacmanInstalledState ? Config.red
                                                : (resultItem.isPacmanAur ? Config.mauve : Config.peach))
                                            : Config.overlay0
                                    font.pixelSize: 12
                                    font.family: Config.fontFamily
                                    font.bold: resultItem.isFlatpak || resultItem.isPacman
                                    elide: Text.ElideRight
                                    Layout.maximumWidth: 180
                                }

                                // Secondary action hint (flatpak only). Surfaces the
                                // Ctrl+Enter shortcut to open the Flathub page, but only
                                // for the currently-selected row — keeps unselected rows
                                // visually quiet while still making the action discoverable.
                                Text {
                                    visible: resultItem.isFlatpak
                                        && resultsView.currentIndex === resultItem.index
                                    text: "\u2303\u23CE Flathub"
                                    color: Config.overlay1
                                    font.pixelSize: 11
                                    font.family: Config.fontFamily
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

                            // Per-row uninstall button. Only shown for app rows
                            // where we've resolved the owning package (flatpak
                            // or pacman/AUR). Later sibling than appMouse so
                            // its own MouseArea captures clicks first — left
                            // click uninstalls, rest bubbles to appMouse.
                            // Keyboard equivalent: Ctrl+Shift+Backspace.
                            Item {
                                id: uninstallBtn
                                width: 28
                                height: 28
                                readonly property var _own: resultItem.isApp
                                    ? root.appOwnership[resultItem.appData.id ?? ""]
                                    : null
                                visible: resultItem.isApp && _own
                                    && (appMouse.containsMouse || uninstallMouse.containsMouse)
                                anchors.right: parent.right
                                anchors.rightMargin: 10
                                anchors.verticalCenter: parent.verticalCenter
                                z: 10

                                Rectangle {
                                    anchors.fill: parent
                                    radius: 6
                                    color: Config.red
                                    opacity: uninstallMouse.containsMouse ? 0.18 : 0
                                    Behavior on opacity { NumberAnimation { duration: 120 } }
                                }

                                IconTrash {
                                    anchors.centerIn: parent
                                    size: 16
                                    color: uninstallMouse.containsMouse ? Config.red : Config.overlay1
                                }

                                MouseArea {
                                    id: uninstallMouse
                                    anchors.fill: parent
                                    hoverEnabled: true
                                    cursorShape: Qt.PointingHandCursor
                                    onClicked: {
                                        if (resultItem.isApp)
                                            root.uninstallApp(resultItem.appData);
                                    }
                                }
                            }
                        }

                        Keys.onReturnPressed: (event) => {
                            if (currentIndex >= 0 && currentIndex < root.filteredResults.length) {
                                let item = root.filteredResults[currentIndex];
                                let ctrl = !!(event.modifiers & Qt.ControlModifier);
                                if (ctrl && item.type === "app")
                                    root.togglePin(item.app.id ?? "");
                                else if (ctrl && item.type === "flatpak")
                                    root.openFlathubPage(item.item.appId);
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
                            } else if (event.key === Qt.Key_Backspace
                                    && (event.modifiers & Qt.ControlModifier)
                                    && (event.modifiers & Qt.ShiftModifier)) {
                                if (currentIndex >= 0 && currentIndex < root.filteredResults.length) {
                                    let item = root.filteredResults[currentIndex];
                                    if (item.type === "app" && root.uninstallApp(item.app))
                                        event.accepted = true;
                                }
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
