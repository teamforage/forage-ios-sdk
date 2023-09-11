import XCTest

@testable import ForageSDK

final class ForageErrorTests: XCTestCase {
    func testDecoding_ErrorWithInsufficientFunds_SetsSnapAndCash() throws {
        let jsonString = """
            {
                "httpStatusCode": 400,
                "code": "ebt_error_51",
                "message": "Insufficient Funds",
                "details": {
                    "snap_balance": "20.00",
                    "cash_balance": "30.12"
                }
            }
            """
        let jsonData = jsonString.data(using: .utf8)!
        let decodedError = try JSONDecoder().decode(ForageErrorObj.self, from: jsonData)
        
        XCTAssertEqual(decodedError.httpStatusCode, 400)
        XCTAssertEqual(decodedError.code, "ebt_error_51")
        XCTAssertEqual(decodedError.message, "Insufficient Funds")
        
        if case .ebtError51(let snapBalance, let cashBalance)? = decodedError.details {
            XCTAssertEqual(snapBalance, "20.00")
            XCTAssertEqual(cashBalance, "30.12")
        } else {
            XCTFail("Decoded details should be of type .ebtError51")
        }
    }
    
    func testDecoding_ErrorWithPartialInsufficientFundsDetails_SetsCashAndNilSnap() throws {
        let jsonString = """
            {
               "httpStatusCode": 400,
               "code": "ebt_error_51",
               "message": "Almost Insufficient Funds, but not",
               "details": {
                   "cash_balance": "123.34"
               }
            }
            """
        let jsonData = jsonString.data(using: .utf8)!
        let decodedError = try JSONDecoder().decode(ForageErrorObj.self, from: jsonData)
        
        XCTAssertEqual(decodedError.httpStatusCode, 400)
        XCTAssertEqual(decodedError.code, "ebt_error_51")
        XCTAssertEqual(decodedError.message, "Almost Insufficient Funds, but not")
        if case .ebtError51(let snapBalance, let cashBalance)? = decodedError.details {
            XCTAssertNil(snapBalance)
            XCTAssertEqual(cashBalance, "123.34")
        } else {
            XCTFail("Decoded details should be of type .ebtError51")
        }
    }
    
    func testDecoding_ErrorWithUnexpectedCode_SetsDetailsToNil() throws {
        let jsonString = """
            {
                "httpStatusCode": 400,
                "code": "some_other_error",
                "message": "Some Other Error",
                "details": {
                  "some_other_details": 123
                }
            }
            """
        let jsonData = jsonString.data(using: .utf8)!
        let decodedError = try JSONDecoder().decode(ForageErrorObj.self, from: jsonData)
        
        XCTAssertEqual(decodedError.httpStatusCode, 400)
        XCTAssertEqual(decodedError.code, "some_other_error")
        XCTAssertEqual(decodedError.message, "Some Other Error")
        XCTAssertNil(decodedError.details)
    }
    
    func testDecoding_ErrorWithMissingDetails_SetsDetailsToNil() throws {
        let jsonString = """
            {
                "httpStatusCode": 400,
                "code": "some_other_error",
                "message": "Some Other Error"
            }
            """
        let jsonData = jsonString.data(using: .utf8)!
        let decodedError = try JSONDecoder().decode(ForageErrorObj.self, from: jsonData)
        
        XCTAssertEqual(decodedError.httpStatusCode, 400)
        XCTAssertEqual(decodedError.code, "some_other_error")
        XCTAssertEqual(decodedError.message, "Some Other Error")
        XCTAssertNil(decodedError.details)
    }
}
