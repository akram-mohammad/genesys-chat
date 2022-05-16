//
//  QueryAvailabilityV2Resource.swift
//  GMSLibrary
//
//  Created by Cindy Wong on 2019-07-05.
//

import Alamofire
import Foundation

/// Resource for querying callback availability (v2)
class QueryAvailabilityV2Resource: ApiResource<AvailabilityV2ResultInternal> {
    init(
        _ service: GmsServiceSettings,
        _ server: GmsServerSettings,
        start: Date?,
        startMs: Int64?,
        numberOfDays: Int?,
        end: Date?,
        endMs: Int64?,
        maxTimeSlots: Int?,
        timezone: String?,
        reportBusy: Bool?
    ) {
        super.init(request: CallbackApiRequest.queryAvailabilityV2(
            service,
            server,
            start: start,
            startMs: startMs,
            numberOfDays: numberOfDays,
            end: end,
            endMs: endMs,
            maxTimeSlots: maxTimeSlots,
            timezone: timezone,
            reportBusy: reportBusy
        )) { (response) -> Result<AvailabilityV2ResultInternal> in
            if let data = response as? Data {
                let decoder = JSONDecoder()
                debugPrint("[QueryAvailabilityV2Resource] data: \(data)")
                let jsonString = String(data: data, encoding: .utf8)!
                debugPrint("[QueryAvailabilityV2Resource] jsonString: \(jsonString)")
                if let availablityResult = try? decoder.decode(AvailabilityV2ResultInternal.self, from: data) {
                    debugPrint("[QueryAvailabilityV2Resource] availabilityResult: \(availablityResult)")
                    return Result.success(availablityResult)
                } else if let callbackException = try? decoder.decode(GmsCallbackErrorResponse.self, from: data) {
                    debugPrint("[QueryAvailabilityV2Resource] exception: \(callbackException)")
                    return Result.failure(GmsApiError.gmsExceptionThrown(exception: callbackException))
                } else {
                    debugPrint("[QueryAvailabilityV2Resource] unknown data: \(data)")
                    return Result.failure(GmsApiError.invalidResponse(data: data))
                }
            } else {
                debugPrint("[QueryAvailabilityV2Resource] empty data")
                return Result.failure(GmsApiError.invalidResponse(data: nil))
            }
        }
    }
}
