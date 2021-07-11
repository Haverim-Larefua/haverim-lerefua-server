import {
  Controller,
  Get,
  Delete,
  Param,
  Post,
  Body,
  Put,
  Logger,
  ClassSerializerInterceptor,
  UseInterceptors,
  Query,
} from '@nestjs/common';
import { UsersService } from './users.service';
import { User } from '../entity/user.entity';

export interface IGetAllUsersQueryString {
  dayFilter?: string;
  nameFilter?: string;
}

@Controller('users')
@UseInterceptors(ClassSerializerInterceptor)
export class UsersController {
  constructor(private readonly usersService: UsersService) {}

  @Get()
  getAllUsers(@Query() query: IGetAllUsersQueryString): Promise<User[]> {
    Logger.log(`[UsersController] getAllUsers()`, JSON.stringify(query));
    return this.usersService.getAllUsers(query);
  }


  @Get(':id')
  getUserById(@Param('id') id: number): Promise<User> {
    Logger.log(`[UsersController] getUserById(${id})`);
    return this.usersService.getUserById(id);
  }

  @Get('name/:name')
  getUserByName(@Param('name') name: string): Promise<User[]> {
    Logger.log(`[UsersController] getUserByName(${name})`);
    return this.usersService.getUsersByName(name);
  }

  @Post()
  CreateUser(@Body() user: User): Promise<{ id: number }> {
    Logger.log(`[UsersController] CreateUser()`);
    return this.usersService.createUser(user);
  }

  @Put(':id')
  updateUser(@Param('id') id: number, @Body() user: User): Promise<void> {
    Logger.log(`[UsersController] updateUser(${id})`);
    return this.usersService.updateUser(id, user);
  }

  @Delete(':id')
  deleteUser(@Param('id') id: number): Promise<void> {
    Logger.log(`[UsersController] deleteUser(${id})`);
    return this.usersService.deleteUser(id);
  }
}
