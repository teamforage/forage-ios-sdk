//
//  ForagePANElement.swift
//
//
//  Created by Danny Leiser on 11/23/23.
//  © 2023-Present Forage Technology Corporation. All rights reserved.
//

/// Represents card information derived from the user's current Primary Account Number (PAN) input value.
public protocol DerivedCardInfoProtocol {
    /// The US state that issued the EBT card, derived from the Issuer Identification Number (IIN),
    /// also known as BIN (Bank Identification Number).
    /// The IIN is the first 6 digits of the PAN.
    var usState: USState? { get }
}

public class DerivedCardInfo: DerivedCardInfoProtocol {
    public var usState: USState?
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
    case districtOfColumbia = "DC"
    case florida = "FL"
    case georgia = "GA"
    case guam = "GU"
    case hawaii = "HI"
    case idaho = "ID"
    case illinois = "IL"
    case indiana = "IN"
    case iowa = "IA"
    case kansas = "KS"
    case kentucky = "KY"
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
    case newHampshire = "NH"
    case newJersey = "NJ"
    case newMexico = "NM"
    case newYork = "NY"
    case northCarolina = "NC"
    case ohio = "OH"
    case oklahoma = "OK"
    case oregon = "OR"
    case pennsylvania = "PA"
    case rhodeIsland = "RI"
    case southCarolina = "SC"
    case southDakota = "SD"
    case tennessee = "TN"
    case texas = "TX"
    case usVirginIslands = "VI"
    case utah = "UT"
    case vermont = "VT"
    case virginia = "VA"
    case washington = "WA"
    case westVirginia = "WV"
    case wisconsin = "WI"
    case wyoming = "WY"
}
