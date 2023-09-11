import XCTest

@testable import ForageSDK

final class MessageResponseTests: XCTestCase {
    func testDecoding_MessageWithDetails_ReturnsCorrectDetails() throws {
        let jsonString = """
             {
                 "content_id": "ee1889a2-7366-41a4-b918-bddae792d5f5",
                 "message_type": "0200",
                 "status": "completed",
                 "failed": false,
                 "errors": [
                     {
                         "status_code": 400,
                         "forage_code": "ebt_error_51",
                         "message": "Insufficient Funds",
                         "details": {
                             "snap_balance": "12.34",
                             "cash_balance": "567.89"
                         }
                     }
                 ]
             }
         """
        let jsonData = jsonString.data(using: .utf8)!
        let decodedResponse = try JSONDecoder().decode(MessageResponseModel.self, from: jsonData)
        
        XCTAssertEqual(decodedResponse.contentId, "ee1889a2-7366-41a4-b918-bddae792d5f5")
        XCTAssertEqual(decodedResponse.messageType, "0200")
        XCTAssertEqual(decodedResponse.status, "completed")
        XCTAssertEqual(decodedResponse.failed, false)
        
        guard let firstError = decodedResponse.errors.first else {
            XCTFail("Should have at least one error")
            return
        }
        
        XCTAssertEqual(firstError.statusCode, 400)
        XCTAssertEqual(firstError.forageCode, "ebt_error_51")
        XCTAssertEqual(firstError.message, "Insufficient Funds")
        
        if case .ebtError51(let snapBalance, let cashBalance)? = firstError.details {
            XCTAssertEqual(snapBalance, "12.34")
            XCTAssertEqual(cashBalance, "567.89")
        } else {
            XCTFail("Decoded details should be of type .ebtError51")
        }
    }
    
    func testDecoding_MessageWithoutDetails_SetsDetailsToNil() throws {
        let jsonString = """
             {
                 "content_id": "ee1889a2-7366-41a4-b918-bddae792d5f5",
                 "message_type": "0200",
                 "status": "received_on_django",
                 "failed": true,
                 "errors": [
                     {
                         "status_code": 500,
                         "forage_code": "some_other_code",
                         "message": "Some Error"
                     }
                 ]
             }
         """
        let jsonData = jsonString.data(using: .utf8)!
        let decodedResponse = try JSONDecoder().decode(MessageResponseModel.self, from: jsonData)
        
        XCTAssertEqual(decodedResponse.contentId, "ee1889a2-7366-41a4-b918-bddae792d5f5")
        XCTAssertEqual(decodedResponse.messageType, "0200")
        XCTAssertEqual(decodedResponse.status, "received_on_django")
        XCTAssertEqual(decodedResponse.failed, true)
        
        XCTAssertEqual(decodedResponse.errors.count, 1)
        let firstError = decodedResponse.errors[0]
        XCTAssertEqual(firstError.statusCode, 500)
        XCTAssertEqual(firstError.forageCode, "some_other_code")
        XCTAssertEqual(firstError.message, "Some Error")
        
        XCTAssertNil(firstError.details)
        
    }
    
    func testDecoding_MessageWithMissingErrorsArray_SetsErrorsToEmpty() throws {
        let jsonString = """
             {
                 "content_id": "some_id",
                 "message_type": "info",
                 "status": "ok",
                 "failed": false
             }
         """
        let jsonData = jsonString.data(using: .utf8)!
        let decodedResponse = try JSONDecoder().decode(MessageResponseModel.self, from: jsonData)
        
        XCTAssertEqual(decodedResponse.contentId, "some_id")
        XCTAssertEqual(decodedResponse.messageType, "info")
        XCTAssertEqual(decodedResponse.status, "ok")
        XCTAssertEqual(decodedResponse.failed, false)
        
        XCTAssertTrue(decodedResponse.errors.isEmpty)
    }
    
    func testDecoding_MessageWithEmptyErrorsArray_ReturnsEmptyErrors() throws {
        let jsonString = """
             {
                 "content_id": "some_id",
                 "message_type": "info",
                 "status": "ok",
                 "failed": false,
                 "errors": []
             }
         """
        let jsonData = jsonString.data(using: .utf8)!
        let decodedResponse = try JSONDecoder().decode(MessageResponseModel.self, from: jsonData)
        
        XCTAssertEqual(decodedResponse.contentId, "some_id")
        XCTAssertEqual(decodedResponse.messageType, "info")
        XCTAssertEqual(decodedResponse.status, "ok")
        XCTAssertEqual(decodedResponse.failed, false)
        
        XCTAssertTrue(decodedResponse.errors.isEmpty)
    }
}
