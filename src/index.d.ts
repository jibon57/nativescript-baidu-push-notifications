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

export interface AndroidOptions {
  apiKey: string;
  icon?: string;
}

// Android
export declare function androidRegister(options: AndroidOptions, successCallback: any, errorCallback: any): void;
export declare function androidUnregister(onSuccessCallback: any, onErrorCallback: any): void;
export declare function onMessageReceived(callback: any): void;
export declare function onNotificationArrived(callback: any): void;
export declare function onNotificationClicked(callback: any): void;

// iOS
export declare function iosRegister(settings: IosRegistrationOptions, success: (token: String) => void, error: (NSError: any) => void): void;
export declare function registerUserNotificationSettings(success: () => void, error: (error: NSError) => void): void;
export declare function iosUnregister(success: (result: any) => void, error: (error: NSError) => void): void;
export declare function areNotificationsEnabled(done: (areEnabled: Boolean) => void): void;