//
//  MultipleReplacementListViewController.swift
//
//  CotEditor
//  https://coteditor.com
//
//  Created by 1024jp on 2017-03-17.
//
//  ---------------------------------------------------------------------------
//
//  © 2017-2020 1024jp
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
import Cocoa
import AudioToolbox

final class MultipleReplacementListViewController: NSViewController, NSMenuItemValidation, MultipleReplacementPanelViewControlling {
    
    // MARK: Private Properties
    
    private var settingNames = [String]()
    
    private var listUpdateObserver: AnyCancellable?
    
    @IBOutlet private weak var tableView: NSTableView?
    
    
    
    // MARK: -
    // MARK: View Controller Methods
    
    override func viewDidLoad() {
        
        super.viewDidLoad()
        
        self.mainViewController?.delegate = self
        
        // register droppable types
        self.tableView?.registerForDraggedTypes([.fileURL])
        
        // create blank if empty
        if ReplacementManager.shared.settingNames.isEmpty {
            do {
                try ReplacementManager.shared.createUntitledSetting()
            } catch {
                NSAlert(error: error).beginSheetModal(for: self.view.window!)
            }
        }
        
        self.settingNames = ReplacementManager.shared.settingNames
        
        // select an item in list
        let row: Int = {
            guard
                let lastSelectedName = UserDefaults.standard[.selectedMultipleReplacementSettingName],
                let row = self.settingNames.firstIndex(of: lastSelectedName)
                else { return 0 }
            
            return row
        }()
        self.tableView?.selectRowIndexes([row], byExtendingSelection: false)
        
        // observe replacement setting list change
        self.listUpdateObserver = ReplacementManager.shared.$settingNames
            .receive(on: RunLoop.main)
            .sink { [weak self] _ in self?.updateSettingList() }
    }
    
    
    
    // MARK: Menu Item Validation
    
    /// apply current state to menu items
    func validateMenuItem(_ menuItem: NSMenuItem) -> Bool {
        
        let isContextualMenu = (menuItem.menu == self.tableView?.menu)
        
        let representedSettingName: String? = {
            guard isContextualMenu else {
                return self.selectedSettingName
            }
            
            guard let clickedRow = self.tableView?.clickedRow, clickedRow != -1 else { return nil }  // clicked blank area
            
            return self.settingNames[safe: clickedRow]
        }()
        menuItem.representedObject = representedSettingName
        
        let itemSelected = (representedSettingName != nil)
        
        // append target setting name to menu titles
        switch menuItem.action {
            case #selector(addSetting), #selector(importSetting(_:)):
                menuItem.isHidden = (isContextualMenu && itemSelected)
            
            case #selector(renameSetting(_:)):
                if let name = representedSettingName, !isContextualMenu {
                    menuItem.title = String(format: "Rename “%@”".localized, name)
                }
                menuItem.isHidden = !itemSelected
            
            case #selector(duplicateSetting(_:)):
                if let name = representedSettingName, !isContextualMenu {
                    menuItem.title = String(format: "Duplicate “%@”".localized, name)
                }
                menuItem.isHidden = !itemSelected
            
            case #selector(deleteSetting(_:)):
                menuItem.isHidden = !itemSelected
            
            case #selector(exportSetting(_:)):
                if let name = representedSettingName, !isContextualMenu {
                    menuItem.title = String(format: "Export “%@”…".localized, name)
                }
                menuItem.isHidden = !itemSelected
                
            case #selector(revealSettingInFinder(_:)):
                if let name = representedSettingName, !isContextualMenu {
                    menuItem.title = String(format: "Reveal “%@” in Finder".localized, name)
                }
                
            case nil:
                return false
            
            default:
                break
        }
        
        return true
    }
    
    
    
    // MARK: Action Messages
    
