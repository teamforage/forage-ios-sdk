//
//  ForagePINTextFieldTests.swift
//  ForageSDK
//
//  Created by Tiago Oliveira on 28/11/22.
//  Copyright © 2023-Present Forage Technology Corporation. All rights reserved.
//

@testable import ForageSDK
import XCTest

final class ForagePINTextFieldTests: XCTestCase {
    var observableState: ObservableState?
    var foragePinTextField: ForagePINTextField!

    override func setUp() {
        setUpForageSDK()
        observableState = nil
        foragePinTextField = ForagePINTextField()
    }

    class mockState: ObservableState {
        var _isFirstResponder = false
        var isFirstResponder: Bool {
            _isFirstResponder
        }

        var _isEmpty = false
        var isEmpty: Bool {
            _isEmpty
        }

        var _isValid = false
        var isValid: Bool {
            _isValid
        }

        var _isComplete = false
        var isComplete: Bool {
            _isComplete
        }

        init(isFirstResponder: Bool, isEmpty: Bool, isValid: Bool, isComplete: Bool) {
            _isFirstResponder = isFirstResponder
            _isEmpty = isEmpty
            _isValid = isValid
            _isComplete = isComplete
        }
    }

    func test_forageElementDelegate_focusDidChange() {
        let expectedIsFirstResponder = true
        let expectedIsEmpty = false
        let expectedIsValid = true
        let expectedIsComplete = false

        foragePinTextField.delegate = self
        foragePinTextField.delegate?.focusDidChange(
            mockState(
                isFirstResponder: expectedIsFirstResponder,
                isEmpty: expectedIsEmpty,
                isValid: expectedIsValid,
                isComplete: expectedIsComplete
            )
        )

        XCTAssertEqual(expectedIsFirstResponder, observableState?.isFirstResponder)
        XCTAssertEqual(expectedIsEmpty, observableState?.isEmpty)
        XCTAssertEqual(expectedIsValid, observableState?.isValid)
        XCTAssertEqual(expectedIsComplete, observableState?.isComplete)
    }

    func test_forageElementDelegate_textFieldDidChange() {
        let expectedIsFirstResponder = false
        let expectedIsEmpty = true
        let expectedIsValid = false
        let expectedIsComplete = true

        foragePinTextField.delegate = self
        foragePinTextField.delegate?.textFieldDidChange(
            mockState(
                isFirstResponder: expectedIsFirstResponder,
                isEmpty: expectedIsEmpty,
                isValid: expectedIsValid,
                isComplete: expectedIsComplete
            )
        )

        XCTAssertEqual(expectedIsFirstResponder, observableState?.isFirstResponder)
        XCTAssertEqual(expectedIsEmpty, observableState?.isEmpty)
        XCTAssertEqual(expectedIsValid, observableState?.isValid)
        XCTAssertEqual(expectedIsComplete, observableState?.isComplete)
    }

    func test_BackgroundColor() {
        // Test ForagePINTextField background color
        foragePinTextField.backgroundColor = .lightGray
        XCTAssertEqual(foragePinTextField.backgroundColor, .lightGray)

        // Test RosettaPINTextField background color
        let rosettaPINTextField = RosettaPINTextField()
        rosettaPINTextField.backgroundColor = .lightGray
        XCTAssertEqual(rosettaPINTextField.backgroundColor, .lightGray)

        // Test RosettaPINTextField background color = nil
        rosettaPINTextField.backgroundColor = nil
        XCTAssertEqual(rosettaPINTextField.backgroundColor, nil)
    }

    func test_CornerRadius() {
        // Test ForagePINTextField border radius
        foragePinTextField.cornerRadius = 10
        XCTAssertEqual(foragePinTextField.cornerRadius, 10)

        // Test RosettaPINTextField corner radius
        let rosettaPINTextField = RosettaPINTextField()
        rosettaPINTextField.cornerRadius = 10
        XCTAssertEqual(rosettaPINTextField.cornerRadius, 10)
    }

    func test_MasksToBounds() {
        let foragePinTextField = ForagePINTextField()
        let newVal = false
        foragePinTextField.masksToBounds = newVal
        XCTAssertEqual(foragePinTextField.masksToBounds, newVal)

        let rosettaPINTextField = RosettaPINTextField()
        rosettaPINTextField.masksToBounds = newVal
        XCTAssertEqual(rosettaPINTextField.masksToBounds, newVal)
    }

