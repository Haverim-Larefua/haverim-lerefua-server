import { Entity, PrimaryGeneratedColumn, Column, ManyToOne, OneToOne, JoinColumn } from 'typeorm';
import 'reflect-metadata';
import { Parcel } from './parcel.entity';
import { User } from './user.entity';
import {ParcelStatus} from './parcel.status.entity';

@Entity('parcel_tracking')
export class ParcelTracking {
  @PrimaryGeneratedColumn()
  id: number;

  @Column({ name: 'status_date' })
  statusDate: Date;

  @Column({name: 'status_fk'})
  statusId: number;

  @Column({name: 'parcel_fk'})
  parcelId: number;

  @OneToOne(type => ParcelStatus)
  @JoinColumn({ name: 'status_fk', referencedColumnName: 'id' })
  status: ParcelStatus;

  @ManyToOne(type => Parcel)
  @JoinColumn({ name: 'parcel_fk', referencedColumnName: 'id' })
  parcel: Parcel;
}
