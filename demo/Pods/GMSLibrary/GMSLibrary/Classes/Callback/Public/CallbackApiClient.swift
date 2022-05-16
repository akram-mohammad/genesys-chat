//
//  CallbackApiClient.swift
//  GMSLibrary
//
//  Created by Cindy Wong on 2019-07-08.
//

import Alamofire
import Foundation
import Promises

/// Callback API client.
public struct CallbackApiClient {
    private static let apiClient: ApiClientProtocol = APIClient()

    /// GMS service settings to be used by this client.
    public var service: GmsServiceSettings

    public var server: GmsServerSettings

    /// Create a new instance of `CallbackApiClient`.
    public init(_ service: GmsServiceSettings, _ server: GmsServerSettings) {
        self.service = service
        self.server = server
    }

    /// Starts a callback.
    ///
    /// - returns:
    /// A `Promise` of the service ID of the created callback. The promise is resolved
    /// when the request is successfully completed, or rejected if any error was encountered.
    ///
    /// - parameters:
    ///     - queue: Dispatch queue to use.
    ///     - phoneNumber: Phone number to start the callback for.
    ///     - desiredTime: Desired time of the callback.  If `nil`, the desired time is the current time.
    ///     - properties: Additional properties to attach to the callback.
    ///       Keys without an underscore prefix are User Attached Data.
    public func startCallback(
        on queue: DispatchQueue,
        phoneNumber: String,
        desiredTime: Date? = nil,
        properties: [String: String] = [String: String]()
    ) -> Promise<String> {
        return Promise<String> { fulfill, reject in
            try CallbackApiClient.apiClient.request(StartCallbackResource(
                self.service,
                self.server,
                phoneNumber: phoneNumber,
                desiredTime: desiredTime,
                properties: properties
            ), on: queue) { (statusCode: Int?, result: Result<CallbackRecord>) -> Void in
                debugPrint("[CallbackApiClient] startCallback completion handler")
                switch result {
                case let .success(callbackRecord):
                    // only accept HTTP 200
                    if let status = statusCode, status == 200 {
                        debugPrint("[CallbackApiClient] startCallback succeeded: \(callbackRecord)")
                        fulfill(callbackRecord.callbackId)
                    } else {
                        let error = GmsApiError.invalidHttpStatusCode(statusCode: statusCode, error: nil)
                        debugPrint("[CallbackApiClient] startCallback failed: \(error)")
                        reject(error)
                    }
                case let .failure(error):
                    debugPrint("[CallbackApiClient] startCallback failed with error: \(error)")
                    if let status = statusCode, status != 200 {
                        reject(GmsApiError.invalidHttpStatusCode(statusCode: status, error: error))
                    } else {
                        reject(error)
                    }
                }
            }
        }
    }

    /// Cancels a callback.
    ///
    /// - returns:
    /// A `Promise` of the ID of the cancelled callback.  The promise would be resolved when
    /// the request is successfully completed, or rejected if any error was encountered.
    ///
    /// - parameters:
    ///     - queue: Dispatch queue to use.
    ///     - serviceId: Service ID of the callback to be cancelled.
    ///     - discardOrsFailure: If `true`, GMS can bypass ORS failures and
    ///       marks the cancellation of the callback.  Default is `false`.
    public func cancelCallback(
        on queue: DispatchQueue,
        serviceId: String,
        discardOrsFailure: Bool? = nil
    ) -> Promise<String> {
        return Promise<String>(on: queue) { fulfill, reject in
            try CallbackApiClient.apiClient.request(CancelCallbackResource(
                self.service,
                self.server,
                serviceId,
                discardOrsFailure: discardOrsFailure
            ), on: queue) { (statusCode: Int?, result: Result<EmptyData>) -> Void in
                switch result {
                case .success:
                    if let status = statusCode, status == 200 {
                        fulfill(serviceId)
                    } else {
                        reject(GmsApiError.invalidHttpStatusCode(statusCode: statusCode, error: nil))
                    }
                case let .failure(error):
                    if let status = statusCode, status != 200 {
                        reject(GmsApiError.invalidHttpStatusCode(statusCode: status, error: error))
                    } else {
                        reject(error)
                    }
                }
            }
        }
    }