    func test_borderColor() {
        let borderColor = UIColor.black
        foragePinTextField.borderColor = borderColor

        let color = foragePinTextField.borderColor
        XCTAssertEqual(color, borderColor)

        // Test RosettaPINTextField border color
        let rosettaPINTextField = RosettaPINTextField()
        rosettaPINTextField.borderColor = .blue
        XCTAssertEqual(rosettaPINTextField.borderColor, .blue)

        // Test RosettaPINTextField border color = .none
        rosettaPINTextField.borderColor = .none
        XCTAssertEqual(rosettaPINTextField.borderColor, nil)
    }

    func test_borderWidth() {
        let borderWidth = 0.1
        foragePinTextField.borderWidth = borderWidth

        let width = foragePinTextField.borderWidth
        XCTAssertEqual(width, borderWidth)

        // Test RosettaPINTextField border width
        let rosettaPINTextField = RosettaPINTextField()
        rosettaPINTextField.borderWidth = 10
        XCTAssertEqual(rosettaPINTextField.borderWidth, 10)
    }

    func test_tintColor() {
        let tintColor = UIColor.red
        foragePinTextField.tfTintColor = tintColor

        let tint = foragePinTextField.tfTintColor
        XCTAssertEqual(tintColor, tint)
    }

    func test_textAlignment() {
        let alignment = NSTextAlignment.center
        foragePinTextField.textAlignment = alignment

        let textAlignment = foragePinTextField.textAlignment
        XCTAssertEqual(alignment, textAlignment)

        // Test RosettaPINTextField text alignment
        let rosettaPINTextField = RosettaPINTextField()
        rosettaPINTextField.textAlignment = .center
        XCTAssertEqual(rosettaPINTextField.textAlignment, .center)
    }

    func test_padding() {
        // Test RosettaPINTextField padding
        let rosettaPINTextField = RosettaPINTextField()
        rosettaPINTextField.padding = UIEdgeInsets(top: 10, left: 10, bottom: 10, right: 10)
        XCTAssertEqual(rosettaPINTextField.padding, UIEdgeInsets(top: 10, left: 10, bottom: 10, right: 10))
    }

    func test_font() {
        let newFont = UIFont.systemFont(ofSize: 14, weight: .regular)
        foragePinTextField.font = newFont

        let font = foragePinTextField.font
        XCTAssertEqual(newFont, font)

        // Test RosettaPINTextField font
        let rosettaPINTextField = RosettaPINTextField()
        let forageFont = UIFont.systemFont(ofSize: 20, weight: .bold)
        rosettaPINTextField.font = forageFont
        XCTAssertEqual(rosettaPINTextField.font, forageFont)
    }

    func test_textColor() {
        let color = UIColor.red
        foragePinTextField.textColor = color

        let textColor = foragePinTextField.textColor
        XCTAssertEqual(color, textColor)
        
        // Test RosettaPINTextField text color
        let rosettaPINTextField = RosettaPINTextField()
        rosettaPINTextField.textColor = .blue
        XCTAssertEqual(rosettaPINTextField.textColor, .blue)
    }

    func test_placeholder() {
        let placeholder = "Test placeholder"
        foragePinTextField.placeholder = placeholder

        let textPlaceholder = foragePinTextField.placeholder
        XCTAssertEqual(textPlaceholder, placeholder)
    }

    func test_clearText() {
        let rosettaPINTextField = RosettaPINTextField()
        rosettaPINTextField.clearText()
        rosettaPINTextField.clearText()

        // assert that it does not cause crash and resets status fields!
        XCTAssertEqual(rosettaPINTextField.isComplete, false)
        XCTAssertEqual(rosettaPINTextField.isEmpty, true)
        XCTAssertEqual(rosettaPINTextField.isValid, false)
    }

    // because we force clearText to run on the main thread!
    func test_clientCallsClearText_onBackgroundThread_doesNotCrash() {
        let rosettaPINTextField = RosettaPINTextField()

        let expectation = XCTestExpectation(description: "should clear text without crashing")

        DispatchQueue.global(qos: .userInitiated).async {
            rosettaPINTextField.clearText()
            rosettaPINTextField.clearText()

            DispatchQueue.main.async {
                XCTAssertFalse(rosettaPINTextField.isComplete)

                expectation.fulfill()
            }
        }

        wait(for: [expectation], timeout: 3.0)
    }

