package com.jibon.baidupush;

import android.app.Activity;
import android.app.NotificationManager;
import android.content.Context;
import android.content.Intent;
import android.content.pm.PackageManager;
import android.os.Bundle;
import android.text.TextUtils;

/**
 * Activity which is an entry point, whenever a notification from the bar is tapped and executed.
 * The activity fires, notifies the callback.
 */
public class PushHandlerActivity extends Activity {

    /*
     * this activity will be started if the user touches a notification that we own.
     * We send it's data off to the push plugin for processing.
     * If needed, we boot up the main activity to kickstart the application.
     * @see android.app.Activity#onCreate(android.os.Bundle)
     */
    @Override
    public void onCreate(Bundle savedInstanceState) {
        super.onCreate(savedInstanceState);

        Bundle extras = getIntent().getExtras();
        processPushBundle(extras);

        // remove this activity from the top of the stack
        finish();

        if (!PushPlugin.isActive) {
            forceMainActivityReload();
        }
    }

    /**
     * Takes the pushBundle extras from the intent,
     * and sends it through to the PushPlugin for processing.
     */
    public static void processPushBundle(Bundle extras) {

        if (extras != null) {
            String message = extras.getString("pushData", "");

            if (!TextUtils.isEmpty(message)) {
                PushPlugin.onNotificationClickedCallback(message);
            }
        }
    }

    /**
     * Forces the main activity to re-launch if it's unloaded.
     */
    private void forceMainActivityReload() {
        PackageManager pm = getPackageManager();
        Intent launchIntent = pm.getLaunchIntentForPackage(getApplicationContext().getPackageName());
        launchIntent.addFlags(Intent.FLAG_ACTIVITY_SINGLE_TOP);
//        launchIntent.setPackage(null);
        startActivity(launchIntent);
    }

    @Override
    protected void onResume() {
        super.onResume();
        final NotificationManager notificationManager = (NotificationManager) this.getSystemService(Context.NOTIFICATION_SERVICE);
        notificationManager.cancelAll();
    }

}