//
//  financesApp.swift
//  finances
//
//  Created by Andrés on 9/6/2025.
//

import SwiftUI
import SwiftData

@main
struct financesApp: App {
    
    init() {
        // Mock data is now loaded directly in each account manager's init
        ExpensesCSVImportManager.shared.importAllCSVFiles()
        SavingsCSVImportManager.shared.importAllCSVFiles()
        WiseCSVImportManager.shared.importAllCSVFiles()
    }

    var body: some Scene {
        WindowGroup {
            ContentView()
        }
    }
}
