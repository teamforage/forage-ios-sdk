//
//  ForagePANValidations.swift
//  ForageSDK
//
//  Created by Tiago Oliveira on 31/10/22.
//  © 2022-Present Forage Technology Corporation. All rights reserved.
//

import UIKit

class ForagePANValidations {
    /// Check ebt card number length
    static func checkPANLength(_ panNumber: String) -> StateIIN? {
        if panNumber.count >= 6 {
            let iin = panNumber.prefix(6)
            return panNumbers.first { $0.iin == iin }
        }

        return nil
    }

    /// List of allowed ebt card numbers and its respective length
    static var panNumbers: [StateIIN] = [
        StateIIN(state: USState.alabama, iin: "507680", panLengths: [16]),
        StateIIN(state: USState.alaska, iin: "507695", panLengths: [16]),
        StateIIN(state: USState.arizona, iin: "507706", panLengths: [16]),
        StateIIN(state: USState.arkansas, iin: "610093", panLengths: [16]),
        StateIIN(state: USState.california, iin: "507719", panLengths: [16]),
        StateIIN(state: USState.colorado, iin: "507681", panLengths: [16]),
        StateIIN(state: USState.connecticut, iin: "600890", panLengths: [18]),
        StateIIN(state: USState.delaware, iin: "507713", panLengths: [16]),
        StateIIN(state: USState.districtOfColumbia, iin: "507707", panLengths: [16]),
        StateIIN(state: USState.florida, iin: "508139", panLengths: [16]),
        StateIIN(state: USState.georgia, iin: "508148", panLengths: [16]),
        StateIIN(state: USState.guam, iin: "578036", panLengths: [16]),
        StateIIN(state: USState.hawaii, iin: "507698", panLengths: [16]),
        StateIIN(state: USState.idaho, iin: "507692", panLengths: [16]),
        StateIIN(state: USState.illinois, iin: "601453", panLengths: [16]),
        StateIIN(state: USState.indiana, iin: "507704", panLengths: [16]),
        StateIIN(state: USState.iowa, iin: "627485", panLengths: [19]),
        StateIIN(state: USState.kansas, iin: "601413", panLengths: [16]),
        StateIIN(state: USState.kentucky, iin: "507709", panLengths: [16]),
        StateIIN(state: USState.louisiana, iin: "504476", panLengths: [16]),
        // Maine cards can be 16 or 19 digits long!
        StateIIN(state: USState.maine, iin: "507703", panLengths: [16, 19]),
        StateIIN(state: USState.maryland, iin: "600528", panLengths: [16]),
        StateIIN(state: USState.massachusetts, iin: "600875", panLengths: [18]),
        StateIIN(state: USState.michigan, iin: "507711", panLengths: [16]),
        StateIIN(state: USState.minnesota, iin: "610423", panLengths: [16]),
        StateIIN(state: USState.mississippi, iin: "507718", panLengths: [16]),
        StateIIN(state: USState.missouri, iin: "507683", panLengths: [16]),
        StateIIN(state: USState.montana, iin: "507714", panLengths: [16]),
        StateIIN(state: USState.nebraska, iin: "507716", panLengths: [16]),
        StateIIN(state: USState.nevada, iin: "507715", panLengths: [16]),
        StateIIN(state: USState.newHampshire, iin: "507701", panLengths: [16]),
        StateIIN(state: USState.newJersey, iin: "610434", panLengths: [16]),
        StateIIN(state: USState.newMexico, iin: "586616", panLengths: [16]),
        StateIIN(state: USState.newYork, iin: "600486", panLengths: [19]),
        StateIIN(state: USState.northCarolina, iin: "508161", panLengths: [16]),
        StateIIN(state: USState.ohio, iin: "507700", panLengths: [16]),
        StateIIN(state: USState.oklahoma, iin: "508147", panLengths: [16]),
        StateIIN(state: USState.oregon, iin: "507693", panLengths: [16]),
        StateIIN(state: USState.pennsylvania, iin: "600760", panLengths: [19]),
        StateIIN(state: USState.rhodeIsland, iin: "507682", panLengths: [16]),
        StateIIN(state: USState.southCarolina, iin: "610470", panLengths: [16]),
        StateIIN(state: USState.southDakota, iin: "508132", panLengths: [16]),
        StateIIN(state: USState.tennessee, iin: "507702", panLengths: [16]),
        StateIIN(state: USState.texas, iin: "610098", panLengths: [19]),
        StateIIN(state: USState.usVirginIslands, iin: "507721", panLengths: [16]),
        StateIIN(state: USState.utah, iin: "601036", panLengths: [16]),
        StateIIN(state: USState.vermont, iin: "507705", panLengths: [16]),
        StateIIN(state: USState.virginia, iin: "622044", panLengths: [16]),
        StateIIN(state: USState.washington, iin: "507710", panLengths: [16]),
        StateIIN(state: USState.westVirginia, iin: "507720", panLengths: [16]),
        StateIIN(state: USState.wisconsin, iin: "507708", panLengths: [16]),
        StateIIN(state: USState.wyoming, iin: "505349", panLengths: [16]),
    ]
}

/// StateINN object to identify card object valid data
struct StateIIN {
    let state: USState
    // first 6 digits of EBT card
    let iin: String
    let panLengths: [Int]
}

extension StateIIN: Equatable {}
