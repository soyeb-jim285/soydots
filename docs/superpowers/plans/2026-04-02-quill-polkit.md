# Quill Polkit Agent Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Build a custom polkit authentication agent with a Catppuccin Mocha themed overlay UI that matches the existing quickshell desktop, replacing hyprpolkitagent.

**Architecture:** A Python D-Bus daemon (`agent.py`) handles polkit registration and authentication via GObject introspection (`PolkitAgent.Listener` + `PolkitAgent.Session`). A Quickshell QML overlay (`PolkitAgent.qml`) provides the UI. Python signals QML via `quickshell ipc call`, QML sends passwords back via a Unix domain socket. The project lives in a separate `quill-polkit` git repo, added as a submodule to the quickshell config.

**Tech Stack:** Python 3 (python-gobject, GLib, Polkit, PolkitAgent GI bindings), Quickshell QML (PanelWindow, IpcHandler, Process), Quill component library, Unix domain sockets.

---

## File Structure

### New repo: `quill-polkit/`

| File | Responsibility |
|------|---------------|
| `agent.py` | Python polkit D-Bus agent — registers with polkit, listens for auth requests, runs Unix socket server, manages PolkitAgent.Session for PAM auth, calls quickshell IPC to show/dismiss UI |
| `PolkitAgent.qml` | QML overlay UI — PanelWindow with centered auth card, password input, error display, submit/cancel buttons, IPC handlers for begin/cancel/fail/success |
| `quill-polkit.service` | systemd user service for the Python agent daemon |
| `quill/` | Git submodule → quill component library |
| `icons/` | Git submodule → quill-icons |

### Modified in `jimdots/`

| File | Change |
|------|--------|
| `quickshell/shell.qml` | Add `PolkitAgent {}` component loader pointing to `quill-polkit/PolkitAgent.qml` |
| `hypr/hyprland.conf` | Add layerrule for `quickshell-polkit` namespace blur, remove hyprpolkitagent autostart + windowrule |
| `tasks.md` | Add quill-polkit to installed/configured sections |

---

## Communication Protocol

**Unix socket:** `/run/user/$UID/quill-polkit.sock`

**Python → QML (via `quickshell ipc call polkit <function> <json>`):**
- `beginAuth '{"cookie":"...","message":"...","user":"...","actionId":"..."}'`
- `cancelAuth '{"cookie":"..."}'`
- `authFailed '{"cookie":"...","message":"Wrong password. X attempts remaining."}'`
- `authSuccess '{"cookie":"..."}'`

**QML → Python (via Process writing to Unix socket):**
- `{"cookie":"...","type":"password","password":"..."}`
- `{"cookie":"...","type":"cancel"}`

---

### Task 1: Create repo and project scaffolding

**Files:**
- Create: `~/quill-polkit/agent.py` (placeholder)
- Create: `~/quill-polkit/PolkitAgent.qml` (placeholder)
- Create: `~/quill-polkit/quill-polkit.service`

- [ ] **Step 1: Initialize git repo**

```bash
mkdir -p ~/quill-polkit
cd ~/quill-polkit
git init
```

- [ ] **Step 2: Add submodules**

```bash
cd ~/quill-polkit
git submodule add https://github.com/soyeb-jim285/quill-icons.git icons
git submodule add <quill-repo-url> quill
```

Note: Get the quill repo URL from `cd ~/jimdots && git config --file .gitmodules --get submodule.quill.url`.

- [ ] **Step 3: Create placeholder files**

`agent.py`:
```python
#!/usr/bin/env python3
"""Quill Polkit Authentication Agent."""
```

`PolkitAgent.qml`:
```qml
pragma ComponentBehavior: Bound
import Quickshell
Scope { id: root }
```

- [ ] **Step 4: Create systemd service**

`quill-polkit.service`:
```ini
[Unit]
Description=Quill Polkit Authentication Agent
PartOf=graphical-session.target
After=graphical-session.target
ConditionEnvironment=WAYLAND_DISPLAY

[Service]
ExecStart=/usr/bin/python3 %h/.config/quickshell/quill-polkit/agent.py
Slice=session.slice
TimeoutStopSec=5sec
Restart=on-failure

[Install]
WantedBy=graphical-session.target
```

