import { Injectable, Inject, Logger } from '@nestjs/common';
import { Repository } from 'typeorm';
import { PushToken } from '../entity/push-token.entity';
import { environment } from '../env';
import { HttpMethod, sendHttpRequest } from '../networking/http-requestor';
import { I18nService } from 'nestjs-i18n';

export enum PushNotificationConfigurationType {
  NEW_PACKAGE = 'newPackage',
  MESSAGE = 'message',
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

export interface ISendNewAssignmentPushMessage {
  packageId: number;
  fullName: string;
  fullAddress: string;
}

@Injectable()
export class PushTokenService {

  constructor(
    @Inject('PUSH_TOKEN_REPOSITORY') private readonly pushTokenRepository: Repository<PushToken>,
    private readonly i18n: I18nService,
  ) { }

  async getAllPushTokens() {
    const pushTokens = await this.pushTokenRepository.find({});
    return pushTokens;
  }

  async updateAddPushToken(userId: number, pushToken: string): Promise<void> {
    const tokenEntity: PushToken = await this.pushTokenRepository.findOne({ userId });
    Logger.log(`[PushTokenService] updateAddPushToken(${userId}, ${pushToken})`);
    if (!tokenEntity) {
      // Create new recorder
      Logger.log(`[PushTokenService] updateAddPushToken() user not found in push tokens list, adding new push token`);
      await this.pushTokenRepository.save({
        token: pushToken,
        userId,
      } as PushToken);
    } else {
      // Update existing record
      Logger.log(`[PushTokenService] updateAddPushToken() user found in push tokens list, updating push token`);
      await this.pushTokenRepository.update(tokenEntity.id, {
        token: pushToken,
      } as PushToken);
    }
  }

  async notifyUserPushMessage(userId: number, title: string, subtitle: string, message: string, parcelId?: number[]): Promise<void> {
    const pushToken: PushToken = await this.pushTokenRepository.findOne({ userId });
    if (!pushToken) return;
    const pushConf: IPushNotificationConfiguration = {
      packageIds: parcelId || [0],
      type: PushNotificationConfigurationType.MESSAGE,
      notification: {
        title,
        subtitle,
        body: message,
      },
      pushTokens: [pushToken.token],
    };

    return new Promise<void>(async (resolve, reject) => {
      this.sendPushMessage(pushConf)
        .then((res) => { Logger.debug(`Push notification send to user: ${userId}`); })
        .catch((err) => {
          Logger.error(`Error sending push notification to user: ${userId}`, err);
          reject();
        });
      resolve();
    });
  }

  public sendNewAssignmentPushMessage = (pushToken: string, parcels: ISendNewAssignmentPushMessage[]): Promise<any> => {
    let body = '';
    if (parcels.length === 1) {
      body = this.i18n.translate('push.PARCEL_ASSIGNMENT.BODY_ONE_PARCEL', { args: { address: parcels[0].fullAddress, fullName: parcels[0].fullName } });
    } else {
      const unique = [...new Set(parcels.map(parcel => parcel.fullAddress))];
      if (unique.length === 1) {
        body = this.i18n.translate('push.PARCEL_ASSIGNMENT.BODY_MULTIPLE_PARCELS_ONE_ADDRESS', { args: { address: parcels[0].fullAddress, fullName: parcels[0].fullName } });
      } else {
        body = this.i18n.translate('push.PARCEL_ASSIGNMENT.BODY_MULTIPLE_PARCELS_MULTIPLE_ADDRESS', { args: { addressCount: unique.length } });
      }
    }

    const pushConf: IPushNotificationConfiguration = {
      packageIds: parcels.map(parcel => parcel.packageId),
      type: PushNotificationConfigurationType.NEW_PACKAGE,
      notification: {
        title: this.i18n.translate('push.PARCEL_ASSIGNMENT.TITLE'),
        subtitle: parcels.length > 1 ? this.i18n.translate('push.PARCEL_ASSIGNMENT.PARCELS_ASSIGN', { args: { parcels: parcels.length } }) : this.i18n.translate('push.PARCEL_ASSIGNMENT.PARCEL_ASSIGN'),
        body,
      },
      pushTokens: [pushToken],
    };
    return this.sendPushMessage(pushConf);
  }

  private sendPushMessage = (config: IPushNotificationConfiguration): Promise<any> => {
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
  }

}
