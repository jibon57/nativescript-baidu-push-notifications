import * as app from 'tns-core-modules/application';
import * as utils from "tns-core-modules/utils/utils";

declare var com: any;

(() => {
    let registerLifecycleEvents = () => {
        com.jibon.baidupush.PushLifecycleCallbacks.registerCallbacks(app.android.nativeApp);
    };

    // Hook on the application events
    if (app.android.nativeApp) {
        registerLifecycleEvents();
    } else {
        app.on(app.launchEvent, registerLifecycleEvents);
    }
})();

export function androidRegister(options, successCallback, errorCallback) {

    let icon = 0;

    if (options.icon) {
        let context = utils.ad.getApplicationContext();
        let resources = context.getResources();
        let packageName: string = context.getApplicationInfo().packageName;
        icon = resources.getIdentifier(options.icon.substr(utils.RESOURCE_PREFIX.length), "drawable", packageName);
    }

    com.jibon.baidupush.PushPlugin.register(app.android.context, options.apiKey, icon,
        new com.jibon.baidupush.PushPluginListener(
            {
                success: successCallback,
                error: errorCallback
            })
    );
}

export function androidUnregister(onSuccessCallback, onErrorCallback) {
    com.jibon.baidupush.PushPlugin.unregister(app.android.context, new com.jibon.baidupush.PushPluginListener(
        {
            success: onSuccessCallback,
            error: onErrorCallback
        }
    ));
}

export function onMessageReceived(callback) {
    com.jibon.baidupush.PushPlugin.setOnMessageReceivedCallback(
        new com.jibon.baidupush.PushPluginListener(
            {
                success: callback
            })
    );
}

export function onNotificationArrived(callback) {
    com.jibon.baidupush.PushPlugin.setOnNotificationArrivedCallback(
        new com.jibon.baidupush.PushPluginListener(
            {
                success: callback
            })
    );
}

export function onNotificationClicked(callback) {
    com.jibon.baidupush.PushPlugin.setOnNotificationClickedCallback(
        new com.jibon.baidupush.PushPluginListener(
            {
                success: callback
            })
    );
}