- [ ] **Step 5: Commit**

```bash
cd ~/quill-polkit
git add -A
git commit -m "feat: initial project scaffolding with submodules and systemd service"
```

---

### Task 2: Install Python dependency and verify polkit GI bindings

- [ ] **Step 1: Install python-gobject**

```bash
sudo pacman -S python-gobject
```

- [ ] **Step 2: Verify all GI imports work**

```bash
python3 -c "
from gi.repository import Polkit, PolkitAgent, Gio, GLib
print('Polkit version:', Polkit._version)
print('PolkitAgent OK')
print('Helper exists:', __import__('os').path.exists('/usr/lib/polkit-1/polkit-agent-helper-1'))
"
```

Expected: All imports succeed, helper exists.

- [ ] **Step 3: Verify quickshell IPC accepts function arguments**

```bash
quickshell ipc call --help 2>&1 | head -20
```

Expected: Shows positional args for `target`, `function`, `arguments`.

---

### Task 3: Write the Python polkit agent

**Files:**
- Create: `~/quill-polkit/agent.py`

This is the core daemon. It:
1. Registers as a polkit auth agent for the current session
2. Listens for `BeginAuthentication` calls from polkit
3. Signals the QML UI via quickshell IPC
4. Receives passwords from QML via Unix domain socket
5. Feeds password to `PolkitAgent.Session` for PAM authentication
6. Handles retries (max 3 attempts) and cancellation

- [ ] **Step 1: Write agent.py**

