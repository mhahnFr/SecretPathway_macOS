/*
 * SecretPathway_macOS - A MUD client, for macOS.
 *
 * Copyright (C) 2022  mhahnFr
 *
 * This file is part of the SecretPathway_macOS. This program is free
 * software: you can redistribute it and/or modify it under the terms
 * of the GNU General Public License as published by the
 * Free Software Foundation, either version 3 of the License, or
 * (at your option) any later version.
 *
 * This program is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 * GNU General Public License for more details.
 *
 * You should have received a copy of the GNU General Public License
 * along with this program, see the file LICENSE.
 * If not, see <https://www.gnu.org/licenses/>.
 */

import Foundation
import SwiftUI

/// This class contains all settings and is responsible for storing the
/// application state.
class Settings: ObservableObject {
    /// The single object of this class.
    static let shared = Settings()
    
    var openConnections: [ConnectionRecord] {
        didSet {
            // TODO: Save
        }
    }
    
    var recentConnections: [ConnectionRecord] {
        didSet {
            // TODO: Save
        }
    }
    
    /// The font size to be used globally.
    @AppStorage(Constants.Storage.FONT_SIZE)
    var fontSize: Double = 12
    
    /// The raw data of the currently opened connections.
    @AppStorage(Constants.Storage.OPEN_CONNECTIONS)
    private var openConnectionsRaw: Data = Data()
    /// The raw data of the recently opened connections.
    @AppStorage(Constants.Storage.RECENT_CONNECTIONS)
    private var recentConnectionsRaw: Data = Data()
    
    /// Private initializer to prevent instancing this class from outside.
    ///
    /// Reads the settings from the storing location.
    private init() {
        // TODO: Parse the raw data
        openConnections   = []
        recentConnections = []
    }
}