    /// add setting
    @IBAction func addSetting(_ sender: Any?) {
        
        let settingName: String
        do {
            settingName = try ReplacementManager.shared.createUntitledSetting()
        } catch {
            self.presentError(error)
            return
        }
        
        self.updateSettingList(bySelecting: settingName)
    }
    
    
    /// duplicate selected setting
    @IBAction func duplicateSetting(_ sender: Any?) {
        
        guard let baseName = self.targetSettingName(for: sender) else { return }
        
        let settingName: String
        do {
            settingName = try ReplacementManager.shared.duplicateSetting(name: baseName)
        } catch {
            self.presentError(error)
            return
        }
        
        self.updateSettingList(bySelecting: settingName)
    }
    
    
    /// rename selected setting
    @IBAction func renameSetting(_ sender: Any?) {
        
        guard
            let settingName = self.targetSettingName(for: sender),
            let row = self.settingNames.firstIndex(of: settingName)
            else { return }
        
        self.tableView?.editColumn(0, row: row, with: nil, select: false)
    }
    
    
    /// remove selected setting
    @IBAction func deleteSetting(_ sender: Any?) {
        
        guard let settingName = self.targetSettingName(for: sender) else { return }
        
        self.deleteSetting(name: settingName)
    }
    
    
    /// export selected setting
    @IBAction func exportSetting(_ sender: Any?) {
        
        guard let settingName = self.targetSettingName(for: sender) else { return }
        
        let savePanel = NSSavePanel()
        savePanel.canCreateDirectories = true
        savePanel.canSelectHiddenExtension = true
        savePanel.nameFieldLabel = "Export As:".localized
        savePanel.nameFieldStringValue = settingName
        savePanel.allowedFileTypes = ReplacementManager.shared.filePathExtensions
        
        savePanel.beginSheetModal(for: self.view.window!) { [unowned self] (result: NSApplication.ModalResponse) in
            guard result == .OK else { return }
            
            do {
                try ReplacementManager.shared.exportSetting(name: settingName, to: savePanel.url!, hidesExtension: savePanel.isExtensionHidden)
            } catch {
                self.presentError(error)
            }
        }
    }
    
    
    /// import a setting file
    @IBAction func importSetting(_ sender: Any?) {
        
        let openPanel = NSOpenPanel()
        openPanel.prompt = "Import".localized
        openPanel.resolvesAliases = true
        openPanel.allowsMultipleSelection = false
        openPanel.canChooseDirectories = false
        openPanel.allowedFileTypes = [ReplacementManager.shared.filePathExtension]
        
        openPanel.beginSheetModal(for: self.view.window!) { [weak self] (result: NSApplication.ModalResponse) in
            guard result == .OK else { return }
            
            self?.importSetting(fileURL: openPanel.url!)
        }
    }
    
    
    /// open directory in Application Support in Finder where the selected setting exists
    @IBAction func revealSettingInFinder(_ sender: Any?) {
        
        guard
            let settingName = self.targetSettingName(for: sender),
            let url = ReplacementManager.shared.urlForUserSetting(name: settingName)
            else { return }
        
        NSWorkspace.shared.activateFileViewerSelecting([url])
    }
    
    
    /// reload all setting files in Application Support
    @IBAction func reloadAllSettings(_ sender: Any?) {
        
        ReplacementManager.shared.reloadCache()
    }
    
    
    
    // MARK: Private Methods
    
    /// return setting name which is currently selected in the list table
    private var selectedSettingName: String? {
        
        let index = self.tableView?.selectedRow ?? 0
        
        return self.settingNames[safe: index]
    }
    
    
    /// return representedObject if sender is menu item, otherwise selection in the list table
    private func targetSettingName(for sender: Any?) -> String? {
        
        if let menuItem = sender as? NSMenuItem {
            return menuItem.representedObject as? String
        }
        return self.selectedSettingName
    }
    
    
    /// try to delete given setting
    private func deleteSetting(name: String) {
        
        let alert = NSAlert()
        alert.messageText = String(format: "Are you sure you want to delete “%@”?".localized, name)
        alert.informativeText = "This action cannot be undone.".localized
        alert.addButton(withTitle: "Cancel".localized)
        alert.addButton(withTitle: "Delete".localized)
        if #available(macOS 11, *) {
            alert.buttons.last?.hasDestructiveAction = true
        }
        
        let window = self.view.window!
        alert.beginSheetModal(for: window) { [unowned self] (returnCode: NSApplication.ModalResponse) in
            guard returnCode == .alertSecondButtonReturn else { return }  // cancelled
            
            do {
                try ReplacementManager.shared.removeSetting(name: name)
                
            } catch {
                alert.window.orderOut(nil)
                NSSound.beep()
                NSAlert(error: error).beginSheetModal(for: window)
                return
            }
            
            AudioServicesPlaySystemSound(.moveToTrash)
            
            // add new blank setting to avoid empty list
            if ReplacementManager.shared.settingNames.isEmpty {
                self.addSetting(nil)
            }
        }
    }
    
    
    /// try to import setting file at given URL
    private func importSetting(fileURL: URL) {
        
        do {
            try ReplacementManager.shared.importSetting(fileURL: fileURL)
        } catch {
            // ask for overwriting if a setting with the same name already exists
            self.presentError(error)
        }
    }
    
    
    /// update setting list
    private func updateSettingList(bySelecting selectingName: String? = nil) {
        
        let settingName = selectingName ?? self.selectedSettingName
        
        self.settingNames = ReplacementManager.shared.settingNames
        
        guard let tableView = self.tableView else { return }
        
        tableView.reloadData()
        
        guard
            let name = settingName,
            let row = self.settingNames.firstIndex(of: name)
            else { return }
        tableView.selectRowIndexes([row], byExtendingSelection: false)
        if selectingName != nil {
            tableView.scrollRowToVisible(row)
        }
    }
    
    
    /// save current setting
    private func saveSetting(setting: MultipleReplacement) {
        
        guard let name = self.selectedSettingName else { return }
        
        do {
            try ReplacementManager.shared.save(setting: setting, name: name)
        } catch {
            print(error.localizedDescription)
        }
    }
    
}



