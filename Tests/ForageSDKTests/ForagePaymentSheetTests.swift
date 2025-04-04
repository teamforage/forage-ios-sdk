//
//  ForagePaymentSheetTests.swift
//
//
//  Created by Jerimiah on 3/17/25.
//  Copyright © 2025-Present Forage Technology Corporation. All rights reserved.
//

@testable import ForageSDK
import XCTest

final class ForagePaymentSheetTests: XCTestCase {
    var foragePaymentSheet: ForagePaymentSheet!

    override func setUp() {
        setUpForageSDK()
        foragePaymentSheet = ForagePaymentSheet()
    }

    override func tearDown() {
        foragePaymentSheet = nil
    }

    // MARK: - Initialization Tests

    func test_initializationShouldBeEmptyAndValid() {
        XCTAssertNotNil(foragePaymentSheet)
        XCTAssertTrue(foragePaymentSheet.completionErrors.isEmpty)
        XCTAssertNil(foragePaymentSheet.currentFirstResponder)
        XCTAssertFalse(foragePaymentSheet.isComplete)
    }

    func test_font() {
        let newFont = UIFont.systemFont(ofSize: 14, weight: .regular)
        foragePaymentSheet.font = newFont

        XCTAssertEqual(newFont, foragePaymentSheet.font)
        for field in foragePaymentSheet.fields {
            XCTAssertEqual(newFont, field.font)
        }
    }

    func test_tintColor() {
        let tintColor = UIColor.red
        foragePaymentSheet.tfTintColor = tintColor
        
        XCTAssertEqual(tintColor, foragePaymentSheet.tfTintColor)
        for field in foragePaymentSheet.fields {
            XCTAssertEqual(tintColor, field.tfTintColor)
        }
    }

    func test_textAlignment() {
        let alignment = NSTextAlignment.center
        foragePaymentSheet.textAlignment = alignment
        
        XCTAssertEqual(alignment, foragePaymentSheet.textAlignment)
        for field in foragePaymentSheet.fields {
            XCTAssertEqual(alignment, field.textAlignment)
        }
    }

    func test_textColor() {
        let color = UIColor.red
        foragePaymentSheet.textColor = color
        
        XCTAssertEqual(color, foragePaymentSheet.textColor)
        for field in foragePaymentSheet.fields {
            XCTAssertEqual(color, field.textColor)
        }
        
        foragePaymentSheet.textColor = nil
        
        XCTAssertEqual(.black, foragePaymentSheet.textColor)
        for field in foragePaymentSheet.fields {
            XCTAssertEqual(.black, field.textColor)
        }
        
    }
    
    func test_clearSheet() {
        foragePaymentSheet.cardHolderNameTextField.enhancedTextField.text = "Nathan Shelley"
        foragePaymentSheet.cardHolderNameTextField.enhancedTextField.textFieldDidChange()
        foragePaymentSheet.cardNumberTextField.enhancedTextField.text = "4321"
        foragePaymentSheet.cardNumberTextField.enhancedTextField.textFieldDidChange()
        foragePaymentSheet.cardExpirationTextField.enhancedTextField.text = "08/45"
        foragePaymentSheet.cardExpirationTextField.enhancedTextField.textFieldDidChange()
        foragePaymentSheet.cardCVVTextField.enhancedTextField.text = "123"
        foragePaymentSheet.cardCVVTextField.enhancedTextField.textFieldDidChange()
        foragePaymentSheet.cardZipCodeTextField.enhancedTextField.text = "123"
        foragePaymentSheet.cardZipCodeTextField.enhancedTextField.textFieldDidChange()
        
        XCTAssertEqual(foragePaymentSheet.cardHolderNameTextField.enhancedTextField.text, "Nathan Shelley")
        XCTAssertEqual(foragePaymentSheet.cardNumberTextField.enhancedTextField.text, "4321")
        XCTAssertEqual(foragePaymentSheet.cardExpirationTextField.enhancedTextField.text, "08/45")
        XCTAssertEqual(foragePaymentSheet.cardCVVTextField.enhancedTextField.text, "123")
        XCTAssertEqual(foragePaymentSheet.cardZipCodeTextField.enhancedTextField.text, "123")
        
        foragePaymentSheet.clearSheet()
        
        XCTAssertEqual(foragePaymentSheet.cardHolderNameTextField.enhancedTextField.text, "")
        XCTAssertEqual(foragePaymentSheet.cardNumberTextField.enhancedTextField.text, "")
        XCTAssertEqual(foragePaymentSheet.cardExpirationTextField.enhancedTextField.text, "")
        XCTAssertEqual(foragePaymentSheet.cardCVVTextField.enhancedTextField.text, "")
        XCTAssertEqual(foragePaymentSheet.cardZipCodeTextField.enhancedTextField.text, "")
    }

    func test_padding() {
        let padding = UIEdgeInsets(top: 2.0, left: 2.0, bottom: 2.0, right: 2.0)
        foragePaymentSheet.padding = padding

        XCTAssertEqual(foragePaymentSheet.padding, padding)
    }

    func test_borderWidth() {
        let newBorderWidth = CGFloat(3)
        foragePaymentSheet.borderWidth = newBorderWidth
        
        XCTAssertEqual(newBorderWidth, foragePaymentSheet.borderWidth)
        for field in foragePaymentSheet.fields {
            XCTAssertEqual(newBorderWidth, field.borderWidth)
        }
    }

    func test_borderColor() {
        let newBorderColor = UIColor.orange
        foragePaymentSheet.borderColor = newBorderColor
        
        XCTAssertEqual(newBorderColor, foragePaymentSheet.borderColor)
        for field in foragePaymentSheet.fields {
            XCTAssertEqual(newBorderColor, field.borderColor)
        }

        foragePaymentSheet.borderColor = nil
        
        XCTAssertEqual(foragePaymentSheet.borderColor, .black)
        for field in foragePaymentSheet.fields {
            XCTAssertEqual(.black, field.borderColor)
        }
    }

    func test_cornerRadius() {
        let newCornerRadius = CGFloat(4)
        foragePaymentSheet.cornerRadius = newCornerRadius
        
        XCTAssertEqual(newCornerRadius, foragePaymentSheet.cornerRadius)
        for field in foragePaymentSheet.fields {
            XCTAssertEqual(newCornerRadius, field.cornerRadius)
        }
    }

    func test_masksToBounds() {
        let masksToBounds = false
        foragePaymentSheet.masksToBounds = masksToBounds
        
        XCTAssertEqual(masksToBounds, foragePaymentSheet.masksToBounds)
        for field in foragePaymentSheet.fields {
            XCTAssertEqual(masksToBounds, field.masksToBounds)
        }
    }
}