```python
#!/usr/bin/env python3
"""Quill Polkit Authentication Agent.

Registers with PolicyKit as an authentication agent, shows a Quickshell
QML overlay for password input, and authenticates via PolkitAgent.Session.
"""

import json
import os
import signal
import socket
import subprocess
import sys
import threading

import gi

gi.require_version("Gio", "2.0")
gi.require_version("GLib", "2.0")
gi.require_version("Polkit", "1.0")
gi.require_version("PolkitAgent", "1.0")

from gi.repository import Gio, GLib, Polkit, PolkitAgent

SOCKET_PATH = f"/run/user/{os.getuid()}/quill-polkit.sock"
MAX_ATTEMPTS = 3


class QuillPolkitAgent(PolkitAgent.Listener):
    """Polkit authentication agent that delegates UI to Quickshell."""

    def __init__(self):
        super().__init__()
        self._pending = {}  # cookie -> {task, identity, attempts}
        self._sock_server = None
        self._start_socket_server()

    def _start_socket_server(self):
        """Start Unix domain socket server for receiving passwords from QML."""
        if os.path.exists(SOCKET_PATH):
            os.unlink(SOCKET_PATH)

        self._sock_server = socket.socket(socket.AF_UNIX, socket.SOCK_STREAM)
        self._sock_server.bind(SOCKET_PATH)
        os.chmod(SOCKET_PATH, 0o600)
        self._sock_server.listen(1)
        self._sock_server.setblocking(False)

        GLib.io_add_watch(
            GLib.IOChannel.unix_new(self._sock_server.fileno()),
            GLib.PRIORITY_DEFAULT,
            GLib.IOCondition.IN,
            self._on_socket_connection,
        )

    def _on_socket_connection(self, channel, condition):
        """Handle incoming connection on the Unix socket."""
        try:
            conn, _ = self._sock_server.accept()
            data = conn.recv(4096).decode("utf-8").strip()
            conn.close()

            if data:
                msg = json.loads(data)
                cookie = msg.get("cookie", "")
                if msg.get("type") == "cancel":
                    self._handle_cancel(cookie)
                elif msg.get("type") == "password":
                    self._handle_password(cookie, msg.get("password", ""))
        except Exception as e:
            print(f"Socket error: {e}", file=sys.stderr)

        return True  # Keep watching

    def _ipc(self, function, data):
        """Send IPC message to Quickshell QML."""
        try:
            subprocess.Popen(
                ["quickshell", "ipc", "call", "polkit", function, json.dumps(data)],
                stdout=subprocess.DEVNULL,
                stderr=subprocess.DEVNULL,
            )
        except Exception as e:
            print(f"IPC error: {e}", file=sys.stderr)

    def do_initiate_authentication(
        self,
        action_id,
        message,
        icon_name,
        details,
        cookie,
        identities,
        cancellable,
        callback,
        user_data,
    ):
        """Called by polkit when authentication is needed."""
        task = Gio.Task.new(self, cancellable, callback, user_data)

        # Pick the first unix-user identity
        identity = None
        user_name = "user"
        for ident in identities:
            if isinstance(ident, Polkit.UnixUser):
                identity = ident
                import pwd

                try:
                    user_name = pwd.getpwuid(ident.get_uid()).pw_name
                except KeyError:
                    user_name = str(ident.get_uid())
                break

        if identity is None and identities:
            identity = identities[0]
            user_name = identity.to_string()

        self._pending[cookie] = {
            "task": task,
            "identity": identity,
            "attempts": 0,
            "action_id": action_id,
            "message": message,
            "user_name": user_name,
        }

        self._ipc(
            "beginAuth",
            {
                "cookie": cookie,
                "message": message,
                "user": user_name,
                "actionId": action_id,
            },
        )

    def do_initiate_authentication_finish(self, result):
        """Called by polkit to get the result of authentication."""
        return Gio.Task.is_valid(result, self) and result.propagate_boolean()

    def _handle_password(self, cookie, password):
        """Process password submission from QML."""
        pending = self._pending.get(cookie)
        if not pending:
            return

        pending["attempts"] += 1
        session = PolkitAgent.Session.new(pending["identity"], cookie)

        def on_request(session, request, echo_on):
            session.response(password)

        def on_completed(session, gained_authorization):
            if gained_authorization:
                self._ipc("authSuccess", {"cookie": cookie})
                task = self._pending.pop(cookie, {}).get("task")
                if task:
                    task.return_boolean(True)
            elif pending["attempts"] >= MAX_ATTEMPTS:
                self._ipc(
                    "authFailed",
                    {"cookie": cookie, "message": "Max attempts reached.", "fatal": True},
                )
                task = self._pending.pop(cookie, {}).get("task")
                if task:
                    task.return_error_literal(
                        Polkit.error_quark(), 0, "Authentication failed"
                    )
            else:
                remaining = MAX_ATTEMPTS - pending["attempts"]
                self._ipc(
                    "authFailed",
                    {
                        "cookie": cookie,
                        "message": f"Wrong password. {remaining} attempt{'s' if remaining != 1 else ''} remaining.",
                        "fatal": False,
                    },
                )

        def on_show_error(session, text):
            print(f"Polkit session error: {text}", file=sys.stderr)

        session.connect("request", on_request)
        session.connect("completed", on_completed)
        session.connect("show-error", on_show_error)
        session.initiate()

    def _handle_cancel(self, cookie):
        """Handle user cancellation from QML."""
        task = self._pending.pop(cookie, {}).get("task")
        if task:
            task.return_error_literal(Polkit.error_quark(), 0, "Authentication cancelled")

    def cleanup(self):
        """Clean up socket on exit."""
        if self._sock_server:
            self._sock_server.close()
        if os.path.exists(SOCKET_PATH):
            os.unlink(SOCKET_PATH)


def get_session_subject():
    """Get the current session subject for agent registration."""
    pid = os.getpid()
    try:
        return Polkit.UnixSession.new_for_process_sync(pid, None)
    except Exception:
        return Polkit.UnixProcess.new_for_owner(pid, 0, os.getuid())


def main():
    agent = QuillPolkitAgent()
    subject = get_session_subject()

    try:
        agent.register(
            PolkitAgent.RegisterFlags.NONE,
            subject,
            None,  # object_path (default)
            None,  # cancellable
        )
        print("Quill polkit agent registered.", file=sys.stderr)
    except Exception as e:
        print(f"Failed to register agent: {e}", file=sys.stderr)
        sys.exit(1)

    loop = GLib.MainLoop()

    def shutdown(signum, frame):
        agent.cleanup()
        loop.quit()

    signal.signal(signal.SIGTERM, shutdown)
    signal.signal(signal.SIGINT, shutdown)

    try:
        loop.run()
    finally:
        agent.cleanup()


if __name__ == "__main__":
    main()
```

