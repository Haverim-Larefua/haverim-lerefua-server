import {Injectable, Logger} from '@nestjs/common';
import {UsersService} from '../users/users.service';
import {User} from '../entity/user.entity';
import {JwtService} from '@nestjs/jwt';
import {Admin} from '../entity/admin.entity';
import {AdminsService} from '../admins/admins.service';

export interface IAppTokenPayload {
  id: number;
  username: string;
}

@Injectable()
export class AuthenticationService {

  constructor(private readonly userService: UsersService,
              private readonly adminService: AdminsService,
              private readonly jwtService: JwtService) {

  }

  public loginUser = async (username: string, password: string): Promise<{ user: User, token: string }> => {
    Logger.debug(`[AuthenticationService] loginUser() username: ${username}, password: '*****'`);
    const user: User = await this.userService.validateUser(username, password);
    const jwtPayload: IAppTokenPayload = {
      id: user.id,
      username,
    };
    const token = this.jwtService.sign(jwtPayload);
    delete user.password;
    delete user.salt;
    return { user, token };
  }

  public loginAdmin = async (username: string, password: string): Promise<{ admin: Admin, token: string }> => {
    Logger.debug(`[AuthenticationService] loginAdmin() username: ${username}, password: '*****'`);
    const admin: Admin = await this.adminService.validateAdmin(username, password);
    const jwtPayload: IAppTokenPayload = {
      id: admin.id,
      username,
    };
    const token = this.jwtService.sign(jwtPayload);
    delete admin.password;
    delete admin.salt;
    return { admin, token };
  }

}
