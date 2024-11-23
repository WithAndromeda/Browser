//
//  ThrowFatalException.swift
//  Andromeda
//
//  Created by WithAndromeda on 11/23/24.
//

import Foundation
func ThrowFatalException(_ message: String) throws -> Never {
    throw AndromedaError.fatal(message)
}
