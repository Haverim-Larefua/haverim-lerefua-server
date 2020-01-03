import { Injectable } from '@nestjs/common';
import { ParcelDto } from './dto/parcel.dto';

@Injectable()
export class ParcelsService {
    getAllParcels(){
        return "get all parcels";
    }

    getParcelbyId(id: number){
        return "get parcel by id: " + id;
    }

    createParcel(parcel: ParcelDto){
        return "create parcel: " + parcel;
    }

    updateParcel(id: number, parcel: ParcelDto){
        return "update parcel with id: " + id + " with the data: " + parcel;
    }
}
