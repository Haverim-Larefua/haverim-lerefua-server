import { Entity, PrimaryGeneratedColumn, Column } from 'typeorm';
import 'reflect-metadata';
@Entity('parcel')
export class ParcelDto {
  @PrimaryGeneratedColumn()
  id: number;
  @Column()
  no: string;
  @Column()
  destination: string;
  @Column({ name: 'destination_address' })
  destinationAddress: string;
  @Column({ name: 'destination_phone' })
  destinationPhone: string;
  @Column()
  address: string;
  @Column({ name: 'delivery_person' })
  deliveryPerson: string;
  @Column({ name: 'delivery_person_phone' })
  deliveryPersonPhone: string;
  @Column()
  comments: string;
}
