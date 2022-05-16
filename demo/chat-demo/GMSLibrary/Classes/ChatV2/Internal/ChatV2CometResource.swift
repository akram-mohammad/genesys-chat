//
//  ChatV2CometResource.swift
//  GMSLibrary
//
//  Created by Cindy Wong on 2019-07-16.
//

import Foundation
import Alamofire

class ChatV2CometResource: ApiResource<ChatV2Response> {
    init(request: ChatV2CometApiRequest) {
        debugPrint("[ChatV2Resource] init: \(request)")
        super.init(request: request) { (response) -> Result<ChatV2Response> in
            debugPrint("[ChatV2Resource] parse: \(response)")
            if let data = response as? Data {
                debugPrint("[ChatV2Resource] data: \(data)")
                let decoder = JSONDecoder()
                let jsonString = String(data: data, encoding: .utf8)!
                debugPrint("[ChatV2Resource] jsonString: \(jsonString)")
                if let chatResponse = try? decoder.decode(ChatV2Response.self, from: data) {
                    debugPrint("[ChatV2Resource] chatResponse: \(chatResponse)")
                    if chatResponse.statusCode == 0 {
                        return Result.success(chatResponse)
                    } else {
                        return Result.failure(GmsApiError.chatErrorStatus(response: chatResponse))
                    }
                } else {
                    return Result.failure(GmsApiError.invalidResponse(data: data))
                }
            } else {
                return Result.failure(GmsApiError.invalidResponse(data: nil))
            }
        }
    }
}
