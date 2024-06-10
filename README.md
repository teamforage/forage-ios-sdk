# ForageSDK

The ForageSDK is a Swift library for securely processing EBT payments. The SDK provides UI components known as Forage Elements and associated methods that perform payment operations.

Learn more about the SDK's features in the [Intro to Forage iOS](https://docs.joinforage.app/docs/ios), check out the [iOS Quickstart](https://docs.joinforage.app/docs/ios-quickstart) for a step-by-step integration guide, or keep reading for instructions on how to run the sample app in this repository.

## How to run the sample app

The Forage iOS SDK sample application can be <a href="https://github.com/teamforage/forage-ios-sdk/tree/main/Sample">found here</a>.

To get the application running:

1. Clone this repo and open the `SampleForageSDK.xcodeproj` project in the `Sample/` directory.
2. Ensure that you have a valid Merchant ID for the Forage API, which can be found on the dashboard ([sandbox](https://dashboard.sandbox.joinforage.app/login/) | [prod](https://dashboard.joinforage.app/login/)).
3. [Create an authentication token](https://docs.joinforage.app/docs/authentication#authentication-tokens) with `pinpad_only` scope.
4. [Create a session token](https://docs.joinforage.app/docs/authentication#session-tokens).
5. Run the Sample app and provide your Merchant ID and session token on the first screen.
6. Forage SDKs include built-in EBT card number validation in both sandbox and production. Use the [Test EBT cards](https://docs.joinforage.app/docs/test-ebt-cards) for developing against successful transactions and invalid EBT test card numbers for triggering exceptions.

### Dependencies

- Xcode 14.1 or above
- iOS 13 or above
- Swift 5.5
- 3rd party libraries:
  - [LaunchDarkly](https://github.com/launchdarkly/ios-client-sdk.git)
  - [BasisTheory](https://github.com/Basis-Theory/basistheory-ios)
