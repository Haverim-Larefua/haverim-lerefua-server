import {Injectable, Logger} from '@nestjs/common';
import {UsersService} from '../users/users.service';
import {User} from '../entity/user.entity';
import {JwtService} from '@nestjs/jwt';
import {Admin} from '../entity/admin.entity';
import {AdminsService} from '../admins/admins.service';
import {environment} from '../env';
import {dbConnection} from '../db/database.providers';

export interface IAppTokenPayload {
  id: number;
  username: string;
}

export interface IAuthAdminResponse {
  admin: Admin;
  token: string;
}

export interface IAuthUserResponse {
  user: User;
  token: string;
  refreshToken: string;
}

@Injectable()
export class AuthenticationService {

  constructor(private readonly userService: UsersService,
              private readonly adminService: AdminsService,
              private readonly jwtService: JwtService) {

  }

  public loginUser = async (username: string, password: string): Promise<IAuthUserResponse> => {
    Logger.debug(`[AuthenticationService] loginUser() username: ${username}, password: '*****'`);
    const user: User = await this.userService.validateUser(username, password);
    const userId = user.id;
    const jwtPayload: IAppTokenPayload = {
      id: user.id,
      username,
    };
    const token = this.jwtService.sign(jwtPayload);
    const refreshToken = this.generateRefreshToken(user.id);

    this.clearUserSecuredData(user);
    await this.updateRefreshTokenForUser(userId, refreshToken);

    return { user, token, refreshToken } as IAuthUserResponse;
  }

  public loginAdmin = async (username: string, password: string): Promise<IAuthAdminResponse> => {
    Logger.debug(`[AuthenticationService] loginAdmin() username: ${username}, password: '*****'`);
    const admin: Admin = await this.adminService.validateAdmin(username, password);
    const jwtPayload: IAppTokenPayload = {
      id: admin.id,
      username,
    };
    const token = this.jwtService.sign(jwtPayload);
    delete admin.password;
    delete admin.salt;
    return { admin, token } as IAuthAdminResponse;
  }

  public refreshToken = async (refreshToken: string): Promise<IAuthUserResponse> => {
    Logger.debug(`[AuthenticationService] refreshToken(${refreshToken})`);
    const user: User = await this.userService.getUserByRefreshToken(refreshToken);
    const jwtPayload: IAppTokenPayload = {
      id: user.id,
      username: user.username,
    };
    this.clearUserSecuredData(user);
    return {
      user,
      token: this.jwtService.sign(jwtPayload),
      refreshToken: this.generateRefreshToken(user.id),
    };
  }

  private updateRefreshTokenForUser = async (userId: number, refreshToken: string) => {
    return dbConnection
        .getRepository(User)
        .createQueryBuilder()
        .update(User)
        .set({ refreshToken })
        .where('id = :userId', { userId })
        .execute();
  }

  private clearUserSecuredData = (user: User): void => {
    delete user.password;
    delete user.salt;
    delete user.refreshToken;
  }

  private generateRefreshToken = (userId: number): string => {
    const refreshToken = this.jwtService.sign({ userId }, { expiresIn: environment.REFRESH_TOKEN_LIFE });
    return refreshToken;
  }

}
