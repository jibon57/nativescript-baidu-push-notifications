#import "BaiduPush.h"
#import <UIKit/UIKit.h>
#import <UIKit/UIUserNotificationSettings.h>
#import <objc/runtime.h>
#import "BPush.h"

const NSString * badgeKey = @"badge";
const NSString * soundKey = @"sound";
const NSString * alertKey = @"alert";
const NSString * areNotificationsEnabledEventName = @"areNotificationsEnabled";
const NSString * didUnregisterEventName = @"didUnregister";
const NSString * didRegisterEventName = @"didRegisterForRemoteNotificationsWithDeviceToken";
const NSString * didFailToRegisterEventName = @"didFailToRegisterForRemoteNotificationsWithError";
const NSString * notificationReceivedEventName = @"notificationReceived";
const NSString * setBadgeNumberEventName = @"setApplicationIconBadgeNumber";
const NSString * didRegisterUserNotificationSettingsEventName = @"didRegisterUserNotificationSettings";
const NSString * failToRegisterUserNotificationSettingsEventName = @"failToRegisterUserNotificationSettings";


static char launchNotificationKey;

NSString *insBPushAPIKey = @"";
BOOL isDevBPushEnvironment = TRUE;

@implementation BaiduPush

@synthesize notificationMessage;
@synthesize isInline;

+ (instancetype)sharedInstance
{
    static BaiduPush *sharedInstance = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        sharedInstance = [[BaiduPush alloc] init];
    });
    return sharedInstance;
}

-(void)setupBaiduAPIKey:(NSString *)apiKey mode:(BOOL)isDevMode{
    NSLog(@"%s", __PRETTY_FUNCTION__);
    insBPushAPIKey = apiKey;
    isDevBPushEnvironment = isDevMode;
}

- (void)areNotificationsEnabled
{
    BOOL registered;
#if __IPHONE_OS_VERSION_MAX_ALLOWED >= 80000
    if ([[UIApplication sharedApplication] respondsToSelector:@selector(isRegisteredForRemoteNotifications)]) {
        registered = [[UIApplication sharedApplication] isRegisteredForRemoteNotifications];
    } else {
        UIRemoteNotificationType types = [[UIApplication sharedApplication] enabledRemoteNotificationTypes];
        registered = types != UIRemoteNotificationTypeNone;
    }
#else
    UIRemoteNotificationType types = [[UIApplication sharedApplication] enabledRemoteNotificationTypes];
    registered = types != UIRemoteNotificationTypeNone;
#endif
    NSString * booleanString = (registered) ? @"true" : @"false";
    [self success:areNotificationsEnabledEventName WithMessage:booleanString];
}

- (void)unregister
{
    [[UIApplication sharedApplication] unregisterForRemoteNotifications];
    [self success:didUnregisterEventName WithMessage:@"Success"];
    
}

-(void)register:(NSMutableDictionary *)options
{
#if __IPHONE_OS_VERSION_MAX_ALLOWED >= 80000
    UIUserNotificationType UserNotificationTypes = UIUserNotificationTypeNone;
    if([self isTrue: badgeKey fromOptions: options]) UserNotificationTypes |= UIUserNotificationTypeBadge;
    if([self isTrue: soundKey fromOptions: options]) UserNotificationTypes |= UIUserNotificationTypeSound;
    if([self isTrue: alertKey fromOptions: options]) UserNotificationTypes |= UIUserNotificationTypeAlert;
#endif
    UIRemoteNotificationType notificationTypes = UIRemoteNotificationTypeNone;
    notificationTypes |= UIRemoteNotificationTypeNewsstandContentAvailability;
    
    if([self isTrue: badgeKey fromOptions: options]) notificationTypes |= UIRemoteNotificationTypeBadge;
    if([self isTrue: soundKey fromOptions: options]) notificationTypes |= UIRemoteNotificationTypeSound;
    if([self isTrue: alertKey fromOptions: options]) notificationTypes |= UIRemoteNotificationTypeAlert;

#if __IPHONE_OS_VERSION_MAX_ALLOWED >= 80000
    UserNotificationTypes |= UIUserNotificationActivationModeBackground;
#endif
    
    if (notificationTypes == UIRemoteNotificationTypeNone)
        NSLog(@"PushPlugin.register: Push notification type is set to none");
    
    isInline = NO;
    
#if __IPHONE_OS_VERSION_MAX_ALLOWED >= 80000
    if ([[UIApplication sharedApplication]respondsToSelector:@selector(registerUserNotificationSettings:)]) {
        UIUserNotificationSettings *settings = [UIUserNotificationSettings settingsForTypes:UserNotificationTypes categories:nil];
        [[UIApplication sharedApplication] registerUserNotificationSettings:settings];
        [[UIApplication sharedApplication] registerForRemoteNotifications];
    } else {
        [[UIApplication sharedApplication] registerForRemoteNotificationTypes:notificationTypes];
    }
#else
    [[UIApplication sharedApplication] registerForRemoteNotificationTypes:notificationTypes];
#endif

    if (notificationMessage)
        [self notificationReceived];
}

