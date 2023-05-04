# ForageSDK

The ForageSDK processes Electronic Benefits Transfer (EBT) payments in your e-commerce application. It provides secure user interfaces for collecting and tokenizing an EBT cardholder's PAN and accepting an EBT cardholder's PIN to execute a balance check and process a payment.

Table of contents
=================

<!--ts-->
   * [Integration](#integration)
      * [CocoaPods](#cocoapods)
      * [Swift Package Manager](#swift-package-manager) 
   * [Usage](#usage)
      * [Create ForageSDK instance](#create-foragesdk-instance)
      * [Forage UI Elements](#forage-ui-elements)
      * [ForagePANTextField](#foragepantextfield)
      * [ForagePINTextField](#foragepintextfield)
      * [Demo Application](#demo-application)
   * [Dependencies](#dependencies)
<!--te-->

## Integration

### CocoaPods

[CocoaPods](https://cocoapods.org) is a dependency manager for Cocoa projects. For usage and installation instructions, visit their website. To integrate ForageSDK into your Xcode project using CocoaPods, specify it in your `Podfile`:

```swift
pod 'ForageSDK', '~> 0.1.1'
```

### Swift Package Manager

The [Swift Package Manager](https://www.swift.org/package-manager/) is a tool for managing the distribution of Swift code. It’s integrated with the Swift build system to automate the process of downloading, compiling, and linking dependencies.

We recommend using Xcode with Swift tools version 5.3 or higher. Earlier Xcode versions don't support Swift packages with resources.
To check your current Swift tools version run in your terminal:

```swift
xcrun swift -version
```

Follow the official Apple SPM guide [instructions](https://developer.apple.com/documentation/xcode/adding_package_dependencies_to_your_app) for more details.

### Step-by-step

Add package:

![Screen Shot 2022-10-31 at 09 54 23](https://user-images.githubusercontent.com/115553362/199012534-9d6475d4-73ed-4459-928e-684aba83a63c.png)

To use Swift Package Manager, in Xcode add the https://github.com/teamforage/forage-ios-sdk dependency and choose the `Dependency Rule` as Branch and the branch enter `main`.

![Screen Shot 2022-10-31 at 09 56 50](https://user-images.githubusercontent.com/115553362/199013574-59c1968a-f879-4404-99df-9db4c0c93f78.png)

Click on `Add Package` button. And, on the next screen, select the package `ForageSDK`, and finish by clicking on `Add Package`.

![Screen Shot 2022-10-31 at 10 00 57](https://user-images.githubusercontent.com/115553362/199013832-ad86b074-63e3-469b-ad8c-75d65169433b.png)

## Usage

### Import SDK into your file
```swift
import ForageSDK
```

### Create ForageSDK instance

To initialize a ForageSDK instance, you need to provide the environment.

```swift
ForageSDK.setup(
    ForageSDK.Config(environment: .sandbox)            
)
```

## Forage UI Elements

ForageSDK provides two UI Elements to securely communicate with the Forage API.

### ForagePANTextField

A component that securely accepts the PAN number. This field validates the PAN number based on the [StateIIN list](https://www.nacha.org/sites/default/files/2019-05/State-IINs-04-10-19.pdf)

![Screen Shot 2022-10-31 at 10 19 27](https://user-images.githubusercontent.com/115553362/199017253-ee05dcf0-01c8-41dc-9662-9da525e573c9.png)


```swift
private let panNumberTextField: ForagePANTextField = {
    let tf = ForagePANTextField()
    tf.placeholder = "PAN Number"
    return tf
}()
```

ForagePANTextField uses a delegate `ForagePANTextFieldDelegate` to communicate the updates to the client side.

```swift
panNumberTextField.delegate = self
```
```swift
public protocol ForagePANTextFieldDelegate: AnyObject {
    func panNumberStatus(_ view: UIView, cardStatus: CardStatus)
}

public enum CardStatus: String {
    case valid
    case invalid
    case identifying
}
```

To send the PAN number, we can use ForageSDK to perform the request.

### Tokenize card number

```swift
// Signature

func tokenizeEBTCard(
    bearerToken: String,
    merchantAccount: String,
    completion: @escaping (Result<PaymentMethodModel, Error>) -> Void,
    userID: String
)
```

```swift
// Usage

ForageSDK.shared.tokenizeEBTCard(
    bearerToken: bearerToken,
    merchantAccount: merchantID,
    // NOTE: The following line is for testing purposes only and should not be used in production.
    // Please replace this line with a real hashed customer ID value.
    userID: UUID.init().uuidString) { result in
        // handle callback here
    }
```

### ForagePINTextField

A component the securely accepts an EBT PIN for balance requests and payment capture. It only accepts 4 digit numbers.

![Screen Shot 2022-10-31 at 10 21 32](https://user-images.githubusercontent.com/115553362/199017609-33b2094c-339c-4117-8124-00b5ce130dac.png)

```swift
private let pinNumberTextField: ForagePINTextField = {
    let tf = ForagePINTextField()
    tf.placeholder = "PIN Field"
    tf.isSecureTextEntry = true
    tf.pinType = .balance
    return tf
}()
```

To identify the type of pin we are handling in the component, you can use the `pinType` property. We have support for these types:
```swift
public enum PinType: String {
    case snap
    case nonSnap
    case balance
}
```

ForagePINTextField uses a delegate `ForagePINTextFieldDelegate` to communicate the updates to the client side.

```swift
pinNumberTextField.delegate = self
```
```swift
public protocol ForagePINTextFieldDelegate: AnyObject {
    func pinStatus(_ view: UIView, isValid: Bool, pinType: PinType)
}
```

To send the PIN number, we can use the ForageSDK to perform the request.

### Balance

```swift
// Signature

func checkBalance(
    bearerToken: String,
    merchantAccount: String,
    paymentMethodReference: String,
    foragePinTextEdit: ForagePINTextField,
    completion: @escaping (Result<BalanceModel, Error>) -> Void
)
```

```swift
// Usage

ForageSDK.shared.checkBalance(
    bearerToken: bearerToken,
    merchantAccount: merchantID,
    paymentMethodReference: paymentMethodReference,
    foragePinTextEdit: pinNumberTextField) { result in
        // handle callback here
    }
```

### Capture payment

```swift
// Signature

func capturePayment(
    bearerToken: String,
    merchantAccount: String,
    paymentReference: String,
    foragePinTextEdit: ForagePINTextField,
    completion: @escaping (Result<PaymentModel, Error>) -> Void
)
```

```swift
// Usage

ForageSDK.shared.capturePayment(
    bearerToken: bearerToken,
    merchantAccount: merchantID,
    paymentReference: paymentReference,
    foragePinTextEdit: pinNumberTextField) { result in
        // handle callback here
    }
```

## Demo Application
Demo application for using our components on iOS is <a href="https://github.com/teamforage/forage-ios-sdk/tree/main/Sample">here</a>.

To get the application running,

1. Clone this repo and open the Sample Project in the Sample folder.
2. Ensure that you have a valid FNS number for the Forage API, which can be found on the dashboard ([sandbox](https://dashboard.sandbox.joinforage.app/login/) | [prod](https://dashboard.joinforage.app/login/)).
3. [Create a bearer token](https://docs.joinforage.app/recipes/generate-a-token) with pinpad_only scope.
4. Run the Sample app project and provide your FNS number and bearer token on the first screen.
  1. These credentials will be passed through to all the SDK calls inside the sample app.

## Dependencies
- iOS 10+
- Swift 5
- 3rd party libraries:
  - [VGS-Collect-iOS](https://github.com/verygoodsecurity/vgs-collect-ios)
