//
//  QueryCallbackByIdResource.swift
//  GMSLibrary
//
//  Created by Cindy Wong on 2019-07-08.
//

import Alamofire
import Foundation

/// Resource for querying callback by properties
class QueryCallbackByIdResource: ApiResource<[CallbackRecord]> {
    init(
        _ service: GmsServiceSettings,
        _ server: GmsServerSettings,
        _ serviceId: String) {
        super.init(request: CallbackApiRequest.queryCallbackById(
            service,
            server,
            serviceId
        )) { (response) -> Result<[CallbackRecord]> in
            if let data = response as? Data {
                let decoder = JSONDecoder()
                if let callback = try? decoder.decode(CallbackRecordInternal.self, from: data) {
                    return Result.success([callback])
                } else if let callbacks = try? decoder.decode([CallbackRecordInternal].self, from: data) {
                    return Result.success(callbacks)
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
