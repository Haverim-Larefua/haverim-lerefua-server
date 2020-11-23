import {
  Injectable,
  Inject,
  Logger,
  UnauthorizedException,
  InternalServerErrorException,
  NotFoundException,
  BadRequestException,
} from '@nestjs/common';
import { User } from '../entity/user.entity';
import { Repository, Like } from 'typeorm';
import { IPassword, saltHashPassword, sha512 } from '../utils/crypto';
import { ParcelsService } from '../parcels/parcels.service';
import { ParcelStatus } from '../enum/status.model';

@Injectable()
export class UsersService {
  constructor(
    @Inject('USER_REPOSITORY')
    private readonly userRepository: Repository<User>,
    private readonly parcelsService: ParcelsService,
  ) {}

  /**
   * Return all users
   */
  async getAllUsers(): Promise<User[]> {
    Logger.log(`[UsersService] getAllUsers()`);
    return this.userRepository.find();
  }

  /**
   * Get user by his id, joining the parcels belongs to user and the parcel tracking status
   * @param id
   */
  async getUserById(id: number): Promise<User> {
    Logger.log(`[UsersService] getUserbyId(${id})`);
    const user: User = await this.userRepository.findOne({
      where: {
        id,
        active: true,
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
  }

  /**
   * Get all users that there firstName or lastName is like the given string
   * @param name
   */
  async getUsersByName(name: string): Promise<User[]> {
    Logger.log(`[UsersService] getUserByName(${name})`);
    const users: User[] = await this.userRepository.find({
      where: [
        { firstName: Like(`%${name}%`) },
        { lastName: Like(`%${name}%`) },
        { active: true },
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
   * Create User in DB, this method will create random hash (salt) and merge to it the password, then generate hash that
   * will be saved in database.
   * @param user
   * Note: Return 201 in case of success (and the user id that was created)
   */
  async createUser(user: User): Promise<{ id: number }> {
    Logger.log(`[UsersService] createUser(${JSON.stringify(user)})`);
    const pass: IPassword = saltHashPassword(user.password);
    user.password = pass.hash;
    user.salt = pass.salt;
    user.active = true;
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
    Logger.log(`[UsersService] updateUser(${id}, ${JSON.stringify(user)})`);
    const existingUser = await this.getUserById(id);
    if (!existingUser) {
      throw new InternalServerErrorException(`User ${id} was not found`);
    }
    if (user.password) {
      const pass: IPassword = saltHashPassword(user.password);
      user.password = pass.hash;
      user.salt = pass.salt;
    }
    if (!user.username) {
      user.username = existingUser.username;
    }
    delete user.refreshToken;

    await this.userRepository.update(id, user);
  }

  /**
   * Delete the user, note this is not really deleting but updating the active parameter to false
   * @param id
   * Note: Return 200 in case of success (does not return the user)
   */
  async deleteUser(id: number): Promise<void> {
    Logger.log(`[UsersService] deleteUser(${id})`);
    const detailedUser: User = await this.getUserById(id);

    if (!detailedUser) {
      throw new NotFoundException();
    }

    if (detailedUser.parcels) {
      if (
        detailedUser.parcels.find(
          parcel => parcel.parcelTrackingStatus === ParcelStatus.distribution,
        )
      ) {
        throw new BadRequestException(
          `User with id ${id} has parcels in distribution status assigned, and therefore can not be deleted`,
        );
      }
    }

    const user: User = await this.userRepository.findOne({ id });

    user.active = false;
    await this.userRepository.update(id, user);
    // await this.userRepository.delete(id);

    // Unassign parcels
    const userParcels = await this.parcelsService.getParcelsByUserId(id);
    const unassignParcelPromises = userParcels
      .filter(parcel => parcel.parcelTrackingStatus === ParcelStatus.assigned) // Unassign assigned parcels only
      .map(parcel => this.parcelsService.unassignParcel(parcel.id));

    await Promise.all(unassignParcelPromises);
  }

  /**
   * Validate user when performing login
   * @param username
   * @param password
   * Note: we use query select to get the password and salt needed for the validation.
   * In User entity password and salt will not return (@Column({ select: false }))
   */
  async validateUser(username: string, password: string): Promise<User> {
    Logger.log(`[UsersService] validateUser(${username},'*****')`);
    const user = await this.userRepository.findOne({
      select: [
        'id',
        'username',
        'firstName',
        'lastName',
        'password',
        'salt',
        'active',
      ],
      where: [{ username, active: true }],
    });
    if (!user || Object.keys(user).length === 0) {
      Logger.error(
        `[UsersService] validateUser() error with user credentials: ${username}`,
      );
      throw new UnauthorizedException();
    }
    const dbPass = sha512(password, user.salt).hash;
    if (dbPass !== user.password) {
      throw new UnauthorizedException();
    }

    Logger.debug(`[UsersService] validateUser() user: ${JSON.stringify(user)}`);
    return user;
  }

  async getUserByRefreshToken(refreshToken: string): Promise<User> {
    Logger.log(`[UsersService] getUserByRefreshToken(${refreshToken})`);
    const user = await this.userRepository.findOne({
      select: [
        'id',
        'username',
        'firstName',
        'lastName',
        'password',
        'salt',
        'active',
      ],
      where: [{ refreshToken, active: true }],
    });
    if (!user || Object.keys(user).length === 0) {
      Logger.error(
        `[UsersService] getUserByRefreshToken() error getting user by refreshToken: ${refreshToken}`,
      );
      throw new UnauthorizedException();
    }
    return user;
  }
}
