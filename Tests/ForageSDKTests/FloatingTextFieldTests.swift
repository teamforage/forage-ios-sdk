//
//  FloatingTextFieldTests.swift
//
//
//  Created by Milos Bogdanovic on 08/23/23.
//  © 2023-Present Forage Technology Corporation. All rights reserved.
//

@testable import ForageSDK
import XCTest

final class FloatingTextFieldTests: XCTestCase {
    var floatingTextField: FloatingTextField!

    override func setUp() {
        setUpForageSDK()
        ForageSDK.shared.environment = .sandbox
        floatingTextField = FloatingTextField()
    }

    override func tearDown() {
        floatingTextField = nil
    }

    func test_placeholder() {
        let placeholder = "PAN number"
        floatingTextField.placeholder = placeholder

        let resultPlaceholder = floatingTextField.placeholder
        XCTAssertEqual(resultPlaceholder, placeholder)
    }

    func test_placeholderWithColor() {
        let placeholder = "PAN number"
        let placeholderColor = UIColor.red

        floatingTextField.placeholder = placeholder
        floatingTextField.placeholderColor = placeholderColor

        let resultPlaceholder = floatingTextField.placeholder
        let resultAttributedPlaceholder = floatingTextField.attributedPlaceholder

        XCTAssertEqual(resultPlaceholder, placeholder)
        XCTAssertNotNil(resultAttributedPlaceholder)

        let expectedAttributes: [NSAttributedString.Key: Any] = [.foregroundColor: placeholderColor]
        let attributedString = NSAttributedString(string: placeholder, attributes: expectedAttributes)
        XCTAssertEqual(resultAttributedPlaceholder, attributedString)
    }

    func test_placeholderWithoutColor() {
        let placeholder = "PAN number"
        floatingTextField.placeholder = placeholder
        floatingTextField.placeholderColor = nil
        XCTAssertNil(floatingTextField.placeholderColor)
    }

    func test_textRect_insetRectForEmptyBounds() {
        let x: CGFloat = 8
        let paddingX: CGFloat = 8
        let bounds = CGRect(x: 0, y: 0, width: 100, height: 100)

        let expectedRect = CGRect(x: x,
                                  y: 0,
                                  width: bounds.width - x - paddingX,
                                  height: bounds.height)
        let resultRect = floatingTextField.textRect(forBounds: bounds)
        XCTAssertEqual(resultRect, expectedRect)
    }

    func test_textRect_insetRectForBounds() {
        let paddingX: CGFloat = 8
        let bounds = CGRect(x: 0, y: 0, width: 100, height: 100)

        floatingTextField.text = "0000 0000"
        floatingTextField.placeholder = "PAN number"

        let expectedRect = CGRect(x: paddingX, y: 3, width: 84, height: 95)
        let resultRect = floatingTextField.textRect(forBounds: bounds)
        XCTAssertEqual(resultRect, expectedRect)
    }

    func test_editingRect_insetRectForBounds() {
        let paddingX: CGFloat = 8
        let bounds = CGRect(x: 0, y: 0, width: 100, height: 100)

        floatingTextField.text = "1111"
        floatingTextField.placeholder = "PAN number"

        let expectedRect = CGRect(x: paddingX, y: 3, width: 84, height: 95)
        let resultRect = floatingTextField.editingRect(forBounds: bounds)
        XCTAssertEqual(resultRect, expectedRect)
    }

    func test_rightViewRect() {
        let paddingX: CGFloat = 8
        let bounds = CGRect(x: 0, y: 0, width: 100, height: 100)

        let expectedOriginX = bounds.width - paddingX
        let expectedRect = CGRect(x: expectedOriginX,
                                  y: (bounds.height - floatingTextField.bounds.size.height) / 2,
                                  width: bounds.origin.x,
                                  height: bounds.origin.y)

        let resultRect = floatingTextField.rightViewRect(forBounds: bounds)
        XCTAssertEqual(resultRect, expectedRect)
    }

    func test_leftViewRect() {
        let bounds = CGRect(x: 0, y: 0, width: 100, height: 100)

        let expectedRect = CGRect(x: floatingTextField.floatingPlaceholderLabel.frame.origin.x,
                                  y: (bounds.height - floatingTextField.bounds.size.height) / 2,
                                  width: bounds.origin.x,
                                  height: bounds.origin.y)

        let resultRect = floatingTextField.leftViewRect(forBounds: bounds)
        XCTAssertEqual(resultRect, expectedRect)
    }

