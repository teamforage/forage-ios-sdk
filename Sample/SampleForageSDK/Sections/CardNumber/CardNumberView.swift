//
//  CardNumberView.swift
//  SampleForageSDK
//
//  Created by Symphony on 18/10/22.
//

import Foundation
import UIKit
import ForageSDK

protocol CardNumberViewDelegate: AnyObject {
    func goToBalance(_ view: CardNumberView)
}

class CardNumberView: UIView {
    
    // MARK: Public Properties
    
    var isCardValid: Bool = false
    weak var delegate: CardNumberViewDelegate?
    
    // MARK: Private Components
    
    private let contentView: UIView = {
        let view = UIView()
        view.translatesAutoresizingMaskIntoConstraints = false
        view.backgroundColor = UIColor.white
        return view
    }()
    
    private let titleLabel: UILabel = {
        let label = UILabel()
        label.text = "PAN number"
        label.font = UIFont.systemFont(ofSize: 28, weight: .bold)
        return label
    }()
    
    private let panNumberTextField: ForagePANTextField = {
        let tf = ForagePANTextField()
        tf.placeholder = "PAN Number"
        return tf
    }()
    
    private let statusLabel: UILabel = {
        let label = UILabel()
        label.text = "Card number status"
        label.textColor = .red
        label.font = UIFont.systemFont(ofSize: 14, weight: .bold)
        return label
    }()
    
