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
    return this.parcelRepository.find();
  }

  getParcelbyId(id: number) {
    return this.parcelRepository.findOne(id);
  }

  createParcel(parcel: Parcel) {
    return this.parcelRepository.save(parcel);
  }

  updateParcel(id: number, parcel: Parcel) {
    return this.parcelRepository.update(id, parcel);
  }

  deleteParcel(id: number) {
    return this.parcelRepository.delete(id);
  }
}
