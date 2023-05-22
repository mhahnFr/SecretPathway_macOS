/*
 * SecretPathway_macOS - A MUD client, for macOS.
 *
 * Copyright (C) 2023  mhahnFr
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
 * You should have received a copy of the GNU General Public License along with
 * this program, see the file LICENSE.  If not, see <https://www.gnu.org/licenses/>.
 */

struct VFile {
    var fullName: String {
        "\(folder.fullName)/\(name)"
    }
    let folder: VPath
    let name: String
    
    init?(from: String, relation: VPath = VPath("", absolute: true)) {
        guard let index = from.lastIndex(of: "/") else { return nil }
        
        let folderName = String(from[..<index])
        let folder: VPath
        if from.first == "/" {
            folder = VPath(from: folderName)
        } else {
            folder = relation.relative(folderName)
        }
        self.init(folder: folder,
                  name:   String(from[from.index(after: index)...]))
    }
    
    init(folder: VPath, name: String) {
        self.folder = folder
        self.name   = name
    }
}
