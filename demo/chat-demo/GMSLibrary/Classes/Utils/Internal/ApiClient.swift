//
//  ApiClient.swift
//  GMSLibrary
//
//  Created by Cindy Wong on 2019-07-08.
//

import Alamofire
import Foundation

protocol ApiClientProtocol {
    func request<T>(
        _ resource: ApiResource<T>,
        on queue: DispatchQueue?,
        completion: @escaping (Int?, Result<T>) -> Void
    ) throws

    func multipartFormDataUpload<T>(
        _ resource: ApiResource<T>,
        on queue: DispatchQueue?,
        encodingErrorHandler: @escaping (Error) -> Void,
        encodingCompletionHandler: @escaping (UploadRequest) -> Void,
        completion: @escaping (Int?, Result<T>) -> Void
    ) throws

    func download<T>(
        _ resource: ApiResource<T>,
        on queue: DispatchQueue?,
        requestBuiltHandler: @escaping (DownloadRequest) -> Void,
        completion: @escaping (Int?, Result<T>) -> Void
    ) throws
}

struct APIClient: ApiClientProtocol {
    func request<T>(
        _ resource: ApiResource<T>,
        on queue: DispatchQueue?,
        completion: @escaping (Int?, Result<T>) -> Void
    ) throws {
        let request = Alamofire.request(resource.request)
        debugPrint("[APIClient] Alamofire request: \(request)")
        request.responseData(queue: queue) { response in
            debugPrint("[APIClient] responseData Request: \(String(describing: response.request))")
            debugPrint("[APIClient] responseData Response: \(String(describing: response.response))")
            debugPrint("[APIClient] responseData Result: \(response.result)")
            let statusCodeStr = String(describing: response.response?.statusCode)
            debugPrint("[APIClient] responseData HTTP status code: \(statusCodeStr)")
            completion(response.response?.statusCode, response.result.flatMap2(resource.parse))
        }
        debugPrint("[APIClient] Alamofire request completed")
    }

    func multipartFormDataUpload<T>(
        _ resource: ApiResource<T>,
        on queue: DispatchQueue?,
        encodingErrorHandler: @escaping (Error) -> Void,
        encodingCompletionHandler: @escaping (UploadRequest) -> Void,
        completion: @escaping (Int?, Result<T>) -> Void
    ) throws {
        let apiRequest = resource.request
        debugPrint("[APIClient] multipartFormDataUpload API request: \(apiRequest)")
        let formDataHandler = { (formData: MultipartFormData) in
            do {
                try apiRequest.appendMultipartFormData(formData: formData)
            } catch {
                debugPrint("[APIClient] multipartFormDataUpload not supported by request")
            }
        }
        let encodingCompletion = { (encodingResult: SessionManager.MultipartFormDataEncodingResult) in
            switch encodingResult {
            case .success(let uploadRequest, _, _):
                debugPrint("[APIClient] multipartFormDataUpload encoding succeeded.  UploadRequest: \(uploadRequest)")
                encodingCompletionHandler(uploadRequest)
                uploadRequest.responseData(queue: queue) { response in
                    debugPrint("[APIClient] multipartFormDataUpload Request: \(String(describing: response.request))")
                    debugPrint("[APIClient] multipartFormDataUpload Response: \(String(describing: response.response))")
                    debugPrint("[APIClient] multipartFormDataUpload Result: \(response.result)")
                    let statusCodeStr = String(describing: response.response?.statusCode)
                    debugPrint("[APIClient] multipartFormDataUpload HTTP status code: \(statusCodeStr)")
                    completion(response.response?.statusCode, response.result.flatMap2(resource.parse))
                }
            case let .failure(error):
                encodingErrorHandler(error)
            }
        }
        debugPrint("[APIClient] multipartFormDataUpload request completed")
        return Alamofire.upload(multipartFormData: formDataHandler,
                                with: apiRequest,
                                encodingCompletion: encodingCompletion)
    }

    func download<T>(
        _ resource: ApiResource<T>,
        on _: DispatchQueue?,
        requestBuiltHandler: @escaping (DownloadRequest) -> Void,
        completion: @escaping (Int?, Result<T>) -> Void
    ) throws {
        let apiRequest = resource.request
        debugPrint("[APIClient] download API request: \(apiRequest)")
        let destination = DownloadRequest.suggestedDownloadDestination(for: .documentDirectory)
        let request = Alamofire.download(apiRequest, to: destination)
        requestBuiltHandler(request)
        request.response { response in
            debugPrint("[APIClient] download Request: \(String(describing: response.request))")
            debugPrint("[APIClient] download Response: \(String(describing: response.response))")
            let statusCodeStr = String(describing: response.response?.statusCode)
            debugPrint("[APIClient] download HTTP status code: \(statusCodeStr)")
            completion(response.response?.statusCode, resource.parse(response))
        }
    }
}

extension Alamofire.Result {
    public func flatMap2<T>(_ transform: (Value) throws -> Result<T>) -> Result<T> {
        switch self {
        case let .success(value):
            do {
                return try transform(value)
            } catch {
                return .failure(error)
            }
        case let .failure(error):
            return .failure(error)
        }
    }
}
