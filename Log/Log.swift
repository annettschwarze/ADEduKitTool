//
//  Log.swift
//  ADEduKitTool
//
//  Created by Annett Schwarze on 12.02.23.
//

import Foundation

/**
 A primitive log class, which uses ``Swift.print`` and only prints when ``DEBUG``is defined.
 */
final class Log {
    static func log(_ msg: any StringProtocol) {
        #if DEBUG
        Swift.print(msg)
        #endif
    }
}
