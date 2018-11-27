var BaiduPushNotifications = require("nativescript-baidu-push-notifications").BaiduPushNotifications;
var baiduPushNotifications = new BaiduPushNotifications();

describe("greet function", function() {
    it("exists", function() {
        expect(baiduPushNotifications.greet).toBeDefined();
    });

    it("returns a string", function() {
        expect(baiduPushNotifications.greet()).toEqual("Hello, NS");
    });
});