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
        ForageSDK.setup(ForageSDK.Config(environment: .sandbox))
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
    
    func test_disable() {
        let foragePinTextField = ForagePINTextField()
        foragePinTextField.disable()
        
        XCTAssertEqual(foragePinTextField.isUserInteractionEnabled, false)
        XCTAssertEqual(foragePinTextField.textColor, .lightGray)
    }
    
    func test_enable() {
        let foragePinTextField = ForagePINTextField()
        foragePinTextField.enable()
        
        XCTAssertEqual(foragePinTextField.isUserInteractionEnabled, true)
        XCTAssertEqual(foragePinTextField.textColor, .black)
    }
    
    class TestForagePINTextField: ForagePINTextField {
        var didCallClearText = false
        
        override public func clearText() {
            didCallClearText = true
        }
    }
    
    func test_handleSubmissionCompletion_shouldEnableAndClearText() {
        let foragePinTextField = TestForagePINTextField(frame: CGRect())
        foragePinTextField.handleSubmissionCompletion()
        
        XCTAssertEqual(foragePinTextField.textColor, .black)
        XCTAssertEqual(foragePinTextField.isUserInteractionEnabled, true)
        XCTAssertTrue(foragePinTextField.didCallClearText, "clearText method should be called")
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