- (BOOL)isTrue:(NSString *)key fromOptions:(NSMutableDictionary *)options
{
    id arg = [options objectForKey:key];
    
    if([arg isKindOfClass:[NSString class]]) return [arg isEqualToString:@"true"];

    if([arg boolValue]) return true;
    
    return false;
}


- (void)didRegisterForRemoteNotificationsWithDeviceToken:(NSData *)deviceToken
{
    NSLog(@"Push didRegisterForRemoteNotificationsWithDeviceToken");
    
    NSMutableDictionary *results = [NSMutableDictionary dictionary];
    NSString *token = [[[[deviceToken description] stringByReplacingOccurrencesOfString:@"<"withString:@""]
                        stringByReplacingOccurrencesOfString:@">" withString:@""]
                       stringByReplacingOccurrencesOfString: @" " withString: @""];
    [results setValue:token forKey:@"deviceToken"];
    
#if !TARGET_IPHONE_SIMULATOR
    // Get Bundle Info for Remote Registration (handy if you have more than one app)
    [results setValue:[[[NSBundle mainBundle] infoDictionary] objectForKey:@"CFBundleDisplayName"] forKey:@"appName"];
    [results setValue:[[[NSBundle mainBundle] infoDictionary] objectForKey:@"CFBundleVersion"] forKey:@"appVersion"];
    
    // Check what Notifications the user has turned on.  We registered for all three, but they may have manually disabled some or all of them.
    NSUInteger rntypes;
#if __IPHONE_OS_VERSION_MAX_ALLOWED >= 80000
    if([UIUserNotificationSettings class]){
        rntypes = [[[UIApplication sharedApplication] currentUserNotificationSettings] types];
    } else {
        rntypes = [[UIApplication sharedApplication] enabledRemoteNotificationTypes];
    }
#else
    rntypes = [[UIApplication sharedApplication] enabledRemoteNotificationTypes];
#endif
    
    // Set the defaults to disabled unless we find otherwise...
    NSString *pushBadge = @"disabled";
    NSString *pushAlert = @"disabled";
    NSString *pushSound = @"disabled";
    
    // Check what Registered Types are turned on. This is a bit tricky since if two are enabled, and one is off, it will return a number 2... not telling you which
    // one is actually disabled. So we are literally checking to see if rnTypes matches what is turned on, instead of by number. The "tricky" part is that the
    // single notification types will only match if they are the ONLY one enabled.  Likewise, when we are checking for a pair of notifications, it will only be
    // true if those two notifications are on.  This is why the code is written this way
    if(rntypes & UIRemoteNotificationTypeBadge){
        pushBadge = @"enabled";
    }
    if(rntypes & UIRemoteNotificationTypeAlert) {
        pushAlert = @"enabled";
    }
    if(rntypes & UIRemoteNotificationTypeSound) {
        pushSound = @"enabled";
    }
    
    [results setValue:pushBadge forKey:@"pushBadge"];
    [results setValue:pushAlert forKey:@"pushAlert"];
    [results setValue:pushSound forKey:@"pushSound"];
    
    // Get the users Device Model, Display Name, Token & Version Number
    UIDevice *dev = [UIDevice currentDevice];
    [results setValue:dev.name forKey:@"deviceName"];
    [results setValue:dev.model forKey:@"deviceModel"];
    [results setValue:dev.systemVersion forKey:@"deviceSystemVersion"];
    
    //[self success:didRegisterEventName WithMessage:[NSString stringWithFormat:@"%@", deviceToken]];
    
    // we will send it to baidu
    
    [BPush registerDeviceToken:deviceToken];
    [BPush bindChannelWithCompleteHandler:^(id result, NSError *error) {
        NSLog(@"bindChannelWithCompleteHandler:%@",result);
        
        if (error) {
            [self fail:didFailToRegisterEventName WithMessage:@"No baidu chanel id" withError:error];
            return ;
        }
        if (result) {
            if ([result[@"error_code"]intValue]!=0) {
                return;
            }
            
            [self success:didRegisterEventName WithDictionary:result];
            
        }
    }];
    
#endif
}

- (void)didFailToRegisterForRemoteNotificationsWithError:(NSError *)error
{
    [self fail:didFailToRegisterEventName WithMessage:@"" withError:error];
}

