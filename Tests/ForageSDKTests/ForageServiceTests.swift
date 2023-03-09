//
//  ForageServiceTests.swift
//  ForageSDK
//
//  Created by Symphony on 29/11/22.
//

import XCTest
import VGSCollectSDK
@testable import ForageSDK

final class ForageServiceTests: XCTestCase {
    
    var forageMocks: ForageMocks!
    
    override func setUp() {
        ForageSDK.setup(ForageSDK.Config(environment: .sandbox))
        ForageSDK.shared.service = nil
        forageMocks = ForageMocks()
    }
    
    func test_tokenizeEBTCard_onSuccess_checkExpectedPayload() {
        let mockSession = URLSessionMock()
        mockSession.data = forageMocks.tokenizeSuccess
        mockSession.response = forageMocks.mockSuccessResponse
        let service = LiveForageService(provider: Provider(mockSession))
        
        let foragePANRequestModel = ForagePANRequestModel(
            authorization: "authToken123",
            merchantAccount: "merchantID123",
            panNumber: "5076801234123412",
            type: "ebt",
            reusable: true
        )
        
        service.tokenizeEBTCard(request: foragePANRequestModel) { result in
            switch result {
            case .success(let response):
                XCTAssertEqual(response.type, "ebt")
                XCTAssertEqual(response.paymentMethodIdentifier, "d0c47b0ed5")
                XCTAssertEqual(response.card.last4, "3412")
                XCTAssertEqual(response.card.token, "tok_sandbox_72VEC9LasHbMYiiVWP9zms")
            case .failure:
                XCTFail("Expected success")
            }
        }
    }
    
    func test_tokenizeEBTCard_onFailure_shouldReturnFailure() {
        let mockSession = URLSessionMock()
        mockSession.error = forageMocks.tokenizeFailure
        mockSession.response = forageMocks.mockFailureResponse
        let service = LiveForageService(provider: Provider(mockSession))
        
        let foragePANRequestModel = ForagePANRequestModel(
            authorization: "authToken123",
            merchantAccount: "merchantID123",
            panNumber: "5076801234123412",
            type: "ebt",
            reusable: true
        )
        
        service.tokenizeEBTCard(request: foragePANRequestModel) { result in
            switch result {
            case .success:
                XCTFail("Expected failure")
            case .failure(let error):
                XCTAssertNotNil(error)
            }
        }
    }

    func test_getXKey_onSuccess_checkExpectedPayload() {
        let mockSession = URLSessionMock()
        mockSession.data = forageMocks.xKeySuccess
        mockSession.response = forageMocks.mockSuccessResponse
        let service = LiveForageService(provider: Provider(mockSession))
        
        service.getXKey(bearerToken: "auth1234", merchantAccount: "1234567") { result in
            switch result {
            case .success(let model):
                XCTAssertEqual(model.alias, "tok_sandbox_agCcwWZs8TMkkq89f8KHSx")
            case .failure:
                XCTFail("Expected success")
            }
        }
    }
    
    func test_getXKey_onFailure_shouldReturnFailure() {
        let mockSession = URLSessionMock()
        mockSession.error = forageMocks.generalError
        mockSession.response = forageMocks.mockFailureResponse
        let service = LiveForageService(provider: Provider(mockSession))
        
        service.getXKey(bearerToken: "auth1234", merchantAccount: "1234567") { result in
            switch result {
            case .success:
                XCTFail("Expected failure")
            case .failure(let error):
                XCTAssertNotNil(error)
            }
        }
    }

