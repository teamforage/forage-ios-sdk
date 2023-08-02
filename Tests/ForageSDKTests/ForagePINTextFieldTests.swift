//
//  ForagePINTextFieldTests.swift
//  ForageSDK
//
//  Created by Symphony on 28/11/22.
//

import XCTest
import VGSCollectSDK
@testable import ForageSDK

//final class ForagePINTextFieldTests: XCTestCase {
//    
//    var pinType: PinType = .balance
//    var isValid: Bool = false
//    
//    override func setUp() {
//        ForageSDK.setup(ForageSDK.Config(environment: .sandbox))
//    }
//    
//    func test_pinResultDelegate_givenPinInputs_shouldReturnValid() {
//        let expectedResultIsValid = true
//        let expectedResultPinType = PinType.balance
//        let foragePinTextField = ForagePINTextField()
//        
//        foragePinTextField.pinType = .balance
//        foragePinTextField.delegate = self
//        foragePinTextField.delegate?.pinStatus(UIView(), isValid: true, pinType: foragePinTextField.pinType)
//        
//        XCTAssertEqual(expectedResultIsValid, isValid)
//        XCTAssertEqual(expectedResultPinType, pinType)
//    }
//    
//    func test_pinResultDelegate_givenPinInputs_shouldReturnInvalid() {
//        let expectedResultIsValid = false
//        let expectedResultPinType = PinType.balance
//        let foragePinTextField = ForagePINTextField()
//        
//        foragePinTextField.pinType = .balance
//        foragePinTextField.delegate = self
//        foragePinTextField.delegate?.pinStatus(UIView(), isValid: false, pinType: foragePinTextField.pinType)
//        
//        XCTAssertEqual(expectedResultIsValid, isValid)
//        XCTAssertEqual(expectedResultPinType, pinType)
//    }
//}
//
//extension ForagePINTextFieldTests: ForagePINTextFieldDelegate {
//    func pinStatus(_ view: UIView, isValid: Bool, pinType: PinType) {
//        self.pinType = pinType
//        self.isValid = isValid
//    }
//}
