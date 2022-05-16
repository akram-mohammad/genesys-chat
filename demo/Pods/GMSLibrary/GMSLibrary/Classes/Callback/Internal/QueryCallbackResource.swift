//
//  QueryCallbackResource.swift
//  GMSLibrary
//
//  Created by Cindy Wong on 2019-07-04.
//

import Alamofire
import Foundation

/// Resource for querying callback by properties
class QueryCallbackResource: ApiResource<[CallbackRecord]> {
    init(
        _ service: GmsServiceSettings,
        _ server: GmsServerSettings,
        operand: CallbackQueryOperand?,
        properties: [String: String]) {
        super.init(request: CallbackApiRequest.queryCallback(
            service, server, operand: operand, properties: properties
        )) { (response) -> Result<[CallbackRecord]> in
            if let data = response as? Data {
                let decoder = JSONDecoder()
                if let callbacks = try? decoder.decode([CallbackRecordInternal].self, from: data) {
                    return Result.success(callbacks)
                } else if let callback = try? decoder.decode(CallbackRecordInternal.self, from: data) {
                    return Result.success([callback])
                } else if let callbackException = try? decoder.decode(GmsCallbackErrorResponse.self, from: data) {
                    return Result.failure(GmsApiError.gmsExceptionThrown(exception: callbackException))
                } else {
                    return Result.failure(GmsApiError.invalidResponse(data: data))
                }
            } else {
                return Result.failure(GmsApiError.invalidResponse(data: nil))
            }
        }
    }
}