- [ ] **Step 2: Make executable**

```bash
chmod +x ~/quill-polkit/agent.py
```

- [ ] **Step 3: Quick smoke test — verify it starts and registers**

```bash
# Stop hyprpolkitagent first (only one agent can register per session)
systemctl --user stop hyprpolkitagent

# Run agent in foreground
python3 ~/quill-polkit/agent.py &
AGENT_PID=$!
sleep 1

# Check it registered
grep -q "registered" /proc/$AGENT_PID/fd/2 2>/dev/null || echo "Check stderr for registration message"

# Kill test instance
kill $AGENT_PID

# Restart hyprpolkitagent for now
systemctl --user start hyprpolkitagent
```

Expected: "Quill polkit agent registered." printed to stderr, no errors.

- [ ] **Step 4: Commit**

```bash
cd ~/quill-polkit
git add agent.py
git commit -m "feat: python polkit agent with GI bindings, socket server, and IPC"
```

---

### Task 4: Write the QML overlay UI

**Files:**
- Create: `~/quill-polkit/PolkitAgent.qml`

The overlay is a full-screen PanelWindow at `WlrLayer.Overlay` with:
- Semi-transparent backdrop (click to cancel)
- Centered card with: header (lock icon + "Authentication Required"), message text, password input with dots + eye toggle, error label, Cancel/Authenticate buttons
- Entrance/exit animations matching the power menu style
- Shake animation on wrong password
- IPC handlers: `beginAuth`, `cancelAuth`, `authFailed`, `authSuccess`
- Process component to send password/cancel to Python agent via Unix socket

- [ ] **Step 1: Write PolkitAgent.qml**

