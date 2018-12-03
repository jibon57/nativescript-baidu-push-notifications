import * as app from 'tns-core-modules/application';
const iosApp = app.ios;

declare const BaiduPush, BaiduPushManager, BPush;

export declare interface IosInteractiveNotificationAction {
    identifier: string;
    title: string;
    activationMode?: string;
    destructive?: boolean;
    authenticationRequired?: boolean;
    behavior?: string;
}

export declare interface IosInteractiveNotificationCategory {
    identifier: string;
    actionsForDefaultContext: string[];
    actionsForMinimalContext: string[];
}

export declare interface IosRegistrationOptions {
    badge: boolean;
    sound: boolean;
    alert: boolean;
    clearBadge: boolean;
    interactiveSettings: {
        actions: IosInteractiveNotificationAction[],
        categories: IosInteractiveNotificationCategory[]
    };
    notificationCallbackIOS: (message: any) => void;
}

export declare interface NSError {
    code: number;
    domain: string;
    userInfo: any;
}

let pushHandler;
let pushManager;
let pushSettings;
(() => {
    console.log("Init NativeScript Baidu Push Notifications");
    if (!pushSettings) {
        pushSettings = {};
    }
    if (!pushHandler) {
        pushHandler = BaiduPush.alloc().init();
    }
    if (!pushManager) {
        pushManager = BaiduPushManager.alloc().init();
    }

})();


const _init = (settings: IosRegistrationOptions) => {
    if (!!pushSettings.isInitialized) return;

    // initialize the native push plugin
    pushSettings.settings = settings;
    pushSettings.notificationCallbackIOS = settings.notificationCallbackIOS;

    // subscribe to the notification received event.
    _addObserver("notificationReceived", (context: any) => {
        const userInfo = JSON.parse(context.userInfo.objectForKey('message'));
        pushSettings.notificationCallbackIOS(userInfo);
    });

    pushSettings.isInitialized = true;
};

const _mapCategories = (interactiveSettings: any) => {
    let categories = [];

    for (let i = 0; i < interactiveSettings.categories.length; i++) {
        const currentCategory = interactiveSettings.categories[i];
        let mappedCategory = {
            identifier: currentCategory.identifier,
            actionsForDefaultContext: [],
            actionsForMinimalContext: []
        };

        for (let j = 0; j < interactiveSettings.actions.length; j++) {
            const currentAction = interactiveSettings.actions[j];

            if (currentCategory.actionsForMinimalContext.indexOf(currentAction.identifier) > -1) {
                mappedCategory.actionsForMinimalContext.push(currentAction);
            }

            if (currentCategory.actionsForDefaultContext.indexOf(currentAction.identifier) > -1) {
                mappedCategory.actionsForDefaultContext.push(currentAction);
            }
        }
        categories.push(mappedCategory);

    }
    return categories;
};

let _addObserver = (eventName: string, callback: (context: any) => void) => {
    return iosApp.addNotificationObserver(eventName, callback);
};

let _removeObserver = function (observer: () => void, eventName: string) {
    iosApp.removeNotificationObserver(observer, eventName);
};

export function iosRegister(settings: IosRegistrationOptions, success: (token: any) => void, error: (NSError: any) => void) {

    _init(settings);

    if (!pushSettings.didRegisterObserver) { // make sure that the events are not attached more than once
        pushSettings.didRegisterObserver = _addObserver("didRegisterForRemoteNotificationsWithDeviceToken", (result: any) => {
            _removeObserver(pushSettings.didRegisterObserver, "didRegisterForRemoteNotificationsWithDeviceToken");
            pushSettings.didRegisterObserver = undefined;

            let baiduInfo = result.userInfo;

            let baiduObj = {
                channel_id: baiduInfo.valueForKey('channel_id'),
                user_id: baiduInfo.valueForKey('user_id'),
                request_id: baiduInfo.valueForKey('request_id'),
                app_id: baiduInfo.valueForKey('app_id'),
            };
            success(baiduObj);
        });
    }

    if (!pushSettings.didFailToRegisterObserver) {
        pushSettings.didFailToRegisterObserver = _addObserver("didFailToRegisterForRemoteNotificationsWithError", (e: NSError) => {
            _removeObserver(pushSettings.didFailToRegisterObserver, "didFailToRegisterForRemoteNotificationsWithError");
            pushSettings.didFailToRegisterObserver = undefined;
            error(e);
        });
    }

    pushHandler.register(pushSettings.settings);
}

export function registerUserNotificationSettings(success: () => void, error: (error: NSError) => void) {
    if (pushSettings.settings && pushSettings.settings.interactiveSettings) {
        const interactiveSettings = pushSettings.settings.interactiveSettings;
        let notificationTypes = [];
        if (pushSettings.settings.alert) {
            notificationTypes.push("alert");
        }
        if (pushSettings.settings.badge) {
            notificationTypes.push("badge");
        }
        if (pushSettings.settings.sound) {
            notificationTypes.push("sound");
        }

        if (!pushSettings.registerUserSettingsObserver) {
            pushSettings.registerUserSettingsObserver = _addObserver("didRegisterUserNotificationSettings", () => {
                _removeObserver(pushSettings.registerUserSettingsObserver, "didRegisterUserNotificationSettings");

                pushSettings.registerUserSettingsObserver = undefined;
                success();
            });
        }

        if (!pushSettings.failToRegisterUserSettingsObserver) {
            pushSettings.failToRegisterUserSettingsObserver = _addObserver("failToRegisterUserNotificationSettings", (e: NSError) => {
                _removeObserver(pushSettings.didFailToRegisterObserver, "failToRegisterUserNotificationSettings");

                pushSettings.failToRegisterUserSettingsObserver = undefined;
                error(e);
            });
        }

        pushHandler.registerUserNotificationSettings({
            types: notificationTypes,
            categories: _mapCategories(interactiveSettings)
        });
    } else {
        success();
    }
}

export function iosUnregister(success: (result: any) => void, error: (error: NSError) => void) {

    if (!pushSettings.didUnregisterObserver) {
        pushSettings.didUnregisterObserver = _addObserver("didUnregister", (context: any) => {
            _removeObserver(pushSettings.didUnregisterObserver, "didUnregister");

            pushSettings.didUnregisterObserver = undefined;

            BPush.unbindChannelWithCompleteHandler(function (result, error) {
                if (result) {
                    success(result.valueForKey('request_id'));
                } else {
                    error(error);
                }
            });
        });
    }

    pushHandler.unregister();
}

export function areNotificationsEnabled(done: (areEnabled: Boolean) => void) {
    if (!pushSettings.areNotificationsEnabledObserver) {
        pushSettings.areNotificationsEnabledObserver = _addObserver("areNotificationsEnabled", function (result) {
            const areEnabledStr = result.userInfo.objectForKey('message');
            const areEnabled = areEnabledStr === "true";

            _removeObserver(pushSettings.areNotificationsEnabledObserver, "areNotificationsEnabled");
            pushSettings.areNotificationsEnabledObserver = undefined;
            done(areEnabled);
        });
    }

    pushHandler.areNotificationsEnabled();
}