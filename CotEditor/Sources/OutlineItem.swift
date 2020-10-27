//
//  OutlineItem.swift
//
//  CotEditor
//  https://coteditor.com
//
//  Created by 1024jp on 2016-05-12.
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

import struct Foundation.NSRange
import AppKit.NSFont

struct OutlineItem: Equatable {
    
    struct Style: OptionSet {
        
        let rawValue: Int
        
        static let bold      = Style(rawValue: 1 << 0)
        static let italic    = Style(rawValue: 1 << 1)
        static let underline = Style(rawValue: 1 << 2)
    }
    
    
    var title: String
    var range: NSRange
    var style: Style = []
    
    
    var isSeparator: Bool {
        
        return self.title == .separator
    }
    
}


extension OutlineItem {
    
    func attributedTitle(for baseFont: NSFont, attributes: [NSAttributedString.Key: Any] = [:]) -> NSAttributedString {
        
        var font = baseFont
        var attributes = attributes
        
        if self.style.contains(.bold) {
            font = NSFontManager.shared.convert(font, toHaveTrait: .boldFontMask)
        }
        if self.style.contains(.italic) {
            font = NSFontManager.shared.convert(font, toHaveTrait: .italicFontMask)
        }
        if self.style.contains(.underline) {
            attributes[.underlineStyle] = NSUnderlineStyle.single.rawValue
        }
        attributes[.font] = font
        
        return NSAttributedString(string: self.title, attributes: attributes)
    }
    
}


extension BidirectionalCollection where Element == OutlineItem {
    
    /// Return the index of element for the given range.
    ///
    /// - Parameter range: The character range to refer.
    /// - Returns: The index of the corresponding outline item, or `nil` if not exist.
    func indexOfItem(at location: Int, allowsSeparator: Bool = false) -> Index? {
        
        return self.lastIndex { $0.range.location <= location && (allowsSeparator || !$0.isSeparator ) }
    }
    
    
    /// Return the previous non-separator element from the given range.
    ///
    /// - Parameter range: The character range to refer.
    /// - Returns: The previous outline item, or `nil` if not exist.
    func previousItem(for range: NSRange) -> OutlineItem? {
        
        guard let currentIndex = self.indexOfItem(at: range.lowerBound) else { return nil }
        
        return self[..<currentIndex].last { !$0.isSeparator }
    }
    
    
    /// Return the next non-separator element from the given range.
    ///
    /// - Parameter range: The character range to refer.
    /// - Returns: The next outline item, or `nil` if not exist.
    func nextItem(for range: NSRange) -> OutlineItem? {
        
        if let first = self.first(where: { !$0.isSeparator }), range.upperBound < first.range.location {
            return first
        }
        
        guard
            let currentIndex = self.indexOfItem(at: range.upperBound),
            currentIndex <= self.endIndex
            else { return nil }
        
        return self[self.index(after: currentIndex)...].first { !$0.isSeparator }
    }
    
}
