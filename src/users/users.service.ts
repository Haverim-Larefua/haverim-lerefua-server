import { Injectable, Inject, Logger } from '@nestjs/common';
import { User } from '../entity/user.entity';
import { Repository } from 'typeorm';

@Injectable()
export class UsersService {
  constructor(
    @Inject('USER_REPOSITORY')
    private readonly userRepository: Repository<User>,
  ) {}
  getAllUsers() {
    return this.userRepository.find({
      relations: ['deliveryDays'],
    });
  }

  getUserbyId(id: number) {
    return this.userRepository.findOne(id, { relations: ['deliveryDays'] });
  }

  createUser(user: User) {
    return this.userRepository.save(user);
  }

  updateUser(id: number, user: User) {
    return this.userRepository.update(id, user);
  }

  deleteUser(id: number) {
    return this.userRepository.delete(id);
  }

  getParcelsForAllUsers() {
    Logger.log('call to getParcelsForAllUsers');
    const parcels = this.userRepository.find({ relations: ['parcels'] });
    return parcels;
  }

  getParcelsForAUser(id: number) {
    Logger.log('call to getParcelsForAllUsers ');
    return this.userRepository.findOne(id, { relations: ['parcels'] });
  }
}
