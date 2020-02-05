import {Injectable, Inject, Logger, HttpException, HttpStatus} from '@nestjs/common';
import { Repository } from 'typeorm';
import { Parcel } from '../entity/parcel.entity';
import { dbConnection } from './../db/database.providers';
@Injectable()
export class ParcelsService {
  constructor(
    @Inject('PARCEL_REPOSITORY')
    private readonly parcelRepository: Repository<Parcel>,
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
  getParcelsByUserId(userId: number, statuses: number[]): Promise<Parcel[]> {
    return dbConnection.getRepository(Parcel)
        .createQueryBuilder('parcel')
        .innerJoinAndSelect('parcel.user', 'user')
        .innerJoinAndSelect('parcel.parcelTracking', 'tracking')
        .where('user.id = :userId')
        .andWhere('tracking.statusId IN (:...statuses)')
        .setParameters({
          userId,
          statuses,
        })
        .getMany();
  }

  /**
   * Get parcels by no (identity of user)
   * @param key
   * Note: This will return array of parcels
   */
  getParcelByNo(no: string): Promise<Parcel[]> {
    return this.parcelRepository.find( {
      where: {
        no,
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
   * @param parcel
   */
  async createParcel(parcel: Parcel): Promise<Parcel> {
    const p = await this.parcelRepository.find({ no: parcel.no });
    if (p.length === 0) {
      return this.parcelRepository.save(parcel);
    } else {
      throw new HttpException('Parcel already exists', HttpStatus.BAD_REQUEST);
    }
  }

  // async createParcels(parcels: Parcel[]) {
  //   //  const p = await this.parcelRepository.find({ no: parcel.no });
  //   // if (p.length === 0) {
  //   //   return this.parcelRepository.save(parcel);
  //   // } else {
  //   return 'Already exits';
  //   // }
  // }

  /**
   * Assign parcel to user, and return the new parcel object with the user
   * @param userId
   * @param parcelId
   * Note: Can not return this.parcelRepository.save(parcel), because it does not return the parcel with the relationship of user
   */
  async assignParcelToUser(userId: number, parcelId: number): Promise<Parcel> {
    Logger.log(`[ParcelsController] parcelId: ${parcelId}`);
    const parcel: Parcel = await this.parcelRepository.findOne({ id: parcelId });
    Logger.log(`[ParcelsController] parcel: ${JSON.stringify(parcel)}`);
    parcel.userId = userId;
    await this.parcelRepository.save(parcel);
    return this.getParcelById(parcelId);
  }

  /**
   * Update parcel by id
   * @param id
   * @param parcel
   */
  updateParcel(id: number, parcel: Parcel) {
    return this.parcelRepository.update(id, parcel);
  }

  /**
   * Delete parcel by id
   * @param id
   */
  deleteParcel(id: number) {
    return this.parcelRepository.delete(id);
  }

}
