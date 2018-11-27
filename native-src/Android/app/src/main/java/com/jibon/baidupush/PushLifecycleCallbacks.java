package com.jibon.baidupush;


import android.app.Activity;
import android.app.Application;
import android.os.Bundle;
import android.util.Log;

/**
 * Subscribe to the Pause and Resume activity events in order to toggle the PushPlugin's status.
 * When the PushPlugin is not in active state - i.e. at foreground, notifications should be created
 * and published in the Notification Center, otherwise they're passed directly to the application
 * by invoking the onMessageReceived callback.
 */
public class PushLifecycleCallbacks implements Application.ActivityLifecycleCallbacks {

    private static PushLifecycleCallbacks callbacks = new PushLifecycleCallbacks();

    /**
     * Register for the application's events
     * @param app
     */
    public static void registerCallbacks(Application app) {
        if (app == null) {
            Log.d("PushLifecycleCallbacks", "The application is null, it's not passed correctly!");
            throw new RuntimeException("The application is null, it's not passed correctly!");
        }

        // clean up, not to leak and register it N times...
        Log.d("PushLifecycleCallbacks", "Unregistering the activity lifecycle callbacks...");
        app.unregisterActivityLifecycleCallbacks(callbacks);

        Log.d("PushLifecycleCallbacks", "Registering the activity lifecycle callbacks...");
        app.registerActivityLifecycleCallbacks(callbacks);
    }

    public void onActivityPaused(Activity activity) {
        Log.d(PushPlugin.TAG, "onActivityPaused: Application has been stopped.");
    }

    public void onActivityResumed(Activity activity) {
        Log.d(PushPlugin.TAG, "onActivityResumed: Application has been started");
        PushPlugin.isActive = true;
    }

    public void onActivityCreated(Activity activity, Bundle bundle) {
    }

    public void onActivityDestroyed(Activity activity) {
        PushPlugin.isActive = false;
    }

    public void onActivitySaveInstanceState(Activity activity,
                                            Bundle outState) {
    }

    public void onActivityStarted(Activity activity) {
    }

    public void onActivityStopped(Activity activity) {
    }
}