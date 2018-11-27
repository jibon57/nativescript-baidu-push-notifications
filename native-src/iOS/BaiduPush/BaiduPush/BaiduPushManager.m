#import "BaiduPushManager.h"
#import <UIKit/UIApplication.h>
#import <objc/runtime.h>
#import "BaiduPush.h"
#import "BPush.h"


@implementation BaiduPushManager
/*__attribute__((constructor))
void myFunction() {
    @autoreleasepool {
        NSLog(@"stuff happened early");
    }
}*/

static IMP didRegisterOriginalMethod = NULL;
static IMP didFailOriginalMethod = NULL;
static IMP didReceiveOriginalMethod = NULL;
static IMP didBecomeActiveOriginalMethod = NULL;
static IMP handleActionWithIdentifierOriginalMethod = NULL;

+ (void)load {
    [[NSNotificationCenter defaultCenter] addObserverForName:UIApplicationDidFinishLaunchingNotification object:nil queue:[NSOperationQueue mainQueue] usingBlock:^(NSNotification *note) {
        
        NSString *path = [[NSBundle mainBundle] pathForResource: @"Info" ofType: @"plist"];
        NSDictionary *dict = [NSDictionary dictionaryWithContentsOfFile: path];
        insBPushAPIKey = [dict objectForKey: @"insBPushAPIKey"];
        isDevBPushEnvironment = [[dict objectForKey: @"isDevBPushEnvironment"] boolValue];
        NSLog(@"load INSBPushAPIKey : %@", insBPushAPIKey);
        
        UIApplication *app = [UIApplication sharedApplication];
        id<UIApplicationDelegate> appDelegate = app.delegate;
        
        // didBecomeActive swizzle
        /*
        Method didBecomeActiveMethod = class_getInstanceMethod([PushManager class], @selector(my_applicationDidBecomeActive:));
        IMP didBecomeActiveImp = method_getImplementation(didBecomeActiveMethod);
        const char* didBecomeActiveTypes = method_getTypeEncoding(didBecomeActiveMethod);
        
        Method didBecomeActiveOriginal = class_getInstanceMethod(appDelegate.class, @selector(applicationDidBecomeActive:));
        if (didBecomeActiveOriginal) {
            didBecomeActiveOriginalMethod = method_getImplementation(didBecomeActiveOriginal);
            method_exchangeImplementations(didBecomeActiveOriginal, didBecomeActiveMethod);
        } else {
            class_addMethod(appDelegate.class, @selector(applicationDidBecomeActive:), didBecomeActiveImp, didBecomeActiveTypes);
        }
        */
        
        // didRegisterForRemoteNotificationsWithDeviceToken swizzle
        Method didRegisterMethod = class_getInstanceMethod([BaiduPushManager class], @selector(my_application:didRegisterForRemoteNotificationsWithDeviceToken:));
        IMP didRegisterMethodImp = method_getImplementation(didRegisterMethod);
        const char* didRegisterTypes = method_getTypeEncoding(didRegisterMethod);
        
        Method didRegisterOriginal = class_getInstanceMethod(appDelegate.class, @selector(application:didRegisterForRemoteNotificationsWithDeviceToken:));
        if (didRegisterOriginal) {
            didRegisterOriginalMethod = method_getImplementation(didRegisterOriginal);
            method_exchangeImplementations(didRegisterOriginal, didRegisterMethod);
        } else {
            class_addMethod(appDelegate.class, @selector(application:didRegisterForRemoteNotificationsWithDeviceToken:), didRegisterMethodImp, didRegisterTypes);
        }
        
        // didFailToRegisterForRemoteNotificationsWithError swizzle
        Method didFailMethod = class_getInstanceMethod([BaiduPushManager class], @selector(my_application:didFailToRegisterForRemoteNotificationsWithError:));
        IMP didFailMethodImp = method_getImplementation(didFailMethod);
        const char* didFailTypes = method_getTypeEncoding(didFailMethod);
        
        Method didFailOriginal = class_getInstanceMethod(appDelegate.class, @selector(application:didFailToRegisterForRemoteNotificationsWithError:));
        if (didFailOriginal) {
            didFailOriginalMethod = method_getImplementation(didFailOriginal);
            method_exchangeImplementations(didFailOriginal, didFailMethod);
        } else {
            class_addMethod(appDelegate.class, @selector(application:didFailToRegisterForRemoteNotificationsWithError:), didFailMethodImp, didFailTypes);
        }
        
        // didReceiveRemoteNotification swizzle
        Method didReceiveMethod = class_getInstanceMethod([BaiduPushManager class], @selector(my_application:didReceiveRemoteNotification:));
        IMP didReceiveMethodImp = method_getImplementation(didReceiveMethod);
        const char* didReceiveTypes = method_getTypeEncoding(didReceiveMethod);
        
        Method didReceiveOriginal = class_getInstanceMethod(appDelegate.class, @selector(application:didReceiveRemoteNotification:));
        if (didReceiveOriginal) {
            didReceiveOriginalMethod = method_getImplementation(didReceiveOriginal);
            method_exchangeImplementations(didReceiveOriginal, didReceiveMethod);
        } else {
            class_addMethod(appDelegate.class, @selector(application:didReceiveRemoteNotification:), didReceiveMethodImp, didReceiveTypes);
        }
        
        #if __IPHONE_OS_VERSION_MAX_ALLOWED >= 80000
        // handleActionWithIdentifier swizzle
        Method handleActionWithIdentifierMethod = class_getInstanceMethod([BaiduPushManager class], @selector(my_application:handleActionWithIdentifier:forRemoteNotification:completionHandler:));
        IMP handleActionWithIdentifierMethodImp = method_getImplementation(handleActionWithIdentifierMethod);
        const char* handleActionWithIdentifierTypes = method_getTypeEncoding(handleActionWithIdentifierMethod);
        
        Method handleActionWithIdentifierOriginal = class_getInstanceMethod(appDelegate.class, @selector(application:handleActionWithIdentifier:forRemoteNotification:completionHandler:));
        if (handleActionWithIdentifierOriginal) {
            handleActionWithIdentifierOriginalMethod = method_getImplementation(handleActionWithIdentifierOriginal);
            method_exchangeImplementations(handleActionWithIdentifierOriginal, handleActionWithIdentifierMethod);
        } else {
            class_addMethod(appDelegate.class, @selector(application:handleActionWithIdentifier:forRemoteNotification:completionHandler:), handleActionWithIdentifierMethodImp, handleActionWithIdentifierTypes);
        }
        #endif
        
        NSLog(@"load PushMananger %@", [note userInfo]);
        
        NSDictionary *launchOptions = [note userInfo];
        NSLog(@"load PushMananger didFinishLaunchingWithOptions: %@",launchOptions);
        
        BPushMode baiduMode = (isDevBPushEnvironment == true) ? BPushModeDevelopment : BPushModeProduction;
        [BPush registerChannel:launchOptions apiKey:insBPushAPIKey pushMode:baiduMode withFirstAction:nil withSecondAction:nil withCategory:nil useBehaviorTextInput:YES isDebug:YES];
        
        [BPush disableLbs];

        NSDictionary *userInfo = [launchOptions objectForKey:UIApplicationLaunchOptionsRemoteNotificationKey];
        if (userInfo) {
            [BPush handleNotification:userInfo];
        }
    }];
    
}

