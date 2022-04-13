//
//  main.swift
//  four_Mac_Client
//
//  Created by Manuel Hahn on 4/13/22.
//

import AppKit

let app = NSApplication.shared
app.setActivationPolicy(.regular)
let appDelegate = AppDelegate()
app.delegate = appDelegate
app.run()
