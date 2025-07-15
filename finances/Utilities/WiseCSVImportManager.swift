import Foundation
import Combine

/// Responsible for locating Wise CSV files in the user's iCloud Drive and importing them
/// into the `WiseAccount` at app launch (and can be triggered manually).
final class WiseCSVImportManager: ObservableObject {
    static let shared = WiseCSVImportManager()
    private init() {}

    private let fileManager = FileManager.default
    private let account = WiseAccount.shared

    /// Folder inside the app's iCloud Drive container where CSVs are expected
    private let iCloudSubfolderPath = "Wise"

    // MARK: - Debug Helper
    private func log(_ message: String) {
        #if DEBUG
        print("[WiseCSVImportManager] \(message)")
        #endif
    }

    // MARK: - Folder Resolution
    private var wiseFolderURL: URL? {
        log("Resolving iCloud Wise folder…")

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
                log("❌ Failed to create Wise folder: \(error.localizedDescription)")
                return nil
            }
        }

        return fullPath
    }

    /// Imports any `.csv` files found in the Wise iCloud folder.
    func importAllCSVFiles() {
        guard let folderURL = wiseFolderURL else {
            log("Wise folder not found.")
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