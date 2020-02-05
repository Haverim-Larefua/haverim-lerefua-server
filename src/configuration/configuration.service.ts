import { Injectable, Inject } from '@nestjs/common';
import { Repository } from 'typeorm';
import { Parcel } from '../entity/parcel.entity';

@Injectable()
export class ConfigurationService {

  constructor(
    @Inject('CONFIGURATION_STATUS_REPOSITORY') private readonly statusRepository: Repository<Parcel>,
    @Inject('CONFIGURATION_ROLE_REPOSITORY') private readonly roleRepository: Repository<Parcel>,
  ) {}

  async getConfiguration() {
    const statuses = await this.statusRepository.find({});
    const roles = await this.roleRepository.find({});
    return {
      statuses,
      roles,
    };
  }

}
