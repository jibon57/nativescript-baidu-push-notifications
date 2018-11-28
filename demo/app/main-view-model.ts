import { Observable } from 'tns-core-modules/data/observable';
import * as app from "tns-core-modules/application";
import { IosRegistrationOptions, AndroidOptions } from "nativescript-baidu-push-notifications";
import * as pushPlugin from "nativescript-baidu-push-notifications";

export class HelloWorldModel extends Observable {

    constructor() {
        super();

        if (app.ios) {
            this.registerForiOS();
        } else {
            this.registerForAndroid();
        }
    }

    /**
     * registerForAndroid
     */
    public registerForAndroid() {

        let opt: AndroidOptions = {
            apiKey: 'My API Key',
            icon: "res://simple_notification_icon"
        }

        pushPlugin.androidRegister(opt, function (Userid, channelId) {
            console.log("Got register");
            console.log("Userid: " + Userid)
            console.log("channelId: " + channelId)
        }, function (err) {
            console.log("not register");
            console.dir(err)
        })
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
        })
        pushPlugin.onNotificationArrived(function (title, msg, customString) {
            console.log("onNotificationArrived")
            console.log(title);
            console.log(msg);
            console.log(customString)
        })
    }

    /**
     * registerForiOS
     */
    public registerForiOS() {
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
            function (token) {
                console.log("IOS PUSH NOTIF TOKEN DEVICE: " + token);

                //Register the interactive settings
                if (notificationSettings.interactiveSettings) {
                    pushPlugin.registerUserNotificationSettings(function () {

                        console.log("SUCCESSFULLY REGISTER PUSH NOTIFICATION: " + token);

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

        pushPlugin.registerBaiduNotificationSettingCallback(function (result) {
            console.log("REGISTER BAIDU PUSH NOTIFICATION SUCCESS:");
            let baiduInfo = result.copy();

            let baiduChannelId = baiduInfo.valueForKey('channel_id');
            let baiduUserId = baiduInfo.valueForKey('user_id');
            console.log("resultBaidu:" + baiduInfo);
            console.log("BAIDU Chanel Id:" + baiduChannelId);
            console.log("BAIDU User Id:" + baiduUserId);

        }, function (error: any) {
            console.log("REGISTER BAIDU PUSH NOTIFICATION FAILED:");
            console.dir(error);
        });
    }
}
