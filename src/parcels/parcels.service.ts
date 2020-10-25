import {
  Injectable,
  Inject,
  Logger,
  HttpException,
  HttpStatus,
  InternalServerErrorException,
  ConflictException,
  ForbiddenException,
  BadRequestException,
} from '@nestjs/common';
import { Repository, DeleteResult } from 'typeorm';
import { Parcel } from '../entity/parcel.entity';
import { dbConnection } from './../db/database.providers';
import { ParcelStatus } from '../entity/status.model';
import { ParcelTracking } from '../entity/parcel.tracking.entity';
import { PushToken } from '../entity/push-token.entity';
import {
  ISendNewAssignmentPushMessage,
  PushTokenService,
} from '../push-token/push-token.service';

@Injectable()
export class ParcelsService {
  constructor(
    @Inject('PARCEL_REPOSITORY')
    private readonly parcelRepository: Repository<Parcel>,
    @Inject('PARCEL_TRACKING_REPOSITORY')
    private readonly parcelTrackingRepository: Repository<ParcelTracking>,
    @Inject('PUSH_TOKEN_REPOSITORY')
    private readonly pushTokenRepository: Repository<PushToken>,
    private readonly pushTokenService: PushTokenService,
  ) {}

  /**
   * Get all parcels
   */
  getAllParcels(): Promise<Parcel[]> {
    return this.parcelRepository.find({
      relations: ['parcelTracking', 'user'],
      where: [{ deleted: false }],
    });
  }

