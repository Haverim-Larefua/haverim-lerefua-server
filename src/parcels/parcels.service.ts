import {
  Injectable,
  Inject,
  Logger,
  HttpException,
  HttpStatus,
  InternalServerErrorException,
} from '@nestjs/common';
import { Repository } from 'typeorm';
import { Parcel } from '../entity/parcel.entity';
import { dbConnection } from './../db/database.providers';
import { ParcelStatus } from '../entity/status.model';
import { ParcelTracking } from '../entity/parcel.tracking.entity';
import { PushToken } from '../entity/push-token.entity';
import { I18nService } from 'nestjs-i18n';
import { IPushNotificationConfiguration, PushNotificationConfigurationType, sendPushMessage } from '../networking/push';

interface ISendNewAssignmentPushMessage {
  packageId: number;
  fullName: string;
  fullAddress: string;
}

@Injectable()
export class ParcelsService {
  constructor(
    @Inject('PARCEL_REPOSITORY') private readonly parcelRepository: Repository<Parcel>,
    @Inject('PARCEL_TRACKING_REPOSITORY') private readonly parcelTrackingRepository: Repository<ParcelTracking>,
    @Inject('PUSH_TOKEN_REPOSITORY') private readonly pushTokenRepository: Repository<PushToken>,
    private readonly i18n: I18nService,
  ) {}

  /**
   * Get all parcels
   */
  getAllParcels(): Promise<Parcel[]> {
    return this.parcelRepository.find({
      relations: ['parcelTracking', 'user'],
    });
  }

  /**
   * Get parcel by parcel id
   * @param id
   */
  getParcelById(id: number): Promise<Parcel> {
    return this.parcelRepository.findOne(id, {
      relations: ['parcelTracking', 'user'],
    });
  }

  /**
   * Get all parcels belongs to userId, by specific statuses
   * @param userId
   */
  getParcelsByUserIdSpecificStatuses(
    userId: number,
    statuses: string[],
  ): Promise<Parcel[]> {
    return dbConnection
      .getRepository(Parcel)
      .createQueryBuilder('parcel')
      .innerJoinAndSelect('parcel.user', 'user')
      .innerJoinAndSelect('parcel.parcelTracking', 'tracking')
      .where('user.id = :userId')
      .andWhere('parcelTrackingStatus IN (:...statuses)')
      .setParameters({
        userId,
        statuses,
      })
      .getMany();
  }

  /**
   * Get all parcels belongs to userId
   * @param userId
   */
  getParcelsByUserId(userId: number): Promise<Parcel[]> {
    return dbConnection
      .getRepository(Parcel)
      .createQueryBuilder('parcel')
      .innerJoinAndSelect('parcel.user', 'user')
      .innerJoinAndSelect('parcel.parcelTracking', 'tracking')
      .where('user.id = :userId')
      .setParameters({
        userId,
      })
      .getMany();
  }

  /**
   * Get parcels by identity (identity of user)
   * @param key
   * Note: This will return array of parcels
   */
  getParcelByIdentity(identity: string): Promise<Parcel[]> {
    return this.parcelRepository.find({
      where: {
        identity,
      },
      join: {
        alias: 'parcel',
        leftJoinAndSelect: {
          user: 'parcel.user',
          parcel_tracking: 'parcel.parcelTracking',
        },
      },
    });
  }

  /**
   * Create new parcel, and return it
   * While creating the parcel need to create also record in parcel_tracking
   * In case parcelTrackingStatus was not supplied set default "ready" status
   * TODO: need to make transaction to verify both save to parcel and parcel_tracking is done
   * @param parcel
   */
  async createParcel(parcel: Parcel): Promise<Parcel> {
    Logger.debug(`parcel.parcelTrackingStatus: ${parcel.parcelTrackingStatus}`);
    const status: ParcelStatus =
      ParcelStatus[
        parcel.parcelTrackingStatus
          ? parcel.parcelTrackingStatus
          : ParcelStatus.ready
      ];
    Logger.debug(`status: ${status}`);
    if (!status) {
      Logger.error(`Parcel status not valid: ${parcel.parcelTrackingStatus}`);
      throw new HttpException(
        `Parcel status not valid: ${parcel.parcelTrackingStatus}`,
        HttpStatus.BAD_REQUEST,
      );
    }
    const result: Parcel = await this.parcelRepository.save(parcel);

    // Update parcel_tracking table
    await this.updateParcelsStatus(parcel.currentUserId, status, [result.id]);
    return result;
  }

