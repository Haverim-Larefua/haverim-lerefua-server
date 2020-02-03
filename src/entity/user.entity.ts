import {Entity, PrimaryGeneratedColumn, Column, OneToMany, OneToOne, JoinColumn} from 'typeorm';
import 'reflect-metadata';
import { Parcel } from './parcel.entity';
import { ParcelTracking } from './parcel.tracking.entity';
import {Role} from './role.entity';

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

  @Column({name: 'role_fk'})
  roleId: number;

  @Column()
  notes: string;

  @OneToOne(type => Role)
  @JoinColumn({ name: 'role_fk', referencedColumnName: 'id' })
  role: Role;

  @OneToMany(type => Parcel, parcel => parcel.user)
  parcels: Parcel[];
}
