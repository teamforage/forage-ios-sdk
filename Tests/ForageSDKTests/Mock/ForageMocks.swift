//
//  ForageMocks.swift
//  ForageSDK
//
//  Created by Symphony on 29/11/22.
//

import Foundation

class ForageMocks {
    
    init() {}
    
    var mockSuccessResponse: HTTPURLResponse? {
        return HTTPURLResponse(url: URL(string: "https://forage.com/tests")!, statusCode: 200, httpVersion: nil, headerFields: nil)
    }
    
    var mockFailureResponse: HTTPURLResponse? {
        return HTTPURLResponse(url: URL(string: "https://forage.com/tests")!, statusCode: 400, httpVersion: nil, headerFields: nil)
    }
    
    var generalError: Error {
        let response = """
        {
           "path":"",
           "errors":[
              {
                 "code":"",
                 "message":"",
                 "source":[
                    
                 ]
              }
           ]
        }
"""
        return NSError(domain: response, code: 400, userInfo: nil)
    }
    
    var tokenizeSuccess: Data {
        let response = """
        {
           "ref":"d0c47b0ed5",
           "type":"ebt",
           "balance":null,
           "card":{
              "last_4":"3412",
              "created":"2022-11-29T03:31:52.349193-08:00",
              "token":"tok_sandbox_72VEC9LasHbMYiiVWP9zms"
           }
        }
"""
        return Data(response.utf8)
    }
    
    var tokenizeFailure: Error {
        let response = """
        {
           "path":"/api/payment_methods/",
           "errors":[
              {
                 "code":"cannot_parse_request_body",
                 "message":"Parsing \"ebt_card\" field failed with message: {'number': [ErrorDetail(string='Card number must be between 15 and 19 digits in length', code='invalid')]}",
                 "source":[
                    {
                       "resource":"Payment_Methods",
                       "ref":""
                    }
                 ]
              }
           ]
        }
"""
        return NSError(domain: response, code: 400, userInfo: nil)
    }
    
    var xKeySuccess: Data {
        let response = """
        {
           "alias":"tok_sandbox_agCcwWZs8TMkkq89f8KHSx"
        }
"""
        return Data(response.utf8)
    }
    
    var getBalanceSuccess: Data {
        let response = """
        {
           "snap":"99.76",
           "non_snap":"100.00",
           "updated":"2022-11-29T12:36:57.482668-08:00"
        }
"""
        return Data(response.utf8)
    }
    
    var capturePaymentSuccess: Data {
        let response = """
        {
           "ref":"8a15d4a672",
           "merchant":"8000009",
           "funding_type":"ebt_snap",
           "amount":"0.01",
           "description":"desc",
           "metadata":{
              
           },
           "payment_method":"1bfc157553",
           "delivery_address":{
              "city":"Los Angeles",
              "country":"United States",
              "line1":"Street",
              "line2":"Number",
              "state":"LA",
              "zipcode":"12345"
           },
           "is_delivery":false,
           "created":"2022-11-29T12:57:10.269929-08:00",
           "updated":"2022-11-29T12:57:18.561355-08:00",
           "status":"succeeded",
           "last_processing_error":null,
           "success_date":"2022-11-29T20:57:18.548072Z",
           "refunds":[
              
           ]
        }
"""
        return Data(response.utf8)
    }
}
