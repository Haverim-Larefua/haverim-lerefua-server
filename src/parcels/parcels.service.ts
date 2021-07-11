import { Injectable, Inject, Logger, InternalServerErrorException, ForbiddenException, BadRequestException, } from '@nestjs/common';
import { Repository, In, } from 'typeorm';
import { Parcel } from '../entity/parcel.entity';
import { dbConnection } from './../db/database.providers';
import { ParcelStatus } from '../enum/status.model';
import { ParcelTracking } from '../entity/parcel.tracking.entity';
import { PushToken } from '../entity/push-token.entity';
import { ISendNewAssignmentPushMessage, PushTokenService, } from '../push-token/push-token.service';
import { IGetAllParcelsQueryString, IParcelResult } from './parcels.controller';
import { User } from 'src/entity/user.entity';
import { I18nService } from 'nestjs-i18n';
import { City } from 'src/entity/city.entity';

@Injectable()
export class ParcelsService {
  constructor(
    @Inject('PARCEL_REPOSITORY')
    private readonly parcelRepository: Repository<Parcel>,
    @Inject('PARCEL_TRACKING_REPOSITORY')
    private readonly parcelTrackingRepository: Repository<ParcelTracking>,
    @Inject('USER_REPOSITORY')
    private readonly userRepository: Repository<User>,
    @Inject('PUSH_TOKEN_REPOSITORY')
    private readonly pushTokenRepository: Repository<PushToken>,
    private readonly pushTokenService: PushTokenService,
    private readonly i18n: I18nService,

  ) { }

  /**
   * Get all parcels
   */
  public async getAllParcels(
    query: IGetAllParcelsQueryString,
  ): Promise<Parcel[]> {
    const {
      cityFilterTerm,
      searchTerm,
      statusFilterTerm,
      freeCondition,
    } = query;
    Logger.log(
      `[ParcelsService] getAllParcels(), return all the parcels with status: ${statusFilterTerm} city: ${cityFilterTerm} search term: ${searchTerm}`,
    );

    const where = this.buildParcelsQueryWhereStatement(query);
    const filteredParcels = this.parcelRepository
      .createQueryBuilder('parcel')
      .leftJoinAndSelect('parcel.user', 'user')
      .leftJoinAndSelect('parcel.parcelTracking', 'parcelTracking')
      .select()
      .where(where);

    if (searchTerm) {
      filteredParcels.andWhere(
        `MATCH(parcel.phone, parcel.customer_name, parcel.customer_id) AGAINST ('${searchTerm}' IN BOOLEAN MODE)`,
      );
    }

    if (freeCondition) {
      filteredParcels.andWhere(freeCondition);
    }

    return filteredParcels.getMany();
  }

  private buildParcelsQueryWhereStatement(query: IGetAllParcelsQueryString) {
    const { cityFilterTerm, statusFilterTerm } = query;
    let where: any = { deleted: false };

    if (cityFilterTerm) {
      where = { ...where, city: cityFilterTerm };
    }

    if (statusFilterTerm) {
      switch (statusFilterTerm) {
        case ParcelStatus.ready:
          where = {
            ...where,
            parcelTrackingStatus: In([
              ParcelStatus.ready,
              ParcelStatus.assigned,
            ]),
          };
          break;
        case ParcelStatus.exception:
          where = { ...where, exception: true };
          break;
        default: {
          where = { ...where, parcelTrackingStatus: statusFilterTerm };
          break;
        }
      }
    }

    return where;
  }

  async getParcelsCityOptions(): Promise<string[]> {
    Logger.log(`[ParcelsService] getParcelsCityOptions()`);
    const cityResults = await this.parcelRepository
      .createQueryBuilder()
      .select('city')
      .distinct(true)
      .where([{ deleted: false }])
      .orderBy('city')
      .getRawMany();

    return cityResults.map(result => result.city);
  }

  /**
   * Get parcel by parcel id
   * @param id
   */
  getParcelById(id: number): Promise<Parcel> {
    return this.parcelRepository.findOne(id, {
      where: [{ deleted: false }],
      relations: ['parcelTracking', 'user'],
    });
  }

