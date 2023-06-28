// State.swift
//
// Copyright (c) 2018 Auth0 (http://auth0.com)
//
// Permission is hereby granted, free of charge, to any person obtaining a copy
// of this software and associated documentation files (the "Software"), to deal
// in the Software without restriction, including without limitation the rights
// to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
// copies of the Software, and to permit persons to whom the Software is
// furnished to do so, subject to the following conditions:
//
// The above copyright notice and this permission notice shall be included in
// all copies or substantial portions of the Software.
//
// THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
// IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
// FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
// AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
// LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
// OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
// THE SOFTWARE.

import UIKit
import Guardian
import SimpleKeychain

struct GuardianState: Codable {

    let identifier: String
    let localIdentifier: String
    let token: String
    let keyTag: String
    let otp: OTPParameters?
    let userEmail: String
    let enrollmentTenantDomain: String
    var enrollmentPIN: String? = ""

    func save() throws {
        let encoder = JSONEncoder()
        let data = try encoder.encode(self)
        let keychain = SimpleKeychain(service: "Auth0")
        try keychain.set(data, forKey: self.localIdentifier)
    }
    
    func saveByEnrollmentId() throws {
        let encoder = JSONEncoder()
        let data = try encoder.encode(self)
        let keychain = SimpleKeychain(service: "Auth0")
        try keychain.set(data, forKey: self.identifier)
    }

    static func delete(by identifier: String = UIDevice.current.identifierForVendor!.uuidString) {
        let keychain = SimpleKeychain(service: "Auth0")
        try! keychain.deleteItem(forKey: identifier)
    }

    static func deleteByEnrollmentId(by enrollmentId: String) {
        let keychain = SimpleKeychain(service: "Auth0")
        try! keychain.deleteItem(forKey: enrollmentId)
    }
    
    static func load(by identifier: String = UIDevice.current.identifierForVendor!.uuidString) -> GuardianState? {
        let decoder = JSONDecoder()
        let keychain = SimpleKeychain(service: "Auth0")
        guard let data = try? keychain.data(forKey: identifier) else { return nil }
        guard let state = try? decoder.decode(GuardianState.self, from: data) else { return nil }
        guard state.localIdentifier == identifier else { return nil }
        
        return state
    }
    
    static func loadByEnrollmentId(by enrollmentId: String) -> GuardianState? {
        let decoder = JSONDecoder()
        let keychain = SimpleKeychain(service: "Auth0")
        guard let data = try? keychain.data(forKey: enrollmentId) else { return nil }
        guard let state = try? decoder.decode(GuardianState.self, from: data) else { return nil }
        guard state.identifier == enrollmentId else { return nil }
        return state
    }
    
    static func loadAll() -> [GuardianState]? {
        let decoder = JSONDecoder()
        let keychain = SimpleKeychain(service: "Auth0")
        var enrollments : [GuardianState] = [GuardianState]()
        guard let keys = try? keychain.keys() else { return nil }
                keys.forEach { key in
                    let data = try! keychain.data(forKey: key)
                    let state = try! decoder.decode(GuardianState.self, from: data)
                    enrollments.append(state)
                    
                }
        
        
        return enrollments
    }
}

extension GuardianState: AuthenticationDevice {
    var signingKey: SigningKey {
        return try! KeychainRSAPrivateKey(tag: self.keyTag)
    }
}

