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

  @Get('identity/:identity')
  getParcelByIdentity(@Param('identity') identity: string): Promise<Parcel[]> {
    Logger.log(`[ParcelsController] getParcelByIdentity(${identity})`);
    return this.parcelsService.getParcelByIdentity(identity);
  }
  /**
   * Note: the request can get also query params with the relevant statuses to return
   * the request should look like this:
   * user/:userId?last_statuses=delivered,ready
   */
  @Get('user/:userId')
  getParcelsByUserId(
      @Param('userId') userId: number,
      @Query() query,
  ): Promise<Parcel[]> {
    Logger.log(`[ParcelsController] getParcelsByUserId(${userId}, ${JSON.stringify(query)})`);
    if (query.last_statuses) {
      const statuses: string[] = query.last_statuses.split(',');
      return this.parcelsService.getParcelsByUserIdSpecificStatuses(userId, statuses);
    } else {
      return this.parcelsService.getParcelsByUserId(userId);
    }
  }

  @Post()
  CreateParcel(@Body() parcel: Parcel) {
    Logger.log(`[ParcelsController] CreateParcel(${JSON.stringify(parcel)})`);
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
