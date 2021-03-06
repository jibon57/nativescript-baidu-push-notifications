package com.jibon.baidupush;

import java.util.Map;

/**
 * Defines methods for Success and Error callbacks
 */
public interface PushPluginListener {
    /**
     * Defines a success callback method, which is used to pass success function reference
     * from the nativescript to the Java plugin
     *
     */
    void success(String userId, String channelId); // method overload to mimic optional argument
    void success(String message); // method overload to mimic optional argument
    void success(String userId, String channelId, String CustomString); // get custom string
    void success(Map data);

    /**
     * Defines a error callback method, which is used to pass success function reference
     * from the nativescript to the Java plugin
     *
     * @param data
     */
    void error(String data);
}
