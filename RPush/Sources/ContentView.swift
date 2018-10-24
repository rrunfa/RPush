//  Created by Nikita Nagaynik on 20/10/2018.
//  Copyright © 2018 Nikita Nagaynik. All rights reserved.

import Cocoa
import TinyConstraints
import SecurityInterface

final class ContentView: NSView {

    weak var windowForSheet: NSWindow?

    private let certNameTextField = NSTextField()
    private let certNameContentTextField = NSTextField()
    private lazy var chooseCertButton = NSButton(title: "Choose Cert", target: self, action: #selector(onChooseCert))

    private let tokenTextField = NSTextField()
    private let tokenContentTextField = NSTextField()

    private let scrollView = NSScrollView()
    private let pushBodyTextView = NSTextView()
    private lazy var sendButton = NSButton(title: "Send", target: self, action: #selector(onSend))

    private let identityManager = SecIdentityManager()

    private var currentIdentity: SecIdentity?
    private var pushManager: PushManager?

    private var identityPanelMessage: String {
        return "Choose the identity to use for delivering notifications: \n(Issued by Apple in the Provisioning Portal)"
    }

    private var defaultPayloadString: String {
        return """
        {
            "aps":{
                "alert":"Test",
                "sound":"default",
                "badge":1
            }
        }
        """
    }

    override init(frame frameRect: NSRect) {
        super.init(frame: .zero)

        addSubview(certNameTextField)
        addSubview(certNameContentTextField)
        addSubview(tokenTextField)
        addSubview(tokenContentTextField)
        addSubview(chooseCertButton)
        addSubview(scrollView)
        addSubview(sendButton)

        certNameTextField.isEditable = false
        certNameTextField.isBezeled = false
        certNameTextField.backgroundColor = .clear

        certNameContentTextField.isEditable = false
        certNameContentTextField.isBezeled = false
        certNameContentTextField.backgroundColor = .clear
        certNameContentTextField.usesSingleLineMode = true

        tokenTextField.isEditable = false
        tokenTextField.isBezeled = false
        tokenTextField.backgroundColor = .clear

        tokenContentTextField.usesSingleLineMode = true
        tokenContentTextField.cell?.isScrollable = true

        scrollView.documentView = pushBodyTextView

        pushBodyTextView.isRichText = false
        pushBodyTextView.isVerticallyResizable = true
        pushBodyTextView.isHorizontallyResizable = true

        certNameTextField.attributedStringValue = NSAttributedString(string: "Identity:",
                                                                     attributes:[.font: NSFont.systemFont(ofSize: 12)])

        tokenTextField.attributedStringValue = NSAttributedString(string: "Token:",
                                                                  attributes:[.font: NSFont.systemFont(ofSize: 12)])

        pushBodyTextView.string = defaultPayloadString
    }

    required init?(coder decoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func layout() {
        super.layout()

        chooseCertButton.rightToSuperview(offset: -50)
        chooseCertButton.topToSuperview(offset: 10)
        chooseCertButton.width(0, relation: .equalOrLess, priority: .defaultLow)

        certNameContentTextField.rightToLeft(of: chooseCertButton, offset: -10)
        certNameContentTextField.topToSuperview(offset: 10)
        certNameContentTextField.setCompressionResistance(.defaultLow, for: .horizontal)

        certNameTextField.leftToSuperview(offset: 50)
        certNameTextField.centerY(to: certNameContentTextField)
        certNameTextField.rightToLeft(of: certNameContentTextField, offset: -10)
        certNameTextField.width(0, relation: .equalOrLess, priority: .defaultLow)

        tokenContentTextField.rightToSuperview(offset: -50)
        tokenContentTextField.topToBottom(of: certNameTextField, offset: 10)
        tokenContentTextField.setCompressionResistance(.defaultLow, for: .horizontal)

        tokenTextField.leftToSuperview(offset: 50)
        tokenTextField.centerY(to: tokenContentTextField)
        tokenTextField.rightToLeft(of: tokenContentTextField, offset: -10)

        scrollView.topToBottom(of: tokenTextField, offset: 10)
        scrollView.leftToSuperview()
        scrollView.rightToSuperview()
        scrollView.bottomToTop(of: sendButton, offset: -10)

        sendButton.rightToSuperview(offset: -10)
        sendButton.bottomToSuperview(offset: -10)

        let contentSize = scrollView.contentSize
        pushBodyTextView.minSize = contentSize
        pushBodyTextView.maxSize = CGSize(width: CGFloat.greatestFiniteMagnitude,
                                          height: CGFloat.greatestFiniteMagnitude)
    }

    @objc private func onChooseCert() {
        guard let window = windowForSheet else { return }

        let panel = SFChooseIdentityPanel.shared()!
        panel.setAlternateButtonTitle("Cancel")
        panel.beginSheet(for: window,
                         modalDelegate: self,
                         didEnd: #selector(onChooseIdentityPanel(didEnd:returnCode:contextInfo:)),
                         contextInfo: nil,
                         identities: identityManager.identities(),
                         message: identityPanelMessage)
    }

    @objc private func onChooseIdentityPanel(didEnd: NSWindow, returnCode: NSApplication.ModalResponse, contextInfo: Any) {
        if returnCode == .OK {
            guard let identityRef = SFChooseIdentityPanel.shared()?.identity() else {
                return
            }
            let identity = identityRef.takeUnretainedValue()
            let info = identityManager.APNSecInfo(for: identity)
            let name = info?.name ?? ""
            certNameContentTextField.attributedStringValue = attributedCertName(string: name)
            currentIdentity = identity
        }
    }

    @objc private func onSend() {
        guard let identity = currentIdentity else { return }
        let pushManager = PushManager(by: identity)

        let payloadString = pushBodyTextView.string
        guard
            let data = payloadString.data(using: .utf8),
            let payload = (try? JSONSerialization.jsonObject(with: data, options: [])) as? [String: Any] else {
                return
        }
        let token = tokenContentTextField.stringValue

        pushManager.push(payload: payload, to: token)

        self.pushManager = pushManager
    }

    private func attributedCertName(string name: String) -> NSAttributedString {
        let paragraphStyle = NSMutableParagraphStyle()
        paragraphStyle.lineBreakMode = .byTruncatingTail
        return NSAttributedString(string: name,
                                  attributes:[.font: NSFont.systemFont(ofSize: 12, weight: .bold),
                                              .paragraphStyle: paragraphStyle])
    }
}
