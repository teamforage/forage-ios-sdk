# ForageSDK

A description of this package.

Table of contents
=================

<!--ts-->
   * [Integration](#integration)
      * [Swift Package Manager](#swift-package-manager) 
   * [Usage](#usage)
      * [Create ForageSDK instance](#create-foragesdk-instance)
      * [Forage UI Elements](#forage-ui-elements)
      * [ForagePANTextFieldView](#foragepantextfieldview)
      * [ForagePINTextFieldView](#foragepintextfieldview)
      * [Demo Application](#demo-application)
   * [Dependencies](#dependencies)
<!--te-->

## Integration

### Swift Package Manager

The [Swift Package Manager](https://www.swift.org/package-manager/) is a tool for managing the distribution of Swift code. It’s integrated with the Swift build system to automate the process of downloading, compiling, and linking dependencies.

We recommend to use Xcode with at least Swift tools version of 5.3. Earlier Xcode versions don't support Swift packages with resources.
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

Click on `Add Package` button. And, on the next screen, select the package `ForageSDK`, and finishes clicking on `Add Package`.

![Screen Shot 2022-10-31 at 10 00 57](https://user-images.githubusercontent.com/115553362/199013832-ad86b074-63e3-469b-ad8c-75d65169433b.png)

## Usage

### Import SDK into your file
```swift
import ForageSDK
```
### Create ForageSDK instance

Initializing a ForageSDK instance, you need to setup ForageSDK providing the merchantID and a valid bearerToken.

```swift
ForageSDK.setup(
  ForageSDK.Config(
    merchantID: merchantID,
    bearerToken: bearerToken
  )
)
```

## Forage UI Elements

ForageSDK provides two UI Elements to work as proxy between your application and Forage service using compliance comunication.

### ForagePANTextFieldView

It is a component to handle PAN number. This field valids the pan number based on the [StateIIN lists](https://www.nacha.org/sites/default/files/2019-05/State-IINs-04-10-19.pdf)

![Screen Shot 2022-10-31 at 10 19 27](https://user-images.githubusercontent.com/115553362/199017253-ee05dcf0-01c8-41dc-9662-9da525e573c9.png)


```swift
private let panNumberTextField: ForagePANTextFieldView = {
    let tf = ForagePANTextFieldView()
    tf.placeholder = "PAN Number"
    tf.translatesAutoresizingMaskIntoConstraints = false
    return tf
}()
```

ForagePANTextFieldView uses a delegate `ForagePANTextFieldDelegate` to communicate the updates to the client side.

```swift
panNumberTextField.delegate = self
```
```swift
public protocol ForagePANTextFieldDelegate: AnyObject {
    func panNumberStatus(_ view: UIView, cardStatus: CardStatus)
}
```

To send the PAN number, we can use the component to perform the request.
```swift
panNumberTextField.sendPanCardNumber()
```

### ForagePINTextFieldView

It is a component to handle PIN number for balance and payment capture. It accepts only number entry and check for 4 digits to be valid.

![Screen Shot 2022-10-31 at 10 21 32](https://user-images.githubusercontent.com/115553362/199017609-33b2094c-339c-4117-8124-00b5ce130dac.png)

```swift
private let pinNumberTextField: ForagePINTextFieldView = {
    let tf = ForagePINTextFieldView()
    tf.placeholder = "PIN Field"
    tf.isSecureTextEntry = true
    tf.translatesAutoresizingMaskIntoConstraints = false
    return tf
}()
```

ForagePINTextFieldView uses a delegate `ForagePINTextFieldDelegate` to communicate the updates to the client side.

```swift
pinNumberTextField.delegate = self
```
```swift
public protocol ForagePINTextFieldDelegate: AnyObject {
    func pinStatus(_ view: UIView, isValid: Bool)
    func balanceCallback(_ view: UIView, result: (Result<ForageBalanceModel, Error>))
    func capturePaymentCallback(_ view: UIView, result: (Result<ForageCaptureModel, Error>))
}

public extension ForagePINTextFieldDelegate {
    func pinStatus(_ view: UIView, isValid: Bool) { }
    func balanceCallback(_ view: UIView, result: (Result<ForageBalanceModel, Error>)) { }
    func capturePaymentCallback(_ view: UIView, result: (Result<ForageCaptureModel, Error>)) { }
}
```

To send the PIN number, we can use the component to perform the request. For ForagePINTextFieldView, we need to specify which type of request we are doing, a balance or capture request.
```swift
/// Balance payment
pinNumberTextField.performRequest(
    forPIN:
            .balance(
                paymentMethodReference: paymentMethodReference,
                cardNumberToken: cardNumberToken
            )
)
```

```swift
/// Capture payment
pinNumberTextField.performRequest(
    forPIN:
            .ebtCapture(
                paymentReference: paymentReference,
                cardNumberToken: cardNumberToken
            )
)
```

## Demo Application
Demo application for using our components on iOS is <a href="https://github.com/teamforage/forage-ios-sdk/tree/main/Sample">here</a>.

You just need to clone this repo and open the Sample Project on Sample folder.

## Dependencies
- iOS 10+
- Swift 5
- 3rd party libraries:
  - [VGS-Collect-iOS](https://github.com/verygoodsecurity/vgs-collect-ios)
  - [CardIO](https://github.com/card-io/card.io-iOS-SDK)
