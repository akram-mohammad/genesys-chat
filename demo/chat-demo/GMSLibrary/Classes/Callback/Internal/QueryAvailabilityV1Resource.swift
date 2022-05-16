//
//  QueryAvailabilityV1Resource.swift
//  GMSLibrary
//
//  Created by Cindy Wong on 2019-07-05.
//

import Alamofire
import Foundation

/// Resource for querying callback availability (v1)
class QueryAvailabilityV1Resource: ApiResource<ProposedAvailabilityV1> {
    init(
        _ service: GmsServiceSettings,
        _ server: GmsServerSettings,
        start: Date?,
        numberOfDays: Int?,
        end: Date?,
        maxTimeSlots: Int?
    ) {
        super.init(request: CallbackApiRequest.queryAvailabilityV1(
            service, server, start: start, numberOfDays: numberOfDays,
            end: end, maxTimeSlots: maxTimeSlots
        )) { (response) -> Result<ProposedAvailabilityV1> in
            if let data = response as? Data {
                let decoder = JSONDecoder()
                if let availability = try? decoder.decode(ProposedAvailabilityV1.self, from: data) {
                    return Result.success(availability)
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
