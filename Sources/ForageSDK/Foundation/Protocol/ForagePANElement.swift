//
//  ForagePANElement.swift
//
//
//  Created by Danny Leiser on 11/23/23.
//  Copyright © 2023-Present Forage Technology Corporation. All rights reserved.
//

/// Represents card information derived from the user's current Primary Account Number (PAN) input value.
public protocol CardInformation {
    
    /// The US state that issued the EBT card, derived from the Issuer Identification Number (IIN),
    /// also known as BIN (Bank Identification Number).
    /// The IIN is the first 6 digits of the PAN.
    var usState: USState? { get }
}

/// Represents a state of the United States of America.
public enum USState: String {
    case alabama = "AL"
    case alaska = "AK"
    case arizona = "AZ"
    case arkansas = "AR"
    case california = "CA"
    case colorado = "CO"
    case connecticut = "CT"
    case delaware = "DE"
    case district_of_columbia = "DC"
    case florida = "FL"
    case georgia = "GA"
    case guam = "GU"
    case hawaii = "HI"
    case idaho = "ID"
    case illinois = "IL"
    case indiana = "IN"
    case iowa = "IA"
    case kansas = "KS"
    case kentucky = "KT"
    case louisiana = "LA"
    case maine = "ME"
    case maryland = "MD"
    case massachusetts = "MA"
    case michigan = "MI"
    case minnesota = "MN"
    case mississippi = "MS"
    case missouri = "MO"
    case montana = "MT"
    case nebraska = "NE"
    case nevada = "NV"
    case new_hampshire = "NH"
    case new_jersey = "NJ"
    case new_mexico = "NM"
    case new_york = "NY"
    case north_carolina = "NC"
    case north_dakota = "ND"
    case ohio = "OH"
    case oklahoma = "OK"
    case oregon = "OR"
    case pennsylvania = "PA"
    case puerto_rico = "PR"
    case rhode_island = "RI"
    case south_carolina = "SC"
    case south_dakota = "SD"
    case tennessee = "TN"
    case texas = "TX"
    case us_virgin_islands = "VI"
    case utah = "UT"
    case vermont = "VT"
    case virginia = "VA"
    case washington = "WA"
    case west_virginia = "WV"
    case wisconsin = "WI"
    case wyoming = "WY"
}
