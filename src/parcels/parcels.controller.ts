import {
  Controller,
  Get,
  Post,
  Put,
  Param,
  Body,
  Logger,
  Delete,
} from '@nestjs/common';
import { ParcelsService } from './parcels.service';
import { Parcel } from '../entity/parcel.entity';

@Controller('parcels')
export class ParcelsController {
  constructor(private readonly parcelsService: ParcelsService) {}

  @Get()
  getAllParcels() {
    Logger.log(`call to getAllParcels()`);
    return this.parcelsService.getAllParcels();
  }

  @Get(':id')
  getParcelbyId(@Param('id') id: number) {
    return this.parcelsService.getParcelbyId(id);
  }

  @Get('find/:key')
  getParcelbyNo(@Param('key') key: string) {
    Logger.log(`call to getParcelbyNo()`);
    return this.parcelsService.findByNo(key);
  }
  

  @Post()
  CreateParcel(@Body() parcel: Parcel) {
    Logger.log(`1call to CreateParcel()`);
    const newParcel = this.parcelsService.findByNo(parcel.no);

    // if (typeof newParcel === 'undefined') {
    //   Logger.log('insert');
    // } else {
    //   Logger.log('update');
    // }

    return this.parcelsService.createParcel(parcel);
  }

  @Put(':id')
  updateParcel(@Param('id') id: number, @Body() parcel: Parcel) {
    Logger.log(`call to updateParcel()`);
    return this.parcelsService.updateParcel(id, parcel);
  }

  @Delete(':id')
  deleteParcelbyId(@Param('id') id: number) {
    return this.parcelsService.deleteParcel(id);
  }
}