// MARK: - MultipleReplacementViewController Delegate

extension MultipleReplacementListViewController: MultipleReplacementViewControllerDelegate {
    
    /// replacement definition being edited in the main view did update
    func didUpdate(setting: MultipleReplacement) {
        
        self.saveSetting(setting: setting)
    }
    
}



// MARK: - TableView Data Source

extension MultipleReplacementListViewController: NSTableViewDataSource {
    
    /// number of settings
    func numberOfRows(in tableView: NSTableView) -> Int {
        
        return self.settingNames.count
    }
    
    
    /// content of table cell
    func tableView(_ tableView: NSTableView, objectValueFor tableColumn: NSTableColumn?, row: Int) -> Any? {
        
        return self.settingNames[row]
    }
    
    
    /// validate when dragged items come to tableView
    func tableView(_ tableView: NSTableView, validateDrop info: NSDraggingInfo, proposedRow row: Int, proposedDropOperation dropOperation: NSTableView.DropOperation) -> NSDragOperation {
        
        // get file URLs from pasteboard
        let pboard = info.draggingPasteboard
        let objects = pboard.readObjects(forClasses: [NSURL.self],
                                         options: [.urlReadingFileURLsOnly: true,
                                                   .urlReadingContentsConformToTypes: [DocumentType.replacement.utType]])
        
        guard let urls = objects, !urls.isEmpty else { return [] }
        
        // highlight text view itself
        tableView.setDropRow(-1, dropOperation: .on)
        
        // show number of setting files
        info.numberOfValidItemsForDrop = urls.count
        
        return .copy
    }
    
    
    /// check acceptability of dragged items and insert them to table
    func tableView(_ tableView: NSTableView, acceptDrop info: NSDraggingInfo, row: Int, dropOperation: NSTableView.DropOperation) -> Bool {
        
        info.enumerateDraggingItems(for: tableView, classes: [NSURL.self],
                                    searchOptions: [.urlReadingFileURLsOnly: true,
                                                    .urlReadingContentsConformToTypes: [DocumentType.replacement.utType]])
        { [weak self] (draggingItem, _, _) in
            
            guard let fileURL = draggingItem.item as? URL else { return }
            
            self?.importSetting(fileURL: fileURL)
        }
        
        return true
    }
    
}



// MARK: - TableView Delegate

extension MultipleReplacementListViewController: NSTableViewDelegate {
    
    /// selection of setting table will change
    func tableView(_ tableView: NSTableView, shouldSelectRow row: Int) -> Bool {
        
        // save the unsaved change before the selection changes
        self.mainViewController?.commitEditing()
        
        return true
    }
    
    
    /// selection of setting table did change
    func tableViewSelectionDidChange(_ notification: Notification) {
        
        guard
            let settingName = self.selectedSettingName,
            let setting = ReplacementManager.shared.setting(name: settingName)
            else { return }
        
        self.mainViewController?.change(setting: setting)
        UserDefaults.standard[.selectedMultipleReplacementSettingName] = settingName
    }
    
}



// MARK: - TextField Delegate

extension MultipleReplacementListViewController: NSTextFieldDelegate {
    
    /// setting name was edited
    func control(_ control: NSControl, textShouldEndEditing fieldEditor: NSText) -> Bool {
        
        // finish if empty (The original name will be restored automatically)
        let newName = fieldEditor.string
        guard
            !newName.isEmpty,
            let oldName = self.selectedSettingName
            else { return true }
        
        do {
            try ReplacementManager.shared.renameSetting(name: oldName, to: newName)
            
        } catch {
            // revert name
            fieldEditor.string = oldName
            
            // show alert
            NSAlert(error: error).beginSheetModal(for: self.view.window!)
            return false
        }
        
        return true
    }
    
}
