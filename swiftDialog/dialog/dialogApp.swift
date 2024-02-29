//
//  dialogApp.swift
//  dialog
//
//  Created by Bart Reardon on 9/3/21.
//

import SwiftUI
import Combine
import UserNotifications
import OSLog

import SystemConfiguration

var background = BlurWindowController()

// Log Stuff
let bundleID = Bundle.main.bundleIdentifier ?? "au.csiro.dialog"
let osLog = OSLog(subsystem: bundleID, category: "main")

// AppDelegate and extension used for notifications
class AppDelegate: NSObject, NSApplicationDelegate, UNUserNotificationCenterDelegate {

    func userNotificationCenter(_ center: UNUserNotificationCenter,
                didReceive response: UNNotificationResponse,
                withCompletionHandler completionHandler:
                                @escaping () -> Void) {
        writeLog("reading notification", logLevel: .debug)
        if response.notification.request.content.categoryIdentifier == "SD_NOTIFICATION" {
            processNotification(response: response)
        } else {
            writeLog("unknown notification type", logLevel: .debug)
        }

        // call the completion handler when done.
        completionHandler()
        // quit dialog since we dont need to show anything
        quitDialog(exitCode: appvars.exitNow.code)
    }

    func applicationWillFinishLaunching(_ notification: Notification) {
        UNUserNotificationCenter.current().delegate = self

    }

    func applicationDidFinishLaunching(_ notification: Notification) {
        var blurredScreen = [BlurWindowController]()

        if let window = NSApplication.shared.windows.first {
            window.standardWindowButton(.closeButton)?.isHidden = !appArguments.windowButtonsEnabled.present
            window.standardWindowButton(.miniaturizeButton)?.isHidden = !appArguments.windowButtonsEnabled.present
            window.standardWindowButton(.zoomButton)?.isHidden = !appArguments.windowButtonsEnabled.present
            window.standardWindowButton(.closeButton)?.isEnabled = appvars.windowCloseEnabled
            window.standardWindowButton(.miniaturizeButton)?.isEnabled = appvars.windowMinimiseEnabled
            window.standardWindowButton(.zoomButton)?.isEnabled = appvars.windowMaximiseEnabled
            window.isMovable = appArguments.movableWindow.present
            window.isMovableByWindowBackground = true
            if appArguments.showOnAllScreens.present {
                window.collectionBehavior = [.canJoinAllSpaces]
            }

            // Set window level
            if appArguments.forceOnTop.present || appArguments.blurScreen.present {
                window.level = .floating
                writeLog("Window is forced on top", logLevel: .debug)
            } else {
                window.level = .normal
            }

            // display a blur screen window on all screens.
            if appArguments.blurScreen.present && !appArguments.fullScreenWindow.present {
                writeLog("Blurscreen enabled", logLevel: .debug)
                let screens = NSScreen.screens
                for (index, screen) in screens.enumerated() {
                    blurredScreen.append(BlurWindowController())
                    allScreens = screen
                    blurredScreen[index].close()
                    blurredScreen[index].loadWindow()
                    blurredScreen[index].showWindow(self)
                }
                window.level = NSWindow.Level(rawValue: Int(CGWindowLevelForKey(.maximumWindow) + 1))
            } else if appArguments.forceOnTop.present {
                window.level = NSWindow.Level(rawValue: Int(CGWindowLevelForKey(.maximumWindow) + 1))
            } else {
                background.close()
            }

            if appArguments.forceOnTop.present || appArguments.blurScreen.present {
                writeLog("Activating window", logLevel: .debug)
                NSApp.activate(ignoringOtherApps: true)
            }

            placeWindow(window, size: window.frame.size,
                        vertical: appvars.windowPositionVertical,
                horozontal: appvars.windowPositionHorozontal,
                        offset: appvars.windowPositionOffset)
        }
    }

    func applicationShouldTerminateAfterLastWindowClosed(_ sender: NSApplication) -> Bool {
            return true
        }
}

@available(OSX 12.0, *)
@main
struct dialogApp: App {

    @NSApplicationDelegateAdaptor(AppDelegate.self) var appDelegate

    @ObservedObject var observedData: DialogUpdatableContent

    init () {

        writeLog("Dialog Launched")
        for argument in CommandLine.arguments {
            writeLog(argument, logLevel: .info)
        }

        // Ensure the singleton NSApplication exists.
        // required for correct determination of screen dimentions for the screen in use in multi screen scenarios
        _ = NSApplication.shared

        if let screen = NSScreen.main {
            let rect = screen.frame
            appvars.screenHeight = rect.size.height
            appvars.screenWidth = rect.size.width
        }

        // get all the command line option values
        processCLOptionValues()

        checkNotificationAuthorisation(notificationPresent: appArguments.notification.present)

        // check if we are sending a notification
        if checkForDialogNotificationMode(appArguments) {
            writeLog("Notification sent")
            quitDialog(exitCode: 0)
        }

        // check for jamfhelper mode
        if appArguments.jamfHelperMode.present {
            writeLog("converting jh to dialog")
            convertFromJamfHelperSyntax()
        }

        // process remaining command line options
        processCLOptions()

        appvars.overlayShadow = 1

        appvars.titleHeight *= appvars.scaleFactor
        appvars.windowWidth *= appvars.scaleFactor
        appvars.windowHeight *= appvars.scaleFactor
        appvars.iconWidth *= appvars.scaleFactor
        appvars.iconHeight *= appvars.scaleFactor

        if appArguments.miniMode.present {
            appvars.windowWidth = 540
            appvars.windowHeight = 128
        }

        //check debug mode and print info
        if appArguments.debug.present {
            writeLog("debug options presented. dialog state sent to stderr", logLevel: .debug)
            appvars.debugMode = true
            appvars.debugBorderColour = Color.green

            writeLog("Window Height = \(appvars.windowHeight): Window Width = \(appvars.windowWidth)", logLevel: .debug)
        }

        // Create main dialog state object
        observedData = DialogUpdatableContent()

        if appArguments.fullScreenWindow.present {
            FullscreenView(observedData: observedData).showFullScreen()
        }

        if appArguments.constructionKit.present {
            ConstructionKitView(observedDialogContent: observedData).showConstructionKit()
            appArguments.movableWindow.present = true
        }

        // bring to front on launch
        writeLog("Activating", logLevel: .debug)
        NSApp.activate(ignoringOtherApps: true)
    }

    var body: some Scene {

        WindowGroup {
            if !appArguments.notification.present {
                if appArguments.miniMode.present {
                    MiniView(observedDialogContent: observedData)
                        .frame(width: observedData.appProperties.windowWidth, height: observedData.appProperties.windowHeight)
                } else {
                    if appArguments.windowResizable.present {
                        ContentView(observedDialogContent: observedData)
                            .sheet(isPresented: $observedData.showSheet, content: {
                                ErrorView(observedContent: observedData)
                            })
                    } else {
                        ContentView(observedDialogContent: observedData)
                            .frame(width: observedData.appProperties.windowWidth, height: observedData.appProperties.windowHeight)
                            .sheet(isPresented: $observedData.showSheet, content: {
                                ErrorView(observedContent: observedData)
                            })
                    }
                }
            }
        }
        // Hide Title Bar
        .windowStyle(HiddenTitleBarWindowStyle())
        .windowResizabilityContentSize()
    }


}


