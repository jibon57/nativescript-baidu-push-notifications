//
//  BaiduPush.h
//  BaiduPush
//
//  Created by Jibon L. Costa on 2018/11/27.
//  Copyright © 2018 Jibon L. Costa. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <Foundation/Foundation.h>
#import <UIKit/UIApplication.h>
#import "BaiduPushManager.h"
#import "BPush.h"

//! Project version number for BaiduPush.
FOUNDATION_EXPORT double BaiduPushVersionNumber;

//! Project version string for BaiduPush.
FOUNDATION_EXPORT const unsigned char BaiduPushVersionString[];



extern BOOL isDevBPushEnvironment;
extern NSString *insBPushAPIKey;

@interface BaiduPush : NSObject <UIApplicationDelegate>
{
    NSDictionary *notificationMessage;
    BOOL    isInline;
}

@property (nonatomic, strong) NSDictionary *notificationMessage;
@property BOOL isInline;
@property (nonatomic, retain) NSDictionary    *launchNotification;
@property (nonatomic, retain) NSDictionary  *launchOptions;


+ (instancetype)sharedInstance;

//-(void)setupBaiduAPIKey:(NSString *)apiKey mode:(BOOL)isDevMode;

-(void)register:(NSMutableDictionary *)options;
-(void)unregister;
-(void)areNotificationsEnabled;
-(void)registerUserNotificationSettings:(NSDictionary*)options;
-(void)setApplicationIconBadgeNumber:(NSMutableDictionary *)options;
-(void)didRegisterForRemoteNotificationsWithDeviceToken:(NSData *)deviceToken;
-(void)didFailToRegisterForRemoteNotificationsWithError:(NSError *)error;
-(void)notificationReceived;
-(void)success:(NSString *)eventName WithMessage:(NSString *)message;
-(void)success:(NSString *)eventName WithDictionary:(NSMutableDictionary *)userInfo;
-(void)fail:(NSString *)eventName WithMessage:(NSString *)message withError:(NSError *)error;

@end
