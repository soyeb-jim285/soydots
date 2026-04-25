# Internet Speed Widget — Design Spec

**Date:** 2026-04-25
**Target:** `quickshell/` status bar
**Status:** approved, ready for implementation plan

## Goal

Show live internet up/down speed in the status bar with a polished fused widget (sparkline + wifi icon + dominant rate), and expose fuller detail (graph, peaks, session totals) inside the existing wifi popup panel.

## User decisions

- **Scope:** both bar + popup (option C from brainstorming)
- **Bar format:** mini sparkline + current rate (option D)
- **Popup depth:** graph + current rates + peak/avg + session totals (option C)
- **Bar placement:** fused widget — sparkline + wifi icon + rate text as one hover target (option B)
- **Popup style:** minimal — single overlaid graph with inline stats (option A)

## Non-goals (YAGNI)

- Per-interface breakdown (wifi vs ethernet vs vpn separately) — all non-virtual ifaces summed
- Disk-persisted daily/monthly totals — session-only (resets on shell restart)
- Rate-limit / QoS controls
- Active speedtest bandwidth probe
- Scrollable historical graph beyond 60s

## Architecture

```
bar/NetSpeedSampler.qml (singleton)
   │ polls /proc/net/dev every 1s via FileView
   │ exposes reactive properties:
   │   rxRate, txRate           (bytes/s, number)
   │   rxHistory, txHistory     (array of last 60 rates)
   │   peakRx, peakTx           (lifetime max since shell start)
   │   sessionRx, sessionTx     (cumulative bytes since shell start)
   │   hasData                  (bool — false before first delta)
   ▼
   ├─→ bar/NetworkStatus.qml           (bar widget, renders sparkline + icon + rate)
   └─→ StatusBar.qml wifi popup        (speed section above wifi list)
```

Single source of truth. Widget and popup bind reactively to the same sampler; no duplicate polling.

## Data source & sampler

### `/proc/net/dev` parsing

Kernel-native; no external deps. Format:

```
Inter-|   Receive                                                |  Transmit
 face |bytes    packets errs drop fifo frame compressed multicast|bytes    packets errs drop fifo colls carrier compressed
    lo: 12345    123    0    0    0     0          0         0   12345    123    0    0    0     0       0          0
  eth0: 98765   ...                                                54321   ...
```

Per line: field 1 = iface name (with trailing colon), field 2 = rx_bytes, field 10 = tx_bytes.

### Interface filtering

Skip virtual/loopback/container interfaces. Regex-style allowlist:

**Exclude** (prefix match):
- `lo`
- `br-`, `br0`, `bridge`
- `docker`
- `veth`
- `virbr`
- `tun`, `tap`
- `wg` (wireguard — counted at underlying iface)

**Include:** everything else (`eth*`, `eno*`, `enp*`, `wlan*`, `wlo*`, `wlp*`, etc.).

### Sample loop

```
on tick (1s):
    read /proc/net/dev
    rxTotal, txTotal = sum rx/tx bytes across included ifaces
    now = Date.now()
    if prev sample exists:
        elapsed = (now - prevTime) / 1000
        dRx = rxTotal - prevRx
        dTx = txTotal - prevTx
        if dRx < 0 or dTx < 0:
            // counter reset (suspend/resume, iface down): skip this sample
            prevRx = rxTotal; prevTx = txTotal; prevTime = now
            return
        rxRate = dRx / elapsed
        txRate = dTx / elapsed
        sessionRx += dRx
        sessionTx += dTx
        peakRx = max(peakRx, rxRate)
        peakTx = max(peakTx, txRate)
        rxHistory.push(rxRate); if len > 60: shift
        txHistory.push(txRate); if len > 60: shift
        hasData = true
    prevRx = rxTotal
    prevTx = txTotal
    prevTime = now
```

### Implementation notes

