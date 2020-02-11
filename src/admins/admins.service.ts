import {Injectable, Inject, Logger, UnauthorizedException} from '@nestjs/common';
import {Repository } from 'typeorm';
import {IPassword, saltHashPassword, sha512} from '../utils/crypto';
import {Admin} from '../entity/admin.entity';

@Injectable()
export class AdminsService {
  constructor(
    @Inject('ADMIN_REPOSITORY')
    private readonly adminRepository: Repository<Admin>,
  ) {}

  /**
   * Return all admins
   */
  async getAllAdmins(): Promise<Admin[]> {
    Logger.log(`[AdminsService] getAllAdmins()`);
    return this.adminRepository.find({ });
  }

  /**
   * Get admin by his id
   * @param id
   */
  async getAdminById(id: number): Promise<Admin> {
    Logger.log(`[AdminsService] getAdminById(${id})`);
    return this.adminRepository.findOne({ id });
  }

  /**
   * Create Admin in DB, this method will create random hash (salt) and merge to it the password, then generate hash that
   * will be saved in database.
   * @param admin
   * Note: Return 201 in case of success (and the user id that was created)
   */
  async createAdmin(admin: Admin): Promise<{ id: number }> {
    Logger.log(`[AdminsService] createAdmin()`);
    const pass: IPassword = saltHashPassword(admin.password);
    admin.password = pass.hash;
    admin.salt = pass.salt;
    const result: Admin = await this.adminRepository.save(admin);
    return {
      id: result.id,
    };
  }

  /**
   * Update the Admin in DB, if password was supplied, create new hash (with salt) for it
   * @param id
   * @param admin
   * Note: Return 201 in case of success (does not return the admin)
   */
  async updateAdmin(id: number, admin: Admin): Promise<void> {
    Logger.log(`[AdminsService] updateAdmin(${id})`);
    if (admin.password) {
      const pass: IPassword = saltHashPassword(admin.password);
      admin.password = pass.hash;
      admin.salt = pass.salt;
    }
    await this.adminRepository.update(id, admin);
  }

  /**
   * Delete the admin
   * @param id
   * Note: Return 200 in case of success (does not return the admin)
   */
  async deleteAdmin(id: number): Promise<void> {
    Logger.log(`[AdminsService] deleteAdmin(${id})`);
    await this.adminRepository.delete(id);
  }

  /**
   * Validate admin when performing login
   * @param username
   * @param password
   * Note: we use query select to get the password and salt needed for the validation.
   * In User entity password and salt will not return (@Column({ select: false }))
   */
  async validateAdmin(username: string, password: string): Promise<Admin> {
    Logger.log(`[AdminsService] validateAdmin(${username},'*****')`);
    const admin =  await this.adminRepository.findOne({
      select: ['id', 'username', 'firstName', 'lastName', 'password', 'salt'],
      where: [ { username } ],
    });
    if (!admin || Object.keys(admin).length === 0) {
      Logger.error(`[AdminsService] validateAdmin() error with admin credentials: ${username}`);
      throw new UnauthorizedException();
    }
    const dbPass = sha512(password, admin.salt).hash;
    if (dbPass !== admin.password) {
      throw new UnauthorizedException();
    }
    Logger.debug(`[AdminsService] validateAdmin() admin: ${JSON.stringify(admin)}`);
    return admin;
  }

}
