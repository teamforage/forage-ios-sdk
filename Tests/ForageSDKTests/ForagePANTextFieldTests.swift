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
        ForageSDK.setup(ForageSDK.Config(environment: .sandbox))
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
    
    func test_elementHeight() {
        let newHeight = 100.0
        foragePANTextField.elementHeight = newHeight
        
        let height = foragePANTextField.elementHeight
        XCTAssertEqual(newHeight, height)
    }
    
    func test_font() {
        let newFont = UIFont.systemFont(ofSize: 14, weight: .regular)
        foragePANTextField.font = newFont
        
        let font = foragePANTextField.font
        XCTAssertEqual(newFont, font)
    }
    
    func test_tintColor() {
        let tintColor = UIColor.red
        foragePANTextField.tfTintColor = tintColor
        
        let tint = foragePANTextField.tfTintColor
        XCTAssertEqual(tintColor, tint)
    }
    
    func test_textAlignment() {
        let alignment = NSTextAlignment.center
        foragePANTextField.textAlignment = alignment
        
        let textAlignment = foragePANTextField.textAlignment
        XCTAssertEqual(alignment, textAlignment)
    }
    
    func test_textColor() {
        let color = UIColor.red
        foragePANTextField.textColor = color
        
        let textColor = foragePANTextField.textColor
        XCTAssertEqual(color, textColor)
    }
    
    func test_placeholder() {
        let placeholder = "Test placeholder"
        foragePANTextField.placeholder = placeholder
        
        let textPlaceholder = foragePANTextField.placeholder
        XCTAssertEqual(textPlaceholder, placeholder)
    }
    
    func test_clearButton() {
        let mode =  UITextField.ViewMode.always
        foragePANTextField.clearButtonMode = mode
        
        let clearButton = foragePANTextField.clearButtonMode
        XCTAssertEqual(clearButton, mode)
    }
    
    func test_padding() {
        let padding = UIEdgeInsets(top: 2.0, left: 2.0, bottom: 2.0, right: 2.0)
        foragePANTextField.padding = padding
        
        let textPadding = foragePANTextField.padding
        XCTAssertEqual(textPadding, padding)
    }
    
    func test_borderColor() {
        let borderColor = UIColor.black
        foragePANTextField.borderColor = borderColor
        
        let color = foragePANTextField.borderColor
        XCTAssertEqual(color, borderColor)
    }
    
    func test_borderWidth() {
        let borderWidth = 0.1
        foragePANTextField.borderWidth = borderWidth
        
        let width = foragePANTextField.borderWidth
        XCTAssertEqual(width, borderWidth)
    }
}