- (void)notificationReceived
{
    if (self.notificationMessage)
    {
        
        NSMutableString *jsonStr = [NSMutableString stringWithString:@"{"];
        
        [self parseDictionary:self.notificationMessage intoJSON:jsonStr];
        
        if (isInline)
        {
            [jsonStr appendFormat:@"\"foreground\":\"%d\"", 1];
            isInline = NO;
        }
        else
            [jsonStr appendFormat:@"\"foreground\":\"%d\"", 0];
        
        [jsonStr appendString:@"}"];
        
        NSLog(@"Msg: %@", jsonStr);
        
        [self success:notificationReceivedEventName WithMessage:jsonStr];
        self.notificationMessage = nil;
    }
}

-(void)parseDictionary:(NSDictionary *)inDictionary intoJSON:(NSMutableString *)jsonString
{
    NSArray         *keys = [inDictionary allKeys];
    NSString        *key;
    
    for (key in keys)
    {
        id thisObject = [inDictionary objectForKey:key];
        
        if ([thisObject isKindOfClass:[NSDictionary class]])
            [self parseDictionary:thisObject intoJSON:jsonString];
        else if ([thisObject isKindOfClass:[NSString class]])
            [jsonString appendFormat:@"\"%@\":\"%@\",",
             key,
             [[[[inDictionary objectForKey:key]
                stringByReplacingOccurrencesOfString:@"\\" withString:@"\\\\"]
               stringByReplacingOccurrencesOfString:@"\"" withString:@"\\\""]
              stringByReplacingOccurrencesOfString:@"\n" withString:@"\\n"]];
        else {
            [jsonString appendFormat:@"\"%@\":\"%@\",", key, [inDictionary objectForKey:key]];
        }
    }
}

- (void)setApplicationIconBadgeNumber:(NSMutableDictionary *)options
{
    int badge = [[options objectForKey:badgeKey] intValue] ?: 0;
    
    [[UIApplication sharedApplication] setApplicationIconBadgeNumber:badge];
    
    [self success:setBadgeNumberEventName WithMessage:[NSString stringWithFormat:@"app badge count set to %d", badge]];
}

- (void)registerUserNotificationSettings:(NSDictionary*)options
{
#if __IPHONE_OS_VERSION_MAX_ALLOWED >= 80000
    if (![[UIApplication sharedApplication]respondsToSelector:@selector(registerUserNotificationSettings:)]) {
        [self success:didRegisterUserNotificationSettingsEventName WithMessage:[NSString stringWithFormat:@"%@", @"user notifications not supported for this ios version."]];
        return;
    }
    
    NSArray *categories = [options objectForKey:@"categories"];
    if (categories == nil) {
        [self fail:failToRegisterUserNotificationSettingsEventName WithMessage:@"No categories specified" withError:nil];
        return;
    }
    NSMutableArray *nsCategories = [[NSMutableArray alloc] initWithCapacity:[categories count]];
    
    for (NSDictionary *category in categories) {
        // ** 1. create the actions for this category
        NSMutableArray *nsActionsForDefaultContext = [[NSMutableArray alloc] initWithCapacity:4];
        NSArray *actionsForDefaultContext = [category objectForKey:@"actionsForDefaultContext"];
        if (actionsForDefaultContext == nil) {
            [self fail:failToRegisterUserNotificationSettingsEventName WithMessage:@"Category doesn't contain actionsForDefaultContext" withError:nil];
            return;
        }
        if (![self createNotificationAction:category actions:actionsForDefaultContext nsActions:nsActionsForDefaultContext]) {
            return;
        }
        
        NSMutableArray *nsActionsForMinimalContext = [[NSMutableArray alloc] initWithCapacity:2];
        NSArray *actionsForMinimalContext = [category objectForKey:@"actionsForMinimalContext"];
        if (actionsForMinimalContext == nil) {
            [self fail:failToRegisterUserNotificationSettingsEventName WithMessage:@"Category doesn't contain actionsForMinimalContext" withError:nil];
            return;
        }
        if (![self createNotificationAction:category actions:actionsForMinimalContext nsActions:nsActionsForMinimalContext]) {
            return;
        }
        
        // ** 2. create the category
        UIMutableUserNotificationCategory *nsCategory = [[UIMutableUserNotificationCategory alloc] init];
        // Identifier to include in your push payload and local notification
        NSString *identifier = [category objectForKey:@"identifier"];
        if (identifier == nil) {
            [self fail:failToRegisterUserNotificationSettingsEventName WithMessage:@"Category doesn't contain identifier" withError:nil];
            return;
        }
        nsCategory.identifier = identifier;
        // Add the actions to the category and set the action context
        [nsCategory setActions:nsActionsForDefaultContext forContext:UIUserNotificationActionContextDefault];
        // Set the actions to present in a minimal context
        [nsCategory setActions:nsActionsForMinimalContext forContext:UIUserNotificationActionContextMinimal];
        [nsCategories addObject:nsCategory];
    }
    
    // ** 3. Determine the notification types
    NSArray *types = [options objectForKey:@"types"];
    if (types == nil) {
        [self fail:failToRegisterUserNotificationSettingsEventName WithMessage:@"No types specified" withError:nil];
        return;
    }
    UIUserNotificationType nsTypes = UIUserNotificationTypeNone;
    for (NSString *type in types) {
        if ([type isEqualToString:badgeKey]) {
            nsTypes |= UIUserNotificationTypeBadge;
        } else if ([type isEqualToString:alertKey]) {
            nsTypes |= UIUserNotificationTypeAlert;
        } else if ([type isEqualToString:soundKey]) {
            nsTypes |= UIUserNotificationTypeSound;
        } else {
            [self fail:failToRegisterUserNotificationSettingsEventName WithMessage:[NSString stringWithFormat:@"Unsupported type: %@, use one of badge, alert, sound", type] withError:nil];
        }
    }
    
    // ** 4. Register the notification categories
    NSSet *nsCategorySet = [NSSet setWithArray:nsCategories];
    
    
    UIUserNotificationSettings *settings = [UIUserNotificationSettings settingsForTypes:nsTypes categories:nsCategorySet];
    [[UIApplication sharedApplication] registerUserNotificationSettings:settings];
#endif
    [self success:didRegisterUserNotificationSettingsEventName WithMessage:[NSString stringWithFormat:@"%@", @"user notifications registered"]];
}

