import {
  Controller,
  Get,
  Post,
  Put,
  Param,
  Body,
  Logger,
} from '@nestjs/common';
import { ParcelsService } from './parcels.service';
import { Parcel } from '../entity/parcel.entity';

@Controller('parcels')
export class ParcelsController {
  constructor(private readonly parcelsService: ParcelsService) {}

  @Get()
  getAllUsers() {
    Logger.log(`call to getAllParcels()`);
    return this.parcelsService.getAllParcels();
  }

  @Get(':id')
  getUserbyId(@Param('id') id: number) {
    return this.parcelsService.getParcelbyId(id);
  }

  @Post()
  CreateUser(@Body() parcel: Parcel) {
    Logger.log(`call to CreateParcel()`);
    return this.parcelsService.createParcel(parcel);
  }

  @Put(':id')
  updateUser(@Param('id') id: number, @Body() parcel: Parcel) {
    Logger.log(`call to updateParcel()`);
    return this.parcelsService.updateParcel(id, parcel);
  }
}