  /**
   * Get parcel by parcel id
   * @param id
   */
  getParcelById(id: number): Promise<Parcel> {
    return this.parcelRepository.findOne(id, {
      where: [{ deleted: false }],
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
    Logger.log(`[ParcelsService] getParcelsByUserIdSpecificStatuses(${userId}, ${statuses})`);
    return dbConnection
      .getRepository(Parcel)
      .createQueryBuilder('parcel')
      .innerJoinAndSelect('parcel.user', 'user')
      .innerJoinAndSelect('parcel.parcelTracking', 'tracking')
      .where('user.id = :userId')
      .andWhere('parcel.deleted = false')
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
    Logger.log(`[ParcelsService] getParcelsByUserId(${userId})`);
    return dbConnection
      .getRepository(Parcel)
      .createQueryBuilder('parcel')
      .innerJoinAndSelect('parcel.user', 'user')
      .innerJoinAndSelect('parcel.parcelTracking', 'tracking')
      .where('user.id = :userId')
      .andWhere('parcel.deleted = false')
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
      where: [
        {
          identity,
          deleted: false,
        },
      ],
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
      throw new BadRequestException(
        `Parcel status not valid: ${parcel.parcelTrackingStatus}`,
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
  async assignParcelsToUser(
    userId: number,
    parcelIds: number[],
  ): Promise<Parcel[]> {
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
          .set({
            currentUserId: userId,
            lastUpdateDate: dt,
            parcelTrackingStatus: ParcelStatus.assigned,
          })
          .where('id = :parcelId', { parcelId })
          .execute();

        const parcelTracking: Partial<ParcelTracking> = {
          statusDate: new Date(),
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

      const pushToken: PushToken = await this.pushTokenRepository.findOne({
        userId,
      });

      this.pushTokenService
        .sendNewAssignmentPushMessage(pushToken.token, pushMessages)
        .then(res => {
          Logger.debug(`Push notification send to user: ${userId}`);
        })
        .catch(err => {
          Logger.error(
            `Error sending push notification to user: ${userId}`,
            err,
          );
          reject(err);
        });

      resolve(responseParcels);
    });
  }

  /**
   * Unassign parcel from user, and return the new parcel object without the user.
   * @param parcelId
   */
  async unassignParcel(parcelId: number): Promise<Parcel> {
    Logger.log(`[ParcelsService] parcelId: ${parcelId}`);
    const dt = new Date();

    return new Promise<Parcel>(async (resolve, reject) => {
      let responseParcel = await this.getParcelById(parcelId);

      // Update parcel table, set currentUserId, lastUpdateDate, parcelTrackingStatus
      await dbConnection
        .getRepository(Parcel)
        .createQueryBuilder()
        .update(Parcel)
        .set({
          currentUserId: null,
          lastUpdateDate: dt,
          parcelTrackingStatus: ParcelStatus.ready,
        })
        .where('id = :parcelId', { parcelId })
        .execute();

      // Add the relevant parcel tracking record
      const parcelTracking: Partial<ParcelTracking> = {
        statusDate: new Date(),
        status: ParcelStatus.ready,
        parcelId,
        userId: null,
        comments: 'השליח הוסר מהחבילה',
      };

      await this.addParcelTracking(parcelTracking);

      responseParcel = await this.getParcelById(parcelId);

      Logger.debug(`[ParcelsService] parcelId: unassigned parcel: ${parcelId}`);
      resolve(responseParcel);
    });
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

  updateParcelsStatus(
    userId: number,
    status: ParcelStatus,
    parcelsIds: number[],
  ): Promise<number[]> {
    Logger.log(
      `[ParcelsService] updateParcelsStatus(${userId}, ${status}, ${parcelsIds})`,
    );
    return new Promise<number[]>((resolve, reject) => {
      parcelsIds.forEach(async (id: number) => {
        await dbConnection
          .getRepository(Parcel)
          .createQueryBuilder()
          .update(Parcel)
          .set({
            parcelTrackingStatus: status,
            lastUpdateDate: new Date(),
            exception: false,
          })
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

  addParcelTracking = (
    parcelTracking: Partial<ParcelTracking>,
  ): Promise<ParcelTracking> => {
    return this.parcelTrackingRepository.save(parcelTracking);
  };

  /**s
   * Update parcel by id
   * @param id
   * @param parcel
   */
  async updateParcel(id: number, parcel: Parcel): Promise<Parcel> {
    await this.parcelRepository.update(id, parcel);
    return this.getParcelById(id);
  }

  async canDeleteParcel(id): Promise<Parcel> {
    const parcel: Parcel = await this.getParcelById(id);

    if (!parcel) {
      Logger.error(
        `[ParcelsService] canDeleteParcel  Parcel ${id} was not found`,
      );
      throw new BadRequestException(`Parcel ${id} was not found`);
    }
    if (
      parcel.parcelTrackingStatus !== ParcelStatus.ready &&
      parcel.parcelTrackingStatus !== ParcelStatus.assigned
    ) {
      Logger.error(
        `[ParcelsService] canDeleteParcel  Parcel ${id} status not ready or assigned`,
      );
      throw new ForbiddenException(`Parcel ${id} status not ready or assigned`);
    }

    return parcel;
  }

  async markParcelAsDeleted(id: number): Promise<Parcel> {
    let parcel: Parcel = await this.canDeleteParcel(id);

    //unassign this parcel && change its status to ready
    if (parcel.parcelTrackingStatus == ParcelStatus.assigned) {
      parcel = await this.unassignParcel(id);
    }

    // mark parcel as deleted
    Logger.log(`[ParcelsService] markParcelAsDeleted parcel: ${JSON.stringify(parcel)}`, );
    parcel.deleted = true;
    const result: Parcel = await this.parcelRepository.save(parcel);
    return result;
  }

  async removeParcel(id: number) {
    const parcel: Parcel = await this.canDeleteParcel(id);

    //unassign this parcel && change its status to ready
    if (parcel.parcelTrackingStatus == ParcelStatus.assigned) {
      await this.unassignParcel(id);
    }

    // delete parcel
    return await this.parcelRepository.delete(id);
  }

  /**
   * Delete parcel by id
   * @param id
   * @param keep if true only mark this parcel as deleted but keep it in DB
   */
  async deleteParcel(id: number, keep: boolean) {
    if (keep) {
      return await this.markParcelAsDeleted(id);
    } else {
      return await this.removeParcel(id);
    }
  }
}
