//
//  GModelTests.swift
//  ADEduKitToolTests
//
//  Created by Schwarze on 29.08.21.
//

import XCTest

@testable import ADEduKitTool
import ADEduKit

class GModelTests: XCTestCase {
    func testVariant1() throws {
        let modelName = "test1"
        let root = ADEduGenericModel.load(name: modelName + "_model")
        let rootStr = root?.description ?? ""
        Log.log("\(#function): root = \(rootStr)")
        let model = root
        let modelList = root!.deepChildList()
        let meta = ADEduGenericMetadata.load(name: modelName + "_meta")

        XCTAssertEqual(model?.identifier, "com.admadic.adedukit.Test1")
        XCTAssertEqual(model?.identifierPath(), ["com.admadic.adedukit.Test1"])

        
        let exp_vals_en : [String: String] = [
            "id": "com.admadic.adedukit.Test1",
            "title": "Root",
            "type": "metagroup",
            "summary": "Summary-en",
        ]
        for (k, v) in exp_vals_en {
            let val = model?.localValueStringFor(key: k, locale: "en")
            XCTAssertEqual(val, v)
        }
    }
}
