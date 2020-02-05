import { Controller, Get, Post, Put, Param, Body, Logger, Delete } from '@nestjs/common';
import { ParcelsService } from './parcels.service';
import { Parcel } from '../entity/parcel.entity';

@Controller('parcels')
export class ParcelsController {
  constructor(private readonly parcelsService: ParcelsService) {}

  @Get()
  getAllParcels() {
    Logger.log(`[ParcelsController] getAllParcels()`);
    return this.parcelsService.getAllParcels();
  }

  @Get(':id')
  getParcelbyId(@Param('id') id: number) {
    Logger.log(`[ParcelsController] getParcelbyId()`);
    return this.parcelsService.getParcelbyId(id);
  }

  @Get('find/:key')
  getParcelbyNo(@Param('key') key: string) {
    Logger.log(`[ParcelsController] getParcelbyNo()`);
    return this.parcelsService.getParcelbyNo(key);
  }

  @Post()
  CreateParcel(@Body() parcel: Parcel) {
    Logger.log(`[ParcelsController] CreateParcel()`);
    return this.parcelsService.createParcel(parcel);
  }

  @Put('assign/:userId/:parcelId')
  assignParcelToUser(
      @Param('userId') userId: number,
      @Param('parcelId') parcelId: number): Promise<Parcel> {
    Logger.log(`[ParcelsController] assignParcelToUser(${userId}, ${parcelId})`);
    return this.parcelsService.assignParcelToUser(userId, parcelId);
  }

    // @Post()
  // CreateParcels(@Body() parcels: Parcel[]) {
  //   /*Logger.log(`[ParcelsController] CreateParcels()`);
  //   const newParcel = this.parcelsService.findByNo(parcel.no); */
  //   return '';
  // }

  @Put(':id')
  updateParcel(@Param('id') id: number, @Body() parcel: Parcel) {
    Logger.log(`[ParcelsController] updateParcel()`);
    return this.parcelsService.updateParcel(id, parcel);
  }

  @Delete(':id')
  deleteParcelbyId(@Param('id') id: number) {
    Logger.log(`[ParcelsController] deleteParcelbyId()`);
    return this.parcelsService.deleteParcel(id);
  }
}