-(id)init
{
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(createNotificationChecker:)
                                                 name:@"UIApplicationDidFinishLaunchingNotification" object:nil];
    
    [[NSNotificationCenter defaultCenter]addObserver:self
                                           selector:@selector(my_applicationDidBecomeActive:)
                                             name:@"UIApplicationDidBecomeActiveNotification" object:nil];
     
    return self;
}

- (void)createNotificationChecker:(NSNotification *)notification
{
    if (notification)
    {
        NSDictionary *launchOptions = [notification userInfo];
        if (launchOptions)
            [BaiduPush sharedInstance].launchNotification = [launchOptions objectForKey: @"UIApplicationLaunchOptionsRemoteNotificationKey"];
    }
}

- (void)my_applicationDidBecomeActive:(UIApplication *)application
{
    [UIApplication sharedApplication].applicationIconBadgeNumber = 0;
    if ([BaiduPush sharedInstance].launchNotification) {
        [BaiduPush sharedInstance].notificationMessage  = [BaiduPush sharedInstance].launchNotification;
        [BaiduPush sharedInstance].launchNotification = nil;
        [[BaiduPush sharedInstance] performSelectorOnMainThread:@selector(notificationReceived) withObject:[BaiduPush sharedInstance]  waitUntilDone:NO];
    }
}

