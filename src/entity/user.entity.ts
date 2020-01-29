import {
  Entity,
  PrimaryGeneratedColumn,
  Column,
  OneToMany,
  ManyToOne,
  JoinColumn,
} from 'typeorm';
import 'reflect-metadata';
import { Parcel } from './parcel.entity';
import { DeliveryDays } from './deliveyDays.entity';

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
  @Column()
  phone: string;
  @Column({ name: 'role_fk' })
  roleFK: number;
  @OneToMany(type => Parcel, parcel => parcel.user)
  parcels: Parcel[];
  @ManyToOne(type => DeliveryDays)
  @JoinColumn({ name: 'deliveryDaysId', referencedColumnName: 'id' })
  deliveryDays: DeliveryDays;
}
