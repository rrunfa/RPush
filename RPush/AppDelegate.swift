//
//  AppDelegate.swift
//  RPush
//
//  Created by Nikita Nagaynik on 20/10/2018.
//  Copyright © 2018 Nikita Nagaynik. All rights reserved.
//

import Cocoa

@NSApplicationMain
class AppDelegate: NSObject, NSApplicationDelegate {

    @IBOutlet weak var window: NSWindow!

    let contentView = ContentView()

    func applicationDidFinishLaunching(_ aNotification: Notification) {
        window.contentView = contentView
        contentView.windowForSheet = window
    }

    func applicationWillTerminate(_ aNotification: Notification) {}

    func applicationShouldTerminateAfterLastWindowClosed(_ sender: NSApplication) -> Bool {
        return true
    }
}
