package com.jibon.baidupush;

import android.content.Context;
import android.util.Log;

import com.baidu.android.pushservice.PushConstants;
import com.baidu.android.pushservice.PushManager;
import com.baidu.android.pushservice.PushMessageReceiver;
import com.baidu.android.pushservice.BasicPushNotificationBuilder;

import java.util.List;

/**
 * Push plugin extends the Baidu Listener Service and has to be registered in the AndroidManifest
 * in order to receive Notification Messages.
 */
public class PushPlugin extends PushMessageReceiver {

    public static boolean isActive = false;
    private static PushPluginListener registerCallbacks;
    private static PushPluginListener unregisterCallbacks;
    private static PushPluginListener onMessageReceivedCallback;
    private static PushPluginListener onNotificationClickedCallback;
    private static PushPluginListener onNotificationArrivedCallback;

    /**
     * Register the application in Baidu
     *
     * @param appContext
     * @param apiKey
     * @param callbacks
     */
    public static void register(Context appContext, String apiKey, int icon, PushPluginListener callbacks) {
        registerCallbacks = callbacks;
        PushManager.startWork(appContext, PushConstants.LOGIN_TYPE_API_KEY, apiKey);

        if(icon > 0){
            BasicPushNotificationBuilder bBuilder = new BasicPushNotificationBuilder();
            bBuilder.setStatusbarIcon(icon);
            PushManager.setDefaultNotificationBuilder(appContext, bBuilder);
        }
    }

    /**
     * Unregister the application from Baidu
     *
     * @param appContext
     * @param callbacks
     */
    public static void unregister(Context appContext, PushPluginListener callbacks) {
        unregisterCallbacks = callbacks;
        PushManager.stopWork(appContext);
    }

    /**
     * Set the on message received callback
     *
     * @param callbacks
     */
    public static void setOnMessageReceivedCallback(PushPluginListener callbacks) {
        onMessageReceivedCallback = callbacks;
    }

    /**
     * onNotificationArrivedCallback
     */
    public static void setOnNotificationArrivedCallback(PushPluginListener callbacks){
        onNotificationArrivedCallback = callbacks;
    }

    /**
     * Set the on message received callback
     *
     * @param callbacks
     */
    public static void setOnNotificationClickedCallback(PushPluginListener callbacks) {
        onNotificationClickedCallback = callbacks;
    }

    public static void onNotificationClickedCallback(String message) {
        if (onNotificationClickedCallback != null) {
            onNotificationClickedCallback.success(message);
        }
    }

    @Override
    public void onBind(Context context, int errorCode, String appid,
                       String userId, String channelId, String requestId) {
        if (registerCallbacks != null) {
            registerCallbacks.success(userId, channelId);
        }
        PushPlugin.isActive = true;
    }

    /**
     * 接收透传消息的函数。
     *
     * @param context             上下文
     * @param message             推送的消息
     * @param customContentString 自定义内容,为空或者json字符串
     */
    @Override
    public void onMessage(Context context, String message, String customContentString) {

        if (onMessageReceivedCallback != null) {
            onMessageReceivedCallback.success(message, customContentString);
        }
        String messageString = "got onMessage=\"" + message
                + "\" customContentString=" + customContentString;
        Log.d(TAG, messageString);
    }

    /**
     * 接收通知到达的函数。
     *
     * @param context             上下文
     * @param title               推送的通知的标题
     * @param description         推送的通知的描述
     * @param customContentString 自定义内容，为空或者json字符串
     */

    @Override
    public void onNotificationArrived(Context context, String title,
                                      String description, String customContentString) {
        String notifyString = "通知到达 onNotificationArrived  title=\"" + title
                + "\" description=\"" + description + "\" customContent="
                + customContentString;
        Log.d(TAG, notifyString);

        if(onNotificationArrivedCallback != null){
            onNotificationArrivedCallback.success(title, description, customContentString);
        }
    }

    /**
     * 接收通知点击的函数。
     *
     * @param context             上下文
     * @param title               推送的通知的标题
     * @param description         推送的通知的描述
     * @param customContentString 自定义内容，为空或者json字符串
     */
    @Override
    public void onNotificationClicked(Context context, String title,
                                      String description, String customContentString) {
        String notifyString = "通知点击 onNotificationClicked title=\"" + title + "\" description=\""
                + description + "\" customContent=" + customContentString;
        Log.d(TAG, notifyString);

        if(onNotificationClickedCallback != null){
            onNotificationClickedCallback.success(title, description, customContentString);
        }
    }

    /**
     * setTags() 的回调函数。
     *
     * @param context     上下文
     * @param errorCode   错误码。0表示某些tag已经设置成功；非0表示所有tag的设置均失败。
     * @param successTags 设置成功的tag
     * @param failTags    设置失败的tag
     * @param requestId   分配给对云推送的请求的id
     */
    @Override
    public void onSetTags(Context context, int errorCode,
                          List<String> successTags, List<String> failTags, String requestId) {
    }

    /**
     * delTags() 的回调函数。
     *
     * @param context     上下文
     * @param errorCode   错误码。0表示某些tag已经删除成功；非0表示所有tag均删除失败。
     * @param successTags 成功删除的tag
     * @param failTags    删除失败的tag
     * @param requestId   分配给对云推送的请求的id
     */
    @Override
    public void onDelTags(Context context, int errorCode,
                          List<String> successTags, List<String> failTags, String requestId) {
    }

    /**
     * listTags() 的回调函数。
     *
     * @param context   上下文
     * @param errorCode 错误码。0表示列举tag成功；非0表示失败。
     * @param tags      当前应用设置的所有tag。
     * @param requestId 分配给对云推送的请求的id
     */
    @Override
    public void onListTags(Context context, int errorCode, List<String> tags, String requestId) {
    }

    /**
     * PushManager.stopWork() 的回调函数。
     *
     * @param context   上下文
     * @param errorCode 错误码。0表示从云推送解绑定成功；非0表示失败。
     * @param requestId 分配给对云推送的请求的id
     */
    @Override
    public void onUnbind(Context context, int errorCode, String requestId) {
        String responseString = errorCode + "-" + requestId;
        if (unregisterCallbacks != null) {
            unregisterCallbacks.success(responseString);
        }
        PushPlugin.isActive = false;
    }
}