    func test_clearButtonRect() {
        let paddingX: CGFloat = 8
        let bounds = CGRect(x: 0, y: 0, width: 342, height: 37)
        let clearButtonSize = CGSize(width: 19, height: 19)

        let resultRect = floatingTextField.clearButtonRect(forBounds: bounds)

        let expectedOriginY = (bounds.height - clearButtonSize.height) / 2
        let expectedOriginX = bounds.width - clearButtonSize.width - paddingX
        let expectedRect = CGRect(x: expectedOriginX,
                                  y: expectedOriginY,
                                  width: clearButtonSize.width,
                                  height: clearButtonSize.height)
        XCTAssertEqual(resultRect, expectedRect)
    }

    func test_SetFloatLabelAlignment() {
        let bounds = CGRect(x: 0, y: 0, width: 0, height: 37)
        let frame = CGRect(x: 8, y: 12, width: 62, height: 12)
        let paddingX: CGFloat = 8

        floatingTextField.placeholder = "PAN number"

        let floatingLabelSize = floatingTextField.floatingPlaceholderLabel.sizeThatFits(
            floatingTextField.floatingPlaceholderLabel.superview!.bounds.size
        )

        floatingTextField.floatingPlaceholderLabel.frame = CGRect(x: paddingX,
                                                                  y: floatingTextField.floatingPlaceholderLabel.frame.origin.y,
                                                                  width: floatingLabelSize.width,
                                                                  height: floatingLabelSize.height)

        // Expected results for different textAlignment values
        let leftAlignment = paddingX
        let centerAlignment = (bounds.width / 2.0) - (frame.size.width / 2.0)

        // Test case for textAlignment = .left
        floatingTextField.textAlignment = .left
        floatingTextField.layoutSubviews()
        XCTAssertEqual(leftAlignment, floatingTextField.floatingPlaceholderLabel.frame.origin.x.rounded())

        // Test case for textAlignment = .center
        floatingTextField.textAlignment = .center
        floatingTextField.layoutSubviews()
        XCTAssertEqual(centerAlignment, floatingTextField.floatingPlaceholderLabel.frame.origin.x.rounded(.awayFromZero))
    }

    func test_borderWidth() {
        let currentBorderWidth = floatingTextField.borderWidth
        floatingTextField.borderWidth = 10
        XCTAssertNotEqual(floatingTextField.borderWidth, currentBorderWidth)
    }

    func test_borderColor() {
        let currentBorderColor = floatingTextField.borderColor
        floatingTextField.borderColor = .red
        XCTAssertNotEqual(floatingTextField.borderColor, currentBorderColor)
    }

    func test_borderCornerRadius() {
        let currentBorderRadius = floatingTextField.borderCornerRadius
        floatingTextField.borderCornerRadius = 10
        XCTAssertNotEqual(floatingTextField.borderCornerRadius, currentBorderRadius)
    }

    func test_floatPlaceholderFont() {
        let currentPlaceholderFont = floatingTextField.floatPlaceholderFont
        floatingTextField.floatPlaceholderFont = UIFont.systemFont(ofSize: 4)
        XCTAssertNotEqual(floatingTextField.floatPlaceholderFont, currentPlaceholderFont)
    }

    func test_paddingYFloatLabel() {
        let currentPaddingYFloatLabel = floatingTextField.paddingYFloatLabel
        floatingTextField.paddingYFloatLabel = 12
        XCTAssertNotEqual(floatingTextField.paddingYFloatLabel, currentPaddingYFloatLabel)
    }

    func test_clear() {
        floatingTextField.placeholder = "PAN number"
        floatingTextField.clear(sender: floatingTextField)
        XCTAssertEqual(floatingTextField.text, "")
    }

    func test_showFloatingLabel() {
        floatingTextField.placeholder = "PAN number"
        floatingTextField.text = "1111 1111"
        floatingTextField.layoutSubviews()
        XCTAssertEqual(floatingTextField.paddingYFloatLabel, 5)
    }
}
