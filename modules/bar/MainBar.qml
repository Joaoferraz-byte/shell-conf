import QtQuick
import Quickshell

// Barra principal customizada
Item {
    id: mainBar
    implicitHeight: 36
    color: "transparent"

    // Espaços vazios para empurrar os widgets para o centro
    Item { width: parent.width / 2 - 100; height: 1 }

    Row {
        spacing: 16
        // Aqui entrariam os widgets carregados dinamicamente ou fixos
    }

    Item { width: parent.width / 2 - 100; height: 1 }
}
