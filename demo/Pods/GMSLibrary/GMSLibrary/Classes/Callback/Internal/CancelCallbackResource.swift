//
//  CancelCallbackResource.swift
//  GMSLibrary
//
//  Created by Cindy Wong on 2019-07-05.
//

import Alamofire
import Foundation

/// Resource for cancelling callback
class CancelCallbackResource: ApiResource<EmptyData> {
    init(
        _ service: GmsServiceSettings,
        _ server: GmsServerSettings,
        _ serviceId: String,
        discardOrsFailure: Bool? = nil
    ) {
        let request = CallbackApiRequest.cancelCallback(
            service, server, serviceId, discardOrsFailure: discardOrsFailure
        )
        debugPrint("[CancelCallbackResource] init: \(request)")
        super.init(request: request) { (response) -> Result<EmptyData> in
            if let data = response as? Data {
                debugPrint("[CancelCallbackResource] data: \(data)")
                if let string = String(data: data, encoding: .utf8) {
                    debugPrint("[CancelCallbackResource] string: \(string)")
                    return Result.success(EmptyData())
                }
                if let callbackException = try? JSONDecoder().decode(GmsCallbackErrorResponse.self, from: data) {
                    debugPrint("[CancelCallbackResource] callbackException: \(callbackException)")
                    return Result.failure(GmsApiError.gmsExceptionThrown(exception: callbackException))
                } else {
                    debugPrint("[CancelCallbackResource] unknown data: \(data)")
                    return Result.failure(GmsApiError.invalidResponse(data: data))
                }
            } else {
                debugPrint("[CancelCallbackResource] empty data")
                return Result.success(EmptyData())
            }
        }
    }
}
