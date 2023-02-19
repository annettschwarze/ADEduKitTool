//
//  ClassKitClient.swift
//  ADEduKitTool
//
//  Created by Schwarze on 28.08.21.
//

import Foundation
import CryptoKit
import ADEduKit

final class Token {
    static let sharedInstance = Token()

    lazy var classKitKey: String = {
        let filename = SecretTemplate.classKitKeyFilename
        let basename: String
        let ext: String
        if let dot = filename.lastIndex(of: ".") {
            basename = String(filename.prefix(upTo: dot))
            ext = String(filename.suffix(from: filename.index(after: dot)))
        } else {
            basename = filename
            ext = ""
        }
        let url = Bundle.main.url(forResource: basename, withExtension: ext)!
        let data = try! Data.init(contentsOf: url)
        return String(data: data, encoding: .utf8)!
    }()

    var _tokenExpire: Date? = nil
    var _token: String? = nil

    func token() -> String {
        let limit = Date().addingTimeInterval(1 * 60) // +1 minute
        if let x = _tokenExpire, x < limit {
            _token = nil
        }
        if let t = _token {
            return t
        } else {
            let (t, e) = Token.create()
            _token = t
            _tokenExpire = e
            return t
        }
    }

    fileprivate static func b64(data: Data) -> String {
        return data.base64EncodedString()
            .replacingOccurrences(of: "+", with: "-")
            .replacingOccurrences(of: "/", with: "_")
            .replacingOccurrences(of: "=", with: "")
    }

    fileprivate static func create() -> (String, Date) {
        let _iat = Date()
        let _exp = Date().addingTimeInterval(60 * 60) // + 60 min
        struct Hdr: Encodable {
            let alg = "ES256"
            let typ = "JWT"
            let kid = SecretTemplate.keyId // Key-ID
        }
        struct Pld: Encodable {
            let iss = SecretTemplate.devId // Dev-ID
            let iat : Int
            let exp : Int
            init(iat: Date, exp: Date) {
                self.iat = Int(iat.timeIntervalSince1970)
                self.exp = Int(exp.timeIntervalSince1970)
            }
        }
        let hdr = Hdr()
        let pld = Pld(iat: _iat, exp: _exp)

        let classKitKey = sharedInstance.classKitKey

        let hdrJson = try! JSONEncoder().encode(hdr)
        let hdrB64 = b64(data: hdrJson)

        let pldJson = try! JSONEncoder().encode(pld)
        let pldB64 = b64(data: pldJson)

        let tokenData = (hdrB64 + "." + pldB64).data(using: .utf8)!

        let prvkey = try! P256.Signing.PrivateKey(pemRepresentation: classKitKey)
        let sig = try! prvkey.signature(for: tokenData).rawRepresentation
        let sigB64 = b64(data: sig)

        let token = [hdrB64, pldB64, sigB64].joined(separator: ".")

        return (token, _exp)
    }
}

final class ClassKitClient {
    static let shared = ClassKitClient()
    
    static let BAD_RESPONSE: Int = 999
    static let BAD_REQUEST: Int = 998
    // Example:
    // "https://classkit-catalog.apple.com/v1/contexts?identifierPath=%5B%22com.apple.example.app%22%5D&locale=en-us&environment=production" -H "Authorization: Bearer <JWT>"

    func req(op: String, model: ADEduGenericModel, idPath: [String], locale: String, env: String) -> URLRequest {
        var comps = URLComponents(string: "https://classkit-catalog.apple.com/v1/contexts")
        comps?.queryItems = [
            URLQueryItem(name: "identifierPath", value: "[" + idPath.map({"\"" + $0 + "\""}).joined(separator: ",") + "]"),
            URLQueryItem(name: "locale", value: locale),
            URLQueryItem(name: "environment", value: env)
        ]
        let url = comps!.url
        var req = URLRequest(url: url!)
        req.httpMethod = op
        let auth = "Bearer " + Token.sharedInstance.token()
        req.setValue(auth, forHTTPHeaderField: "Authorization")
        return req
    }

    func getContext(model: ADEduGenericModel, idPath: [String], locale: String, env: String, completion: ( (_ error: Error?) -> Void)?) {
        model.opState = .busy
        let req = req(op: "GET", model: model, idPath: idPath, locale: locale, env: env)
        let task = URLSession.shared.dataTask(with: req) {(data, response, error) in
            let statusCode = (response as? HTTPURLResponse)?.statusCode ?? Self.BAD_RESPONSE
            Log.log("\(#function): st:\(statusCode) error: \(error?.localizedDescription ?? "nil") req: \(req)")
            let state = ADEduGenericModelState(url: req.url, statusCode: statusCode, error: error, data: data)
            model.add(state: state, locale: locale, op: "get")
            completion?(error)
        }
        task.resume()
    }