- Use `Quickshell.Io.FileView` with a `Timer` calling `reload()` every tick (avoids subprocess overhead of `Process cat`). `/proc/net/dev` is a virtual file; `FileView.text` yields current snapshot after reload.
- If `FileView` proves awkward (needs to be tested), fall back to a `Process` running `cat /proc/net/dev` — same as existing `nmcli` usage pattern.
- Timer interval: `Config.netSpeedPollInterval` (default 1000 ms).
- History length: `Config.netSpeedHistoryLength` (default 60).

## Bar widget rendering

File: `bar/NetworkStatus.qml` (extend existing).

### Layout (left → right)

1. **Sparkline** — `Shape` with `PathPolyline` of `rxHistory`, ~40×16 px. Auto-scales y to local max. Color: `Theme.blue`.
2. **Wifi state icon** — existing `IconWifiSector` / `IconEthernet` / `IconWifiOff`, current state logic untouched.
3. **Rate text** — dominant direction only (larger of rxRate/txRate). Color: `Theme.blue` if rx, `Theme.green` if tx. Dim to `Theme.overlay0` when `< 1 KB/s`.

### Rate formatter

Binary units (1024-based) for consistency with byte totals below.

| Rate (B/s)                  | Display       |
|-----------------------------|---------------|
| `< 1024` or `!hasData`      | `"—"`         |
| `< 1024²` (1 MiB)           | `"234K"`      |
| `< 1024³` (1 GiB)           | `"2.4M"`      |
| `>= 1024³`                  | `"1.2G"`      |

