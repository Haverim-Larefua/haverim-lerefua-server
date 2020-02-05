import {Injectable, Logger} from '@nestjs/common';
import {UsersService} from '../users/users.service';
import {User} from '../entity/user.entity';
import {JwtService} from '@nestjs/jwt';
import {IToken} from './authentication.controller';

@Injectable()
export class AuthenticationService {

  constructor(private readonly userService: UsersService,
              private readonly jwtService: JwtService) {

  }

  public login = async (username: string, password: string): Promise<{ user: User, token: string }> => {
    Logger.debug(`[AuthenticationService] login() username: ${username}, password: '*****'`);
    const user: User = await this.userService.validateUser(username, password);
    const jwtPayload = {
      id: user.id,
      username,
    };
    const token = this.jwtService.sign(jwtPayload);
    delete user.password;
    delete user.salt;
    return { user, token };
  }

}
