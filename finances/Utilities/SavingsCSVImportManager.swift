import Foundation
import Combine

/// Responsible for locating Savings CSV files in the user's iCloud Drive and importing them
/// into the `SavingsAccount` at app launch (and can be triggered manually).
final class SavingsCSVImportManager: ObservableObject {
    static let shared = SavingsCSVImportManager()
    private init() {}

    private let fileManager = FileManager.default
    private let account = SavingsAccount.shared

    /// Folder inside the app's iCloud Drive container where CSVs are expected
    private let iCloudSubfolderPath = "Savings"

    // MARK: - Debug Helper
    private func log(_ message: String) {
        #if DEBUG
        print("[SavingsCSVImportManager] \(message)")
        #endif
    }

    // MARK: - Folder Resolution
    private var savingsFolderURL: URL? {
        log("Resolving iCloud Savings folder…")

        guard let containerURL = fileManager.url(forUbiquityContainerIdentifier: nil) else {
            log("⚠️ iCloud container not available.")
            return nil
        }

        let fullPath = containerURL
            .appendingPathComponent("Documents")
            .appendingPathComponent(iCloudSubfolderPath)

        log("Checking iCloud path: \(fullPath.path)")

        var isDir: ObjCBool = false
        if !fileManager.fileExists(atPath: fullPath.path, isDirectory: &isDir) {
            do {
                try fileManager.createDirectory(at: fullPath, withIntermediateDirectories: true, attributes: nil)
            } catch {
                log("❌ Failed to create Savings folder: \(error.localizedDescription)")
                return nil
            }
        }

        return fullPath
    }

    /// Imports any `.csv` files found in the Savings iCloud folder.
    func importAllCSVFiles() {
        guard let folderURL = savingsFolderURL else {
            log("Savings folder not found.")
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