```qml
pragma ComponentBehavior: Bound

import Quickshell
import Quickshell.Io
import Quickshell.Wayland
import QtQuick
import QtQuick.Layouts
import "../quill" as Quill
import "../icons"

Scope {
    id: root

    property bool visible: false
    property string cookie: ""
    property string message: ""
    property string userName: ""
    property string actionId: ""
    property string password: ""
    property string errorMsg: ""
    property string status: "idle" // idle, input, verifying, error, success
    property int uid: parseInt(Quickshell.env("UID") || "1000")

    readonly property string socketPath: "/run/user/" + root.uid + "/quill-polkit.sock"

    function show(data: var): void {
        root.cookie = data.cookie || "";
        root.message = data.message || "";
        root.userName = data.user || "";
        root.actionId = data.actionId || "";
        root.password = "";
        root.errorMsg = "";
        root.status = "input";
        root.visible = true;
    }

    function dismiss(): void {
        root.visible = false;
        root.status = "idle";
        root.password = "";
        root.errorMsg = "";
        root.cookie = "";
    }

    function submitPassword(): void {
        if (root.password.length === 0) return;
        root.status = "verifying";
        let escaped = JSON.stringify({
            cookie: root.cookie,
            type: "password",
            password: root.password
        }).replace(/'/g, "'\\''");
        sendProc.command = ["bash", "-c",
            "printf '%s\\n' '" + escaped + "' | python3 -c \"import socket,sys,os; s=socket.socket(socket.AF_UNIX); s.connect('" + root.socketPath + "'); s.send(sys.stdin.buffer.readline()); s.close()\""
        ];
        sendProc.running = true;
    }

    function cancelAuth(): void {
        let escaped = JSON.stringify({
            cookie: root.cookie,
            type: "cancel"
        }).replace(/'/g, "'\\''");
        sendProc.command = ["bash", "-c",
            "printf '%s\\n' '" + escaped + "' | python3 -c \"import socket,sys,os; s=socket.socket(socket.AF_UNIX); s.connect('" + root.socketPath + "'); s.send(sys.stdin.buffer.readline()); s.close()\""
        ];
        sendProc.running = true;
        root.dismiss();
    }

    Process {
        id: sendProc
        command: ["true"]
        running: false
    }

    IpcHandler {
        target: "polkit"

        function beginAuth(data: string): void {
            let parsed = JSON.parse(data);
            root.show(parsed);
        }

        function cancelAuth(data: string): void {
            let parsed = JSON.parse(data);
            if (parsed.cookie === root.cookie) {
                root.dismiss();
            }
        }

        function authFailed(data: string): void {
            let parsed = JSON.parse(data);
            if (parsed.cookie !== root.cookie) return;

            if (parsed.fatal) {
                root.errorMsg = parsed.message || "Authentication failed.";
                root.status = "error";
                dismissTimer.restart();
            } else {
                root.errorMsg = parsed.message || "Wrong password.";
                root.status = "error";
                root.password = "";
                shakeAnim.restart();
                errorResetTimer.restart();
            }
        }

        function authSuccess(data: string): void {
            let parsed = JSON.parse(data);
            if (parsed.cookie === root.cookie) {
                root.status = "success";
                dismissTimer.restart();
            }
        }
    }

    Timer {
        id: dismissTimer
        interval: 800
        onTriggered: root.dismiss()
    }

    Timer {
        id: errorResetTimer
        interval: 1500
        onTriggered: {
            if (root.status === "error") {
                root.status = "input";
            }
        }
    }

    LazyLoader {
        active: root.visible

        PanelWindow {
            id: window

            WlrLayershell.layer: WlrLayer.Overlay
            WlrLayershell.namespace: "quickshell-polkit"
            WlrLayershell.keyboardFocus: WlrKeyboardFocus.Exclusive

            anchors {
                top: true
                left: true
                right: true
                bottom: true
            }

            color: "transparent"

            // Backdrop
            Rectangle {
                id: backdrop
                anchors.fill: parent
                color: Qt.rgba(0, 0, 0, fadeIn.value * 0.4)

                NumberAnimation {
                    id: fadeIn
                    property: "value"
                    target: fadeIn
                    from: 0; to: 1
                    duration: Quill.Theme.animDuration
                    easing.type: Easing.OutCubic
                    running: true

                    property real value: 0
                }

                MouseArea {
                    anchors.fill: parent
                    onClicked: root.cancelAuth()
                }
            }

            // Auth card
            Rectangle {
                id: card
                anchors.centerIn: parent
                width: 400
                height: cardLayout.implicitHeight + 48
                radius: Quill.Theme.radiusLg
                color: Quill.Theme.surface0

                // Entrance animation
                scale: fadeIn.value * 0.05 + 0.95
                opacity: fadeIn.value

                // Shake animation
                transform: Translate { id: cardShake; x: 0 }
                SequentialAnimation {
                    id: shakeAnim
                    NumberAnimation { target: cardShake; property: "x"; to: 12; duration: 50 }
                    NumberAnimation { target: cardShake; property: "x"; to: -10; duration: 50 }
                    NumberAnimation { target: cardShake; property: "x"; to: 8; duration: 50 }
                    NumberAnimation { target: cardShake; property: "x"; to: -6; duration: 50 }
                    NumberAnimation { target: cardShake; property: "x"; to: 3; duration: 50 }
                    NumberAnimation { target: cardShake; property: "x"; to: 0; duration: 50 }
                }

                ColumnLayout {
                    id: cardLayout
                    anchors.fill: parent
                    anchors.margins: 24
                    spacing: 16

                    // Header
                    RowLayout {
                        Layout.alignment: Qt.AlignHCenter
                        spacing: 10

                        IconLock {
                            size: 22
                            color: root.status === "success" ? Quill.Theme.success
                                 : root.status === "error" ? Quill.Theme.error
                                 : Quill.Theme.primary
                            Behavior on color { ColorAnimation { duration: 200 } }
                        }

                        Quill.Label {
                            text: "Authentication Required"
                            variant: "heading"
                        }
                    }

                    // User
                    Quill.Label {
                        text: "Authenticating as " + root.userName
                        variant: "caption"
                        Layout.alignment: Qt.AlignHCenter
                        color: Quill.Theme.textSecondary
                    }

                    // Separator
                    Quill.Separator {}

                    // Message
                    Quill.Label {
                        text: root.message
                        variant: "body"
                        Layout.fillWidth: true
                        wrapMode: Text.WordWrap
                    }

                    // Password field
                    Quill.TextField {
                        id: passwordField
                        Layout.fillWidth: true
                        placeholder: "Password"
                        echoMode: TextInput.Password
                        enabled: root.status === "input" || root.status === "error"

                        Component.onCompleted: forceActiveFocus()

                        onSubmitted: root.submitPassword()

                        Connections {
                            target: root
                            function onVisibleChanged() {
                                if (root.visible) passwordField.forceActiveFocus();
                            }
                            function onStatusChanged() {
                                if (root.status === "input") passwordField.forceActiveFocus();
                            }
                        }
                    }

                    // Bind password (TextField doesn't have onTextEdited with binding)
                    Binding {
                        target: root
                        property: "password"
                        value: passwordField.text
                    }

                    // Error label
                    Quill.Label {
                        text: root.errorMsg
                        variant: "caption"
                        color: Quill.Theme.error
                        visible: root.errorMsg.length > 0
                        Layout.alignment: Qt.AlignHCenter
                    }

                    // Spinner while verifying
                    Quill.Spinner {
                        Layout.alignment: Qt.AlignHCenter
                        visible: root.status === "verifying"
                        size: "small"
                    }

                    // Buttons
                    RowLayout {
                        Layout.alignment: Qt.AlignRight
                        spacing: 8

                        Quill.Button {
                            text: "Cancel"
                            variant: "ghost"
                            onClicked: root.cancelAuth()
                        }

                        Quill.Button {
                            text: root.status === "success" ? "Authenticated" : "Authenticate"
                            variant: root.status === "success" ? "primary" : "secondary"
                            enabled: root.status === "input" || root.status === "error"
                            onClicked: root.submitPassword()
                        }
                    }
                }
            }

            // Keyboard handling
            Item {
                focus: true
                Keys.onEscapePressed: root.cancelAuth()
                Keys.onReturnPressed: root.submitPassword()
                Keys.onEnterPressed: root.submitPassword()
            }
        }
    }
}
```

