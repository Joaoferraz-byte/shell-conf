import QtQuick
import Quickshell
import Quickshell.Io

Scope {
    id: root

    // Carregar configurações do JSON
    FileView {
        id: settingsFile
        path: Qt.resolvedUrl("settings.json").toString().replace("file://", "")
        watchChanges: true
        onFileChanged: reload()
        onAdapterUpdated: writeAdapter()

        JsonAdapter {
            property real opacity: 0.85
            property string accentColor: "#7c3aed"
            property int fontSize: 12
            property var widgets: ({
                "battery": true,
                "clock": true,
                "volume": true
            })
        }
    }

    // Barra principal
    Variants {
        model: Quickshell.screens
        PanelWindow {
            required property var modelData
            screen: modelData
            anchors {
                top: true
                left: true
                right: true
                margins: 10
            }
            implicitHeight: 36
            color: Qt.rgba(0, 0, 0, settingsFile.JsonAdapter.opacity)

            Row {
                anchors.centerIn: parent
                spacing: 16
                
                // Widget de Relógio
                Text {
                    text: Qt.formatTime(new Date(), "hh:mm")
                    font.pixelSize: settingsFile.JsonAdapter.fontSize
                    color: "white"
                    
                    Timer {
                        interval: 1000
                        running: true
                        repeat: true
                        onTriggered: parent.text = Qt.formatTime(new Date(), "hh:mm")
                    }
                }
                
                // Widget de Bateria (Simulação para teste)
                Text {
                    text: "Bateria: 100%"
                    font.pixelSize: settingsFile.JsonAdapter.fontSize
                    color: settingsFile.JsonAdapter.accentColor
                }
            }
        }
    }
}