- (void)my_application:(UIApplication *)application didRegisterForRemoteNotificationsWithDeviceToken:(NSData *)deviceToken {
   if (didRegisterOriginalMethod) {
        void (*originalImp)(id, SEL, UIApplication *, NSData *) = didRegisterOriginalMethod;
        originalImp(self, @selector(application:didRegisterForRemoteNotificationsWithDeviceToken:), application, deviceToken);
    }
    NSLog(@"%@", deviceToken);
    [[BaiduPush sharedInstance] didRegisterForRemoteNotificationsWithDeviceToken:deviceToken];
}

- (void)my_application:(UIApplication *)application didReceiveRemoteNotification:(NSDictionary *)userInfo {
    if (didReceiveOriginalMethod) {
        void (*originalImp)(id, SEL, UIApplication *, NSDictionary *) = didReceiveOriginalMethod;
        originalImp(self, @selector(application:didReceiveRemoteNotification:), application, userInfo);
    }
    NSLog(@"didReceiveNotification");
    
    UIApplicationState appState = UIApplicationStateActive;
    if ([application respondsToSelector:@selector(applicationState)]) {
        appState = application.applicationState;
    }
    
    if (appState == UIApplicationStateActive || appState == UIApplicationStateBackground) {
        [BaiduPush sharedInstance].notificationMessage = userInfo;
        [BaiduPush sharedInstance].isInline = appState == UIApplicationStateActive; 
        [[BaiduPush sharedInstance] notificationReceived]; 
    } else {
        [BaiduPush sharedInstance].launchNotification = userInfo;
    } 
}

- (void)my_application:(UIApplication *)application didFailToRegisterForRemoteNotificationsWithError:(NSError *)error {
    if (didFailOriginalMethod) {
        void (*originalImp)(id, SEL, UIApplication *, NSError *) = didFailOriginalMethod;
        originalImp(self, @selector(application:didFailToRegisterForRemoteNotificationsWithError:), application, error);
    }
    NSLog(@"Error registering...");
    [[BaiduPush sharedInstance] didFailToRegisterForRemoteNotificationsWithError:error];
}

- (void)my_application:(UIApplication *) application handleActionWithIdentifier: (NSString *) identifier forRemoteNotification: (NSDictionary *) notification completionHandler: (void (^)()) completionHandler {
    
    NSLog(@"handle action with identifier");
    
    NSMutableDictionary *mutableNotification = [notification mutableCopy];
    
    [mutableNotification setObject:identifier forKey:@"identifier"];
    if (application.applicationState == UIApplicationStateActive) {
        [BaiduPush sharedInstance].notificationMessage = mutableNotification;
        [BaiduPush sharedInstance].isInline = YES;
        [[BaiduPush sharedInstance] notificationReceived];
    } else {
        [BaiduPush sharedInstance].notificationMessage = mutableNotification;
        [[BaiduPush sharedInstance] performSelectorOnMainThread:@selector(notificationReceived) withObject:[BaiduPush sharedInstance] waitUntilDone:NO];
    }
    
    if (handleActionWithIdentifierOriginalMethod) {
        void (*originalImp)(id, SEL, UIApplication *, NSString *, NSDictionary *, void(^)()) = handleActionWithIdentifierOriginalMethod;
        originalImp(self, @selector(application:handleActionWithIdentifier:forRemoteNotification:completionHandler:), application, identifier, notification, completionHandler);
    } else {
        completionHandler();
    }
}


@end
