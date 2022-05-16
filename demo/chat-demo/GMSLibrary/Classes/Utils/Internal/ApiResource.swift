//
//  ApiResource.swift
//  GMSLibrary
//
//  Created by Cindy Wong on 2019-07-08.
//

import Alamofire
import Foundation

open class ApiResource<T> {
    let request: ApiRequest
    let parse: (Any) -> Result<T>

    init(request: ApiRequest, parse: @escaping (Any) -> Result<T>) {
        self.request = request
        self.parse = parse
        do {
            let urlrequest = try request.asURLRequest()
            debugPrint("[ApiResource] init: \(urlrequest)")
        } catch {
            debugPrint("[ApiResource] Error: \(error)")
        }
    }
}
