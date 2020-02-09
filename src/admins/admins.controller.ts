import {Controller, Get, Delete, Param, Post, Body, Put, Logger } from '@nestjs/common';
import { AdminsService } from './admins.service';
import {Admin} from '../entity/admin.entity';

@Controller('admins')
export class AdminsController {
  constructor(private readonly adminsService: AdminsService) {}

  @Get()
  getAllAdmins(): Promise<Admin[]> {
    Logger.log('[AdminsController] getAllAdmins()');
    return this.adminsService.getAllAdmins();
  }

  @Get(':id')
  getAdminById(@Param('id') id: number): Promise<Admin> {
    Logger.log(`[AdminsController] getAdminById(${id})`);
    return this.adminsService.getAdminById(id);
  }

  @Post()
  createAdmin(@Body() admin: Admin): Promise<{ id: number }> {
    Logger.log(`[AdminsController] createAdmin()`);
    return this.adminsService.createAdmin(admin);
  }

  @Put(':id')
  updateAdmin(@Param('id') id: number, @Body() admin: Admin): Promise<void> {
    Logger.log(`[AdminsController] updateAdmin(${id})`);
    return this.adminsService.updateAdmin(id, admin);
  }

  @Delete(':id')
  deleteAdmin(@Param('id') id: number): Promise<void> {
    Logger.log(`[AdminsController] deleteAdmin(${id})`);
    return this.adminsService.deleteAdmin(id);
  }

}
