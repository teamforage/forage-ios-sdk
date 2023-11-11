//
//  ForageMocks.swift
//  ForageSDK
//
//  Created by Tiago Oliveira on 29/11/22.
//  Copyright © 2023-Present Forage Technology Corporation. All rights reserved.
//

import Foundation

class ForageMocks {
    init() {}

    var mockSuccessResponse: HTTPURLResponse? {
        HTTPURLResponse(url: URL(string: "https://forage.com/tests")!, statusCode: 200, httpVersion: nil, headerFields: nil)
    }

    var mockFailureResponse: HTTPURLResponse? {
        HTTPURLResponse(url: URL(string: "https://forage.com/tests")!, statusCode: 400, httpVersion: nil, headerFields: nil)
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
                   },
                   "reusable":true,
                   "customer_id":"test-ios-customer-id"
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

    var getPaymentMethodSuccess: Data {
        let response = """
                {
                    "ref": "ca29d3443f",
                    "type": "ebt",
                    "balance": {
                        "snap": "100.00",
                        "non_snap": "100.00",
                        "updated": "2023-02-23T14:26:02.140579-08:00"
                    },
                    "card": {
                        "last_4": "1234",
                        "created": "2023-02-23T14:25:37.531327-08:00",
                        "token": "tok_sandbox_vJp2BwDc6R6Z16mgzCxuXk",
                        "state": "PA"
                    },
                    "reusable":true
                }
        """
        return Data(response.utf8)
    }

    var getPaymentMethodFailure: Error {
        let response = """
                {
                    "path": "/api/payment_methods/ca293443f/",
                    "errors": [
                        {
                            "code": "resource_not_found",
                            "message": "Payment method with id ca293443f does not exist for Tenant BaseTenant using FNS 9000002",
                            "source": {
                                "resource": "Payment_Methods",
                                "ref": "ca293443f"
                            }
                        }
                    ]
                }
        """
        return NSError(domain: response, code: 400, userInfo: nil)
    }

    var xKeySuccess: Data {
        let response = """
                {
                   "alias":"tok_sandbox_agCcwWZs8TMkkq89f8KHSx",
                   "bt_alias":"443b4f60-67f3-46d7-af4f-0476b7db4894"
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
                    "ref": "11767381fd",
                    "merchant": "9000002",
                    "funding_type": "ebt_snap",
                    "amount": "10.00",
                    "description": "Testing the JS SDK",
                    "metadata": {},
                    "payment_method": "81dab02290",
                    "delivery_address": {
                        "city": "New York",
                        "country": "US",
                        "line1": "203 Spring Street",
                        "line2": "",
                        "state": "NY",
                        "zipcode": "10012"
                    },
                    "is_delivery": false,
                    "created": "2023-04-26T18:50:57.049025-07:00",
                    "updated": "2023-04-26T18:50:59.379628-07:00",
                    "status": "succeeded",
                    "last_processing_error": null,
                    "success_date": "2023-04-27T01:50:59.350429Z",
                    "receipt": {
                        "ref_number": "11767381fd",
                        "is_voided": false,
                        "snap_amount": "10.00",
                        "ebt_cash_amount": "0.00",
                        "other_amount": "0.00",
                        "sales_tax_applied": "0.00",
                        "balance": {
                            "id": 57869,
                            "snap": "90.00",
                            "non_snap": "100.00",
                            "updated": "2023-04-26T18:50:59.336838-07:00"
                        },
                        "last_4": "6789",
                        "message": "Approved",
                        "transaction_type": "Payment",
                        "created": "2023-04-26T18:50:59.345272-07:00"
                    },
                    "refunds": [
                        "9bf75154be"
                    ]
                }
        """
        return Data(response.utf8)
    }

    var getPaymentError: Error {
        let response = """
                {
                    "path": "/api/payments/1767381fd/",
                    "errors": [
                        {
                            "code": "resource_not_found",
                            "message": "Payment with ref 1767381fd does not exist for current Merchant with FNS 9000002. For payments that are associated with an order, please use `/api/orders/<order_ref>/payments/` instead",
                            "source": {
                                "resource": "Payments",
                                "ref": "1767381fd"
                            }
                        }
                    ]
                }
        """
        return NSError(domain: response, code: 400, userInfo: nil)
    }

    // MARK: GET /message/ success responses

    var getMessageCompleted: Data {
        let response = """
        {
          "content_id": "d789c086-9c4f-41c3-854a-1c436eee1d63",
          "message_type": "0200",
          "status": "completed",
          "failed": false,
          "errors": []
        }
        """
        return Data(response.utf8)
    }
    
    // we continue to retry until we see status: "completed"
    // so we permantly set the status to: "sent_to_proxy" to trigger retry attempts
    var getMessageIncomplete: Data {
        let response = """
        {
          "content_id": "i789c086-9c4f-41c3-854a-1c436eee1d63",
          "message_type": "0200",
          "status": "sent_to_proxy",
          "failed": false,
          "errors": []
        }
        """
        return Data(response.utf8)
    }

    // MARK: GET /message/ error responses

    var getMessageUnauthorized: Data {
        let response = """
        {
            "path": "/api/message/1c53e9e0-92e9-4568-a128-deecf4c2194a/",
            "errors": [
              {
                "code": "missing_merchant_account",
                "message": "No merchant account FNS number was provided.",
                "source": {
                  "resource": "Merchant_Account_Header",
                  "ref": ""
                }
              }
            ]
          }
        """
        return Data(response.utf8)
    }

    var getMessageExpiredCard: Data {
        let response = """
        {
          "content_id": "36058ff7-0e9d-4025-94cd-80ef04a3bb1c",
          "message_type": "0200",
          "status": "received_on_django",
          "failed": true,
          "errors": [
            {
              "status_code": 400,
              "forage_code": "ebt_error_54",
              "message": "Expired card - Expired Card"
            }
          ]
        }
        """
        return Data(response.utf8)
    }

    var getMessageFailed: Data {
        let response = """
        {
          "content_id": "c2bf2b14-415f-4cb3-8687-7eea06f75369",
          "message_type": "0200",
          "status": "received_on_django",
          "failed": true,
          "errors": [
            {
              "status_code": 400,
              "forage_code": "ebt_error_51",
              "message": "Received failure response from EBT network"
            }
          ]
        }
        """
        return Data(response.utf8)
    }
    
    // missing "errors" list
    var getMessageMalformed: Data {
        let response = """
        {
          "content_id": "d789c086-9c4f-41c3-854a-1c436eee1d63",
          "message_type": "0200",
          "status": "completed",
          "failed": false
        }
        """
        return Data(response.utf8)
    }
}
