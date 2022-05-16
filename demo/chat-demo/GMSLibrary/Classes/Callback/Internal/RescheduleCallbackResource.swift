//
//  RescheduleCallbackResponse.swift
//  GMSLibrary
//
//  Created by Cindy Wong on 2019-07-05.
//

import Alamofire
import Foundation

/// Resource for rescheduling callback
class RescheduleCallbackResource: ApiResource<EmptyData> {
    init(
        _ service: GmsServiceSettings,
        _ server: GmsServerSettings,
        _ serviceId: String,
        newDesiredTime: Date? = nil,
        properties: [String: String] = [String: String]()
    ) {
        super.init(request: CallbackApiRequest.rescheduleCallback(
            service, server, serviceId, newDesiredTime: newDesiredTime, properties: properties
        )) { (response) -> Result<EmptyData> in
            if let data = response as? Data {
                if let callbackException = try? JSONDecoder().decode(GmsCallbackErrorResponse.self, from: data) {
                    return Result.failure(GmsApiError.gmsExceptionThrown(exception: callbackException))
                } else {
                    return Result.failure(GmsApiError.invalidResponse(data: data))
                }
            } else {
                return Result.success(EmptyData())
            }
        }
    }
}