No decimal for values `< 1 MB`. One decimal from 1 MB/s up. Truncate (don't round up to next unit).

### Hover behavior

Unchanged: hovering widget opens wifi popup. Fused widget = single hover target for both sparkline and wifi icon. No new popup plumbing in `StatusBar.qml` for speed — it lives inside the existing wifi panel.

### Disconnected state

Sparkline flat at baseline (dim), rate text `"—"`, wifi icon stays red. Sampler keeps polling; if network comes back, widget lights up automatically.

### Width

New config: `Config.speedWidgetWidth` (default ~100 px). Bar is horizontal `Row` — width affects rightSection layout only, no StatusBar mask changes needed.

## Popup speed section

File: `StatusBar.qml`, inserted inside `wifiContent` `ColumnLayout` before the existing "Wi-Fi" header `RowLayout`.

### Layout

```
┌──────────────────────────────────────────────┐
│  Network              ● Wi-Fi • MyHouse      │  status line
├──────────────────────────────────────────────┤
│  ↓ Download               ↑ Upload           │
│  2.4 MB/s                 120 KB/s           │  big numbers (20px monospace)
│  ┌────────────────────────────────────────┐  │
│  │ blue filled area (rx)                  │  │
│  │ green line overlay (tx)                │  │  60px graph
│  └────────────────────────────────────────┘  │
│  peak ↓ 8.1 MB/s   session ↓ 1.2 GB ↑ 180 MB │  inline stats
├──────────────────────────────────────────────┤
│  Wi-Fi Networks                    [rescan]  │  existing list below
│  ...                                         │
└──────────────────────────────────────────────┘
```

### Graph rendering

- Single `Shape` container, `preferredRendererType: Shape.CurveRenderer`
- Two `ShapePath`s:
    1. Download: filled with `LinearGradient` (blue → transparent), plus stroked polyline on top. Path drawn from `rxHistory`.
    2. Upload: stroke only, green. Path drawn from `txHistory`.
- Shared y-axis: `max(max(rxHistory), max(txHistory), 1)` — so low rates don't render as visually zero when both arrays are tiny.
- X-axis: 60 samples, newest on right, 1 sample = `width/59` pixels.
- Empty history (before first delta): render flat baseline.

### Stats row

Byte formatter for totals (different from bar rate formatter — totals need `GB`/`TB` not `G`/`T`):

| Bytes                       | Display     |
|-----------------------------|-------------|
| `< 1024`                    | `"123 B"`   |
| `< 1024²`                   | `"12.3 KB"` |
| `< 1024³`                   | `"12.3 MB"` |
| `< 1024⁴`                   | `"12.3 GB"` |
| `>= 1024⁴`                  | `"12.3 TB"` |

### Connection status line

Top right of section: colored dot + type + connection name. Matches existing root state:
- `status === "wifi"` → `Theme.green` dot + `"Wi-Fi • <connectionName>"`
- `status === "ethernet"` → `Theme.green` dot + `"Ethernet • <connectionName>"`
- `status === "disconnected"` → `Theme.red` dot + `"Offline"`

### Animation

No new animation plumbing. `wifiContent.implicitHeight + 28` already drives `panelAnimHeight`; adding section grows panel automatically via existing `Behavior on panelAnimHeight`.

## Error handling

| Condition                        | Behavior                                         |
|----------------------------------|--------------------------------------------------|
| `/proc/net/dev` unreadable       | Rates stay 0, empty history. Console.warn once. |
| Counter wraps / resets           | Skip sample, update baseline. No spike.          |
| No interfaces pass filter        | Treated as disconnected. All values zero.        |
| First tick (no prev sample)      | `hasData = false`, text shows `"—"`.             |
| Single interface disappears      | Sum drops, counter-reset guard kicks in.         |

No retry logic, no exponential backoff. Next 1s tick simply tries again.

## Configuration (Config.qml additions)

```qml
// Network speed widget
property int netSpeedPollInterval: _data?.network?.speedPollInterval ?? 1000
property int netSpeedHistoryLength: _data?.network?.speedHistoryLength ?? 60
property int speedWidgetWidth: _data?.network?.speedWidgetWidth ?? 100
```

Corresponding toml keys under existing `[network]` section:

```toml
[network]
pollInterval = 10000
speedPollInterval = 1000
speedHistoryLength = 60
speedWidgetWidth = 100
```

## Testing

### Functional

- **Active traffic:** `curl -o /dev/null https://speed.cloudflare.com/__down?bytes=500000000` → rates should climb, sparkline should animate, peak should update.
- **Idle:** no traffic for 10s → rates drop to `0`, text dims to `"—"`.
- **Disconnect mid-stream:** `nmcli device disconnect wlan0` while curl runs → rate drops to 0 next tick, no NaN, no spike.
- **Suspend/resume:** `systemctl suspend` → resume → counters reset, wrap guard suppresses giant fake sample.
- **Interface swap:** plug ethernet while on wifi → new iface's bytes get included next tick. No double-counting (wg filtered).

### Visual

- Theme switch via Settings → sparkline blue + rate text green transition smoothly via existing `ColorAnimation` on Theme colors.
- Hover fused widget → wifi popup opens, speed section visible at top. No flicker.
- Graph with wide rate range (100 KB/s alongside 10 MB/s spike) — y-axis auto-scales, low-rate line still visible above baseline.

### Regression

- Other status bar widgets (Volume, Battery, Bluetooth, Clock) still align correctly after widget width change.
- Wifi popup mask region still sized correctly — panelAnimHeight binding auto-adjusts.
- Existing network connection detection (ethernet priority, VPN fallback from prior fix) unchanged.

## Files touched

**New:**
- `quickshell/bar/NetSpeedSampler.qml` (singleton)

**Modified:**
- `quickshell/bar/NetworkStatus.qml` (add sparkline + rate to fused widget)
- `quickshell/StatusBar.qml` (insert speed section into `wifiContent` ColumnLayout)
- `quickshell/Config.qml` (add 3 new properties + toml bindings)
- `quickshell/defaults.toml` (add new `[network]` keys)
- `quickshell/bar/qmldir` (register new singleton)

No changes to:
- Panel layout plumbing (mask, hover zones, bgShape)
- Theme colors
- Wifi connection logic
- Hyprland / Settings pages

## Open questions

None — ready for implementation plan.