  /**
   * Assign parcels to user, and return the new parcels object with the user.
   * Also send push notification to the user
   * @param userId
   * @param parcelId
   */
  async assignParcelsToUser(userId: number, parcelIds: number[]): Promise<Parcel[]> {
    Logger.log(`[ParcelsService] parcelIds: ${parcelIds}`);
    const dt = new Date();
    return new Promise<Parcel[]>(async (resolve, reject) => {

      const pushMessages: ISendNewAssignmentPushMessage[] = [];
      const responseParcels: Parcel[] = [];

      for (const parcelId of parcelIds) {

        // Update parcel table, set currentUserId, lastUpdateDate, parcelTrackingStatus
        await dbConnection
            .getRepository(Parcel)
            .createQueryBuilder()
            .update(Parcel)
            .set({ currentUserId: userId, lastUpdateDate: dt, parcelTrackingStatus: ParcelStatus.assigned })
            .where('id = :parcelId', { parcelId })
            .execute();

        // Insert new record for parcel_tracking table
        const parcelTracking: Partial<ParcelTracking> = {
          statusDate: dt,
          status: ParcelStatus.assigned,
          parcelId,
          userId,
        };
        await this.addParcelTracking(parcelTracking);

        const currentParcel = await this.getParcelById(parcelId);

        pushMessages.push({
          fullName: currentParcel.customerName,
          fullAddress: currentParcel.address,
          packageId: parcelId,
        });

        responseParcels.push(currentParcel);

        Logger.debug(`[ParcelsService] parcelIds: added parcel: ${parcelId}`);
      }

      const pushToken: PushToken = await this.pushTokenRepository.findOne({ userId });

      this.sendNewAssignmentPushMessage(pushToken.token, pushMessages)
          .then((res) => {
            Logger.debug(`Push notification send to user: ${userId}`);
          }).catch((err) => {
        Logger.error(`Error sending push notification to user: ${userId}`, err);
        reject(err);
      });

      resolve(responseParcels);
    });
  }

  sendNewAssignmentPushMessage = (pushToken: string, parcels: ISendNewAssignmentPushMessage[]): Promise<any> => {
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

    const message: IPushNotificationConfiguration = {
      packageIds: parcels.map(parcel => parcel.packageId),
      type: PushNotificationConfigurationType.NEW_PACKAGE,
      notification: {
        title: this.i18n.translate('push.PARCEL_ASSIGNMENT.TITLE'),
        subtitle: parcels.length > 1 ? this.i18n.translate('push.PARCEL_ASSIGNMENT.PARCELS_ASSIGN', { args: { parcels: parcels.length } }) : this.i18n.translate('push.PARCEL_ASSIGNMENT.PARCEL_ASSIGN'),
        body,
      },
      pushTokens: [pushToken],
    };
    return sendPushMessage(message);
  }

  /**
   * Adding signature to parcel, also update Parcel tracking status table with status delivered
   * @param userId
   * @param parcelId
   * @param signature
   */
  async addParcelSignature(
    userId: number,
    parcelId: number,
    signature: string,
  ): Promise<Parcel> {
    Logger.log(`[ParcelsService] addParcelSignature: ${parcelId}`);
    const parcel: Parcel = await this.getParcelById(parcelId);
    if (!parcel) {
      throw new InternalServerErrorException(
        `Parcel ${parcelId} was not found`,
      );
    }
    Logger.log(`[ParcelsService] parcel: ${JSON.stringify(parcel)}`);
    parcel.currentUserId = userId;
    parcel.signature = signature;

    const result: Parcel = await this.parcelRepository.save(parcel);

    // Update parcel_tracking table
    await this.updateParcelsStatus(
      parcel.currentUserId,
      ParcelStatus.delivered,
      [result.id],
    );

    return this.getParcelById(parcelId);
  }

  updateParcelsStatus(userId: number, status: ParcelStatus, parcelsIds: number[]): Promise<number[]> {
    Logger.log(`[ParcelsService] updateParcelsStatus(${userId}, ${status}, ${parcelsIds})`);
    return new Promise<number[]>((resolve, reject) => {
      parcelsIds.forEach(async (id: number) => {
        await dbConnection
          .getRepository(Parcel)
          .createQueryBuilder()
          .update(Parcel)
          .set({ parcelTrackingStatus: status, lastUpdateDate: new Date() })
          .where('id = :id', { id })
          .execute();

        const parcelTracking: Partial<ParcelTracking> = {
          statusDate: new Date(),
          status,
          parcelId: id,
          userId,
        };
        await this.addParcelTracking(parcelTracking);
      });
      resolve(parcelsIds);
    });
  }

  addParcelTracking = (parcelTracking: Partial<ParcelTracking>): Promise<ParcelTracking> => {
    return this.parcelTrackingRepository.save(parcelTracking);
  }

  /**s
   * Update parcel by id
   * @param id
   * @param parcel
   */
  async updateParcel(id: number, parcel: Parcel): Promise<Parcel> {
    await this.parcelRepository.update(id, parcel);
    return this.getParcelById(id);
  }

  /**
   * Delete parcel by id
   * @param id
   */
  deleteParcel(id: number) {
    return this.parcelRepository.delete(id);
  }
}
