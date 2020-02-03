import { Injectable, Inject } from '@nestjs/common';
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

  async createParcel(parcel: Parcel) {
    const p = await this.parcelRepository.find({ no: parcel.no });
    if (p.length === 0) {
      return this.parcelRepository.save(parcel);
    } else {
      return 'Already exits';
    }
  }
  async createParcels(parcels: Parcel[]) {
    //  const p = await this.parcelRepository.find({ no: parcel.no });
    // if (p.length === 0) {
    //   return this.parcelRepository.save(parcel);
    // } else {
    return 'Already exits';
    // }
  }

  updateParcel(id: number, parcel: Parcel) {
    return this.parcelRepository.update(id, parcel);
  }

  deleteParcel(id: number) {
    return this.parcelRepository.delete(id);
  }

}
