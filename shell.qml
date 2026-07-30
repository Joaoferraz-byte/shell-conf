import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Io

Scope {
    id: root

    // ── Persistência de Configurações ───────────────────────────────────
    FileView {
        id: settingsFile
        path: Qt.resolvedUrl("settings.json").toString().replace("file://", "")
        watchChanges: true
        onFileChanged: reload()
        onAdapterUpdated: writeAdapter()

        JsonAdapter {
            property real opacity: 0.85
            property string accentColor: "#7c3aed"
            property int fontSize: 13
            property int barHeight: 42
            property int borderRadius: 16
        }
    }

    // ── Integração com Hyprland via axctl ──────────────────────────────
    // O axctl detecta automaticamente o Hyprland e fornece uma API JSON-RPC
    // unificada. Usamos axctl em vez de hyprctl diretamente para manter
    // compatibilidade com múltiplos compositores.
    property var hyprlandWorkspaces: []
    property string activeWindow: "No Window"

    Process {
        id: hyprlandWorkspacesProc
        command: ["axctl", "workspaces"]
        running: true
        onRunningChanged: if (!running) running = true // Loop contínuo

        stdout: StdioCollector {
            onStreamFinished: {
                try {
                    const data = JSON.parse(this.text);
                    root.hyprlandWorkspaces = (Array.isArray(data) ? data : Object.values(data)).map(ws => ({
                        id: ws.id !== undefined ? ws.id : (ws.idx !== undefined ? ws.idx : 0),
                        name: ws.name || String(ws.id !== undefined ? ws.id : (ws.idx !== undefined ? ws.idx : 0))
                    }));
                } catch (e) {
                    console.log("Erro ao parsear workspaces:", e);
                }
            }
        }
    }

    Process {
        id: hyprlandWindowProc
        command: ["axctl", "active-window"]
        running: true
        onRunningChanged: if (!running) running = true

        // Atualizar a cada 2 segundos para não sobrecarregar
        Timer {
            interval: 2000
            running: true
            repeat: true
            onTriggered: hyprlandWindowProc.running = true
        }

        stdout: StdioCollector {
            onStreamFinished: {
                try {
                    const data = JSON.parse(this.text);
                    root.activeWindow = data.title || "No Window";
                } catch (e) {
                    root.activeWindow = "No Window";
                }
            }
        }
    }

    // ── Barra Principal (Estilo Ambxst/Notch) ─────────────────────────
    Variants {
        model: Quickshell.screens
        FloatingWindow {
            required property var modelData
            screen: modelData

            // Posicionamento Flutuante (Top Center)
            anchors {
                top: parent.top
                horizontalCenter: parent.horizontalCenter
                topMargin: 16
            }

            implicitWidth: contentRow.width + 40
            implicitHeight: settingsFile.JsonAdapter.barHeight

            // Estilo Visual (Glassmorphism / Material)
            Rectangle {
                anchors.fill: parent
                color: Qt.rgba(24/255, 24/255, 27/255, settingsFile.JsonAdapter.opacity)
                radius: settingsFile.JsonAdapter.borderRadius

                // Borda sutil
                border.color: Qt.rgba(255/255, 255/255, 255/255, 0.05)
                border.width: 1

                // Sombras (Simulação com drop shadow)
                layer.enabled: true
                layer.effect: DropShadow {
                    horizontalOffset: 0
                    verticalOffset: 4
                    radius: 12
                    color: Qt.rgba(0, 0, 0, 0.3)
                }
            }

            RowLayout {
                id: contentRow
                anchors.centerIn: parent
                spacing: 16

                // ── Workspaces (Hyprland) ────────────────────────────
                Repeater {
                    model: root.hyprlandWorkspaces
                    delegate: Rectangle {
                        width: 32
                        height: 32
                        radius: 10
                        color: (modelData.id === root.currentWorkspaceId)
                               ? settingsFile.JsonAdapter.accentColor
                               : "transparent"

                        Text {
                            anchors.centerIn: parent
                            text: modelData.name
                            color: "white"
                            font.pixelSize: settingsFile.JsonAdapter.fontSize
                            font.bold: true
                        }

                        MouseArea {
                            anchors.fill: parent
                            onClicked: {
                                // Comando para mudar workspace no Hyprland via axctl
                                Quickshell.execDetached(["axctl", "focus-workspace", String(modelData.id)]);
                            }
                        }
                    }
                }

                // ── Título da Janela Ativa ────────────────────────────
                Text {
                    text: root.activeWindow
                    color: "white"
                    font.pixelSize: settingsFile.JsonAdapter.fontSize
                    elide: Text.ElideMiddle
                    Layout.maximumWidth: 300
                }

                // ── Relógio ───────────────────────────────────────────
                Text {
                    id: clockText
                    text: Qt.formatTime(new Date(), "hh:mm")
                    color: settingsFile.JsonAdapter.accentColor
                    font.pixelSize: settingsFile.JsonAdapter.fontSize
                    font.bold: true

                    Timer {
                        interval: 1000
                        running: true
                        repeat: true
                        onTriggered: clockText.text = Qt.formatTime(new Date(), "hh:mm")
                    }
                }
            }
        }
    }
}