    private let sendPanButton: UIButton = {
        let button = UIButton()
        button.setTitle("Send PAN number", for: .normal)
        button.titleLabel?.font = UIFont.systemFont(ofSize: 16, weight: .semibold)
        button.tintColor = .white
        button.translatesAutoresizingMaskIntoConstraints = false
        button.addTarget(self, action: #selector(sendInfo(_:)), for: .touchUpInside)
        button.backgroundColor = .systemBlue
        button.isEnabled = false
        button.isUserInteractionEnabled = false
        button.alpha = 0.5
        return button
    }()
    
    private let nextButton: UIButton = {
        let button = UIButton()
        button.setTitle("Go To Next", for: .normal)
        button.titleLabel?.font = UIFont.systemFont(ofSize: 16, weight: .semibold)
        button.tintColor = .white
        button.translatesAutoresizingMaskIntoConstraints = false
        button.addTarget(self, action: #selector(goToBalance(_:)), for: .touchUpInside)
        button.backgroundColor = .systemBlue
        button.isEnabled = false
        button.isUserInteractionEnabled = false
        button.alpha = 0.5
        return button
    }()
    
    private let resultLabel: UILabel = {
        let label = UILabel()
        label.text = "Result"
        label.textColor = .black
        label.font = UIFont.systemFont(ofSize: 14, weight: .bold)
        label.numberOfLines = 0
        return label
    }()
    
    // MARK: Fileprivate Methods
    
    @objc fileprivate func sendInfo(_ gesture: UIGestureRecognizer) {
        if isCardValid {
            ForageSDK.shared.tokenizeEBTCard(
                bearerToken: ClientSharedData.shared.bearerToken,
                merchantAccount: ClientSharedData.shared.merchantID) { result in
                    self.printResult(result: result)
                }
        }
    }
    
    @objc fileprivate func goToBalance(_ gesture: UIGestureRecognizer) {
        delegate?.goToBalance(self)
    }
    
    // MARK: Public Methods
    
    public func render() {
        panNumberTextField.delegate = self
        setupView()
        setupConstraints()
    }
    
    // MARK: Private Methods
    
    private func printResult(result: Result<Data?, Error>) {        
        DispatchQueue.main.async {
            switch result {
            case .success(let data):
                guard let data = data,
                      let response = try? JSONDecoder().decode(ForagePANModel.self, from: data)
                else { return }
                
                self.resultLabel.text = """
                Success:\n
                ref: \(response.paymentMethodIdentifier)\n
                type: \(response.type)\n
                card.token: \(response.card.token)\n
                card.last4: \(response.card.last4)\n
                """
                ClientSharedData.shared.cardNumberToken = response.card.token
                ClientSharedData.shared.paymentMethodReference = response.paymentMethodIdentifier
                self.updateButtonState(isEnabled: true, button: self.nextButton)
            case .failure(let error):
                self.resultLabel.text = "Error: \n\(error.localizedDescription)"
                self.updateButtonState(isEnabled: false, button: self.nextButton)
            }
            
            self.layoutIfNeeded()
            self.layoutSubviews()
        }
    }
    
    private func setupView() {
        self.addSubview(contentView)
        contentView.addSubview(titleLabel)
        contentView.addSubview(panNumberTextField)
        contentView.addSubview(statusLabel)
        contentView.addSubview(resultLabel)
        contentView.addSubview(sendPanButton)
        contentView.addSubview(nextButton)
    }
    
    private func setupConstraints() {
        setupContentViewConstraints()
    }
    
    private func setupContentViewConstraints() {
        
        contentView.anchor(
            top: self.topAnchor,
            leading: self.leadingAnchor,
            bottom: self.bottomAnchor,
            trailing: self.trailingAnchor,
            centerXAnchor: self.centerXAnchor
        )
        
        titleLabel.anchor(
            top: contentView.safeAreaLayoutGuide.topAnchor,
            leading: contentView.safeAreaLayoutGuide.leadingAnchor,
            bottom: nil,
            trailing: contentView.safeAreaLayoutGuide.trailingAnchor,
            centerXAnchor: contentView.centerXAnchor,
            padding: UIEdgeInsets(top: 24, left: 24, bottom: 0, right: 24)
        )
        
        panNumberTextField.anchor(
            top: titleLabel.safeAreaLayoutGuide.bottomAnchor,
            leading: contentView.safeAreaLayoutGuide.leadingAnchor,
            bottom: nil,
            trailing: contentView.safeAreaLayoutGuide.trailingAnchor,
            centerXAnchor: contentView.centerXAnchor,
            padding: UIEdgeInsets(top: 24, left: 24, bottom: 0, right: 24),
            size: .init(width: 0, height: 60)
        )
        
        statusLabel.anchor(
            top: panNumberTextField.safeAreaLayoutGuide.bottomAnchor,
            leading: contentView.safeAreaLayoutGuide.leadingAnchor,
            bottom: nil,
            trailing: contentView.safeAreaLayoutGuide.trailingAnchor,
            centerXAnchor: contentView.centerXAnchor,
            padding: UIEdgeInsets(top: 24, left: 24, bottom: 0, right: 24)
        )
        
        resultLabel.anchor(
            top: statusLabel.safeAreaLayoutGuide.bottomAnchor,
            leading: contentView.safeAreaLayoutGuide.leadingAnchor,
            bottom: nil,
            trailing: contentView.safeAreaLayoutGuide.trailingAnchor,
            centerXAnchor: contentView.centerXAnchor,
            padding: UIEdgeInsets(top: 24, left: 24, bottom: 0, right: 24)
        )
        
        sendPanButton.anchor(
            top: nil,
            leading: contentView.safeAreaLayoutGuide.leadingAnchor,
            bottom: nextButton.safeAreaLayoutGuide.topAnchor,
            trailing: contentView.safeAreaLayoutGuide.trailingAnchor,
            centerXAnchor: contentView.centerXAnchor,
            padding: .init(top: 0, left: 24, bottom: 8, right: 24),
            size: .init(width: 0, height: 48)
        )
        
        nextButton.anchor(
            top: nil,
            leading: contentView.safeAreaLayoutGuide.leadingAnchor,
            bottom: contentView.safeAreaLayoutGuide.bottomAnchor,
            trailing: contentView.safeAreaLayoutGuide.trailingAnchor,
            centerXAnchor: contentView.centerXAnchor,
            padding: .init(top: 0, left: 24, bottom: 0, right: 24),
            size: .init(width: 0, height: 48)
        )
    }
    
    private func updateButtonState(isEnabled: Bool, button: UIButton) {
        button.isEnabled = isEnabled
        button.isUserInteractionEnabled = isEnabled
        button.alpha = isEnabled ? 1.0 : 0.5
    }
}

// MARK: - ForagePANTextFieldDelegate

extension CardNumberView: ForagePANTextFieldDelegate {
    func panNumberStatus(_ view: UIView, cardStatus: CardStatus) {
        var isValid = false
        switch cardStatus {
        case .valid:
            statusLabel.text = "It is an VALID card number"
            statusLabel.textColor = .green
            isValid = true
        case .invalid:
            statusLabel.text = "It is a NON VALID card number"
            statusLabel.textColor = .red
            isValid = false
        case .identifying:
            statusLabel.text = "It is IDENTIFYING card number"
            statusLabel.textColor = .gray
            isValid = false
        }
        
        updateButtonState(isEnabled: isValid, button: sendPanButton)
        isCardValid = isValid
    }
}
