//
//  IncompatibleCharacterScanner.swift
//
//  CotEditor
//  https://coteditor.com
//
//  Created by 1024jp on 2016-05-28.
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

import Combine
import AppKit

final class IncompatibleCharacterScanner {
    
    // MARK: Public Properties
    
    var shouldScan = false
    
    @Published private(set) var incompatibleCharacters: [IncompatibleCharacter] = []  // line endings applied
    
    
    // MARK: Private Properties
    
    private weak var document: Document?
    
    private lazy var updateTask = Debouncer(delay: .milliseconds(400)) { [weak self] in self?.scan() }
    
    
    
    // MARK: -
    // MARK: Lifecycle
    
    required init(document: Document) {
        
        self.document = document
    }
    
    
    
    // MARK: Public Methods
    
    /// set update timer
    func invalidate() {
        
        guard self.shouldScan else { return }
        
        self.updateTask.schedule()
    }
    
    
    /// scan immediately
    func scan() {
        
        self.updateTask.cancel()
        
        guard let document = self.document else { return assertionFailure() }
        
        self.incompatibleCharacters = document.string.scanIncompatibleCharacters(for: document.fileEncoding.encoding)
    }
    
}