  /**
   * Get all parcels belongs to userId, by specific statuses
   * @param userId
   */
  getParcelsByUserIdSpecificStatuses(
    userId: number,
    statuses: string[],
  ): Promise<Parcel[]> {
    Logger.log(
      `[ParcelsService] getParcelsByUserIdSpecificStatuses(${userId}, ${statuses})`,
    );
    return dbConnection
      .getRepository(Parcel)
      .createQueryBuilder('parcel')
      .innerJoinAndSelect('parcel.user', 'user')
      .innerJoinAndSelect('parcel.parcelTracking', 'tracking')
      .where('user.id = :userId')
      .andWhere('parcel.deleted = false')
      .andWhere('parcelTrackingStatus IN (:...statuses)')
      .setParameters({
        userId,
        statuses,
      })
      .getMany();
  }

  /**
   * Get all parcels belongs to userId
   * @param userId
   */
  getParcelsByUserId(userId: number): Promise<Parcel[]> {
    Logger.log(`[ParcelsService] getParcelsByUserId(${userId})`);
    return dbConnection
      .getRepository(Parcel)
      .createQueryBuilder('parcel')
      .innerJoinAndSelect('parcel.user', 'user')
      .innerJoinAndSelect('parcel.parcelTracking', 'tracking')
      .where('user.id = :userId')
      .andWhere('parcel.deleted = false')
      .setParameters({
        userId,
      })
      .getMany();
  }

  /**
   * Get parcels by identity (identity of user)
   * @param key
   * Note: This will return array of parcels
   */
  getParcelByIdentity(identity: string): Promise<Parcel[]> {
    return this.parcelRepository.find({
      where: [
        {
          identity,
          deleted: false,
        },
      ],
      join: {
        alias: 'parcel',
        leftJoinAndSelect: {
          user: 'parcel.user',
          parcel_tracking: 'parcel.parcelTracking',
        },
      },
    });
  }

  private findParcelByUniqProperties(parcel: Parcel): Promise<Parcel> {
    const startDate = new Date(parcel.startDate).toISOString().slice(0, 10);
    const startTime = parcel.startTime;
    const customerId = parcel.customerId;

    return dbConnection
      .getRepository(Parcel)
      .createQueryBuilder('parcel')
      .where('parcel.startTime = :startTime')
      .andWhere('parcel.customerId = :customerId')
      .andWhere('parcel.deleted = false')
      .setParameters({
        startTime,
        customerId,
      })
      .select()
      .andWhere(`Date(parcel.start_date) = '${startDate}'`)
      .getOne();
  }


  async createParcels(parcels: Parcel[]) {
    const result: IParcelResult = {
      added: [],
      errors: [],
    };

    for (let index = 0; index < parcels.length; index++) {
      try {
        const response = await this.createParcel(parcels[index]);
        result.added.push(response);
      } catch (ex) {
        result.errors.push(`שורה ${index + 1}: ${ex.message}`)
      }

    }

    return result;
  }

  /**
   * Create new parcel, and return it
   * While creating the parcel need to create also record in parcel_tracking
   * In case parcelTrackingStatus was not supplied set default "ready" status
   * TODO: need to make transaction to verify both save to parcel and parcel_tracking is done
   * @param parcel
   */
  async createParcel(parcel: Parcel): Promise<Parcel> {

    await this.validateParcel(parcel);

    Logger.debug(`parcel.parcelTrackingStatus: ${parcel.parcelTrackingStatus}`);
    const status: ParcelStatus =
      ParcelStatus[
      parcel.parcelTrackingStatus
        ? parcel.parcelTrackingStatus
        : ParcelStatus.ready
      ];
    Logger.debug(`status: ${status}`);
    if (!status) {
      Logger.error(`Parcel status not valid: ${parcel.parcelTrackingStatus}`);
      throw new BadRequestException(
        `Parcel status not valid: ${parcel.parcelTrackingStatus}`,
      );
    }
    const result: Parcel = await this.parcelRepository.save(parcel);

    // Update parcel_tracking table
    await this.updateParcelsStatus(parcel.currentUserId, status, [result.id]);
    return result;
  }

