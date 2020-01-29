import { Injectable, Inject, Logger } from '@nestjs/common';
import { Repository } from 'typeorm';
import { DeliveryDays } from '../entity/deliveyDays.entity';

@Injectable()
export class DeliveryDaysService {
  constructor(
    @Inject('DELIVERY_DAYS_REPOSITORY')
    private readonly deliveryDaysRepository: Repository<DeliveryDays>,
  ) {}

  getAllDD() {
    return this.deliveryDaysRepository.find();
  }

  getDDbyId(id: number) {
    return this.deliveryDaysRepository.findOne(id);
  }

  async createDD(deliveryDays: DeliveryDays) {
    return this.deliveryDaysRepository.save(deliveryDays);
  }

  updateDD(id: number, deliveryDays: DeliveryDays) {
    return this.deliveryDaysRepository.update(id, deliveryDays);
  }

  deleteDD(id: number) {
    return this.deliveryDaysRepository.delete(id);
  }
}
