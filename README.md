[![npm](https://img.shields.io/npm/v/nativescript-baidu-push-notifications.svg)](https://www.npmjs.com/package/nativescript-baidu-push-notifications)
[![npm](https://img.shields.io/npm/dt/nativescript-baidu-push-notifications.svg?label=npm%20downloads)](https://www.npmjs.com/package/nativescript-baidu-push-notifications)


# Baidu push notifications plugin for NativeScript

Baidu is an alternative solution of Google FCM in China. This plugin will add Baidu push notification (http://push.baidu.com).

## Prerequisites / Requirements

For getting API key follow: http://push.baidu.com/doc/guide/join

For iOS need to follow `第七章 iOS证书指导` from http://push.baidu.com/doc/ios/api to setup Baidu.

**Note:** I am not an expert of neigher iOS nor Android. So, please contribute if you think something you can do better :)


## Installation

```javascript
tns plugin add nativescript-baidu-push-notifications
```

## Usage 

Your application ID is important here. Make sure that your Baidu API key & Application ID is correct.

**Import**

TS/Angular:

```javascript
import { IosRegistrationOptions, AndroidOptions } from "nativescript-baidu-push-notifications";
import * as pushPlugin from "nativescript-baidu-push-notifications";
```

JavaScript:

```javascript
pushPlugin = require("nativescript-baidu-push-notifications");
```

**Android**

If you want to test in emulator then use Genymotion otherwise Baidu will send error message. Better to test with a real device.

```javascript
let opt: AndroidOptions = {
    apiKey: 'My API Key',
    icon: "res://simple_notification_icon" // optional App_Resouces/Android/drawable
}

pushPlugin.androidRegister(opt, function (data) {

    console.log("Got register");
    console.log("userId: " + data.get("userId"));
    console.log("channelId: " + data.get("channelId"));
    console.log("appid: " + data.get("appid"));
    console.log("requestId: " + data.get("requestId"));
    console.log("errorCode: " + data.get("errorCode"));

}, function (err) {
    console.log("not register");
    console.dir(err)
});

pushPlugin.onMessageReceived(function (msg, customString) {
    console.log("got message")
    console.log(msg);
    console.log(customString);
});

pushPlugin.onNotificationClicked(function (title, msg, customString) {
    console.log("clicked message")
    console.log(title);
    console.log(msg);
    console.log(customString)
});

pushPlugin.onNotificationArrived(function (title, msg, customString) {
    console.log("onNotificationArrived")
    console.log(title);
    console.log(msg);
    console.log(customString)
});
```

**iOS**

iOS will require a real device. In simulator baidu will send error message.

First of all need to add this config in `App_Resource/iOS/Info.plist` file:

Development Environment:

```javascript
<key>insBPushAPIKey</key>
<string>Your-Baidu-Key</string>
<key>isDevBPushEnvironment</key>
<true/>
```

Production Environment:

```javascript
<key>insBPushAPIKey</key>
<string>Your-Baidu-Key</string>
<key>isDevBPushEnvironment</key>
<false/>
```

JS code:

```javascript
// check details https://github.com/NativeScript/push-plugin#using-the-plugin-in-ios

let notificationSettings: IosRegistrationOptions = {
    badge: true,
    sound: true,
    alert: true,
    clearBadge: true,
    interactiveSettings: {
        actions: [{
            identifier: 'READ_IDENTIFIER',
            title: 'Read',
            activationMode: "foreground",
            destructive: false,
            authenticationRequired: true
        }, {
            identifier: 'CANCEL_IDENTIFIER',
            title: 'Cancel',
            activationMode: "foreground",
            destructive: true,
            authenticationRequired: true
        }],
        categories: [{
            identifier: 'READ_CATEGORY',
            actionsForDefaultContext: ['READ_IDENTIFIER', 'CANCEL_IDENTIFIER'],
            actionsForMinimalContext: ['READ_IDENTIFIER', 'CANCEL_IDENTIFIER']
        }]
    },

    notificationCallbackIOS: function (message) {
        console.log("notificationCallbackIOS : " + JSON.stringify(message));
        alert(message.alert)
    }
};

pushPlugin.iosRegister(notificationSettings,
    //success callback
    function (result: any) {
        //Register the interactive settings
        if (notificationSettings.interactiveSettings) {

            pushPlugin.registerUserNotificationSettings(function () {
                console.log("SUCCESSFULLY REGISTER BAIDU PUSH NOTIFICATION")
                console.dir(result);

            }, function (err) {
                console.log("ERROR REGISTER PUSH NOTIFICATION: " + JSON.stringify(err));
            })
        }
    },
    //error callback
    function (error) {
        console.log("REGISTER PUSH NOTIFICATION FAILED:");
        console.dir(error);
    }
);

pushPlugin.areNotificationsEnabled(function (areEnabled) {
    console.log("Are Notifications enabled:" + JSON.stringify(areEnabled));
});
```
Please check demo project for more details.


## All Methods/Options

```javascript
export interface IosInteractiveNotificationAction {
    identifier: string;
    title: string;
    activationMode?: string;
    destructive?: boolean;
    authenticationRequired?: boolean;
    behavior?: string;
}
export interface IosInteractiveNotificationCategory {
    identifier: string;
    actionsForDefaultContext: string[];
    actionsForMinimalContext: string[];
}
export interface IosRegistrationOptions {
    badge: boolean;
    sound: boolean;
    alert: boolean;
    clearBadge: boolean;
    interactiveSettings: {
        actions: IosInteractiveNotificationAction[];
        categories: IosInteractiveNotificationCategory[];
    };
    notificationCallbackIOS: (message: any) => void;
}
export interface NSError {
    code: number;
    domain: string;
    userInfo: any;
}

export interface AndroidOptions {
    apiKey: string;
    icon?: string;
}

// Android
export declare function androidRegister(options: AndroidOptions, successCallback: any, errorCallback: any): void;
export declare function androidUnregister(onSuccessCallback: any, onErrorCallback: any): void;
export declare function onMessageReceived(callback: any): void;
export declare function onNotificationArrived(callback: any): void;
export declare function onNotificationClicked(callback: any): void;

// iOS
export declare function iosRegister(settings: IosRegistrationOptions, success: (token: any) => void, error: (NSError: any) => void): void;
export declare function registerUserNotificationSettings(success: () => void, error: (error: NSError) => void): void;
export declare function iosUnregister(success: (result: any) => void, error: (error: NSError) => void): void;
export declare function areNotificationsEnabled(done: (areEnabled: Boolean) => void): void;
```

**Tips:**

* For Android push notification icon you will need to add icon sets in `App_Resources/Android/src/main/res`. Better to use 36X36 dimension for icon. Check the demo.
* For message notification can use `nativescript-local-notifications` plugin.

## Credit

Most of the work of this plugin has been followed/copied from this libaries:

https://github.com/NativeScript/push-plugin

https://www.npmjs.com/package/nativescript-baidu-push-ins

https://www.npmjs.com/package/nativescript-baidu-push

Special thanks to `Phuc Bui` and `Quang Le Hong` author of above 2 npm packages.


## License

Apache License Version 2.0, January 2004