- [ ] **Step 2: Commit**

```bash
cd ~/quill-polkit
git add PolkitAgent.qml
git commit -m "feat: QML polkit overlay with Quill components, blur, and animations"
```

---

### Task 5: Integrate with jimdots quickshell

**Files:**
- Modify: `~/jimdots/quickshell/shell.qml:48`
- Modify: `~/jimdots/hypr/hyprland.conf` (layerrules, autostart)
- Modify: `~/jimdots/tasks.md`

- [ ] **Step 1: Add quill-polkit as a submodule in quickshell/**

```bash
cd ~/jimdots
git submodule add <quill-polkit-repo-url> quickshell/quill-polkit
```

Note: First push the quill-polkit repo to GitHub, then use that URL.

- [ ] **Step 2: Update shell.qml to load PolkitAgent**

Add to `shell.qml` after the `LockScreen` line:

```qml
    LockScreen { id: lockScreen }
    Loader { source: "quill-polkit/PolkitAgent.qml" }
    IdleManager { caffeineActive: notifCenter.caffeineEnabled }
```

Note: Using `Loader` because the QML file is in a submodule subdirectory. The `Loader` resolves imports relative to the loaded file, so `"../quill"` in PolkitAgent.qml correctly resolves to `quickshell/quill/`.

- [ ] **Step 3: Add layerrule for blur in hyprland.conf**

Add after the existing quickshell layerrules:

```
layerrule = blur on, match:namespace quickshell-polkit
layerrule = ignore_alpha 0.3, match:namespace quickshell-polkit
```

- [ ] **Step 4: Remove hyprpolkitagent autostart and windowrule**

In `hyprland.conf`:
- Remove or comment out: `exec-once = systemctl --user start hyprpolkitagent`
- Remove the `windowrule { name = polkit-blur ... }` block
- The `gsettings` exec-once line can stay (useful for other Qt/GTK apps)

- [ ] **Step 5: Install the systemd service**

```bash
# Symlink the service file
mkdir -p ~/.config/systemd/user
ln -sf ~/jimdots/quickshell/quill-polkit/quill-polkit.service ~/.config/systemd/user/quill-polkit.service
systemctl --user daemon-reload
```

- [ ] **Step 6: Disable hyprpolkitagent, enable quill-polkit**

```bash
systemctl --user disable --now hyprpolkitagent
systemctl --user enable --now quill-polkit
```

- [ ] **Step 7: Update tasks.md**

Add to Installed section:
```
- python-gobject (Python GObject introspection bindings)
```

Add to Configured section:
```
- quill-polkit — custom polkit authentication agent:
  - Python D-Bus daemon (PolkitAgent.Listener + PolkitAgent.Session)
  - Quickshell QML overlay (PanelWindow, Quill components, blur)
  - Catppuccin Mocha themed, matches desktop shell
  - Unix socket IPC for secure password transfer
  - Max 3 retry attempts with shake animation on failure
```

Add to Dotfiles Structure:
```
- `quickshell/quill-polkit/` — git submodule (polkit agent repo)
```

- [ ] **Step 8: Commit jimdots changes**

```bash
cd ~/jimdots
git add quickshell/shell.qml hypr/hyprland.conf tasks.md quickshell/quill-polkit
git commit -m "feat: integrate quill-polkit agent, replace hyprpolkitagent"
```

---

### Task 6: End-to-end test

- [ ] **Step 1: Verify the agent starts and registers**

```bash
systemctl --user status quill-polkit
journalctl --user -u quill-polkit --no-pager -n 5
```

Expected: "Quill polkit agent registered." in logs, service active.

- [ ] **Step 2: Verify the socket exists**

```bash
ls -la /run/user/$(id -u)/quill-polkit.sock
```

Expected: Socket file with `srw-------` permissions.

- [ ] **Step 3: Trigger a polkit action**

Try mounting a drive, or run:
```bash
pkexec echo "polkit test"
```

Expected: The Quickshell overlay appears with "Authentication Required", password field, and the action message.

- [ ] **Step 4: Test wrong password**

Enter a wrong password and click Authenticate.

Expected: Shake animation, "Wrong password. 2 attempts remaining." error text, password field cleared, focus returns to password field.

- [ ] **Step 5: Test correct password**

Enter the correct password.

Expected: Spinner appears briefly, lock icon turns green, overlay dismisses, the polkit action completes.

- [ ] **Step 6: Test cancellation**

Trigger another polkit action, click Cancel (or press Escape, or click backdrop).

Expected: Overlay dismisses, polkit action fails gracefully.

- [ ] **Step 7: Verify no leftover hyprpolkitagent**

```bash
systemctl --user status hyprpolkitagent
```

Expected: Inactive/disabled.

---

### Task 7: Polish and edge cases

- [ ] **Step 1: Test multiple rapid auth requests**

If one auth dialog is already shown and another polkit action fires, verify the agent handles it (queues or replaces).

- [ ] **Step 2: Test service restart resilience**

```bash
systemctl --user restart quill-polkit
```

Then trigger a polkit action. Should work normally.

- [ ] **Step 3: Remove qt6ct/Kvantum overrides for hyprpolkitagent**

Since we're no longer using hyprpolkitagent, the systemd override is no longer needed:

```bash
rm -rf ~/.config/systemd/user/hyprpolkitagent.service.d
systemctl --user daemon-reload
```

The qt6ct/Kvantum config can stay — it themes ALL Qt apps, not just polkit.

- [ ] **Step 4: Final commit in quill-polkit repo**

```bash
cd ~/quill-polkit
git add -A
git commit -m "feat: complete polkit agent with QML overlay and systemd service"
```