    func test_getBalance_onSuccess_checkExpectedPayload() {
        let mockSession = URLSessionMock()
        mockSession.data = forageMocks.getBalanceSuccess
        mockSession.response = forageMocks.mockSuccessResponse
        let vgs = VGSCollect(id: "1234", environment: .sandbox)
        let service = LiveForageService(provider: Provider(mockSession))
        
        let forageRequestModel = ForageRequestModel(
            authorization: "authToken123",
            paymentMethodReference: "refMethod123",
            paymentReference: "",
            cardNumberToken: "cardToken123",
            merchantID: "merchantID123",
            xKey: "tok_sandbox_agCcwWZs8TMkkq89f8KHSx"
        )

        service.getBalance(vgs: vgs, request: forageRequestModel) { result in
            switch result {
            case .success(let data):
                guard let data = data,
                      let response = try? JSONDecoder().decode(ForageBalanceModel.self, from: data)
                else { return }
                
                XCTAssertEqual(response.snap, "99.76")
                XCTAssertEqual(response.nonSnap, "100.00")
                XCTAssertEqual(response.updated, "2022-11-29T12:36:57.482668-08:00")
            case .failure:
                XCTFail("Expected success")
            }
        }
    }
    
    func test_getBalance_onFailure_shouldReturnFailure() {
        let mockSession = URLSessionMock()
        mockSession.error = forageMocks.generalError
        mockSession.response = forageMocks.mockFailureResponse
        let vgs = VGSCollect(id: "1234", environment: .sandbox)
        let service = LiveForageService(provider: Provider(mockSession))
        
        let forageRequestModel = ForageRequestModel(
            authorization: "authToken123",
            paymentMethodReference: "refMethod123",
            paymentReference: "",
            cardNumberToken: "cardToken123",
            merchantID: "merchantID123",
            xKey: "tok_sandbox_agCcwWZs8TMkkq89f8KHSx"
        )

        service.getBalance(vgs: vgs, request: forageRequestModel) { result in
            switch result {
            case .success:
                XCTFail("Expected failure")
            case .failure(let error):
                XCTAssertNotNil(error)
            }
        }
    }
    
    func test_capturePayment_onSuccess_checkExpectedPayload() {
        let mockSession = URLSessionMock()
        mockSession.data = forageMocks.capturePaymentSuccess
        mockSession.response = forageMocks.mockSuccessResponse
        let vgs = VGSCollect(id: "1234", environment: .sandbox)
        let service = LiveForageService(provider: Provider(mockSession))
        
        let forageRequestModel = ForageRequestModel(
            authorization: "authToken123",
            paymentMethodReference: "",
            paymentReference: "ref1234",
            cardNumberToken: "cardToken123",
            merchantID: "merchantID123",
            xKey: "tok_sandbox_agCcwWZs8TMkkq89f8KHSx"
        )

        service.requestCapturePayment(vgs: vgs, request: forageRequestModel) { result in
            switch result {
            case .success(let data):
                guard let data = data,
                      let response = try? JSONDecoder().decode(ForageCaptureModel.self, from: data)
                else { return }
                
                XCTAssertEqual(response.paymentIdentifier, "8a15d4a672")
                XCTAssertEqual(response.merchantAccount, "8000009")
                XCTAssertEqual(response.fundingType, "ebt_snap")
                XCTAssertEqual(response.amount, "0.01")
                XCTAssertEqual(response.paymentMethodIdentifier, "1bfc157553")
                XCTAssertEqual(response.status.rawValue, "succeeded")
            case .failure:
                XCTFail("Expected success")
            }
        }
    }
    
    func test_capturePayment_onFailure_shouldReturnFailure() {
        let mockSession = URLSessionMock()
        mockSession.error = forageMocks.generalError
        mockSession.response = forageMocks.mockFailureResponse
        let vgs = VGSCollect(id: "1234", environment: .sandbox)
        let service = LiveForageService(provider: Provider(mockSession))
        
        let forageRequestModel = ForageRequestModel(
            authorization: "authToken123",
            paymentMethodReference: "",
            paymentReference: "ref1234",
            cardNumberToken: "cardToken123",
            merchantID: "merchantID123",
            xKey: "tok_sandbox_agCcwWZs8TMkkq89f8KHSx"
        )

        service.getBalance(vgs: vgs, request: forageRequestModel) { result in
            switch result {
            case .success:
                XCTFail("Expected failure")
            case .failure(let error):
                XCTAssertNotNil(error)
            }
        }
    }
}
