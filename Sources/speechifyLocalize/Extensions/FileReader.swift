//
//  FileReader.swift
//  
//
//  Created by Oleh Hudeichuk on 13.05.2020.
//

import Foundation

class FileReader {

    let fileURL: URL
    private var file: UnsafeMutablePointer<FILE>? = nil

    init(fileURL: URL) {
        self.fileURL = fileURL
    }

    deinit {
        if self.file != nil { fatalError("Please, close file descriptor.") }
    }

    func open() throws {
        guard let descriptor = fopen(fileURL.path, "r") else {
            throw NSError(domain: NSPOSIXErrorDomain, code: Int(errno), userInfo: nil)
        }
        self.file = descriptor
    }

    func close() {
        if let descriptor = self.file {
            self.file = nil
            let success: Bool = fclose(descriptor) == 0
            assert(success)
        }
    }

    func readLine(maxLength: Int = 4096) throws -> String? {
        guard let descriptor = self.file else {
            throw NSError(domain: NSPOSIXErrorDomain, code: Int(EBADF), userInfo: nil)
        }
        var buffer = [CChar](repeating: 0, count: maxLength)
        guard fgets(&buffer, Int32(maxLength), descriptor) != nil else {
            if feof(descriptor) != 0 {
                return nil
            } else {
                throw NSError(domain: NSPOSIXErrorDomain, code: Int(errno), userInfo: nil)
            }
        }

        return String(cString: buffer)
    }
}
