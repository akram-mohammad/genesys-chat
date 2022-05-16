//
//  StartCallbackResource
//  GMSLibrary
//
//  Created by Cindy Wong on 2019-07-04.
//

import Alamofire
import Foundation

/// Resource for starting callback
class StartCallbackResource: ApiResource<CallbackRecord> {
    init(
        _ service: GmsServiceSettings,
        _ server: GmsServerSettings,
        phoneNumber: String,
        desiredTime: Date?,
        properties: [String: String]
    ) {
        let request = CallbackApiRequest.startCallback(
            service,
            server,
            phoneNumber: phoneNumber,
            desiredTime: desiredTime,
            properties: properties)
        debugPrint("[StartCallbackResource] init: \(request)")

        super.init(request: request) { (response) -> Result<CallbackRecord> in
            debugPrint("[StartCallbackResource] parse: \(response)")
            if let data = response as? Data {
                debugPrint("[StartCallbackResource] data: \(data)")
                let decoder = JSONDecoder()
                let jsonString = String(data: data, encoding: .utf8)!
                debugPrint("[StartCallbackResource] jsonString: \(jsonString)")

                if let callbackRecord = try? decoder.decode(CallbackRecordInternal.self, from: data) {
                    debugPrint("[StartCallbackResource] callbackRecord: \(callbackRecord)")
                    return Result.success(callbackRecord)
                } else if let callbackException = try? decoder.decode(GmsCallbackErrorResponse.self, from: data) {
                    debugPrint("[StartCallbackResource] callbackException: \(callbackException)")
                    return Result.failure(GmsApiError.gmsExceptionThrown(exception: callbackException))
                } else {
                    debugPrint("[StartCallbackResource] unknown data: \(data)")
                    return Result.failure(GmsApiError.invalidResponse(data: data))
                }
            } else {
                debugPrint("[StartCallbackResource] empty data")
                return Result.failure(GmsApiError.invalidResponse(data: nil))
            }
        }
    }
}
