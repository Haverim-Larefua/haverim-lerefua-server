import { Controller, Get, Post, Put, Param, Body } from '@nestjs/common';
import { ParcelsService } from './parcels.service';
import { ParcelDto } from './dto/parcel.dto';

@Controller('parcels')
export class ParcelsController {
    constructor (private readonly parcelsService: ParcelsService) {}
    
    @Get()
    getAllUsers() {
        return this.parcelsService.getAllParcels();
    }

    @Get(':id')
    getUserbyId(@Param('id') id: number) {
        return this.parcelsService.getParcelbyId(id);
    }

    @Post()
    CreateUser(@Body() parcel: ParcelDto) {
        console.log(parcel);
        return this.parcelsService.createParcel(parcel);
    }

    @Put(':id')
    updateUser(@Param('id') id: number, @Body() parcel: ParcelDto){
        console.log(parcel);
        return this.parcelsService.updateParcel(id, parcel);
    }
}
