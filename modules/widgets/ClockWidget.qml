import QtQuick

Text {
    id: clockText
    text: Qt.formatTime(new Date(), "hh:mm")
    color: "white"
    font.pixelSize: 12

    Timer {
        interval: 1000
        running: true
        repeat: true
        onTriggered: clockText.text = Qt.formatTime(new Date(), "hh:mm")
    }
}
