export interface IosInteractiveNotificationAction {
  identifier: string;
  title: string;
  activationMode?: string;
  destructive?: boolean;
  authenticationRequired?: boolean;
  behavior?: string;
}
export interface IosInteractiveNotificationCategory {
  identifier: string;
  actionsForDefaultContext: string[];
  actionsForMinimalContext: string[];
}
export interface IosRegistrationOptions {
  badge: boolean;
  sound: boolean;
  alert: boolean;
  clearBadge: boolean;
  interactiveSettings: {
    actions: IosInteractiveNotificationAction[];
    categories: IosInteractiveNotificationCategory[];
  };
  notificationCallbackIOS: (message: any) => void;
}
export interface NSError {
  code: number;
  domain: string;
  userInfo: any;
}
export declare function iOSregister(settings: IosRegistrationOptions, success: (token: String) => void, error: (NSError: any) => void): void;
export declare function registerUserNotificationSettings(success: () => void, error: (error: NSError) => void): void;
export declare function unregister(done: (context: any) => void): void;
export declare function areNotificationsEnabled(done: (areEnabled: Boolean) => void): void;
export declare function registerBaiduNotificationSettingCallback(success: (result: any) => void, error: (error: NSError) => void): void;
