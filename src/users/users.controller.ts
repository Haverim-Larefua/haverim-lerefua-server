import { Controller, Get, Delete, Param, Post, Body, Put, Logger } from '@nestjs/common';
import { UsersService } from './users.service';
import { User } from '../entity/user.entity';

@Controller('users')
export class UsersController {
  constructor(private readonly usersService: UsersService) {}

  @Get()
  getAllUsers(): Promise<User[]> {
    return this.usersService.getAllUsers();
  }

  @Get(':id')
  getUserbyId(@Param('id') id: number): Promise<User> {
    Logger.log('call to getUserbyId');
    return this.usersService.getUserbyId(id);
  }

  @Get('name/:name')
  getUserByName(@Param('name') name: string): Promise<User[]> {
    return this.usersService.getUsersByName(name);
  }

  @Post()
  CreateUser(@Body() user: User): Promise<{ id: number }> {
    return this.usersService.createUser(user);
  }

  @Put(':id')
  updateUser(@Param('id') id: number, @Body() user: User): Promise<void> {
    return this.usersService.updateUser(id, user);
  }

  @Delete(':id')
  deleteUser(@Param('id') id: number): Promise<void> {
    return this.usersService.deleteUser(id);
  }

}
