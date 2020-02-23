import {environment} from '../env';
import {HttpMethod, sendHttpRequest} from './http-requestor';

export enum PushNotificationConfigurationType {
    NEW_PACKAGE = 'newPackage',
    MESSAGE = 'message'
}

export interface IPushNotificationConfiguration {
    pushTokens: string[];
    type: PushNotificationConfigurationType;
    packageIds: number[];
    notification: {
        title: string,
        subtitle: string,
        body: string,
    };
}

export const sendPushMessage = (config: IPushNotificationConfiguration): Promise<any> => {
    const url = environment.URLS.PUSH_MOBILE;
    const headers = { 'Authorization': `key=${environment.FIREBASE_API_KEY}`, 'Content-Type': 'application/json' };
    const data = {
        content_available: true,
        notification: {
            title: config.notification.title,
            subtitle: config.notification.subtitle,
            body: config.notification.body,
            sound: 'default',
        },
        registration_ids: config.pushTokens,
        priority: 'high',
        data: {
            notificationType: config.type,
            packageIds: config.packageIds,
        },
    };
    return sendHttpRequest(url, HttpMethod.POST, headers, data);
};
