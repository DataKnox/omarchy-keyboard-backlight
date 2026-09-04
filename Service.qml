import QtQuick
import Quickshell
import Quickshell.Io
import Quickshell.Wayland

// Headless service: the compositor's idle notifier drives `idle` / `active`,
// and a timer runs `tick` for the ambient light sensor. All the policy lives in
// bin/omarchy-keyboard-backlight so it can also run without the shell.
Item {
  id: root

  property var shell: null
  property var manifest: null

  readonly property string script: String(Qt.resolvedUrl("bin/omarchy-keyboard-backlight")).replace(/^file:\/\//, "")
  property bool supported: false
  property int idleSeconds: 10
  property int pollMs: 2000

  function run(action) {
    if (!root.supported) return
    if (action === "tick" && (idleProc.running || tickProc.running)) return
    if (action === "tick") {
      tickProc.command = [root.script, "tick"]
      tickProc.running = true
    } else {
      idleProc.command = [root.script, action]
      idleProc.running = true
    }
  }

  function readIdleSeconds() {
    // IDLE_SECONDS in ~/.config/omarchy/keyboard-backlight.conf, if set.
    configProc.running = true
  }

  Component.onCompleted: probeProc.running = true

  Process {
    id: probeProc
    command: [root.script, "probe"]
    onExited: function(exitCode) {
      root.supported = (exitCode === 0)
      if (root.supported) {
        console.log("keyboard-backlight: sensor and LED found, enabling")
        root.readIdleSeconds()
        root.run("active")
      } else {
        console.log("keyboard-backlight: no ambient light sensor or keyboard backlight, staying idle")
      }
    }
  }

  Process {
    id: configProc
    command: ["bash", "-c", "source \"$HOME/.config/omarchy/keyboard-backlight.conf\" 2>/dev/null; echo \"${IDLE_SECONDS:-10}\""]
    stdout: StdioCollector {
      waitForEnd: true
      onStreamFinished: {
        var n = parseInt(text, 10)
        if (!isNaN(n) && n > 0) root.idleSeconds = n
      }
    }
  }

  Process { id: tickProc }
  Process { id: idleProc }

  IdleMonitor {
    enabled: root.supported
    timeout: root.idleSeconds
    respectInhibitors: false
    onIsIdleChanged: root.run(isIdle ? "idle" : "active")
  }

  Timer {
    interval: root.pollMs
    running: root.supported
    repeat: true
    onTriggered: root.run("tick")
  }
}
