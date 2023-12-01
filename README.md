# ForageSDK

The ForageSDK is a Swift library for securely processing EBT payments. You can use the library to add all of the following EBT checkout operations to your iOS app:

- Store tokenized EBT card numbers for future use
- Check the balance of an EBT card
- Capture an EBT payment

## Table of contents

<!--ts-->

- [ForageSDK](#foragesdk)
  - [Table of contents](#table-of-contents)
  - [Install the ForageSDK](#install-the-foragesdk)
    - [CocoaPods](#cocoapods)
    - [Xcode](#xcode)
  - [Usage](#usage)
    - [Import the SDK](#import-the-sdk)
    - [Initialize the ForageSDK](#initialize-the-foragesdk)
  - [Forage UI Elements](#forage-ui-elements)
    - [ForagePANTextField](#foragepantextfield)
      - [Initialize the `ForagePANTextField`](#initialize-the-foragepantextfield)
      - [Subscribe to `ForageElement` state changes](#subscribe-to-forageelement-state-changes)
      - [Set the `ForageElement` as the First Responder](#set-the-forageelement-as-the-first-responder)
    - [Tokenize a customer's EBT card](#tokenize-a-customers-ebt-card)
    - [ForagePINTextField](#foragepintextfield)
      - [Initialize the `ForagePINTextField`](#initialize-the-foragepintextfield)
      - [Subscribe to `ForagePINTextField` state changes](#subscribe-to-foragepintextfield-state-changes)
      - [Check the balance of an EBT card](#check-the-balance-of-an-ebt-card)
      - [Capture an EBT payment](#capture-an-ebt-payment)
  - [Sample Application](#sample-application)
  - [Dependencies](#dependencies)

## Install the ForageSDK

You can use CocoaPods or Swift Package Manager (SPM) to install `forage-ios-sdk`.

The Forage iOS SDK requires Xcode 14.1 or later and is compatible with apps targeting iOS 13 or above. Earlier Xcode versions do not support Swift packages with resources.

### CocoaPods

1. If you haven’t already, install the latest version of [CocoaPods](https://guides.cocoapods.org/using/getting-started.html).

2. If you don’t have an existing [Podfile](https://guides.cocoapods.org/syntax/podfile.html), run the following command to create one:

```bash
pod init
```

3. Add the following line to your `Podfile`:

```swift
pod 'ForageSDK', '~> 4.2'
```

4. Run the following command

```bash
pod install
```

5. To update to the latest version of the SDK, run:

```bash
pod repo update
pod update ForageSDK
```

### Xcode

<details>
<summary>
See the step-by-step Xcode installation instructions
</summary>

<img width="50%" src="https://user-images.githubusercontent.com/115553362/199012534-9d6475d4-73ed-4459-928e-684aba83a63c.png" alt="File > Add packages">

To use Swift Package Manager, in Xcode add the https://github.com/teamforage/forage-ios-sdk dependency and choose the `Dependency Rule` as Branch and the branch enter `main`.

<img src="https://user-images.githubusercontent.com/115553362/199013574-59c1968a-f879-4404-99df-9db4c0c93f78.png" alt="Add package" width="80%">

Click on the `Add Package` button. On the next screen, select the package `ForageSDK`, and finish by clicking on `Add Package`.

<img src="https://user-images.githubusercontent.com/115553362/199013832-ad86b074-63e3-469b-ad8c-75d65169433b.png" alt="Confirm adding package" width="70%">

Follow the official Apple SPM guide [instructions](https://developer.apple.com/documentation/xcode/adding_package_dependencies_to_your_app) for more details.

</details>

## Usage

### Import the SDK

```swift
import ForageSDK

// your code here
```

### Initialize the ForageSDK

Initialize the ForageSDK by calling `ForageSDK.setup` and passing in a `ForageSDK.Config` object with a valid `merchantID` and `sessionToken`.

ℹ️ **Note:** `ForageSDK.setup` must be called before initializing the [Forage UI Elements](#forage-ui-elements).

```swift
ForageSDK.setup(
    ForageSDK.Config(
        merchantID: "1234567",
        sessionToken: "sandbox_eyJ0eXAiOiJKV1Qi..."
    )
)
```

## Forage UI Elements

ForageSDK provides two UI Elements to securely communicate with the Forage API.

### ForagePANTextField

A `ForageElement` that securely collects the customer's EBT PAN. This field validates the PAN based on the Issuer Identification Number (IIN).

<img width="45%" alt="image" src="https://github.com/teamforage/forage-ios-sdk/assets/32694765/0a338662-9d29-4a65-882c-b09e99417b25">

#### Initialize the `ForagePANTextField`

```swift
private let foragePanTextField: ForagePANTextField = {
    let tf = ForagePANTextField()

    tf.borderColor = .black
    tf.borderWidth = 3
    tf.clearButtonMode = .whileEditing
    tf.cornerRadius = 4
    tf.font = .systemFont(ofSize: 22)
    tf.placeholder = "EBT Card Number"

    return tf
}()
```

#### Subscribe to `ForageElement` state changes

Forage validates an EBT Element’s input as a customer types. To notify customers of input validation errors, you'll need to conform to the `ForageElementDelegate` protocol.

The `focusDidChange` method is triggered when a `ForageElement` gains or loses focus.

```swift
foragePanTextField.delegate = self
```

```swift
// signature
public protocol ForageElementDelegate: AnyObject {
    func focusDidChange(_ state: ObservableState)
    func textFieldDidChange(_ state: ObservableState)
}

// usage
extension ForagePanView: ForageElementDelegate {
    func focusDidChange(_ state: ObservableState) {
        if state.isFirstResponder { ... } // element gained focus
        else { ... } // element lost focus (blurred)
    }

    func textFieldDidChange(_ state: ObservableState) {
        // show an error message on blur if the input is invalid
        if !state.isValid && !state.isFirstResponder { ... }
    }
}
```

The `ObservableState` protocol defines properties reflecting the state of a `ForageElement`.

```swift
public protocol ObservableState {
    /// Indicates whether the input is focused.
    var isFirstResponder: Bool { get }

    /// Indicates whether the input is empty.
    var isEmpty: Bool { get }

    /// Indicates whether all validation checks pass, excluding the the minimum length validator.
    var isValid: Bool { get }

    /// Indicates whether all validation checks pass and the ForageElement is ready for submission.
    var isComplete: Bool { get }
}
```

The `DerivedCardInfoProtocol` protocol defines inferred information about the `ForagePANTextField`.

```
public protocol DerivedCardInfoProtocol {
    
    /// The US state that issued the EBT card, derived from the Issuer Identification Number (IIN),
    /// also known as BIN (Bank Identification Number).
    /// The IIN is the first 6 digits of the PAN.
    var usState: USState? { get }
}
```

This field can be accessed through the `derivedCardInfo` property.

```
foragePanTextField.derivedCardInfo.usState
```

#### Set the `ForageElement` as the First Responder

Call `foragePanTextField.becomeFirstResponder()` to programmatically set focus on the `ForagePANTextField`:

```swift
func becomeFirstResponder() -> Bool
```

### Tokenize a customer's EBT card

Call `ForageSDK.shared.tokenizeEBTCard` to tokenize a customer’s EBT card number and create a Forage `PaymentMethod`.

```swift
// Signature

func tokenizeEBTCard(
    foragePanTextField: ForagePANTextField,
    customerID: String,
    reusable: Bool?,
    completion: @escaping (Result<PaymentMethodModel, Error>) -> Void
)
```

```swift
// Usage

ForageSDK.shared.tokenizeEBTCard(
    foragePanTextField: foragePanTextField,
    // NOTE: The following line is for testing purposes only and should not be used in production.
    // Please replace this line with a real hashed customer ID value.
    customerID: UUID.init().uuidString,
    reusable: true
) { result in
    // Handle result and error here
}
```

### ForagePINTextField

A `ForageElement` that securely collects the customer's EBT card PIN to perform a balance check or capture an EBT payment.

<img width="40%" alt="image" src="https://github.com/teamforage/forage-ios-sdk/assets/32694765/aa65ead5-08ea-40ff-be6c-40d97466cfaa">

#### Initialize the `ForagePINTextField`

```swift
private let foragePinTextField: ForagePINTextField = {
    let tf = ForagePINTextField()
    tf.borderRadius = 10
    tf.backgroundColor = .systemGray6
    return tf
}()
```

#### Subscribe to `ForagePINTextField` state changes

Use the `ForageElementDelegate` to subscribe to input validation and element focus state changes for `ForagePINTextField`.

```swift
foragePinTextField.delegate = self

extension ForagePinView: ForageElementDelegate {
    func focusDidChange(_ state: ObservableState) {
        if state.isFirstResponder { ... }
    }

    func textFieldDidChange(_ state: ObservableState) {
        if state.isComplete { ... }
    }
}
```

#### Check the balance of an EBT card

> **FNS requirements for balance inquiries**
>
> FNS prohibits balance inquiries on sites and apps that offer guest checkout. Skip this section if your customers can opt for guest checkout.
>
> If guest checkout is not an option, then it's up to you whether or not to add a balance inquiry feature. No FNS regulations apply.

Call `ForageSDK.shared.checkBalance` to retrieve the balance of a customer’s EBT card.

```swift
// Signature

func checkBalance(
    foragePinTextField: ForagePINTextField,
    paymentMethodReference: String,
    completion: @escaping (Result<BalanceModel, Error>) -> Void
)
```

```swift
// Usage

ForageSDK.shared.checkBalance(
    foragePinTextField: foragePinTextField,
    paymentMethodReference: paymentMethodReference
) { result in
    // Handle result and error here
}
```

#### Capture an EBT payment

```swift
// Signature

func capturePayment(
    foragePinTextField: ForagePINTextField,
    paymentReference: String,
    completion: @escaping (Result<PaymentModel, Error>) -> Void
)
```

```swift
// Usage

ForageSDK.shared.capturePayment(
    foragePinTextField: foragePinTextField,
    paymentReference: paymentReference
) { result in
    // Handle result and error here
}
```

## Sample Application

The Forage iOS SDK sample application can be <a href="https://github.com/teamforage/forage-ios-sdk/tree/main/Sample">found here</a>.

To get the application running:

1. Clone this repo and open the `SampleForageSDK.xcodeproj` project in the `Sample/` directory.
2. Ensure that you have a valid Merchant ID for the Forage API, which can be found on the dashboard ([sandbox](https://dashboard.sandbox.joinforage.app/login/) | [prod](https://dashboard.joinforage.app/login/)).
3. [Create an authentication token](https://docs.joinforage.app/docs/authentication#authentication-tokens) with `pinpad_only` scope.
4. [Create a session token](https://docs.joinforage.app/docs/authentication#session-tokens).
5. Run the Sample app and provide your Merchant ID and session token on the first screen.
6. Forage SDKs include built-in EBT card number validation in both sandbox and production. Use the [Test EBT cards](https://docs.joinforage.app/docs/test-ebt-cards) for developing against successful transactions and invalid EBT test card numbers for triggering exceptions.

## Dependencies

- Xcode 14.1 or above
- iOS 13 or above
- Swift 5.5
- 3rd party libraries:
  - [VGS-Collect-iOS](https://github.com/verygoodsecurity/vgs-collect-ios)
  - [LaunchDarkly](https://github.com/launchdarkly/ios-client-sdk.git)
  - [BasisTheory](https://github.com/Basis-Theory/basistheory-ios)
