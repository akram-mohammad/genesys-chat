//
//  CodableExtensions.swift
//  GMSLibrary
//
//  Created by Cindy Wong on 2019-07-04.
//

import Foundation

// MARK: - AnyCodingKey

/// An implementation of CodingKey protocol supporting free-formed keys
class AnyCodingKey: CodingKey {
    var stringValue: String
    var intValue: Int?

    required init?(stringValue: String) {
        self.stringValue = stringValue
    }

    required convenience init?(intValue: Int) {
        self.init(stringValue: "\(intValue)")
        self.intValue = intValue
    }
}

// MARK: - KeyedDecodingContainer

/// Add special [String: CustomStringConvertible] mapping decoding where the keyss are free-form strings
extension KeyedDecodingContainer {
    func decode(
        _ type: [String: CustomStringConvertible].Type,
        forKey key: K
    ) throws -> [String: CustomStringConvertible] {
        let container = try nestedContainer(keyedBy: AnyCodingKey.self, forKey: key)
        return try container.decode(type)
    }

    func decodeIfPresent(
        _ type: [String: CustomStringConvertible].Type,
        forKey key: K
    ) throws -> [String: CustomStringConvertible]? {
        guard contains(key) else {
            return nil
        }
        guard try decodeNil(forKey: key) == false else {
            return nil
        }
        return try decode(type, forKey: key)
    }

    func decode(_ type: [CustomStringConvertible].Type, forKey key: K) throws -> [CustomStringConvertible] {
        var container = try nestedUnkeyedContainer(forKey: key)
        return try container.decode(type)
    }

    func decodeIfPresent(_ type: [CustomStringConvertible].Type, forKey key: K) throws -> [CustomStringConvertible]? {
        guard contains(key) else {
            return nil
        }
        guard try decodeNil(forKey: key) == false else {
            return nil
        }
        return try decode(type, forKey: key)
    }

    func decode(_: [String: CustomStringConvertible].Type) throws -> [String: CustomStringConvertible] {
        var dictionary = [String: CustomStringConvertible]()

        for key in allKeys {
            if let boolValue = try? decode(Bool.self, forKey: key) {
                dictionary[key.stringValue] = boolValue
            } else if let stringValue = try? decode(String.self, forKey: key) {
                dictionary[key.stringValue] = stringValue
            } else if let intValue = try? decode(Int.self, forKey: key) {
                dictionary[key.stringValue] = intValue
            } else if let doubleValue = try? decode(Double.self, forKey: key) {
                dictionary[key.stringValue] = doubleValue
            } else if let nestedDictionary = try? decode([String: CustomStringConvertible].self, forKey: key) {
                dictionary[key.stringValue] = nestedDictionary
            } else if let nestedArray = try? decode([CustomStringConvertible].self, forKey: key) {
                dictionary[key.stringValue] = nestedArray
            }
        }
        return dictionary
    }
}

// MARK: - UnkeyedDecodingContainer

/// Add special [String: CustomStringConvertible] mapping decoding where the keys are free-form stings
extension UnkeyedDecodingContainer {
    mutating func decode(_: [CustomStringConvertible].Type) throws -> [CustomStringConvertible] {
        var array: [CustomStringConvertible] = []
        while isAtEnd == false {
            // See if the current value in the JSON array is `null` first,
            // prevent infinite recursion with nested arrays.
            if try decodeNil() {
                continue
            } else if let value = try? decode(Bool.self) {
                array.append(value)
            } else if let value = try? decode(Double.self) {
                array.append(value)
            } else if let value = try? decode(String.self) {
                array.append(value)
            } else if let nestedDictionary = try? decode([String: CustomStringConvertible].self) {
                array.append(nestedDictionary)
            } else if let nestedArray = try? decode([CustomStringConvertible].self) {
                array.append(nestedArray)
            }
        }
        return array
    }

    mutating func decode(_ type: [String: CustomStringConvertible].Type) throws -> [String: CustomStringConvertible] {
        let nestedContainer = try self.nestedContainer(keyedBy: AnyCodingKey.self)
        return try nestedContainer.decode(type)
    }
}
