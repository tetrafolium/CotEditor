//
//  NSToolbarItem+Statable.swift
//
//  CotEditor
//  https://coteditor.com
//
//  Created by 1024jp on 2016-05-26.
//
//  ---------------------------------------------------------------------------
//
//  © 2016-2020 1024jp
//
//  Licensed under the Apache License, Version 2.0 (the "License");
//  you may not use this file except in compliance with the License.
//  You may obtain a copy of the License at
//
//  https://www.apache.org/licenses/LICENSE-2.0
//
//  Unless required by applicable law or agreed to in writing, software
//  distributed under the License is distributed on an "AS IS" BASIS,
//  WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
//  See the License for the specific language governing permissions and
//  limitations under the License.
//

import AppKit

final class StatableToolbarItem: NSToolbarItem, StatableItem {
    
    // MARK: Public Properties
    
    var state: NSControl.StateValue = .off  { didSet { self.invalidateImage() } }
    var stateImages: [NSControl.StateValue: NSImage] = [:]  { didSet { self.invalidateImage() } }
    
    
    
    // MARK: -
    // MARK: Toolbar Item Methods
    
    override init(itemIdentifier: NSToolbarItem.Identifier) {
        
        super.init(itemIdentifier: itemIdentifier)
        
        // Use active (green) icons for colored icons in toolbar config panel
        if ProcessInfo().operatingSystemVersion.majorVersion < 11 {
            self.state = .on
        }
    }
    
    
    override var image: NSImage? {
        
        get { super.image }
        @available(*, unavailable, message: "Set images through 'stateImages' instead.") set {  }
    }
    
    
    
    // MARK: Private Methods
    
    private func invalidateImage() {
        
        assert(self.state != .mixed)
        
        super.image = self.stateImages[self.state]
    }
    
}
