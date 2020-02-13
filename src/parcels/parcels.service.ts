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

@Injectable()
export class ParcelsService {
  constructor(
    @Inject('PARCEL_REPOSITORY')
    private readonly parcelRepository: Repository<Parcel>,
    @Inject('PARCEL_TRACKING_REPOSITORY')
    private readonly parcelTrackingRepository: Repository<ParcelTracking>,
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
   * Assign parcel to user, and return the new parcel object with the user
   * @param userId
   * @param parcelId
   * Note: Can not return this.parcelRepository.save(parcel), because it does not return the parcel with the relationship of user
   */
  async assignParcelToUser(userId: number, parcelId: number): Promise<Parcel> {
    Logger.log(`[ParcelsService] parcelId: ${parcelId}`);
    const parcel: Parcel = await this.getParcelById(parcelId);
    if (!parcel) {
      throw new InternalServerErrorException(
        `Parcel ${parcelId} was not found`,
      );
    }
    Logger.log(`[ParcelsService] parcel: ${JSON.stringify(parcel)}`);

    const dt = new Date();
    return new Promise<Parcel>(async (resolve, reject) => {
      await dbConnection
        .getRepository(Parcel)
        .createQueryBuilder()
        .update(Parcel)
        .set({ currentUserId: userId, lastUpdateDate: dt })
        .where('id = :parcelId', { parcelId })
        .execute();

      const parcelTracking: Partial<ParcelTracking> = {
        statusDate: dt,
        status: parcel.parcelTrackingStatus as ParcelStatus,
        parcelId,
        userId,
      };
      await this.addParcelTracking(parcelTracking);
      resolve(parcel);
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

  /**
   * Delete parcel by id
   * @param id
   */
  deleteParcel(id: number) {
    return this.parcelRepository.delete(id);
  }
}
