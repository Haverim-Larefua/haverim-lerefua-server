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
import { IGetAllUsersQueryString } from './users.controller';
import { SMSService } from 'src/utils/sms.service';

@Injectable()
export class UsersService {
  constructor(
    @Inject('USER_REPOSITORY')
    private readonly userRepository: Repository<User>,
    private readonly parcelsService: ParcelsService,
  ) { }

  /**
   * Return all users
   */
  async getAllUsers(query: IGetAllUsersQueryString): Promise<User[]> {
    Logger.log(`[UsersService] getAllUsers()`);
    const select = this.userRepository
      .createQueryBuilder('user')
      .leftJoinAndSelect('user.cities', 'cities')
      .leftJoinAndSelect("cities.district", "district")
      .leftJoinAndSelect("cities.subdistrict", "subdistrict")
      .select()
      .where(this.buildUsersQueryWhereStatement(query));

    if (query.nameFilter) {
      select.andWhere(
        `MATCH(first_name, last_name, phone) AGAINST ('${query.nameFilter}' IN BOOLEAN MODE)`,
      );
    }
    return select.getMany();
  }

  private buildUsersQueryWhereStatement(query: IGetAllUsersQueryString) {
    const { cityFilter, dayFilter } = query;
    let where = "1 = 1 ";

    if (cityFilter) {
      where += `and cities.id IN (${cityFilter}) `;
    }

    if (dayFilter) {
      where += `and delivery_days LIKE '%${dayFilter}%' `;
    }

    return where;
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
      },
      join: {
        alias: 'person',
        leftJoinAndSelect: {
          parcels: 'person.parcels',
          parcel_tracking: 'parcels.parcelTracking',
          cities: 'person.cities'
        },
      },

    });

    return user;
  }

  async getUserByPhoneNumber(phone: string): Promise<User> {
    Logger.log(`[UsersService] getUserByPhone(${phone})`);
    const user: User = await this.userRepository.findOne({
      where: {
        phone,
      }
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
          cities: 'person.cities',
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
    if (!user.username) {
      user.username = existingUser.username;
    }
    delete user.refreshToken;

    await this.userRepository.save(user);
  }

  async updatePassword(id: number, password: string): Promise<void> {
    const existingUser = await this.getUserById(id);
    if (!existingUser) {
      throw new InternalServerErrorException(`User ${id} was not found`);
    }

    await this.saveNewPassword(password, existingUser);
  }

  private async saveNewPassword(password: string, existingUser: User) {
    const pass: IPassword = saltHashPassword(password);
    existingUser.password = pass.hash;
    existingUser.salt = pass.salt;
    delete existingUser.refreshToken;
    existingUser.new = false;

    await this.userRepository.save(existingUser);
  }

  async forgotPassword(phoneNumber: string): Promise<User> {
    const existingUser = await this.getUserByPhoneNumber(phoneNumber);
    if (!existingUser) {
      throw new UnauthorizedException(`User with phone number: ${phoneNumber} was not found`);
    }

    const password = Math.random().toString(36).substring(7);
    SMSService.sendSMS(phoneNumber, `The new code is': ${password}`)

    this.saveNewPassword(password, existingUser);
    return existingUser;
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
        'new',
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
