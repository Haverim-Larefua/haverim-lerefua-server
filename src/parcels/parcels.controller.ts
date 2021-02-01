import {
  Controller,
  Get,
  Post,
  Put,
  Param,
  Body,
  Logger,
  Delete,
  Query,
  UseGuards,
} from '@nestjs/common';
import { ParcelsService } from './parcels.service';
import { Parcel } from '../entity/parcel.entity';
import { AuthGuard } from '@nestjs/passport';
import { ParcelStatus } from '../enum/status.model';

interface IAddSignatureRequest {
  signature: string;
  comment: string;
}

interface IUpdateParcelWithExceptionRequest {
  exception: string;
}

interface IUpdateParcelsStatusRequest {
  status: string;
  userId: number;
  parcels: number[];
}

export interface IGetAllParcelsQueryString {
  statusFilterTerm?: ParcelStatus;
  cityFilterTerm?: string;
  searchTerm?: string;
  freeCondition?: string;
}

@Controller('parcels')
export class ParcelsController {
  constructor(private readonly parcelsService: ParcelsService) { }
  @Get()
  getAllParcels(@Query() query: IGetAllParcelsQueryString): Promise<Parcel[]> {
    Logger.log(
      `[ParcelsController] getAllParcels(), query parameters are: ${JSON.stringify(
        query,
      )}`,
    );
    return this.parcelsService.getAllParcels(query);
  }

  @Get('/cityOptions')
  getParcelsCityOptions(): Promise<string[]> {
    Logger.log(`[ParcelsController] getParcelsCityOptions()`);
    return this.parcelsService.getParcelsCityOptions();
  }

  // @UseGuards(AuthGuard('app'))
  @Get(':id')
  getParcelById(@Param('id') id: number): Promise<Parcel> {
    Logger.log(`[ParcelsController] getParcelById()`);
    return this.parcelsService.getParcelById(id);
  }

  @UseGuards(AuthGuard('app'))
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
    Logger.log(
      `[ParcelsController] getParcelsByUserId(${userId}, ${JSON.stringify(
        query,
      )})`,
    );
    if (query.last_statuses) {
      const statuses: string[] = query.last_statuses.split(',');
      return this.parcelsService.getParcelsByUserIdSpecificStatuses(
        userId,
        statuses,
      );
    } else {
      return this.parcelsService.getParcelsByUserId(userId);
    }
  }

  @Post()
  CreateParcel(@Body() parcel: Parcel) {
    Logger.log(`[ParcelsController] CreateParcel(${JSON.stringify(parcel)})`);
    return this.parcelsService.createParcel(parcel);
  }

  @Put('assign/:userId')
  assignParcelsToUser(
    @Param('userId') userId: number,
    @Body() parcelIds: number[],
  ): Promise<Parcel[]> {
    Logger.log(
      `[ParcelsController] assignParcelsToUser(${userId}, ${parcelIds})`,
    );
    return this.parcelsService.assignParcelsToUser(userId, parcelIds);
  }

  @Put(':parcelId/unassign')
  unassignParcel(
    @Param('parcelId') parcelId: number,
  ): Promise<Parcel> {
    Logger.log(
      `[ParcelsController] unassignParcel(${parcelId})`,
    );
    return this.parcelsService.unassignParcel(parcelId);
  }

  @Put(':parcelId/signature/:userId')
  addParcelSignature(
    @Param('userId') userId: number,
    @Param('parcelId') parcelId: number,
    @Body() body: IAddSignatureRequest,
  ): Promise<Parcel> {
    Logger.log(
      `[ParcelsController] addParcelSignature(${userId}, ${parcelId}, ${body.signature}, ${body.comment})`,
    );
    return this.parcelsService.addParcelSignature(
      userId,
      parcelId,
      body.signature,
      body.comment,
    );
  }

  @Put(':parcelId/exception')
  updateParcelWithException(
    @Param('parcelId') parcelId: number,
    @Body() body: IUpdateParcelWithExceptionRequest,
  ): void {
    Logger.log(
      `[ParcelsController] updateParcelWithException(${parcelId}, ${body.exception})`,
    );
    this.parcelsService.updateParcelWithException(parcelId, body.exception);
  }

  @Put('user/:userId/:status')
  updateParcelsStatus(
    @Param('userId') userId: number,
    @Param('status') status: ParcelStatus,
    @Body() body: IUpdateParcelsStatusRequest,
  ): Promise<number[]> {
    Logger.log(
      `[ParcelsController] updateParcelsStatus(${userId}, ${status}, ${body.parcels})`,
    );
    
    if (isNaN(userId)){
      userId = null;
    }
    
    return this.parcelsService.updateParcelsStatus(
      userId,
      status,
      body.parcels,
    );
  }

  @Put(':id')
  updateParcel(@Param('id') id: number, @Body() parcel: Parcel) {
    Logger.log(`[ParcelsController] updateParcel()`);
    return this.parcelsService.updateParcel(id, parcel);
  }

  @Delete(':id/:keep')
  deleteParcelById(@Param('id') id: number, @Param('keep') keep: boolean) {
    Logger.log(`[ParcelsController] deleteParcelById()`);
    return this.parcelsService.deleteParcel(id, keep);
  }


  @Post('push')
  notifyParcelsToUsers(
    @Body() body: {parcelIds: number[]}): Promise<void> {
      Logger.log(`[PushTokenController] notifyParcelsToUsers(${JSON.stringify(body)})`);
      return this.parcelsService.notifyParcelsToUsers(body.parcelIds);
  }
}
