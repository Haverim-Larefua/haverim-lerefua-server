import {Controller, Get, Post, Put, Param, Body, Logger, Delete, Query} from '@nestjs/common';
import { ParcelsService } from './parcels.service';
import { Parcel } from '../entity/parcel.entity';

@Controller('parcels')
export class ParcelsController {
  constructor(private readonly parcelsService: ParcelsService) {}

  @Get()
  getAllParcels(): Promise<Parcel[]> {
    Logger.log(`[ParcelsController] getAllParcels()`);
    return this.parcelsService.getAllParcels();
  }

  @Get(':id')
  getParcelById(@Param('id') id: number): Promise<Parcel> {
    Logger.log(`[ParcelsController] getParcelById()`);
    return this.parcelsService.getParcelById(id);
  }

  @Get('find/:key')
  getParcelByNo(@Param('key') key: string): Promise<Parcel[]> {
    Logger.log(`[ParcelsController] getParcelByNo()`);
    return this.parcelsService.getParcelByNo(key);
  }
  /**
   * Note: the request should look like this:
   * status/:userId?statuses=1,2
   */
  @Get('status/:userId')
  getParcelsByUserIdForStatuses(
      @Param('userId') userId: number,
      @Query() query,
  ): Promise<Parcel[]> {
    const statuses: number[] = query.statuses.split(',');
    Logger.log(`[ParcelsController] getParcelsByUserIdForStatuses(${userId}, [${statuses}])`);
    return this.parcelsService.getParcelsByUserIdForStatuses(userId, statuses);
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
