import {environment} from '../env';
import {HttpMethod, sendHttpRequest} from './http-requestor';
import {Logger} from '@nestjs/common';

export enum PushNotificationConfigurationType {
    NEW_PACKAGE = 'newPackage',
    MESSAGE = 'message'
}

export interface IPushNotificationConfiguration {
    pushTokens: string[];
    type: PushNotificationConfigurationType;
    packageId: number;
    notification: {
        title?: string,
        subtitle?: string,
        body: string,
    };
}

export const sendPushMessage = (config: IPushNotificationConfiguration): Promise<any> => {
    const url = environment.URLS.PUSH_MOBILE;
    const headers = { 'Authorization': `key=${environment.FIREBASE_API_KEY}`, 'Content-Type': 'application/json' };
    const data = {
        content_available: true,
        notification: {
            title: config.notification.title || 'חברים לרפואה',
            subtitle: config.notification.subtitle || 'שוייכה אליך חבילה חדשה',
            body: config.notification.body, // ' חבילה עבור ישראל ישראלי לכתובת: איירפורט סיטי ',
            sound: 'default',
        },
        registration_ids: config.pushTokens,
        priority: 'high',
        data: {
            notificationType: config.type,
            packageId: config.packageId,
        },
    };
    return sendHttpRequest(url, HttpMethod.POST, headers, data);
};