    func removeContext(model: ADEduGenericModel, idPath: [String], locale: String, env: String, completion: ( (_ error: Error?) -> Void)?) {
        model.opState = .busy
        let req = req(op: "DELETE", model: model, idPath: idPath, locale: locale, env: env)
        let task = URLSession.shared.dataTask(with: req) {(data, response, error) in
            let statusCode = (response as? HTTPURLResponse)?.statusCode ?? Self.BAD_RESPONSE
            Log.log("\(#function): st:\(statusCode) error: \(error?.localizedDescription ?? "nil") req: \(req)")
            let state = ADEduGenericModelState(url: req.url, statusCode: statusCode, error: error, data: data)
            model.add(state: state, locale: locale, op: "del")
            completion?(error)
        }
        task.resume()
    }

    func putContext(model: ADEduGenericModel, idPath: [String], locale: String, env: String, ctxData: Any, completion: ( (_ error: Error?) -> Void)?) {
        model.opState = .busy
        var req = req(op: "POST", model: model, idPath: idPath, locale: locale, env: env)
        req.setValue("application/json", forHTTPHeaderField: "Content-Type")
        req.httpMethod = "POST"
        let data = ["contexts": [ctxData]]
        let pl: Data
        do {
            pl = try JSONSerialization.data(withJSONObject: data, options: .prettyPrinted)
            req.httpBody = pl
        } catch {
            pl = Data()
            let state = ADEduGenericModelState(url: req.url, payload: pl, statusCode: Self.BAD_REQUEST, error: error, data: nil)
            model.add(state: state, locale: locale, op: "put")
            completion?(error)
            return
        }
        let task = URLSession.shared.dataTask(with: req) {(data, response, error) in
            let statusCode = (response as? HTTPURLResponse)?.statusCode ?? Self.BAD_RESPONSE
            Log.log("\(#function): st:\(statusCode) error: \(error?.localizedDescription ?? "nil") req: \(req)")
            let state = ADEduGenericModelState(url: req.url, payload: pl, statusCode: statusCode, error: error, data: data)
            model.add(state: state, locale: locale, op: "put")
            completion?(error)
        }
        task.resume()
    }
}

final class ClassKitOpQueue {
    var client: ClassKitClient? = nil
    var queueModels: [ADEduGenericModel]? = nil
    var queueLocale: String? = nil
    var queueEnv: String? = nil
    var queueMeta: ADEduGenericMetadata? = nil
    var queueOp: String? = nil
    var queueInitialSize: Int = 1

    init(client: ClassKitClient, models: [ADEduGenericModel], meta: ADEduGenericMetadata, locale: String, env: String) {
        self.client = client
        // Items are popped from the end, so to keep the order when processing, reverse the array:
        queueModels = models.reversed()
        queueInitialSize = models.count
        queueLocale = locale
        queueEnv = env
        queueMeta = meta
    }

    func run(op: String, update: ((_: Float) -> Void)?) {
        Log.log("\(#function): running op queue with op: \(op)")
        runAllImpl(op: op, update: update)
    }

    func cancel() {
        if let mq = queueModels {
            Log.log("\(#function): cancelling with queue size: \(mq.count)")
        }
        self.queueModels = nil
    }

    func runAllImpl(op: String, update: ((_: Float) -> Void)?) {
        runNextImpl(op: op, update: update)
    }

    func runNextImpl(op: String, update: ((_: Float) -> Void)?) {
        DispatchQueue.global(qos: .userInitiated).async {
            // If any of the parameters is gone, do a full stop:
            guard let m = self.queueModels?.popLast(),
                  let loc = self.queueLocale,
                  let env = self.queueEnv,
                  let met = self.queueMeta else {
                self.cancel()
                return
            }

            // For now run the single request in the main thread:
            DispatchQueue.main.async {
                let runNextBlock: (Error?) -> () = { error in
                    self.runNextImpl(op: op, update: update)
                }
                switch op {
                case "get":
                    self.client!.getContext(model: m, idPath: m.identifierPath(), locale: loc, env: env, completion: runNextBlock)
                case "put":
                    let ctxData = ADEduGenericContext.configureFrom(model: m, meta: met, locale: loc)
                    self.client!.putContext(model: m, idPath: m.identifierPath(), locale: loc, env: env, ctxData: ctxData, completion: runNextBlock)
                case "del":
                    self.client!.removeContext(model: m, idPath: m.identifierPath(), locale: loc, env: env, completion: runNextBlock)
                default:
                    // bad op. leave.
                    self.cancel()
                    return
                }
                if let u = update {
                    if let mq = self.queueModels {
                        let progress = 1.0 - Float(mq.count) / Float(self.queueInitialSize)
                        u(progress)
                    }
                }
            }
        }
    }
}
