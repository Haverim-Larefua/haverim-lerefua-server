import { Injectable, Inject } from '@nestjs/common';
import { User } from './entity/user.entity';
import { Repository } from 'typeorm';

@Injectable()
export class UsersService {
  constructor(
    @Inject('USER_REPOSITORY')
    private readonly userRepository: Repository<User>,
  ) {}
  getAllUsers() {
    return this.userRepository.find();
  }

  getUserbyId(id: number) {
    return this.userRepository.findOne(id);
  }

  createUser(user: User) {
    return this.userRepository.save(user);
  }

<<<<<<< HEAD
    updateUser(id: number, user: UserDto){
        return "update user with id: " + id + " with the data: " + user;
    }

    deleteUser(id: number){
        return "delete user with id: " + id;
    }
=======
  updateUser(id: number, user: User) {
    return this.userRepository.update(id, user);
  }

  deleteUser(id: number) {
    return this.userRepository.delete(id);
  }
>>>>>>> master
}
