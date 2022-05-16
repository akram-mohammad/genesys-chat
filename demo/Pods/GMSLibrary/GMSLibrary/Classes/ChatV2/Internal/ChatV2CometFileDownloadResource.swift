//
//  ChatV2CometFileDownloadResource.swift
//  GMSLibrary
//
//  Created by Cindy Wong on 2019-07-16.
//

import Alamofire
import Foundation

class ChatV2CometFileDownloadResource: ApiResource<URL> {
    init(request: ChatV2CometApiRequest) {
        debugPrint("[ChatV2FileDownloadResource] init: \(request)")
        super.init(request: request) { (response) -> Result<URL> in
            debugPrint("[ChatV2FileDownloadResource] parse: \(response)")
            if let downloadResponse = response as? DefaultDownloadResponse {
                debugPrint("[ChatV2FileDownloadResource] response: \(downloadResponse)")
                if let url = downloadResponse.destinationURL {
                    debugPrint("[ChatV2FileDownloadResource] downloaded URL: \(url)")
                    return Result.success(url)
                }
                return Result.failure(GmsApiError.downloadError(response: downloadResponse))
            }
            return Result.failure(GmsApiError.downloadError(response: nil))
        }
    }
}
