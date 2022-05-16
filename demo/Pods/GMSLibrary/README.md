# GMSLibrary

This is a library to interact with the Genesys Mobile Service (GMS) callback and chat API. 

## Requirements

GMSLibrary depends on the following libraries: 

 * [Alamofire](https://github.com/Alamofire/Alamofire)
 * [Google Promises](https://github.com/google/promises)
 * [GFayeSwift](https://github.com/ckpwong/GFayeSwift)

In addition, the following libraries must be included in the target project for 
[Firebase Cloud Messaging](https://firebase.google.com/) 
(FCM) support.  These libraries are not directly referenced in GMSLibrary.

 * [Firebase/Core](https://github.com/firebase/firebase-ios-sdk)
 * [Firebase/Messaging](https://github.com/firebase/firebase-ios-sdk)
 
## Example App

To run the example project, clone the repo, and run `pod install` from the Example directory first.  This app demonstrates all of the capabilities of GMSLibrary except for file upload/download in chat.


## Installation

GMSLibrary is available through [CocoaPods](https://cocoapods.org). To install
it, simply add the following line to your Podfile:

```ruby
pod 'GMSLibrary'
```

## Firebase Cloud Messaging (FCM) Support in Example App

Follow the latest instructions from [Google Firebase](https://firebase.google.com/) on how to install the Firebase libraries and
incorporate Firebase in your iOS project.

The following instructions are current as of writing.

First, add the following lines to your Podfile:

```ruby
pod 'Firebase/Core'
pod 'Firebase/Messaging'
```

Download the `GoogleService-Info.plist` of your Firebase project and copy it to `Example/GoogleService-Info.plist`.

Configure GMS push notification settings according to the 
[GMS documentation](https://docs.genesys.com/Documentation/GMS/8.5.1/API/PushNotificationService#fcm).  The value for
`fcm.apiKey` should be the "Server key" under "Project Settings" -> "Cloud Messagings".

## Disclaimer

THIS CODE IS PROVIDED BY GENESYS TELECOMMUNICATIONS LABORATORIES, INC. ("GENESYS") "AS IS" WITHOUT ANY WARRANTY OF ANY KIND. GENESYS HEREBY DISCLAIMS ALL EXPRESS, IMPLIED, OR STATUTORY CONDITIONS, REPRESENTATIONS AND WARRANTIES WITH RESPECT TO THIS CODE (OR ANY PART THEREOF), INCLUDING, BUT NOT LIMITED TO, IMPLIED WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE OR NON-INFRINGEMENT. GENESYS AND ITS SUPPLIERS SHALL NOT BE LIABLE FOR ANY DAMAGE SUFFERED AS A RESULT OF USING THIS CODE. IN NO EVENT SHALL GENESYS AND ITS SUPPLIERS BE LIABLE FOR ANY DIRECT, INDIRECT, CONSEQUENTIAL, ECONOMIC, INCIDENTAL, OR SPECIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, ANY LOST REVENUES OR PROFITS).

## License

GMSLibrary is available under the MIT license. See the LICENSE file for more info.
