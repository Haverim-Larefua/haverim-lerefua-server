import { Controller, Get, Param, Post, Body, Put, Delete } from '@nestjs/common';
import { UsersService } from './users.service';
import { UserDto } from './dto/user.dto';

@Controller('users')
export class UsersController {
    constructor (private readonly usersService: UsersService) {}
    
    @Get()
    getAllUsers() {
        return this.usersService.getAllUsers();
    }

    @Get(':id')
    getUserbyId(@Param('id') id: number) {
        return this.usersService.getUserbyId(id);
    }

    @Post()
    CreateUser(@Body() user: UserDto) {
        console.log(user);
        return this.usersService.createUser(user);
    }

    @Put(':id')
    updateUser(@Param('id') id: number, @Body() user: UserDto) {
        console.log(user);
        return this.usersService.updateUser(id, user);
    }

    @Delete(':id')
    deleteUser(@Param('id') id: number) {
        console.log(id);
        return this.usersService.deleteUser(id);
    }
}
