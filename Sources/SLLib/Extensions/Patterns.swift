//
//  File.swift
//  
//
//  Created by Oleh Hudeichuk on 26.05.2020.
//

import Foundation

public let LocalizableStringPattern: String = #".*\"([\s\S]+)\"\s+=\s+\"([\s\S]+)\".*;.*$"#

public let PathWithSwiftExtensionPattern: String = #"^([\s\S]+)\.swift$"#

public let CommentPattern: String = #"^\s*//\s*((?!MARK)[\s\S])+$"#

public let MarkPattern: String = #"^\s*//\s+MARK:.+"#

public let LprojNamePattern: String = #"([^/]+)\.lproj$"#

public let FileNamePattern: String = #"([^/]+)$"#

public let StringFilePattern: String = #"[\s\S]+\.strings$"#

public func lprojFolderNamePattern(_ lang: String) -> String {
    "\(lang)\\.lproj$"
}

public func csvElementPattern(_ separator: String) -> String {
    "((\"[\\s\\S]+?\")|([\\s\\S]+?))(\(separator)|$)"
}

public func stringForLocalizePattern(_ stringPrefix: String) -> String {
    "^([\\s\\S]*)\"\\s*\(stringPrefix)\\.([\\s\\S]+)\\S*?\"([\\s\\S]*)$"
}

public func localizedStringItemsPattern(_ localizedPrefix: String) -> String {
    "^.*\"([\\s\\S]+)(\\.\(localizedPrefix)_\\d+.*?)\"\\s+=\\s+\"([\\s\\S]+)\".*;.*$"
}

public func fileNameFromLocalizedKeyPattern(_ localizedPrefix: String) -> String {
    "^([\\s\\S]+)\\.\(localizedPrefix)_\\d+$"
}

public func localizedKeyItemsPattern(_ localizedPrefix: String) -> String {
    "\"([^\"]+)\\.\(localizedPrefix)_(\\d+)\\s*\""
}

public func numberLocalizedStringPattern(_ localizedPrefix: String) -> String {
    "\(localizedPrefix)_(\\d+)"
}

public func fileLocalizedStringPattern(_ localizedPrefix: String, _ methodName: String) -> String {
    "\"([^\"]+)\\.\(localizedPrefix)_(\\d+)\"\\.\(methodName)"
}
