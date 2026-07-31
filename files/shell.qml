//@ pragma UseQApplication
//@ pragma ShellId ambxst
//@ pragma DataDir $BASE/ambxst
//@ pragma StateDir $BASE/ambxst
import QtQuick
import Quickshell
import Quickshell.Wayland
import qs.modules.bar
import qs.modules.bar.workspaces
import qs.modules.notifications
import qs.modules.widgets.dashboard.wallpapers
import qs.modules.notch
import qs.modules.widgets.overview
import qs.modules.widgets.presets
import qs.modules.services
import qs.modules.corners
import qs.modules.frame
import qs.modules.components
import qs.modules.desktop
import qs.modules.lockscreen
import qs.modules.dock
import qs.modules.globals
import qs.modules.shell
import qs.config
import qs.modules.shell.osd
import "modules/tools"

ShellRoot {
    id: root

    ContextMenu {
        id: contextMenu
        screen: Quickshell.screens[0]
        Component.onCompleted: Visibilities.setContextMenu(contextMenu)
    }

    Variants {
        model: Quickshell.screens

        Loader {
            id: wallpaperLoader
            active: true
            required property ShellScreen modelData
            sourceComponent: Wallpaper {
                screen: wallpaperLoader.modelData
            }
        }
    }

    Variants {
        model: Quickshell.screens

        Loader {
            id: desktopLoader
            active: Config.desktop.enabled && SuspendManager.wakeReady
            required property ShellScreen modelData
            sourceComponent: Desktop {
                screen: desktopLoader.modelData
            }
        }
    }

    Variants {
        model: Quickshell.screens

        Loader {
            id: dockLoader
            active: Config.dock.enabled && SuspendManager.wakeReady
            required property ShellScreen modelData
            sourceComponent: Dock {
                screen: dockLoader.modelData
            }
        }
    }

    Variants {
        model: Quickshell.screens

        // Surface auto-created per screen
        Bar {}
    }

    Variants {
        model: Quickshell.screens

        Loader {
            id: notchLoader
            active: Config.notch.enabled && SuspendManager.wakeReady
            required property ShellScreen modelData
            sourceComponent: Notch {
                screen: notchLoader.modelData
            }
        }
    }

    Variants {
        model: Quickshell.screens

        Loader {
            id: notificationsLoader
            active: SuspendManager.wakeReady
            required property ShellScreen modelData
            sourceComponent: NotificationPopups {
                screen: notificationsLoader.modelData
            }
        }
    }

    Variants {
        model: Quickshell.screens

        Loader {
            id: cornersLoader
            active: Config.bar.roundedCorners && SuspendManager.wakeReady
            required property ShellScreen modelData
            sourceComponent: Corners {
                screen: cornersLoader.modelData
            }
        }
    }

    Variants {
        model: Quickshell.screens

        Loader {
            id: frameLoader
            active: Config.bar.frameEnabled && SuspendManager.wakeReady
            required property ShellScreen modelData
            sourceComponent: Frame {
                screen: frameLoader.modelData
            }
        }
    }

    Variants {
        model: Quickshell.screens

        Loader {
            id: dashboardLoader
            active: SuspendManager.wakeReady && (Visibilities.getForScreen(modelData.name) ? Visibilities.getForScreen(modelData.name).dashboard : false)
            required property ShellScreen modelData
            sourceComponent: Dashboard {
                screen: dashboardLoader.modelData
            }
        }
    }

    Variants {
        model: Quickshell.screens

        Loader {
            id: overviewLoader
            active: ((Config.overview && Config.overview.enabled !== undefined ? Config.overview.enabled : true)) && SuspendManager.wakeReady && (Visibilities.getForScreen(modelData.name) ? Visibilities.getForScreen(modelData.name).overview : false)
            required property ShellScreen modelData
            sourceComponent: OverviewPopup {
                screen: overviewLoader.modelData
            }
        }
    }

    // Presets popup
    Variants {
        model: {
            const screens = Quickshell.screens;
            const list = (Config.bar && Config.bar.screenList !== undefined ? Config.bar.screenList : []);
            if (!list || list.length === 0)
                return screens;
            return screens.filter(screen => list.indexOf(screen.name) !== -1);
        }

        Loader {
            id: presetsLoader
            active: SuspendManager.wakeReady && (Visibilities.getForScreen(modelData.name) ? Visibilities.getForScreen(modelData.name).presets : false)
            required property ShellScreen modelData
            sourceComponent: PresetsPopup {
                screen: presetsLoader.modelData
            }
        }
    }

    // Secure WlSessionLock lockscreen
    WlSessionLock {
        id: sessionLock
        locked: GlobalStates.lockscreenVisible

        // Surface auto-created per screen
        LockScreen {}
    }

    CompositorConfig {
        id: compositorConfig
    }

    // Este singleton gerencia o ciclo de vida dos binds do compositor (axctl).
    // Mantido como adição do shell-conf para garantir que os keybinds sejam
    // registrados e atualizados via CompositorTomlWriter.
    CompositorKeybinds {}

    // Screenshot tool
    Variants {
        model: Quickshell.screens

        Loader {
            id: screenshotLoader
            active: GlobalStates.screenshotToolVisible
            required property ShellScreen modelData
            sourceComponent: ScreenshotTool {
                targetScreen: screenshotLoader.modelData
            }
        }
    }

    // Screenshot preview overlay
    Variants {
        model: Quickshell.screens

        Loader {
            id: screenshotOverlayLoader
            active: SuspendManager.wakeReady
            required property ShellScreen modelData
            sourceComponent: ScreenshotOverlay {
                targetScreen: screenshotOverlayLoader.modelData
            }
        }
    }

    // Screen recording tool
    Loader {
        id: screenRecordLoader
        active: SuspendManager.wakeReady && GlobalStates.screenRecordToolVisible
        source: "modules/tools/ScreenrecordTool.qml"

        onLoaded: {
            if (GlobalStates.screenRecordToolVisible && item) {
                item.open();
            }
        }

        Connections {
            target: GlobalStates
            function onScreenRecordToolVisibleChanged() {
                if (screenRecordLoader.status === Loader.Ready) {
                    if (GlobalStates.screenRecordToolVisible) {
                        screenRecordLoader.item.open();
                    } else {
                        screenRecordLoader.item.close();
                    }
                }
            }
        }

        Connections {
            target: screenRecordLoader.item
            ignoreUnknownSignals: true
            function onVisibleChanged() {
                if (!screenRecordLoader.item.visible && GlobalStates.screenRecordToolVisible) {
                    GlobalStates.screenRecordToolVisible = false;
                }
            }
        }
    }

    // Mirror tool
    Loader {
        id: mirrorLoader
        active: SuspendManager.wakeReady && GlobalStates.mirrorWindowVisible
        source: "modules/tools/MirrorWindow.qml"
    }

    // Settings
    Loader {
        id: settingsWindowLoader
        active: SuspendManager.wakeReady && GlobalStates.settingsWindowVisible
        source: "modules/widgets/config/SettingsWindow.qml"
    }

    // On-screen display
    Variants {
        model: Quickshell.screens

        Loader {
            id: osdLoader
            active: SuspendManager.wakeReady
            required property ShellScreen modelData
            sourceComponent: OSD {
                targetScreen: osdLoader.modelData
            }
        }
    }

    // Init clipboard service
    Connections {
        target: ClipboardService
        function onListCompleted() {
            // Service initialized and ready
        }
    }

    // Force service init at startup but defer it slightly so it doesn't block the UI
    QtObject {
        id: serviceInitializer

        Component.onCompleted: {
            // Critical services — init immediately (next tick)
            Qt.callLater(() => {
                let _ = CaffeineService.inhibit;
                _ = IdleService.lockCmd; // Force init
                _ = GlobalShortcuts.appId; // Force init (IPC pipe listener)
                // Bootstrap do PresetsService para garantir que os presets
                // estejam disponíveis antes do primeiro render do shell.
                PresetsService.initialize();
            });
        }
    }

    // Non-critical services — defer 2s after startup
    Timer {
        interval: 2000
        running: true
        onTriggered: {
            let _ = NightLightService.active;
            _ = GameModeService.toggled;
        }
    }
}
