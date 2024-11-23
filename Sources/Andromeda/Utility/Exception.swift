//
//  Exception.swift
//  Andromeda
//
//  Created by WithAndromeda on 10/20/24.
//

func NotImplementedException() {
    print("This feature is not implemented yet.")
}

func ThrowFatalException(error: String) throws {
    do {
        fatalError(error)
    }
}
