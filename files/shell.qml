import QtQuick
import Quickshell
import Quickshell.Io
import qs.modules.globals
import qs.modules.services
import qs.modules.theme
import qs.modules.bar
import qs.modules.widgets.config
import qs.modules.widgets.dashboard
import qs.modules.widgets.defaultview
import qs.modules.lockscreen
import qs.modules.notifications
import qs.modules.tools

ShellRoot {
    id: root

    Variants {
        model: Quickshell.screens

        // Surface auto-created per screen
        Bar {}
    }

    Variants {
        model: Quickshell.screens

        // Surface auto-created per screen
        LockScreen {}
    }

    CompositorConfig {
        id: compositorConfig
    }

    // Este singleton deve ser instanciado para gerenciar o ciclo de vida dos binds
    CompositorKeybinds {}

    // Bootstrap de serviços críticos
    QtObject {
        Component.onCompleted: {
            Qt.callLater(() => {
                PresetsService.initialize();
                // O CompositorTomlWriter deve ser notificado para escrever o primeiro TOML
                // se ele ainda não existir, o que disparará o AxctlService.
            });
        }
    }
}
