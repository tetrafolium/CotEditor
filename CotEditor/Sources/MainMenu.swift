//
//  MainMenu.swift
//
//  CotEditor
//  https://coteditor.com
//
//  Created by 1024jp on 2016-10-19.
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

enum MainMenu: Int {
    
    case application
    case file
    case edit
    case format
    case view
    case text
    case find
    case window
    case script
    case help
    
    
    enum MenuItemTag: Int {
        
        case services = 999  // not to list up in "Menu Key Bindings" setting
        case recentDocumentsDirectory = 2999  // not to list up in "Menu Key Bindings" setting
        case sharingService = 1999
        case scriptDirectory = 8999  // not to list up in "Menu Key Bindings" setting
    }
    
    
    var menu: NSMenu? {
        
        return NSApp.mainMenu?.item(at: self.rawValue)?.submenu
    }
    
}



extension LineEnding {
    
    init?(index: Int) {
        
        switch index {
            case 0:
                self = .lf
            case 1:
                self = .cr
            case 2:
                self = .crlf
            default:
                return nil
        }
    }
    
    
    var index: Int {
        
        switch self {
            case .lf:
                return 0
            case .cr:
                return 1
            case .crlf:
                return 2
            default:
                return -1
        }
    }
    
}