#if __IPHONE_OS_VERSION_MAX_ALLOWED >= 80000
- (BOOL)createNotificationAction:(NSDictionary *)category
                         actions:(NSArray *) actions
                       nsActions:(NSMutableArray *)nsActions
{
    for (NSDictionary *action in actions) {
        UIMutableUserNotificationAction *nsAction = [[UIMutableUserNotificationAction alloc] init];
        // Define an ID string to be passed back to your app when you handle the action
        NSString *identifier = [action objectForKey:@"identifier"];
        if (identifier == nil) {
            [self fail:failToRegisterUserNotificationSettingsEventName WithMessage:@"Action doesn't contain identifier" withError:nil];
            return NO;
        }
        nsAction.identifier = identifier;
        // Localized text displayed in the action button
        NSString *title = [action objectForKey:@"title"];
        if (title == nil) {
            [self fail:failToRegisterUserNotificationSettingsEventName WithMessage:@"Action doesn't contain title" withError:nil];
            return NO;
        }
        nsAction.title = title;
        // If you need to show UI, choose foreground (background gives your app a few seconds to run)
        BOOL isForeground = [@"foreground" isEqualToString:[action objectForKey:@"activationMode"]];
        nsAction.activationMode = isForeground ? UIUserNotificationActivationModeForeground : UIUserNotificationActivationModeBackground;
        // Destructive actions display in red
        BOOL isDestructive = [[action objectForKey:@"destructive"] isEqual:[NSNumber numberWithBool:YES]];
        nsAction.destructive = isDestructive;
        // Set whether the action requires the user to authenticate
        BOOL isAuthRequired = [[action objectForKey:@"authenticationRequired"] isEqual:[NSNumber numberWithBool:YES]];
        nsAction.authenticationRequired = isAuthRequired;
        [nsActions addObject:nsAction];
    }
    return YES;
}
#endif

-(void)success:(NSString *)eventName WithDictionary:(NSMutableDictionary *)userInfo
{
    [[NSNotificationCenter defaultCenter]
     postNotificationName:eventName
     object:self userInfo:userInfo];
}

-(void)success:(NSString *)eventName WithMessage:(NSString *)message
{
    NSMutableDictionary *userInfo = [NSMutableDictionary dictionary];
    [userInfo setValue:message forKey:@"message"];
    [[NSNotificationCenter defaultCenter]
     postNotificationName:eventName
     object:self userInfo:userInfo];
}

-(void)fail:(NSString *)eventName WithMessage:(NSString *)message withError:(NSError *)error
{
    NSMutableDictionary *userInfo = [NSMutableDictionary dictionary];
    NSString *errorMessage = (error) ? [NSString stringWithFormat:@"%@ - %@", message, [error localizedDescription]] : message;
    [userInfo setValue:errorMessage forKey:@"message"];
    
    [[NSNotificationCenter defaultCenter]
     postNotificationName:eventName
     object:self userInfo:userInfo];
}

- (NSMutableArray *)launchNotification
{
    return objc_getAssociatedObject(self, &launchNotificationKey);
}

- (void)setLaunchNotification:(NSDictionary *)aDictionary
{
    objc_setAssociatedObject(self, &launchNotificationKey, aDictionary, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
}

- (void)dealloc
{
    self.launchNotification	= nil;
}

@end