    /// Reschedules a calllback.
    ///
    /// - returns:
    /// A `Promise` of the ID of the rescheduled callback.  The promise would be resolved when
    /// the request is successfully completed, or rejected if any error was encountered.
    ///
    /// - parameters:
    ///     - queue: Dispatch queue to use.
    ///     - serviceId: Service ID of the callback to be cancelled.
    ///     - newDesiredTime: The new desired time of the callback.  Default is current time.
    ///     - properties: Additional properties to attach to the callback.
    ///       Keys without an underscore prefix are User Attached Data.
    public func rescheduleCallback(
        on queue: DispatchQueue,
        serviceId: String,
        newDesiredTime: Date? = nil,
        properties: [String: String] = [String: String]()
    ) -> Promise<String> {
        return Promise<String>(on: queue) { fulfill, reject in
            try CallbackApiClient.apiClient.request(RescheduleCallbackResource(
                self.service,
                self.server,
                serviceId,
                newDesiredTime: newDesiredTime,
                properties: properties
            ), on: queue) { (statusCode: Int?, result: Result<EmptyData>) -> Void in
                switch result {
                case .success:
                    if let status = statusCode, status == 200 {
                        fulfill(serviceId)
                    } else {
                        reject(GmsApiError.invalidHttpStatusCode(statusCode: statusCode, error: nil))
                    }
                case let .failure(error):
                    if let status = statusCode, status != 200 {
                        reject(GmsApiError.invalidHttpStatusCode(statusCode: status, error: error))
                    } else {
                        reject(error)
                    }
                }
            }
        }
    }

    /// Queries the time slot(s) available on a callback execution service.
    ///
    /// - returns:
    /// A `Promise` of a `Dictionary<Date, Int>` where each key is the start time of a time slot,
    /// and the value is the currently available capacity of the slot.  The promise would be resolved
    /// when the request is successfully completed, or rejected if any error was encountered.
    ///
    /// - parameters:
    ///     - queue: Dispatch queue to use.
    ///     - start: Start of the time period to query availability for.  Default is current time.
    ///     - numberOfDays: The number of days starting from `start` to query the availability for.
    ///     - end: End of the time period to query availability for.  If `numberOfDays` is provided,
    ///       defaults to `numberOfDays` after `start`.  Otherwise, defaults to current time.
    ///     - maxTimeSlots: Maximum number of time slots to return.
    public func queryAvailabilityV1(
        on queue: DispatchQueue,
        start: Date? = nil,
        numberOfDays: Int? = nil,
        end: Date? = nil,
        maxTimeSlots: Int? = nil
    ) -> Promise<[Date: Int]> {
        return Promise<[Date: Int]>(on: queue) { fulfill, reject in
            try CallbackApiClient.apiClient.request(QueryAvailabilityV1Resource(
                self.service,
                self.server,
                start: start,
                numberOfDays: numberOfDays,
                end: end,
                maxTimeSlots: maxTimeSlots
            ), on: queue) { (statusCode: Int?, result: Result<ProposedAvailabilityV1>) -> Void in
                switch result {
                case let .success(availability):
                    if let status = statusCode, status == 200 {
                        fulfill(availability.slots)
                    } else {
                        reject(GmsApiError.invalidHttpStatusCode(statusCode: statusCode, error: nil))
                    }
                case let .failure(error):
                    if let status = statusCode, status != 200 {
                        reject(GmsApiError.invalidHttpStatusCode(statusCode: status, error: error))
                    } else {
                        reject(error)
                    }
                }
            }
        }
    }

