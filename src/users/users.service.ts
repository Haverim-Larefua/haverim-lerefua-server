import {Injectable, Inject, Logger, UnauthorizedException} from '@nestjs/common';
import { User } from '../entity/user.entity';
import {Repository, Like} from 'typeorm';
import {IPassword, saltHashPassword, sha512} from '../utils/crypto';

@Injectable()
export class UsersService {
  constructor(
    @Inject('USER_REPOSITORY')
    private readonly userRepository: Repository<User>,
  ) {}

  /**
   * Return all users
   */
  async getAllUsers(): Promise<User[]> {
    return this.userRepository.find({});
  }

  /**
   * Get user by his id, joining the parcels belongs to user and the parcel tracking status
   * @param id
   */
  async getUserbyId(id: number): Promise<User> {
    const user: User = await this.userRepository.findOne({
      where: {
        id,
      },
      join: {
        alias: 'person',
        leftJoinAndSelect: {
          parcels: 'person.parcels',
          parcel_tracking: 'parcels.parcelTracking',
        },
      },
    });
    return user;
    // return this.userRepository.findOne(id, {
    //   relations: ['role', 'parcels'],
    // });
  }

  /**
   * Get all users that there firstName or lastName is like the given string
   * @param name
   */
  async getUsersByName(name: string): Promise<User[]> {
    Logger.log(`call to getUserByName: '${name}'`);
    const users: User[] = await this.userRepository.find({
      where: [
        { firstName: Like(`%${name}%`) },
        { lastName: Like(`%${name}%`) },
      ],
      join: {
        alias: 'person',
        leftJoinAndSelect: {
          parcels: 'person.parcels',
          parcel_tracking: 'parcels.parcelTracking',
        },
      },
    });
    return users;
  }

  /**
   * Create User in DB, this method will create random hash and merge to it the password, then generate hash that
   * will be saved in database.
   * @param user
   * Note: Return 201 in case of success (and the user id that was created)
   */
  async createUser(user: User): Promise<{ id: number }> {
    const pass: IPassword = saltHashPassword(user.password);
    user.password = pass.hash;
    user.salt = pass.salt;
    Logger.debug(`[AuthenticationService] createUser() user: ${JSON.stringify(user)}`);
    const result: User = await this.userRepository.save(user);
    return {
      id: result.id,
    };
  }

  /**
   * Update the user in DB, if password was supplied, create new hash (with salt) for it
   * @param id
   * @param user
   * Note: Return 201 in case of success (does not return the user)
   */
  async updateUser(id: number, user: User): Promise<void> {
    if (user.password) {
      const pass: IPassword = saltHashPassword(user.password);
      user.password = pass.hash;
      user.salt = pass.salt;
    }
    await this.userRepository.update(id, user);
  }

  /**
   * Delete the user
   * @param id
   * Note: Return 200 in case of success (does not return the user)
   */
  async deleteUser(id: number): Promise<void> {
    await this.userRepository.delete(id);
  }

  /**
   * Validate user when performing login
   * @param username
   * @param password
   * Note: we use query select to get the password and salt needed for the validation.
   * In User entity password and salt will not return (@Column({ select: false }))
   */
  async validateUser(username: string, password: string): Promise<User> {
    const user =  await this.userRepository.findOne({
      select: ['firstName', 'lastName', 'address', 'deliveryArea', 'deliveryDays', 'phone', 'roleId', 'notes', 'username', 'password', 'salt'],
      where: [ { username } ],
    });
    if (!user || Object.keys(user).length === 0) {
      Logger.error(`[AuthenticationService] login() error with user credentials: ${username}`);
      throw new UnauthorizedException();
    }
    const dbPass = sha512(password, user.salt).hash;
    if (dbPass !== user.password) {
      throw new UnauthorizedException();
    }
    Logger.debug(`[AuthenticationService] login() user: ${JSON.stringify(user)}`);
    return user;
  }

}
