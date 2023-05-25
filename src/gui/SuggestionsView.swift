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

import SwiftUI

struct SuggestionsView: View {
    @ObservedObject var delegate: SuggestionsDelegate
    
    var body: some View {
        if delegate.suggestions.isEmpty {
            Text("No suggestions available")
                .padding(.horizontal, 5)
        } else {
            VStack {
//                ForEach(delegate.suggestions, id: \.hashValue) { suggestion in
                List(delegate.suggestions, id: \.hashValue) { suggestion in
                    let selected = suggestion.hashValue == delegate.selected?.hashValue
                    HStack {
                        Text(suggestion.description)
                            .foregroundColor(selected ? Color.white : nil)
                            .padding(.horizontal, 5)
//                            .padding(.vertical, 1)
                        Spacer()
                        Text(suggestion.rightSide)
                            .padding(.horizontal, 5)
                            .foregroundColor(.gray)
//                            .padding(.vertical, 1)
                    }.background(selected ? Color.blue : Color?.none)
//                        .padding(.vertical, 1)
                }
                Text("Insert using <ENTER> or replace using <TAB>")
                    .padding(.horizontal, 5)
                    .foregroundColor(.gray)
            }
        }
    }
}

struct SuggestionsView_Previews: PreviewProvider {
    static var previews: some View {
        SuggestionsView(delegate: SuggestionsDelegate(suggestions: [SwitchSuggestion(), DoSuggestion(), ThisSuggestion()]))
    }
}
