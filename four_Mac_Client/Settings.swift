//
//  Settings.swift
//  four_Mac_Client
//
//  Created by Manuel Hahn on 11.06.22.
//

import Foundation

class Settings {
    static let shared = Settings()
    var windowWidth: Int
    var windowHeight: Int
    var windowPositionX: Int
    var windowPositionY: Int
    var port: Int
    var host: String
    
    private init() {
        // TODO: Read settings from somewhere
        port = 4242
        host = "localhost"
        windowWidth = 750
        windowHeight = 500
        windowPositionX = -1
        windowPositionY = -1
    }
}
