//  Created by Nikita Nagaynik on 20/10/2018.
//  Copyright © 2018 Nikita Nagaynik. All rights reserved.

import Foundation
import Security

private extension String {
    // http://www.apple.com/certificateauthority/Apple_WWDR_CPS
    static let developmentCustomExtension = "1.2.840.113635.100.6.3.1"
    static let productionCustomExtension = "1.2.840.113635.100.6.3.2"
    static let universalCustomExtension = "1.2.840.113635.100.6.3.6"

    static let commonName = kSecOIDCommonName as String
}

final class SecIdentityManager {

    enum APNSecIdentityType {
        case invalid
        case development
        case production
        case universal
    }

    struct APNSecIdentityInfo {
        let type: APNSecIdentityType
        let name: String
    }

    func identities() -> [SecIdentity]? {
        let query: [String: Any] = [kSecClass as String: kSecClassIdentity,
                                    kSecMatchLimit as String: kSecMatchLimitAll,
                                    kSecReturnRef as String: true]

        var itemsRef: CFTypeRef?
        _ = SecItemCopyMatching(query as CFDictionary, &itemsRef)
        guard
            let items = itemsRef as? NSArray,
            let identities = items as? [SecIdentity] else {
                return nil
        }
        return identities
    }

    func APNSecInfo(for identity: SecIdentity) -> APNSecIdentityInfo? {
        let type = APNSecIdentityGetType(of: identity)
        let name = APNSecIdentityGetName(of: identity)
        return APNSecIdentityInfo(type: type, name: name)
    }

    func certificate(from identity: SecIdentity) -> SecCertificate? {
        var certificate: SecCertificate?
        _ = SecIdentityCopyCertificate(identity, &certificate)
        return certificate
    }

    private func APNSecIdentityGetName(of identity: SecIdentity) -> String {
        guard
            let certificate = certificate(from: identity),
            let values = APNSecCertValues(for: certificate) else {
                return ""
        }
        return (((values[.commonName] as? [String: Any]?)??["value"]) as? [String]?)??.first ?? ""
    }

    private func APNSecCertValues(for certificate: SecCertificate) -> Dictionary<String, Any>? {
        let keys: [String] = [
            .developmentCustomExtension,
            .productionCustomExtension,
            .universalCustomExtension,
            .commonName
        ]
        guard let values = SecCertificateCopyValues(certificate, keys as CFArray, nil) as? [String: NSObject] else {
            return nil
        }
        var dict = [String: Any]()
        for (key, value) in values {
            dict[key] = value
        }
        return dict
    }

    private func APNSecIdentityGetType(of identity: SecIdentity) -> APNSecIdentityType {
        guard
            let certificate = certificate(from: identity),
            let values = APNSecCertValues(for: certificate) else {
                return .invalid
        }
        if values[.developmentCustomExtension] != nil, values[.productionCustomExtension] != nil {
            return .universal
        } else if values[.developmentCustomExtension] != nil {
            return .development
        } else if values[.productionCustomExtension] != nil {
            return .production
        } else {
            return .invalid
        }
    }

    private func getPathOfDefaultKeychain() -> String {
        var keychain: SecKeychain?
        SecKeychainCopyDefault(&keychain)

        var pName = Array(repeating: 0 as Int8, count: 1024)
        var pLength = UInt32(pName.count)
        _ = SecKeychainGetPath(keychain, &pLength, &pName)
        let path = FileManager.default.string(withFileSystemRepresentation: pName, length: Int(pLength))

        return path
    }
}
