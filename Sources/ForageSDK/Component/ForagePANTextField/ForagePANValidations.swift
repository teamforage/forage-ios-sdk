//
//  ForagePANValidations.swift
//  ForageSDK
//
//  Created by Tiago Oliveira on 31/10/22.
//  Copyright © 2022-Present Forage Technology Corporation. All rights reserved.
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
        StateIIN(state: USState.alabama, panNumber: "507680", panLength: 16),
        StateIIN(state: USState.alaska, panNumber: "507695", panLength: 16),
        StateIIN(state: USState.arizona, panNumber: "507706", panLength: 16),
        StateIIN(state: USState.arkansas, panNumber: "610093", panLength: 16),
        StateIIN(state: USState.california, panNumber: "507719", panLength: 16),
        StateIIN(state: USState.colorado, panNumber: "507681", panLength: 16),
        StateIIN(state: USState.connecticut, panNumber: "600890", panLength: 18),
        StateIIN(state: USState.delaware, panNumber: "507713", panLength: 16),
        StateIIN(state: USState.districtOfColumbia, panNumber: "507707", panLength: 16),
        StateIIN(state: USState.florida, panNumber: "508139", panLength: 16),
        StateIIN(state: USState.georgia, panNumber: "508148", panLength: 16),
        StateIIN(state: USState.guam, panNumber: "578036", panLength: 16),
        StateIIN(state: USState.hawaii, panNumber: "507698", panLength: 16),
        StateIIN(state: USState.idaho, panNumber: "507692", panLength: 16),
        StateIIN(state: USState.illinois, panNumber: "601453", panLength: 16),
        StateIIN(state: USState.indiana, panNumber: "507704", panLength: 16),
        StateIIN(state: USState.iowa, panNumber: "627485", panLength: 19),
        StateIIN(state: USState.kansas, panNumber: "601413", panLength: 16),
        StateIIN(state: USState.kentucky, panNumber: "507709", panLength: 16),
        StateIIN(state: USState.louisiana, panNumber: "504476", panLength: 16),
        StateIIN(state: USState.maine, panNumber: "507703", panLength: 19),
        StateIIN(state: USState.maryland, panNumber: "600528", panLength: 16),
        StateIIN(state: USState.massachusetts, panNumber: "600875", panLength: 18),
        StateIIN(state: USState.michigan, panNumber: "507711", panLength: 16),
        StateIIN(state: USState.minnesota, panNumber: "610423", panLength: 16),
        StateIIN(state: USState.mississippi, panNumber: "507718", panLength: 16),
        StateIIN(state: USState.missouri, panNumber: "507683", panLength: 16),
        StateIIN(state: USState.montana, panNumber: "507714", panLength: 16),
        StateIIN(state: USState.nebraska, panNumber: "507716", panLength: 16),
        StateIIN(state: USState.nevada, panNumber: "507715", panLength: 16),
        StateIIN(state: USState.newHampshire, panNumber: "507701", panLength: 16),
        StateIIN(state: USState.newJersey, panNumber: "610434", panLength: 16),
        StateIIN(state: USState.newMexico, panNumber: "586616", panLength: 16),
        StateIIN(state: USState.newYork, panNumber: "600486", panLength: 19),
        StateIIN(state: USState.northCarolina, panNumber: "508161", panLength: 16),
        StateIIN(state: USState.northDakota, panNumber: "508132", panLength: 16),
        StateIIN(state: USState.ohio, panNumber: "507700", panLength: 16),
        StateIIN(state: USState.oklahoma, panNumber: "508147", panLength: 16),
        StateIIN(state: USState.oregon, panNumber: "507693", panLength: 16),
        StateIIN(state: USState.pennsylvania, panNumber: "600760", panLength: 19),
        StateIIN(state: USState.rhodeIsland, panNumber: "507682", panLength: 16),
        StateIIN(state: USState.southCarolina, panNumber: "610470", panLength: 16),
        StateIIN(state: USState.southDakota, panNumber: "508132", panLength: 16),
        StateIIN(state: USState.tennessee, panNumber: "507702", panLength: 16),
        StateIIN(state: USState.texas, panNumber: "610098", panLength: 19),
        StateIIN(state: USState.usVirginIslands, panNumber: "507721", panLength: 16),
        StateIIN(state: USState.utah, panNumber: "601036", panLength: 16),
        StateIIN(state: USState.vermont, panNumber: "507705", panLength: 16),
        StateIIN(state: USState.virginia, panNumber: "622044", panLength: 16),
        StateIIN(state: USState.washington, panNumber: "507710", panLength: 16),
        StateIIN(state: USState.westVirginia, panNumber: "507720", panLength: 16),
        StateIIN(state: USState.wisconsin, panNumber: "507708", panLength: 16),
        StateIIN(state: USState.wyoming, panNumber: "505349", panLength: 16),
    ]
}

/// StateINN object to identify card object valid data
struct StateIIN {
    let state: USState
    let panNumber: String
    let panLength: Int
}

extension StateIIN: Equatable {}
