//
//  File.swift
//  
//
//  Created by Oleh Hudeichuk on 26.05.2020.
//

import Foundation

let LocalizableStringPattern: String = #"^\"([\s\S]+)\"\s+=\s+\"([\s\S]+)\".*;.*$"#

let PathWithSwiftExtensionPattern: String = #"^([\s\S]+)\.swift$"#

let CommentPattern: String = #"^\s*//\s*((?!MARK)[\s\S])+$"#

let MarkPattern: String = #"^\s*//\s+MARK:.+"#

let LprojNamePattern: String = #"([^/]+)\.lproj$"#

let FileNamePattern: String = #"([^/]+)$"#

let StringFilePattern: String = #"[\s\S]+\.strings$"#

func lprojFolderNamePattern(_ lang: String) -> String {
    "\(lang)\\.lproj$"
}

func csvElementPattern(_ separator: String) -> String {
    "((\"[\\s\\S]+?\")|([\\s\\S]+?))(\(separator)|$)"
}

func stringForLocalizePattern(_ stringPrefix: String) -> String {
    "^([\\s\\S]*)\"\\s*\(stringPrefix)\\.([\\s\\S]+)\\S*?\"([\\s\\S]*)$"
}

func localizedStringItemsPattern(_ localizedPrefix: String) -> String {
    "^.*\"([\\s\\S]+)(\\.\(localizedPrefix)_\\d+.*?)\"\\s+=\\s+\"([\\s\\S]+)\".*;.*$"
}

func fileNameFromLocalizedKeyPattern(_ localizedPrefix: String) -> String {
    "^([\\s\\S]+)\\.\(localizedPrefix)_\\d+$"
}

func localizedKeyItemsPattern(_ localizedPrefix: String) -> String {
    "\"([^\"]+)\\.\(localizedPrefix)_(\\d+)\\s*\""
}

func numberLocalizedStringPattern(_ localizedPrefix: String) -> String {
    "\(localizedPrefix)_(\\d+)"
}

func fileLocalizedStringPattern(_ localizedPrefix: String, _ methodName: String) -> String {
    "\"([^\"]+)\\.\(localizedPrefix)_(\\d+)\"\\.\(methodName)"
}
