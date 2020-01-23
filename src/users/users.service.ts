import { Injectable } from '@nestjs/common';
import { UserDto } from './dto/user.dto';

@Injectable()
export class UsersService {
    getAllUsers(){
        return "get all users";
    }

    getUserbyId(id: number){
        return "get user by id: " + id;
    }

    createUser(user: UserDto){
        return "create user: " + user;
    }

    updateUser(id: number, user: UserDto){
        return "update user with id: " + id + " with the data: " + user;
    }

    deleteUser(id: number){
        return "delete user with id: " + id;
    }
}
