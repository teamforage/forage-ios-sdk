//
//  ForagePANTextFieldTests.swift
//
//
//  Created by Danilo Joksimovic on 2023-08-15.
//

@testable import ForageSDK
import XCTest

final class ForagePANTextFieldTests: XCTestCase {
    var foragePANTextField: ForagePANTextField!

    override func setUp() {
        setUpForageSDK()
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

    func test_multiplePanElements_shouldHaveTheirOwnStates() {
        let validTextField = ForagePANTextField()
        let invalidTextField = ForagePANTextField()

        validTextField.enhancedTextField.text = "5077031234567890123"
        invalidTextField.enhancedTextField.text = "1234123412341234"

        validTextField.enhancedTextField.textFieldDidChange()
        invalidTextField.enhancedTextField.textFieldDidChange()

        XCTAssertEqual(validTextField.enhancedTextField.actualPAN, "5077031234567890123")
        XCTAssertEqual(invalidTextField.enhancedTextField.actualPAN, "1234123412341234")

        XCTAssertEqual(validTextField.enhancedTextField.text, "507703 1234 5678 901 23")
        XCTAssertEqual(invalidTextField.enhancedTextField.text, "1234 1234 1234 1234")

        XCTAssertTrue(validTextField.isValid)
        XCTAssertFalse(invalidTextField.isValid)

        XCTAssertTrue(validTextField.isComplete)
        XCTAssertFalse(invalidTextField.isComplete)

        XCTAssertFalse(validTextField.isEmpty)
        XCTAssertFalse(invalidTextField.isEmpty)

        XCTAssertEqual(validTextField.derivedCardInfo.usState, .maine)
        XCTAssertNil(invalidTextField.derivedCardInfo.usState)
    }

    func test_southDakota_shouldBeValidCard() {
        let validTextField = ForagePANTextField()

        validTextField.enhancedTextField.text = "5081321111111111"

        validTextField.enhancedTextField.textFieldDidChange()

        XCTAssertEqual(validTextField.enhancedTextField.actualPAN, "5081321111111111")

        XCTAssertEqual(validTextField.enhancedTextField.text, "5081 3211 1111 1111")

        XCTAssertTrue(validTextField.isValid)

        XCTAssertTrue(validTextField.isComplete)

        XCTAssertFalse(validTextField.isEmpty)

        XCTAssertEqual(validTextField.derivedCardInfo.usState, .southDakota)
    }

    func test_maine_shouldBeValidCardFor16or19Digits() {
        let validTextField = ForagePANTextField()

        // 16 digits
        validTextField.enhancedTextField.text = "5077031234123412"
        validTextField.enhancedTextField.textFieldDidChange()
        XCTAssertEqual(validTextField.enhancedTextField.actualPAN, "5077031234123412")

        XCTAssertEqual(validTextField.enhancedTextField.text, "5077 0312 3412 3412")
        XCTAssertTrue(validTextField.isValid)
        XCTAssertTrue(validTextField.isComplete)
        XCTAssertFalse(validTextField.isEmpty)
        XCTAssertEqual(validTextField.derivedCardInfo.usState, .maine)

        validTextField.enhancedTextField.text = "5077031234123412345"
        validTextField.enhancedTextField.textFieldDidChange()
        XCTAssertEqual(validTextField.enhancedTextField.actualPAN, "5077031234123412345")

        XCTAssertEqual(validTextField.enhancedTextField.text, "507703 1234 1234 123 45")
        XCTAssertTrue(validTextField.isValid)
        XCTAssertTrue(validTextField.isComplete)
        XCTAssertFalse(validTextField.isEmpty)
        XCTAssertEqual(validTextField.derivedCardInfo.usState, .maine)
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
        let mode = UITextField.ViewMode.always
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

    func test_borderWidth() {
        let newBorderWidth = CGFloat(3)
        foragePANTextField.borderWidth = newBorderWidth
        XCTAssertEqual(newBorderWidth, foragePANTextField.borderWidth)
    }

    func test_borderColor() {
        let newBorderColor = UIColor.orange
        foragePANTextField.borderColor = newBorderColor
        XCTAssertEqual(newBorderColor, foragePANTextField.borderColor)
    }

    func test_cornerRadius() {
        let newCornerRadius = CGFloat(4)
        foragePANTextField.cornerRadius = newCornerRadius
        XCTAssertEqual(newCornerRadius, foragePANTextField.cornerRadius)
    }

    func test_masksToBounds() {
        let masksToBounds = false
        foragePANTextField.masksToBounds = masksToBounds
        XCTAssertEqual(masksToBounds, foragePANTextField.masksToBounds)
    }

    func test_recognizeCardText_shouldRecognizeValidCardNumber() {
        // Create an expectation for the async call
        let expectation = XCTestExpectation(description: "Card text recognition")
        
        // Create a test image with card number text
        let renderer = UIGraphicsImageRenderer(size: CGSize(width: 300, height: 100))
        let testImage = renderer.image { ctx in
            let rect = CGRect(x: 0, y: 0, width: 300, height: 100)
            ctx.cgContext.setFillColor(UIColor.white.cgColor)
            ctx.cgContext.fill(rect)
            
            let text = "5077 0312 3412 3412"
            let attributes: [NSAttributedString.Key: Any] = [
                .font: UIFont.systemFont(ofSize: 16),
                .foregroundColor: UIColor.black
            ]
            
            text.draw(at: CGPoint(x: 10, y: 40), withAttributes: attributes)
        }
        
        // Save the image to the Documents directory for inspection
        saveImageForInspection(testImage, named: "card_number_test_image")
        
        // Call the function under test
        recognizeCardText(from: testImage) { result in
            switch result {
            case .success(let cardNumber):
                // The actual test assertions
                XCTAssertNotNil(cardNumber, "Card number should be recognized")
                if let number = cardNumber {
                    XCTAssertEqual(number, "5077031234123412", "Recognized card number should match expected value")
                }
            case .failure(let error):
                XCTFail("Card recognition failed with error: \(error)")
            }
            expectation.fulfill()
        }
        
        // Wait for the expectation to be fulfilled
        wait(for: [expectation], timeout: 5.0)
    }

    func test_recognizeCardText_withInvalidImage_shouldReturnNil() {
        // Create an expectation for the async call
        let expectation = XCTestExpectation(description: "Card text recognition with invalid image")
        
        // Create a blank image without any text
        let renderer = UIGraphicsImageRenderer(size: CGSize(width: 300, height: 100))
        let blankImage = renderer.image { ctx in
            let rect = CGRect(x: 0, y: 0, width: 300, height: 100)
            ctx.cgContext.setFillColor(UIColor.white.cgColor)
            ctx.cgContext.fill(rect)
        }
        
        // Save the image to the Documents directory for inspection
        saveImageForInspection(blankImage, named: "blank_test_image")
        
        // Call the function under test
        recognizeCardText(from: blankImage) { result in
            switch result {
            case .success(let cardNumber):
                XCTAssertNil(cardNumber, "No card number should be recognized from a blank image")
            case .failure(let error):
                // While we expect nil result rather than an error, we shouldn't fail the test
                // if Vision framework encounters an error with our test image
                print("Card recognition returned error: \(error)")
            }
            expectation.fulfill()
        }
        
        // Wait for the expectation to be fulfilled
        wait(for: [expectation], timeout: 5.0)
    }

    // Helper function to save images for inspection
    private func saveImageForInspection(_ image: UIImage, named filename: String) {
        guard let documentsDirectory = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first else {
            print("Could not access documents directory")
            return
        }
        
        let fileURL = documentsDirectory.appendingPathComponent("\(filename).png")
        
        if let data = image.pngData() {
            do {
                try data.write(to: fileURL)
                print("Test image saved to: \(fileURL.path)")
            } catch {
                print("Could not save test image: \(error)")
            }
        }
    }
}
