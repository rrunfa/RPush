//  Created by Nikita Nagaynik on 21/10/2018.
//  Copyright © 2018 Nikita Nagaynik. All rights reserved.

protocol PushManagerDelegate: AnyObject {
    func pushManager(_ manager: PushManager, didRecieveStatus: Int, reason: String?, for id: String?)
    func pushManager(_ manager: PushManager, didFailWithError: Error?)
}

final class PushManager: NSObject {

    weak var delegate: PushManagerDelegate?

    private let identityManager = SecIdentityManager()
    private let identity: SecIdentity
    private lazy var session = URLSession(configuration: .default, delegate: self, delegateQueue: .main)

    func setup(by identity: SecIdentity) {

    }

    init(by identity: SecIdentity) {
        self.identity = identity
        super.init()
    }

    func push(payload: [String: Any], to token: String, in sandbox: Bool = true) {
        //[NSURL URLWithString:[NSString stringWithFormat:@"https://api%@.push.apple.com/3/device/%@", sandbox?@".development":@"", token]]];
        let prepToken = preparedToken(token: token)
        guard let url = URL(string: "https://api\(sandbox ? ".development" : "").push.apple.com/3/device/\(prepToken)") else { return }
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.httpBody = try? JSONSerialization.data(withJSONObject: payload, options: [])


        // Add topic?

        // Add collapse ID?

        // Add priority?
        request.addValue("\(5)", forHTTPHeaderField: "apns-priority")

        let task = session.dataTask(with: request) { [weak self] (data, response, error) in
            guard let self = self else { return }
            guard let response = response as? HTTPURLResponse else {
                self.delegate?.pushManager(self, didFailWithError: error)
                return
            }
            if response.statusCode != 200,
                let data = data,
                let dictData = (try? JSONSerialization.jsonObject(with: data, options: [])) as? [String: Any] {

                let reason = dictData["reason"] as? String
                self.delegate?.pushManager(self, didRecieveStatus: response.statusCode, reason: reason, for: nil)
            }
        }
        task.resume()
    }

    private func preparedToken(token: String) -> String {
        let removeCharacterSet = NSCharacterSet.alphanumerics.inverted
        return token.components(separatedBy: removeCharacterSet).joined(separator: "")
    }
}

extension PushManager: URLSessionDelegate {

    func urlSession(_ session: URLSession, didReceive challenge: URLAuthenticationChallenge,
                    completionHandler: @escaping (URLSession.AuthChallengeDisposition, URLCredential?) -> Void) {

        guard let cert = identityManager.certificate(from: identity) else { return }
        let cred = URLCredential(identity: identity, certificates: [cert], persistence: .forSession)
        completionHandler(.useCredential, cred)
    }
}
