//
//  CallbackQueryOperand.swift
//  GMSLibrary
//
//  Created by Cindy Wong on 2019-07-08.
//

import Foundation

/// Operand for querying callback by properties.
public enum CallbackQueryOperand: String {
    /// Callback must match all of the provided properties.
    case andOp = "AND"

    /// Callback must match one or more of the provided properties.
    case orOp = "OR"
}
