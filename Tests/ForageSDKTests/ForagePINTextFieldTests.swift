//
//  ForagePINTextFieldTests.swift
//  ForageSDK
//
//  Created by Symphony on 28/11/22.
//

import XCTest
import VGSCollectSDK
@testable import ForageSDK

final class ForagePINTextFieldTests: XCTestCase {
    
    var observableState: ObservableState?
    
    override func setUp() {
        ForageSDK.setup(ForageSDK.Config(
            environment: .sandbox,
            merchantAccount: "merchantID123",
            bearerToken: "authToken123"
        ))        
        observableState = nil
    }
    
    class mockState: ObservableState {
        var _isFirstResponder = false
        var isFirstResponder: Bool {
            get {
                return _isFirstResponder
            }
        }
        
        var _isEmpty = false
        var isEmpty: Bool {
            get {
                return _isEmpty
            }
        }
        
        var _isValid = false
        var isValid: Bool {
            get {
                return _isValid
            }
        }
        
        var _isComplete = false
        var isComplete: Bool {
            get {
                return _isComplete
            }
        }
        
        init(isFirstResponder: Bool, isEmpty: Bool, isValid: Bool, isComplete: Bool) {
            self._isFirstResponder = isFirstResponder
            self._isEmpty = isEmpty
            self._isValid = isValid
            self._isComplete = isComplete
        }
    }
    
    func test_forageElementDelegate_focusDidChange() {
        let foragePinTextField = ForagePINTextField()
        
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
        let foragePinTextField = ForagePINTextField()
        
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
        let foragePinTextField = ForagePINTextField()
        foragePinTextField.backgroundColor = .lightGray
        XCTAssertEqual(foragePinTextField.backgroundColor, .lightGray)
        
        // Test VGSTextFieldWrapper background color
        let vgsTextFieldWrapper = VGSTextFieldWrapper()
        vgsTextFieldWrapper.backgroundColor = .lightGray
        XCTAssertEqual(vgsTextFieldWrapper.backgroundColor, .lightGray)
        
        // Test BasisTheoryTextFieldWrapper background color
        let btTextFieldWrapper = BasisTheoryTextFieldWrapper()
        btTextFieldWrapper.backgroundColor = .lightGray
        XCTAssertEqual(btTextFieldWrapper.backgroundColor, .lightGray)
        
        // Test BasisTheoryTextFieldWrapper background color = nil
        btTextFieldWrapper.backgroundColor = nil
        XCTAssertEqual(btTextFieldWrapper.backgroundColor, nil)
    }
    
    func test_CornerRadius() {
        // Test ForagePINTextField border radius
        let foragePinTextField = ForagePINTextField()
        foragePinTextField.borderRadius = 10
        XCTAssertEqual(foragePinTextField.borderRadius, 10)
        
        // Test VGSTextFieldWrapper border radius
        let vgsTextFieldWrapper = VGSTextFieldWrapper()
        vgsTextFieldWrapper.borderRadius = 10
        XCTAssertEqual(vgsTextFieldWrapper.borderRadius, 10)
        
        // Test BasisTheoryTextFieldWrapper border radius
        let btTextFieldWrapper = BasisTheoryTextFieldWrapper()
        btTextFieldWrapper.borderRadius = 10
        XCTAssertEqual(btTextFieldWrapper.borderRadius, 10)
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
