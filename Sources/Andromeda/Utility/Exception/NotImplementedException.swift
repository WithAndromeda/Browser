//
//  Exception.swift
//  Andromeda
//
//  Created by WithAndromeda on 10/20/24.
//

enum AndromedaError: Error {
    case notImplemented
    case fatal(String)
}

func NotImplementedException() throws {
    throw AndromedaError.notImplemented
}
