//
//  ForagePANValidations.swift
//  ForageSDK
//
//  Created by Symphony on 31/10/22.
//

import UIKit

class ForagePANValidations {
    
    /// Check ebt card number length
    static func checkPANLength(_ panNumber: String) -> StateIIN? {
        if panNumber.count >= 6 {
            let pan = panNumber.prefix(6)
            return panNumbers.first { $0.panNumber == pan }
        }
        
        return nil
    }

    /// List of allowed ebt card numbers and its respective length
    static var panNumbers: [StateIIN] = [
        StateIIN(state: "ALABAMA", panNumber: "507680", panLength: 16),
        StateIIN(state: "ALASKA", panNumber: "507695", panLength: 16),
        StateIIN(state: "ARIZONA", panNumber: "507706", panLength: 16),
        StateIIN(state: "ARKANSAS", panNumber: "610093", panLength: 16),
        StateIIN(state: "CALIFORNIA", panNumber: "507719", panLength: 16),
        StateIIN(state: "COLORADO", panNumber: "507681", panLength: 16),
        StateIIN(state: "CONNECTICUT", panNumber: "600890", panLength: 18),
        StateIIN(state: "DELAWARE", panNumber: "507713", panLength: 16),
        StateIIN(state: "DISTRICT_OF_COLUMBIA", panNumber: "507707", panLength: 16),
        StateIIN(state: "FLORIDA", panNumber: "508139", panLength: 16),
        StateIIN(state: "GEORGIA", panNumber: "508148", panLength: 16),
        StateIIN(state: "GUAM", panNumber: "578036", panLength: 16),
        StateIIN(state: "HAWAII", panNumber: "507698", panLength: 16),
        StateIIN(state: "IDAHO", panNumber: "507692", panLength: 16),
        StateIIN(state: "ILLINOIS", panNumber: "601453", panLength: 19),
        StateIIN(state: "INDIANA", panNumber: "507704", panLength: 16),
        StateIIN(state: "IOWA", panNumber: "627485", panLength: 19),
        StateIIN(state: "KANSAS", panNumber: "601413", panLength: 16),
        StateIIN(state: "KENTUCKY", panNumber: "507709", panLength: 16),
        StateIIN(state: "LOUISIANA", panNumber: "504476", panLength: 16),
        StateIIN(state: "MAINE", panNumber: "507703", panLength: 19),
        StateIIN(state: "MARYLAND", panNumber: "600528", panLength: 16),
        StateIIN(state: "MASSACHUSETTS", panNumber: "600875", panLength: 18),
        StateIIN(state: "MICHIGAN", panNumber: "507711", panLength: 16),
        StateIIN(state: "MINNESOTA", panNumber: "610423", panLength: 16),
        StateIIN(state: "MISSISSIPPI", panNumber: "507718", panLength: 16),
        StateIIN(state: "MISSOURI", panNumber: "507683", panLength: 16),
        StateIIN(state: "MONTANA", panNumber: "507714", panLength: 16),
        StateIIN(state: "NEBRASKA", panNumber: "507716", panLength: 16),
        StateIIN(state: "NEVADA", panNumber: "507715", panLength: 16),
        StateIIN(state: "NEW_HAMPSHIRE", panNumber: "507701", panLength: 16),
        StateIIN(state: "NEW_JERSEY", panNumber: "610434", panLength: 16),
        StateIIN(state: "NEW_MEXICO", panNumber: "586616", panLength: 16),
        StateIIN(state: "NEW_YORK", panNumber: "600486", panLength: 19),
        StateIIN(state: "NORTH_CAROLINA", panNumber: "508161", panLength: 16),
        StateIIN(state: "NORTH_DAKOTA", panNumber: "508132", panLength: 16),
        StateIIN(state: "OHIO", panNumber: "507700", panLength: 16),
        StateIIN(state: "OKLAHOMA", panNumber: "508147", panLength: 16),
        StateIIN(state: "OREGON", panNumber: "507693", panLength: 16),
        StateIIN(state: "PENNSYLVANIA", panNumber: "600760", panLength: 19),
        StateIIN(state: "RHODE_ISLAND", panNumber: "507682", panLength: 16),
        StateIIN(state: "SOUTH_CAROLINA", panNumber: "610470", panLength: 19),
        StateIIN(state: "SOUTH_DAKOTA", panNumber: "508132", panLength: 16),
        StateIIN(state: "TENNESSEE", panNumber: "507702", panLength: 16),
        StateIIN(state: "TEXAS", panNumber: "610098", panLength: 19),
        StateIIN(state: "US_VIRGIN_ISLANDS", panNumber: "507721", panLength: 16),
        StateIIN(state: "UTAH", panNumber: "601036", panLength: 16),
        StateIIN(state: "VERMONT", panNumber: "507705", panLength: 16),
        StateIIN(state: "VIRGINIA", panNumber: "622044", panLength: 16),
        StateIIN(state: "WASHINGTON", panNumber: "507710", panLength: 16),
        StateIIN(state: "WEST_VIRGINIA", panNumber: "507720", panLength: 16),
        StateIIN(state: "WISCONSIN", panNumber: "507708", panLength: 16),
        StateIIN(state: "WYOMING", panNumber: "505349", panLength: 16),        
    ]
}

/// StateINN object to identify card object valid data
struct StateIIN {
    let state: String
    let panNumber: String
    let panLength: Int
    
    init(state: String, panNumber: String, panLength: Int) {
        self.state = state
        self.panNumber = panNumber
        self.panLength = panLength
    }
}
