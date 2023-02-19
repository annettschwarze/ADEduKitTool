//
//  SecretTmpl.swift
//  ADEduKitTool
//
//  Created by Schwarze on 11.02.23.
//

import Foundation

/**
 TODO: Copy this to _Secret/Secret.swift, copy your p8 file to _Secret/, change all references to the struct `SecretTemplate` to `Secret` and remove the deprecated marker in Secret.swift.
 */
@available(*, deprecated, message: "Use your struct Secret in group _Secret instead")
struct SecretTemplate {
    static let classKitKeyFilename = "Your_ClassKitCatalog_Key_File_KEYID.p8"
    static let keyId = "KEYID"
    static let devId = "DEVID"
}