  private readonly parcelAssignedToUser = 'חבילה שויכה לשליח';
  private readonly notifyUserTitle = 'חברים לרפואה';
  private readonly notifyUserSubTitle = 'שלום';
  private readonly notifyUserMessage = 'ישנן חבילות המוכנות לחלוקה באזורך. אנא היכנס לאפליקצית שליחים לרפואה כדי לבחור את החבילות שרלוונטיות בשבילך.';

  private async validateParcel(parcel: Parcel) {
    if (!parcel.startDate || !parcel.startTime) {
      throw new BadRequestException('חסר תאריך התחלה או שעת התחלה');
    }

    if (!parcel.customerId || parcel.customerId.length == 0) {
      throw new BadRequestException('חסר ת.ז');
    }

    if (!parcel.city) {
      throw new BadRequestException('חסר עיר או עיר לא תקינה');
    }

    const alreadyExists = await this.findParcelByUniqProperties(parcel);
    if (alreadyExists) {
      throw new BadRequestException("החבילה כבר קיימת");
    }
  }

  /**
   * Assign parcels to user, and return the new parcels object with the user.
   * Also send push notification to the user
   * @param userId
   * @param parcelId
   */
  async assignParcelsToUser(
    userId: number,
    parcelIds: number[],
  ): Promise<Parcel[]> {
    Logger.log(`[ParcelsService] parcelIds: ${parcelIds}`);
    const dt = new Date();
    return new Promise<Parcel[]>(async (resolve, reject) => {
      const pushMessages: ISendNewAssignmentPushMessage[] = [];
      const responseParcels: Parcel[] = [];

      for (const parcelId of parcelIds) {
        // Update parcel table, set currentUserId, lastUpdateDate, parcelTrackingStatus
        await dbConnection
          .getRepository(Parcel)
          .createQueryBuilder()
          .update(Parcel)
          .set({
            currentUserId: userId,
            lastUpdateDate: dt,
            parcelTrackingStatus: ParcelStatus.assigned,
          })
          .where('id = :parcelId', { parcelId })
          .execute();

        const parcelTracking: Partial<ParcelTracking> = {
          statusDate: new Date(),
          status: ParcelStatus.assigned,
          parcelId,
          userId,
          comments: this.parcelAssignedToUser,
        };

        await this.addParcelTracking(parcelTracking);

        const currentParcel = await this.getParcelById(parcelId);

        pushMessages.push({
          fullName: currentParcel.customerName,
          fullAddress: currentParcel.address,
          packageId: parcelId,
        });

        responseParcels.push(currentParcel);

        Logger.debug(`[ParcelsService] parcelIds: added parcel: ${parcelId}`);
      }

      try {
        await this.pushMessageToUser(userId, pushMessages);
      } catch (err) {
        reject(err);
      }

      resolve(responseParcels);
    });
  }

  private async pushMessageToUser(
    userId: number,
    pushMessages: ISendNewAssignmentPushMessage[],
  ) {
    const pushToken: PushToken = await this.pushTokenRepository.findOne({
      userId,
    });

    return new Promise((resolve, reject) => {
      if (!pushToken) {
        resolve();
        Logger.warn(`No push token was found to userId=${userId}`);
        return;
      }

      this.pushTokenService
        .sendNewAssignmentPushMessage(pushToken.token, pushMessages)
        .then(() => {
          Logger.debug(`Push notification send to user: ${userId}`);
          resolve();
        })
        .catch(err => {
          Logger.error(
            `Error sending push notification to user: ${userId}`,
            err,
          );
          reject(err);
        });
    });
  }

  /**
   * Unassign parcel from user, and return the new parcel object without the user.
   * @param parcelId
   */
  async unassignParcel(parcelId: number): Promise<Parcel> {
    Logger.log(`[ParcelsService] parcelId: ${parcelId}`);
    const dt = new Date();

    return new Promise<Parcel>(async (resolve) => {
      await this.getParcelById(parcelId);

      // Update parcel table, set currentUserId, lastUpdateDate, parcelTrackingStatus
      await dbConnection
        .getRepository(Parcel)
        .createQueryBuilder()
        .update(Parcel)
        .set({
          currentUserId: null,
          lastUpdateDate: dt,
          parcelTrackingStatus: ParcelStatus.ready,
        })
        .where('id = :parcelId', { parcelId })
        .execute();

      // Add the relevant parcel tracking record
      const parcelTracking: Partial<ParcelTracking> = {
        statusDate: new Date(),
        status: ParcelStatus.ready,
        parcelId,
        userId: null,
        comments: 'השליח הוסר מהחבילה',
      };

      await this.addParcelTracking(parcelTracking);

      const responseParcel = await this.getParcelById(parcelId);

      Logger.debug(`[ParcelsService] parcelId: unassigned parcel: ${parcelId}`);
      resolve(responseParcel);
    });
  }

