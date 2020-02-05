import { Entity, PrimaryGeneratedColumn, Column, ManyToOne, OneToOne, JoinColumn } from 'typeorm';
import 'reflect-metadata';
import { Parcel } from './parcel.entity';
import {ParcelStatus} from './parcel.status.entity';
import {IsDate, IsNotEmpty} from 'class-validator';

@Entity('parcel_tracking')
export class ParcelTracking {
  @PrimaryGeneratedColumn()
  id: number;

  @Column({ name: 'status_date' })
  @IsNotEmpty()
  @IsDate()
  statusDate: Date;

  @Column({name: 'status_fk'})
  @IsNotEmpty()
  statusId: number;

  @Column({name: 'parcel_fk'})
  @IsNotEmpty()
  parcelId: number;

  @OneToOne(type => ParcelStatus)
  @JoinColumn({ name: 'status_fk', referencedColumnName: 'id' })
  status: ParcelStatus;

  @ManyToOne(type => Parcel)
  @JoinColumn({ name: 'parcel_fk', referencedColumnName: 'id' })
  parcel: Parcel;
}
