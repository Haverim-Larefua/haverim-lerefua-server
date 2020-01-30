import { Injectable, Inject, Logger } from '@nestjs/common';
import { Repository } from 'typeorm';
import { Parcel } from '../entity/parcel.entity';

@Injectable()
export class ParcelsService {
  constructor(
    @Inject('PARCEL_REPOSITORY')
    private readonly parcelRepository: Repository<Parcel>,
  ) {}

  getAllParcels() {
    return this.parcelRepository.find();
  }

  getParcelbyId(id: number) {
    return this.parcelRepository.findOne(id);
  }

  async createParcel(parcel: Parcel) {
    const p = await this.parcelRepository.find({ no: parcel.no });
    if (p.length === 0) {
      return this.parcelRepository.save(parcel);
    } else {
      return 'Allready exits';
    }
  }
  async createParcels(parcels: Parcel[]) {
    //  const p = await this.parcelRepository.find({ no: parcel.no });
    // if (p.length === 0) {
    //   return this.parcelRepository.save(parcel);
    // } else {
    return 'Allready exits';
    //}
  }

  updateParcel(id: number, parcel: Parcel) {
    return this.parcelRepository.update(id, parcel);
  }

  deleteParcel(id: number) {
    return this.parcelRepository.delete(id);
  }

  findByNo(key: string) {
    return this.parcelRepository.find({ no: key });
  }
}
