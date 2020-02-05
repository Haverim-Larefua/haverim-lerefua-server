import {Injectable, Inject, Logger} from '@nestjs/common';
import { Repository } from 'typeorm';
import { Parcel } from '../entity/parcel.entity';

@Injectable()
export class ParcelsService {
  constructor(
    @Inject('PARCEL_REPOSITORY')
    private readonly parcelRepository: Repository<Parcel>,
  ) {}

  getAllParcels() {
    return this.parcelRepository.find({
      relations: ['parcelTracking', 'user'],
    });
  }

  getParcelbyId(id: number) {
    return this.parcelRepository.findOne(id, {
      relations: ['parcelTracking', 'user'],
    });
  }

  getParcelbyNo(key: string) {
    // return this.parcelRepository.find({ no: key });
    return this.parcelRepository.find( {
      where: {
        no: key,
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
   * Create new parcel
   * @param parcel
   */
  async createParcel(parcel: Parcel) {
    const p = await this.parcelRepository.find({ no: parcel.no });
    if (p.length === 0) {
      return this.parcelRepository.save(parcel);
    } else {
      return 'Already exits';
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
    return this.getParcelbyId(parcelId);
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