  /**
   * Adding signature to parcel, also update Parcel tracking status table with status delivered
   * @param userId
   * @param parcelId
   * @param signature
   */
  async addParcelSignature(
    userId: number,
    parcelId: number,
    signature: string,
    comment: string,
  ): Promise<Parcel> {
    Logger.log(`[ParcelsService] addParcelSignature: ${parcelId}`);
    const parcel: Parcel = await this.getParcelById(parcelId);
    if (!parcel) {
      throw new InternalServerErrorException(
        `Parcel ${parcelId} was not found`,
      );
    }
    Logger.log(`[ParcelsService] parcel: ${JSON.stringify(parcel)}`);
    parcel.currentUserId = userId;
    parcel.signature = signature;
    const result: Parcel = await this.parcelRepository.save(parcel);

    // Update parcel_tracking table
    await this.updateParcelsStatus(
      parcel.currentUserId,
      ParcelStatus.delivered,
      [result.id],
      comment,
    );

    return this.getParcelById(parcelId);
  }

  async updateParcelWithException(parcelId: number, exception: string) {
    const parcel = await this.getParcelById(parcelId);
    parcel.exception = true;
    await this.parcelRepository.save(parcel);

    const exceptionMessage = exception ? ` - ${exception}` : '';
    const parcelTracking: Partial<ParcelTracking> = {
      status: parcel.parcelTrackingStatus,
      parcelId,
      userId: parcel.currentUserId,
      comments: `חבילה עברה לחריגה${exceptionMessage}`,
    };
    await this.addParcelTracking(parcelTracking);
  }

  updateParcelsStatus(
    userId: number,
    status: ParcelStatus,
    parcelsIds: number[],
    comment: string = '',
  ): Promise<number[]> {
    Logger.log(
      `[ParcelsService] updateParcelsStatus(${userId}, ${status}, ${comment}, ${parcelsIds})`,
    );

    const finalStatus = this.getFinalStatus(status, userId);

    return new Promise<number[]>((resolve) => {
      parcelsIds.forEach(async (id: number) => {
        await dbConnection
          .getRepository(Parcel)
          .createQueryBuilder()
          .update(Parcel)
          .set({
            parcelTrackingStatus: finalStatus,
            lastUpdateDate: new Date(),
            exception: false,
          })
          .where('id = :id', { id })
          .execute();

        const parcelTracking: Partial<ParcelTracking> = {
          statusDate: new Date(),
          status: finalStatus,
          comments: comment,
          parcelId: id,
          userId,
        };
        await this.addParcelTracking(parcelTracking);
      });
      resolve(parcelsIds);
    });
  }

  addParcelTracking = (
    parcelTracking: Partial<ParcelTracking>,
  ): Promise<ParcelTracking> => {
    return this.parcelTrackingRepository.save(parcelTracking);
  };

  private getFinalStatus(status: ParcelStatus, userId: number) {
    let finalStatus = status;
    if (userId && status === ParcelStatus.ready) {
      finalStatus = ParcelStatus.assigned;
    }
    return finalStatus;
  }

  /**s
   * Update parcel by id
   * @param id
   * @param parcel
   */
  async updateParcel(id: number, parcel: Parcel): Promise<Parcel> {
    await this.parcelRepository.update(id, parcel);
    return this.getParcelById(id);
  }

  async canDeleteParcel(id): Promise<Parcel> {
    const parcel: Parcel = await this.getParcelById(id);

    if (!parcel) {
      Logger.error(
        `[ParcelsService] canDeleteParcel  Parcel ${id} was not found`,
      );
      throw new BadRequestException(`Parcel ${id} was not found`);
    }
    if (
      parcel.parcelTrackingStatus !== ParcelStatus.ready &&
      parcel.parcelTrackingStatus !== ParcelStatus.assigned
    ) {
      Logger.error(
        `[ParcelsService] canDeleteParcel  Parcel ${id} status not ready or assigned`,
      );
      throw new ForbiddenException(`Parcel ${id} status not ready or assigned`);
    }

    return parcel;
  }

