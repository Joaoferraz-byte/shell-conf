patch_content = """--- a/config/Config.qml
+++ b/config/Config.qml
@@ -34,6 +34,9 @@
-    property string configDir: (Quickshell.env("XDG_CONFIG_HOME") || (Quickshell.env("HOME") + "/.config")) + "/ambxst/config"
+    readonly property string configRoot: Quickshell.env("AMBXST_CONFIG_ROOT") || ((Quickshell.env("XDG_CONFIG_HOME") || (Quickshell.env("HOME") + "/.config")) + "/ambxst")
+    property string configDir: configRoot + "/config"
+    property string keybindsPath: configRoot + "/binds.json"
--- a/modules/bar/workspaces/Workspaces.qml
+++ b/modules/bar/workspaces/Workspaces.qml
@@ -481,7 +481,5 @@
-                                anchors.bottom: parent.bottom
-                                anchors.right: parent.right
-                                anchors.bottomMargin: (parent.height - height) / 2
-                                anchors.rightMargin: (parent.width - width) / 2
+                                anchors.centerIn: parent
+                                mipmap: true
--- a/modules/services/AxctlService.qml
+++ b/modules/services/AxctlService.qml
@@ -31,3 +31,3 @@
-    property string configPath: (Quickshell.env("XDG_DATA_HOME") || (Quickshell.env("HOME") + "/.local/share")) + "/ambxst/axctl.toml"
-    property bool daemonStarted: true
+    property string configPath: (Quickshell.env("XDG_DATA_HOME") || (Quickshell.env("HOME") + "/.local/share")) + "/ambxst/axctl.toml"
+    property bool daemonStarted: false
--- a/shell.qml
+++ b/shell.qml
@@ -177,4 +177,6 @@
-    }
-
-    CompositorConfig {
-        id: compositorConfig
+    }
+
+    CompositorConfig {
+        id: compositorConfig
+    }
+
+    CompositorKeybinds {
+        id: compositorKeybinds
"""

with open('patches/0001-ambxst-runtime-state-bootstrap-and-workspace-icons.patch', 'w') as f:
    f.write(patch_content)
