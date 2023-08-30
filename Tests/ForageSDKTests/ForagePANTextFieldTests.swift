//
//  ForagePANTextFieldTests.swift
//  
//
//  Created by Danilo Joksimovic on 2023-08-15.
//

import XCTest
@testable import ForageSDK

final class ForagePANTextFieldTests: XCTestCase {
    var foragePANTextField: ForagePANTextField!
    
    override func setUp() {
         ForageSDK.setup(ForageSDK.Config(
            environment: .sandbox,
            merchantID: "merchantID123",
            sessionToken: "authToken123"
        ))
        ForageSDK.shared.service = nil
        ForageSDK.shared.panNumber = ""
        foragePANTextField = ForagePANTextField()       
    }
    
    override func tearDown() {
        foragePANTextField = nil
    }
    
    // MARK: - Initialization Tests
    
    func test_initialization_shouldBeEmptyAndValid() {
        XCTAssertNotNil(foragePANTextField)
        XCTAssertTrue(foragePANTextField.isEmpty)
        XCTAssertTrue(foragePANTextField.isValid)
        XCTAssertFalse(foragePANTextField.isComplete)
    }
    
    func test_textField_enterNumericString_shouldReturnTrue() {
        let changesAllowed = foragePANTextField.textField(UITextField(), shouldChangeCharactersIn: NSRange(), replacementString: "1234")
        
        XCTAssertTrue(changesAllowed)
    }
    
    func test_textField_pressBackspace_shouldReturnTrue() {
        let changesAllowed = foragePANTextField.textField(UITextField(), shouldChangeCharactersIn: NSRange(), replacementString: "")
        
        XCTAssertTrue(changesAllowed)
    }
    
    func test_textField_nonNumericStr_shouldReturnFalse() {
        let changesAllowed = foragePANTextField.textField(UITextField(), shouldChangeCharactersIn: NSRange(), replacementString: "abcdef")
        
        XCTAssertFalse(changesAllowed)
    }
    
    func test_textField_pressSpace_shouldReturnFalse() {
        let changesAllowed = foragePANTextField.textField(UITextField(), shouldChangeCharactersIn: NSRange(), replacementString: " ")
        
        XCTAssertFalse(changesAllowed)
    }
}