  async markParcelAsDeleted(id: number): Promise<Parcel> {
    let parcel: Parcel = await this.canDeleteParcel(id);

    //unassign this parcel && change its status to ready
    if (parcel.parcelTrackingStatus === ParcelStatus.assigned) {
      parcel = await this.unassignParcel(id);
    }

    // mark parcel as deleted
    Logger.log(
      `[ParcelsService] markParcelAsDeleted parcel: ${JSON.stringify(parcel)}`,
    );
    parcel.deleted = true;
    const result: Parcel = await this.parcelRepository.save(parcel);
    return result;
  }

  async removeParcel(id: number) {
    const parcel: Parcel = await this.canDeleteParcel(id);

    //unassign this parcel && change its status to ready
    if (parcel.parcelTrackingStatus === ParcelStatus.assigned) {
      await this.unassignParcel(id);
    }

    // delete parcel
    return await this.parcelRepository.delete(id);
  }

  /**
   * Delete parcel by id
   * @param id
   * @param keep if true only mark this parcel as deleted but keep it in DB
   */
  async deleteParcel(id: number, keep: boolean) {
    if (keep) {
      return await this.markParcelAsDeleted(id);
    } else {
      return await this.removeParcel(id);
    }
  }

  async notifyParcelsToUsers(parcelIds: number[]): Promise<void> {
    Logger.log(`[ParcelsService] notifyParcelsToUsers parcelIds: ${JSON.stringify(parcelIds)}`,);
    const parcels = await this.getReadyParcelWithoutUserByIds(parcelIds);
    Logger.log(`[ParcelsService] notifyParcelsToUsers parcels: ${JSON.stringify(parcels)}`,);
    if (parcels.length > 0) {
      const parcelCities = parcels.map(parcel => parcel.city);
      const users = await this.getUsersByCities(parcelCities);
      Logger.log(`[ParcelsService] notifyParcelsToUsers users: ${JSON.stringify(users)}`);
      const parcelIdsPerUserMap = new Map<number, number[]>();
      parcels.forEach(parcel => {
        users.filter(user => user.cities.includes(parcel.city)).forEach(user => {
          if (!parcelIdsPerUserMap.has(user.id)) {
            parcelIdsPerUserMap.set(user.id, [parcel.id]);
          } else {
            parcelIdsPerUserMap[user.id].push(parcel.id);
          }
        })
      })
      parcelIdsPerUserMap.forEach((parcelIdsPerUser: number[], userId) => {
        const currentUser = users.find(u => u.id === userId);
        const name = currentUser ? `${currentUser.firstName} ${currentUser.lastName}` : '';
        const title = this.notifyUserTitle;
        const subTitle = `${this.notifyUserSubTitle} ${name}`;
        const message = this.notifyUserMessage;
        Logger.log(`[ParcelsService] notifyParcelsToUsers userId: ${userId} (${name} ) - parcelIds: ${JSON.stringify(parcelIdsPerUser)}`,);

        this.pushTokenService.notifyUserPushMessage(userId, title, subTitle, message, parcelIdsPerUser).catch(() => {
          throw new InternalServerErrorException(`!Error sending push notification to users`);
        });
      })
    }

  }

  async getReadyParcelWithoutUserByIds(parcelIds: number[]): Promise<Parcel[]> {
    return await this.parcelRepository.createQueryBuilder('parcel')
      .whereInIds(parcelIds)
      .andWhere('parcel.deleted = false')
      .andWhere('parcel.currentUserId IS NULL')
      .andWhere("parcel.parcelTrackingStatus IN (:...status)", { status: [ParcelStatus.ready] })
      .getMany()
  }

  async getUsersByCities(cities: City[]): Promise<User[]> {
    return await this.userRepository.createQueryBuilder('users')
      .where('users.active = true')
      .andWhere("users.cities IN (:...cities)", { cities })
      .getMany()
  }
}
