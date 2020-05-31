//
//  FileManager.swift
//  
//
//  Created by Oleh Hudeichuk on 12.05.2020.
//

import Foundation

extension FileManager {

    func urls(for directory: FileManager.SearchPathDirectory, skipsHiddenFiles: Bool = true ) -> [URL] {
        var fileURLs: [URL] = .init()

        if let documentsURL = urls(for: directory, in: .userDomainMask).first {
            do {
                fileURLs = try contentsOfDirectory(at: documentsURL,
                                                   includingPropertiesForKeys: nil,
                                                   options: skipsHiddenFiles ? [.skipsHiddenFiles] : [] )
            } catch {}
        }

        return fileURLs
    }

    func urls(for directory: String, skipsHiddenFiles: Bool = true ) -> [URL] {
        guard let documentsURL = URL(string: directory) else { return [] }
        do {
            return try contentsOfDirectory(at: documentsURL,
                                           includingPropertiesForKeys: [],
                                           options: skipsHiddenFiles ? [.skipsHiddenFiles] : [] )
        } catch {
            return []
        }
    }

    func isDirectory(_ url: URL) -> Bool {
        (try? url.resourceValues(forKeys: [.isDirectoryKey]))?.isDirectory ?? false
    }

    func isDirectory(_ path: String) -> Bool {
        guard let url = URL(string: path) else { fatalError("\(path) - can not convert to URL") }
        return isDirectory(url)
    }

    func isFile(_ url: URL) -> Bool {
        !isDirectory(url)
    }

    func isFile(_ path: String) -> Bool {
        guard let url = URL(string: path) else { fatalError("\(path) - can not convert to URL") }
        return isFile(url)
    }
}