    func test_RosettaPINTextField_isComplete() {
        let rosettaPINTextField = RosettaPINTextField()
        let textField = UITextField()

        textField.text = "1234"
        rosettaPINTextField.textFieldDidChange(textField)
        XCTAssertTrue(rosettaPINTextField.isComplete)

        textField.text = "123"
        rosettaPINTextField.textFieldDidChange(textField)
        XCTAssertFalse(rosettaPINTextField.isComplete)
    }

    func test_RosettaPINTextField_isValid() {
        let rosettaPINTextField = RosettaPINTextField()
        let textField = UITextField()

        textField.text = "1234"
        rosettaPINTextField.textFieldDidChange(textField)
        XCTAssertTrue(rosettaPINTextField.isValid)

        textField.text = "123"
        rosettaPINTextField.textFieldDidChange(textField)
        XCTAssertFalse(rosettaPINTextField.isValid)

        textField.text = "12ab"
        rosettaPINTextField.textFieldDidChange(textField)
        XCTAssertFalse(rosettaPINTextField.isValid)
    }

    func test_RosettaPINTextField_rejectsNonNumbers() {
        let rosettaPINTextField = RosettaPINTextField()
        let result = rosettaPINTextField.textField(UITextField(), shouldChangeCharactersIn: NSRange(), replacementString: "a")
        XCTAssertEqual(result, false)
    }

    func test_RosettaPINTextField_allowsNumbers() {
        let rosettaPINTextField = RosettaPINTextField()
        let result = rosettaPINTextField.textField(UITextField(), shouldChangeCharactersIn: NSRange(), replacementString: "1")
        XCTAssertEqual(result, true)
    }

    func test_RosettaPINTextField_rejectsOverFourDigits() {
        let rosettaPINTextField = RosettaPINTextField()
        let result = rosettaPINTextField.textField(UITextField(), shouldChangeCharactersIn: NSRange(), replacementString: "12345")
        XCTAssertEqual(result, false)
    }

    func test_RosettaPINTextField_allowsFourDigits() {
        let rosettaPINTextField = RosettaPINTextField()
        let result = rosettaPINTextField.textField(UITextField(), shouldChangeCharactersIn: NSRange(), replacementString: "1234")
        XCTAssertEqual(result, true)
    }

    func test_RosettaPINTextField_delegateMethodCalls() {
        class MockDelegate: VaultWrapperDelegate {
            var textFieldDidChangeCalledTimes = 0
            var firstResponderDidChangeCalledTimes = 0

            func textFieldDidChange(_ textField: any VaultWrapper) {
                textFieldDidChangeCalledTimes += 1
            }

            func firstResponderDidChange(_ textField: any VaultWrapper) {
                firstResponderDidChangeCalledTimes += 1
            }
        }

        let rosettaPINTextField = RosettaPINTextField()
        let mockDelegate = MockDelegate()
        let textField = UITextField()
        let window = UIWindow()

        rosettaPINTextField.delegate = mockDelegate
        window.addSubview(rosettaPINTextField)

        // textFieldDidChange
        rosettaPINTextField.textFieldDidChange(textField)
        XCTAssertEqual(mockDelegate.textFieldDidChangeCalledTimes, 1)

        // firstResponderDidChange
        XCTAssertFalse(rosettaPINTextField.isFirstResponder)

        // simulating the system firing the .editingDidBegin event
        rosettaPINTextField.becomeFirstResponder()
        rosettaPINTextField.editingBegan(textField)

        // wait for the responder chain to update
        RunLoop.current.run(until: Date(timeIntervalSinceNow: 0.1))

        // Assert that we called the right delegate methods and the isFirstResponder status was updated
        XCTAssertEqual(mockDelegate.firstResponderDidChangeCalledTimes, 1)
        XCTAssertTrue(rosettaPINTextField.isFirstResponder)

        // simulating the system firing the .editingDidEnd event
        rosettaPINTextField.resignFirstResponder()
        rosettaPINTextField.editingEnded(textField)

        // wait for the responder chain to update
        RunLoop.current.run(until: Date(timeIntervalSinceNow: 0.1))

        // Assert that we called the right delegate methods and the isFirstResponder status was updated
        XCTAssertEqual(mockDelegate.firstResponderDidChangeCalledTimes, 2)
        XCTAssertFalse(rosettaPINTextField.isFirstResponder)
    }
}

extension ForagePINTextFieldTests: ForageElementDelegate {
    func focusDidChange(_ state: ObservableState) {
        observableState = state
    }

    func textFieldDidChange(_ state: ObservableState) {
        observableState = state
    }
}