    /// Queries the time slot(s) available on a callback execution service.
    ///
    /// - returns:
    /// A `Promise` of a `CallbackAvailabilityV2Result` object.  The promise would be resolved
    /// when the request is successfully completed, or rejected if any error was encountered.
    ///
    /// - parameters:
    ///     - queue: Dispatch queue to use.
    ///     - start: Start of the time period to query availability for.  Default is current time.
    ///     - startMs: Start of the time period to query availability for, in milliseconds since
    ///       1970-01-01 00:00:00.000 UTC.  Alternative to `start`.
    ///     - numberOfDays: The number of days starting from `start` to query the availability for.
    ///     - end: End of the time period to query availability for.  If `numberOfDays` is provided,
    ///       defaults to `numberOfDays` after `start`.  Otherwise, defaults to current time.
    ///     - endMs: Alternative to `end` in milliseconds since 1970-01-01 00:00:00.000 UTC.
    ///     - maxTimeSlots: Maximum number of time slots to return.
    ///     - timezone: Timezone for start and end parameters.  Additionally, the response will return
    ///       `localTime` fields formatted in this timezone.
    ///     - reportBusy: Whether the response should include time slots where the office is open and
    ///       the callbacks are booked to full capacity.  Default is `false`.
    public func queryAvailabilityV2(
        on queue: DispatchQueue,
        start: Date? = nil,
        startMs: Int64? = nil,
        numberOfDays: Int? = nil,
        end: Date? = nil,
        endMs: Int64? = nil,
        maxTimeSlots: Int? = nil,
        timezone: String? = nil,
        reportBusy: Bool? = nil
    ) -> Promise<CallbackAvailabilityV2Result> {
        return Promise<CallbackAvailabilityV2Result>(on: queue) { fulfill, reject in
            try CallbackApiClient.apiClient.request(QueryAvailabilityV2Resource(
                self.service,
                self.server,
                start: start, startMs: startMs,
                numberOfDays: numberOfDays, end: end, endMs: endMs,
                maxTimeSlots: maxTimeSlots, timezone: timezone, reportBusy: reportBusy
            ), on: queue) { (statusCode: Int?, result: Result<AvailabilityV2ResultInternal>) -> Void in
                switch result {
                case let .success(availability):
                    if let status = statusCode, status == 200 {
                        fulfill(availability)
                    } else {
                        reject(GmsApiError.invalidHttpStatusCode(statusCode: statusCode, error: nil))
                    }
                case let .failure(error):
                    if let status = statusCode, status != 200 {
                        reject(GmsApiError.invalidHttpStatusCode(statusCode: status, error: error))
                    } else {
                        reject(error)
                    }
                }
            }
        }
    }

    /// Queries callbacks.
    ///
    /// - returns:
    /// A `Promise` of a `Array<CallbackRecord>` object.  The promise would be resolved
    /// when the request is successfully completed, or rejected if any error was encountered.
    ///
    /// - parameters:
    ///     - queue: Dispatch queue to use.
    ///     - operand: Which operand to use for the query.  Default is `AND`.
    ///     - properties: Properties to query.
    public func queryCallback(
        on queue: DispatchQueue,
        operand: CallbackQueryOperand? = nil,
        properties: [String: String] = [String: String]()
    ) -> Promise<[CallbackRecord]> {
        return Promise<[CallbackRecord]>(on: queue) { fulfill, reject in
            try CallbackApiClient.apiClient.request(QueryCallbackResource(
                self.service,
                self.server,
                operand: operand, properties: properties
            ), on: queue) { (statusCode: Int?, result: Result<[CallbackRecord]>) -> Void in
                switch result {
                case let .success(callbackRecords):
                    if let status = statusCode, status == 200 {
                        fulfill(callbackRecords)
                    } else {
                        reject(GmsApiError.invalidHttpStatusCode(statusCode: statusCode, error: nil))
                    }
                case let .failure(error):
                    if let status = statusCode, status != 200 {
                        reject(GmsApiError.invalidHttpStatusCode(statusCode: status, error: error))
                    } else {
                        reject(error)
                    }
                }
            }
        }
    }

    /// Queries callback by service ID.
    ///
    /// - returns:
    /// A `Promise` of a `CallbackRecord` object.  The promise would be resolved
    /// when the request is successfully completed, or rejected if any error was encountered.
    ///
    /// - parameters:
    ///     - queue: Dispatch queue to use.
    ///     - serviceId: Service ID of the callback to query.
    public func queryCallbackById(on queue: DispatchQueue, serviceId: String) -> Promise<CallbackRecord> {
        return Promise<CallbackRecord>(on: queue) { fulfill, reject in
            try CallbackApiClient.apiClient.request(QueryCallbackByIdResource(
                self.service,
                self.server,
                serviceId
            ), on: queue) { (statusCode: Int?, result: Result<[CallbackRecord]>) -> Void in
                switch result {
                case let .success(callbackRecords):
                    if let status = statusCode, status == 200 {
                        if callbackRecords.count >= 1 {
                            fulfill(callbackRecords[0])
                        } else {
                            reject(GmsApiError.notFound)
                        }
                    } else {
                        reject(GmsApiError.invalidHttpStatusCode(statusCode: statusCode, error: nil))
                    }
                case let .failure(error):
                    if let status = statusCode, status != 200 {
                        reject(GmsApiError.invalidHttpStatusCode(statusCode: status, error: error))
                    } else {
                        reject(error)
                    }
                }
            }
        }
    }
}
