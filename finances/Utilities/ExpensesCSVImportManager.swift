import Foundation
import Combine

/// Responsible for locating CSV files in the user's iCloud Drive and importing them
/// into the `ExpensesAccount` at app launch (and can be triggered manually).
final class ExpensesCSVImportManager: ObservableObject {
    static let shared = ExpensesCSVImportManager()
    private init() {}

    private let fileManager = FileManager.default
    private let account = ExpensesAccount.shared

    /// Path components inside the iCloud container's Documents folder.
    private let iCloudSubfolderPath = "Expenses"

    // MARK: - Debug Helper
    private func log(_ message: String) {
        #if DEBUG
        print("[ExpensesCSVImportManager] \(message)")
        #endif
    }

    // MARK: - Folder Resolution
    private var expensesFolderURL: URL? {
        log("Attempting to resolve iCloud Expenses folder…")

        // Resolve the iCloud container
        guard let containerURL = fileManager.url(forUbiquityContainerIdentifier: nil) else {
            log("⚠️ iCloud container not available.")
            return nil
        }

        // iCloud Drive starts at /Documents/ for the app’s container
        let fullPath = containerURL
            .appendingPathComponent("Documents")
            .appendingPathComponent(iCloudSubfolderPath)

        log("Checking iCloud path: \(fullPath.path)")

        // Create directory if it doesn’t exist
        var isDir: ObjCBool = false
        if !fileManager.fileExists(atPath: fullPath.path, isDirectory: &isDir) {
            do {
                try fileManager.createDirectory(at: fullPath, withIntermediateDirectories: true, attributes: nil)
            } catch {
                log("❌ Failed to create Expenses folder: \(error.localizedDescription)")
                return nil
            }
        }

        return fullPath
    }

    /// Imports any `.csv` files found in the Expenses iCloud folder.
    func importAllCSVFiles() {
        guard let folderURL = expensesFolderURL else {
            log("iCloud Expenses folder not found.")
            return
        }

        log("Importing CSVs from: \(folderURL.path)")

        guard let enumerator = fileManager.enumerator(at: folderURL, includingPropertiesForKeys: nil) else {
            log("❌ Failed to enumerate files in folder.")
            return
        }

        var csvFiles: [URL] = []
        for case let fileURL as URL in enumerator {
            if fileURL.pathExtension.lowercased() == "csv" {
                csvFiles.append(fileURL)
            }
        }

        log("Discovered \(csvFiles.count) CSV file(s)")

        if !csvFiles.isEmpty {
            log("Beginning import of CSV files…")
            account.importTransactions(fromCSV: csvFiles)
        }
    }
}