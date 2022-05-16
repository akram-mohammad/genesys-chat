//
//  ChatV2FileLimits.swift
//  GMSLibrary
//
//  Created by Cindy Wong on 2019-07-10.
//

import Foundation

/**
 Chat session file limits received from GMS.
 
 This is an immutable object.
 */
public class ChatV2FileLimits: CustomStringConvertible, Hashable, Codable {
    
    /// Number of download attempts allowed.
    public let downloadAttempts: UInt
    
    /// Maximum number of file uploads allowed.
    public let uploadMaxFiles: UInt
    
    /// Maximum size for a single upload file.
    public let uploadMaxFileSize: UInt64
    
    /// Maximum size for all upload files combined.
    public let uploadMaxTotalSize: UInt64
    
    /// Whether upload needs agent.
    public let uploadNeedAgent: Bool
    
    /// Allowed file types for uploads.
    public let uploadFileTypes: [String]
    
    /// Number of uploads already used.
    public let usedUploadMaxFiles: UInt
    
    /// Total upload size already used.
    public let usedUploadMaxTotalSize: UInt64
    
    /// Number of download attempts already used.
    public let usedDownloadAttempts: UInt
    
    /// Whether the number of upload files allowed is decremented after a file is deleted.
    public let deleteFile: String

    /// Whether upload is allowed.
    public var isUploadAllowed: Bool {
        return uploadMaxFiles > 0 &&
            usedUploadMaxFiles < uploadMaxFiles &&
            uploadMaxTotalSize > 0
            && usedUploadMaxTotalSize < uploadMaxTotalSize
    }

    /// Whether download is allowed.
    public var isDownloadAllowed: Bool {
        return downloadAttempts > 0 &&
            usedDownloadAttempts < downloadAttempts
    }

    // MARK: - CustomStringConvertible

    public var description: String {
        return String(describing: ChatV2FileLimits.self) + "@\(hashValue)[" +
            "downloadAttempts=\(downloadAttempts)," +
            "uploadMaxFiles=\(uploadMaxFiles)," +
            "uploadMaxFileSize=\(uploadMaxFileSize)," +
            "uploadMaxTotalSize=\(uploadMaxTotalSize)," +
            "uploadNeedAgent=\(uploadNeedAgent)," +
            "uploadFileTypes=\(uploadFileTypes)," +
            "usedUploadMaxFiles=\(usedUploadMaxFiles)," +
            "usedUploadMaxTotalSize=\(usedUploadMaxTotalSize)," +
            "usedDownloadAttempts=\(usedDownloadAttempts)," +
            "deleteFile=\(deleteFile)]"
    }

    // MARK: - Equatable

    public static func == (lhs: ChatV2FileLimits, rhs: ChatV2FileLimits) -> Bool {
        return lhs.downloadAttempts == rhs.downloadAttempts &&
            lhs.uploadMaxFiles == rhs.uploadMaxFiles &&
            lhs.uploadMaxFileSize == rhs.uploadMaxFileSize &&
            lhs.uploadMaxTotalSize == rhs.uploadMaxTotalSize &&
            lhs.uploadNeedAgent == rhs.uploadNeedAgent &&
            lhs.uploadFileTypes == rhs.uploadFileTypes &&
            lhs.usedUploadMaxFiles == rhs.usedUploadMaxFiles &&
            lhs.usedUploadMaxTotalSize == rhs.usedUploadMaxTotalSize &&
            lhs.usedDownloadAttempts == rhs.usedDownloadAttempts &&
            lhs.deleteFile == rhs.deleteFile
    }

    // MARK: - Hashable

    public func hash(into hasher: inout Hasher) {
        hasher.combine(downloadAttempts)
        hasher.combine(uploadMaxFiles)
        hasher.combine(uploadMaxFileSize)
        hasher.combine(uploadMaxTotalSize)
        hasher.combine(uploadNeedAgent)
        hasher.combine(uploadFileTypes)
        hasher.combine(usedUploadMaxFiles)
        hasher.combine(usedUploadMaxTotalSize)
        hasher.combine(usedDownloadAttempts)
        hasher.combine(deleteFile)
    }

    // MARK: - Codable

    enum CodingKeys: String, CodingKey {
        case downloadAttempts = "download-attempts"
        case uploadMaxFiles = "upload-max-files"
        case uploadMaxFileSize = "upload-max-file-size"
        case uploadMaxTotalSize = "upload-max-total-size"
        case uploadNeedAgent = "upload-need-agent"
        case uploadFileTypes = "upload-file-types"
        case usedUploadMaxFiles = "used-upload-max-files"
        case usedUploadMaxTotalSize = "used-upload-max-total-size"
        case usedDownloadAttempts = "used-download-attempts"
        case deleteFile = "delete-file"
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(downloadAttempts.description, forKey: .downloadAttempts)
        try container.encode(uploadMaxFiles.description, forKey: .uploadMaxFiles)
        try container.encode(uploadMaxFileSize.description, forKey: .uploadMaxFileSize)
        try container.encode(uploadMaxTotalSize.description, forKey: .uploadMaxTotalSize)
        try container.encode(uploadNeedAgent.description, forKey: .uploadNeedAgent)
        let filetypes = uploadFileTypes.joined(separator: ":")
        try container.encode(filetypes, forKey: .uploadFileTypes)
        try container.encode(usedUploadMaxFiles.description, forKey: .usedUploadMaxFiles)
        try container.encode(usedUploadMaxTotalSize.description, forKey: .usedUploadMaxTotalSize)
        try container.encode(usedDownloadAttempts.description, forKey: .usedDownloadAttempts)
        try container.encode(deleteFile.description, forKey: .deleteFile)
    }

