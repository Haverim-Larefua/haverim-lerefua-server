import { Entity, PrimaryGeneratedColumn, Column, OneToMany, ManyToOne, JoinColumn} from 'typeorm';
import 'reflect-metadata';
import { Parcel } from './parcel.entity';
import { ParcelTracking } from './parcelTracking.entity';

@Entity('users')
export class User {
  @PrimaryGeneratedColumn()
  id: number;
  
  @Column({ name: 'first_name' })
  firstName: string;
  
  @Column({ name: 'last_name' })
  lastName: string;
  
  @Column()
  address: string;
  
  @Column({ name: 'delivery_area' })
  deliveryArea: string;
  
  @Column({ name: 'delivery_days' })
  deliveryDays: string;
  
  @Column()
  phone: string;
  
  @Column({ name: 'role_fk' })
  roleFK: number;
  
  @Column()
  notes: string;
  
  @OneToMany(type => Parcel, parcel => parcel.user)
  parcels: Parcel[];

  @OneToMany(type => ParcelTracking, tracking => tracking.user)
  tracking: ParcelTracking[];
}
