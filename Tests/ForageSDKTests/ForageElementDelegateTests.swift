//
//  ForageElementDelegateTests.swift
//
//
//  Created by Danilo Joksimovic on 2023-08-15.
//

@testable import ForageSDK
import XCTest

final class ForageElementDelegateTests: XCTestCase {
    var observableState: TextFieldObservableState?
    class mockState: TextFieldObservableState {
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

    override func setUp() {
        setUpForageSDK()
        observableState = nil
    }

    func test_forageElementDelegate_focusDidChange() {
        let foragePanTextField = ForagePANTextField()

        let expectedIsFirstResponder = true
        let expectedIsEmpty = false
        let expectedIsValid = true
        let expectedIsComplete = false

        foragePanTextField.delegate = self
        foragePanTextField.delegate?.focusDidChange(
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
        let foragePanTextField = ForagePANTextField()

        let expectedIsFirstResponder = false
        let expectedIsEmpty = true
        let expectedIsValid = false
        let expectedIsComplete = true

        foragePanTextField.delegate = self
        foragePanTextField.delegate?.textFieldDidChange(
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
}

extension ForageElementDelegateTests: ForageTextFieldDelegate {
    func focusDidChange(_ state: TextFieldObservableState) {
        observableState = state
    }

    func textFieldDidChange(_ state: TextFieldObservableState) {
        observableState = state
    }
}
