import {
  Controller,
  Get,
  Param,
  Post,
  Body,
  Put,
  Logger,
} from '@nestjs/common';
import { UsersService } from './users.service';
import { User } from '../entity/user.entity';

@Controller('users')
export class UsersController {
  constructor(private readonly usersService: UsersService) {}

  @Get()
  getAllUsers() {
    return this.usersService.getAllUsers();
  }

  @Get(':id')
  getUserbyId(@Param('id') id: number) {
    Logger.log('call to getUserbyId');
    return this.usersService.getUserbyId(id);
  }

  @Get('parcels/all')
  getAllParcels() {
    Logger.log('call to getParcelsForAllUsers');
    return this.usersService.getParcelsForAllUsers();
  }

  @Get('parcels/:id')
  getParcelsByUser(@Param('id') id: number) {
    Logger.log('call to getParcelsById');
    return this.usersService.getParcelsForAUser(id);
  }

  @Post()
  CreateUser(@Body() user: User) {
    return this.usersService.createUser(user);
  }

  @Put(':id')
  updateUser(@Param('id') id: number, @Body() user: User) {
    return this.usersService.updateUser(id, user);
  }
  @Get('username/:name')
  getUserByName(@Param('name') name: string) {
    return this.usersService.getUserByName(name);
  }
}
