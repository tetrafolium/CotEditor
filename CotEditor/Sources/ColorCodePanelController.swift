//
//  ColorPanelController.swift
//
//  CotEditor
//  https://coteditor.com
//
//  Created by 1024jp on 2014-04-22.
//
//  ---------------------------------------------------------------------------
//
//  © 2014-2020 1024jp
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

import Cocoa
import ColorCode

@objc protocol ColorCodeReceiver: AnyObject {
    
    func insertColorCode(_ sender: ColorCodePanelController)
}



// MARK: -

final class ColorCodePanelController: NSViewController, NSWindowDelegate {
    
    // MARK: Public Properties
    
    static let shared = ColorCodePanelController.instantiate(storyboard: "ColorCodePanelAccessory")
    
    @objc private(set) dynamic var colorCode: String?
    
    
    // MARK: Private Properties
    
    private let stylesheetColorList: NSColorList = NSColor.stylesheetKeywordColors
        .reduce(into: NSColorList(name: "Stylesheet Keywords".localized)) { $0.setColor($1.value, forKey: $1.key) }
    
    private weak var panel: NSColorPanel?
    @objc private dynamic var color: NSColor?
    
    
    
    // MARK: -
    // MARK: View Controller Methods
    
    override func viewDidLoad() {
        
        super.viewDidLoad()
        
        self.view.translatesAutoresizingMaskIntoConstraints = false
    }
    
    
    
    // MARK: Public Methods
    
    /// Set color to color panel with color code.
    ///
    /// - Parameter code: The color code of the color to set.
    func setColor(code: String?) {
        
        guard let code = code?.trimmingCharacters(in: .whitespacesAndNewlines), !code.isEmpty else { return }
        
        var codeType: ColorCodeType?
        guard let color = NSColor(colorCode: code, type: &codeType) else { return }
        
        self.selectedCodeType = codeType ?? .hex
        self.panel?.color = color
    }
    
    
    
    // MARK: Window Delegate
    
    /// panel will close
    func windowWillClose(_ notification: Notification) {
        
        guard let panel = self.panel else { return assertionFailure() }
        
        panel.delegate = nil
        panel.accessoryView = nil
        panel.detachColorList(self.stylesheetColorList)
        panel.showsAlpha = false
    }
    
    
    
    // MARK: Action Messages
    
    /// on show color panel
    @IBAction func showWindow(_ sender: Any?) {
        
        // setup the shared color panel
        let panel = NSColorPanel.shared
        panel.isRestorable = false
        panel.delegate = self
        panel.accessoryView = self.view
        panel.attachColorList(self.stylesheetColorList)
        panel.showsAlpha = true
        
        panel.setAction(#selector(selectColor))
        panel.setTarget(self)
        
        // make position of accessory view center
        if let superview = panel.accessoryView?.superview {
            NSLayoutConstraint.activate([
                superview.leadingAnchor.constraint(equalTo: self.view.leadingAnchor),
                superview.trailingAnchor.constraint(equalTo: self.view.trailingAnchor),
            ])
        }
        
        self.panel = panel
        self.color = panel.color
        self.updateCode(self)
        
        panel.orderFront(self)
    }
    
    
    /// insert color code to the selection of the frontmost document
    @IBAction func insertCodeToDocument(_ sender: Any?) {
        
        guard self.colorCode != nil else { return }
        
        guard let receiver = NSApp.target(forAction: #selector(ColorCodeReceiver.insertColorCode)) as? ColorCodeReceiver else {
            return NSSound.beep()
        }
        
        receiver.insertColorCode(self)
    }
    
    
    /// a new color was selected on the panel
    @IBAction func selectColor(_ sender: NSColorPanel) {
        
        self.color = sender.color
        self.updateCode(sender)
    }
    
    
    /// set color from the color code field in the panel
    @IBAction func applayColorCode(_ sender: Any?) {
        
        self.setColor(code: self.colorCode)
    }
    
    
    /// update color code in the field
    @IBAction func updateCode(_ sender: Any?) {
        
        let codeType = self.selectedCodeType
        let color = self.color?.usingColorSpace(.genericRGB)
        var code = color?.colorCode(type: codeType)
        
        // keep lettercase if current Hex code is uppercase
        if (codeType == .hex || codeType == .shortHex), self.colorCode?.range(of: "^#[0-9A-F]{1,6}$", options: .regularExpression) != nil {
            code = code?.uppercased()
        }
        
        self.colorCode = code
    }
    
    
    
    // MARK: Private Accessors
    
    /// current color code type selection
    private var selectedCodeType: ColorCodeType {
        
        get { ColorCodeType(rawValue: UserDefaults.standard[.colorCodeType]) ?? .hex }
        set { UserDefaults.standard[.colorCodeType] = newValue.rawValue }
    }
    
}