    public required convenience init(from decoder: Decoder) throws {
        let values = try decoder.container(keyedBy: CodingKeys.self)
        var userData = [CodingKeys: String]()
        for key in values.allKeys {
            userData[key] = try values.decode(String.self, forKey: key)
        }
        try self.init(userData: userData)
    }

    // MARK: - init

    convenience init(userData: [String: String]) throws {
        debugPrint("[ChatV2FileLimits] converting userData \(userData)")
        try self.init(
            userData:
            Dictionary(
                uniqueKeysWithValues:
                userData.filter { key, _ in
                    CodingKeys(rawValue: key) != nil
                }.map { key, value in
                    (CodingKeys(rawValue: key)!, value)
                }
            )
        )
    }

    init(userData: [CodingKeys: String]) throws {
        guard let downloadAttemptsStr = userData[.downloadAttempts],
            let downloadAttempts = UInt(downloadAttemptsStr) else {
            let error = GmsApiError.invalidParameter(
                key: CodingKeys.downloadAttempts.stringValue,
                value: userData[.downloadAttempts])
            debugPrint("[ChatV2FileLimits] Error: \(error)")
            throw error
        }
        self.downloadAttempts = downloadAttempts

        guard let uploadMaxFilesStr = userData[.uploadMaxFiles],
            let uploadMaxFiles = UInt(uploadMaxFilesStr) else {
            let error = GmsApiError.invalidParameter(
                key: CodingKeys.uploadMaxFiles.stringValue,
                value: userData[.uploadMaxFiles])
            debugPrint("[ChatV2FileLimits] Error: \(error)")
            throw error
        }
        self.uploadMaxFiles = uploadMaxFiles

        guard let uploadMaxFileSizeStr = userData[.uploadMaxFileSize],
            let uploadMaxFileSize = UInt64(uploadMaxFileSizeStr) else {
            let error = GmsApiError.invalidParameter(
                key: CodingKeys.uploadMaxFileSize.stringValue,
                value: userData[.uploadMaxFileSize])
            debugPrint("[ChatV2FileLimits] Error: \(error)")
            throw error
        }
        self.uploadMaxFileSize = uploadMaxFileSize

        guard let uploadMaxTotalSizeStr = userData[.uploadMaxTotalSize],
            let uploadMaxTotalSize = UInt64(uploadMaxTotalSizeStr) else {
            let error = GmsApiError.invalidParameter(
                key: CodingKeys.uploadMaxTotalSize.stringValue,
                value: userData[.uploadMaxTotalSize])
            debugPrint("[ChatV2FileLimits] Error: \(error)")
            throw error
        }
        self.uploadMaxTotalSize = uploadMaxTotalSize

        guard let usedUploadMaxFilesStr = userData[.usedUploadMaxFiles],
            let usedUploadMaxFiles = UInt(usedUploadMaxFilesStr) else {
            let error = GmsApiError.invalidParameter(
                key: CodingKeys.usedUploadMaxFiles.stringValue,
                value: userData[.usedUploadMaxFiles])
            debugPrint("[ChatV2FileLimits] Error: \(error)")
            throw error
        }
        self.usedUploadMaxFiles = usedUploadMaxFiles

        guard let usedUploadMaxTotalSizeStr = userData[.usedUploadMaxTotalSize],
            let usedUploadMaxTotalSize = UInt64(usedUploadMaxTotalSizeStr) else {
            let error = GmsApiError.invalidParameter(
                key: CodingKeys.usedUploadMaxTotalSize.stringValue,
                value: userData[.usedUploadMaxTotalSize])
            debugPrint("[ChatV2FileLimits] Error: \(error)")
            throw error
        }
        self.usedUploadMaxTotalSize = usedUploadMaxTotalSize

        guard let usedDownloadAttemptsStr = userData[.usedDownloadAttempts],
            let usedDownloadAttempts = UInt(usedDownloadAttemptsStr) else {
            let error = GmsApiError.invalidParameter(
                key: CodingKeys.usedDownloadAttempts.stringValue,
                value: userData[.usedDownloadAttempts])
            debugPrint("[ChatV2FileLimits] Error: \(error)")
            throw error
        }
        self.usedDownloadAttempts = usedDownloadAttempts

        guard let uploadNeedAgentStr = userData[.uploadNeedAgent],
            let uploadNeedAgent = Bool(uploadNeedAgentStr) else {
            let error = GmsApiError.invalidParameter(
                key: CodingKeys.uploadNeedAgent.stringValue,
                value: userData[.uploadNeedAgent])
            debugPrint("[ChatV2FileLimits] Error: \(error)")
            throw error
        }
        self.uploadNeedAgent = uploadNeedAgent

        guard let fileTypes = userData[.uploadFileTypes] else {
            let error = GmsApiError.invalidParameter(
                key: CodingKeys.uploadFileTypes.stringValue,
                value: userData[.uploadFileTypes])
            debugPrint("[ChatV2FileLimits] Error: \(error)")
            throw error
        }
        uploadFileTypes = fileTypes.components(separatedBy: ":").sorted()

        guard let deleteFile = userData[.deleteFile] else {
            let error = GmsApiError.invalidParameter(
                key: CodingKeys.deleteFile.stringValue,
                value: userData[.deleteFile])
            debugPrint("[ChatV2FileLimits] Error: \(error)")
            throw error
        }
        self.deleteFile = deleteFile
    }
}
