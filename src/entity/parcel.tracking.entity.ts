import { Entity, PrimaryGeneratedColumn, Column, ManyToOne, JoinColumn } from 'typeorm';
import 'reflect-metadata';
import { Parcel } from './parcel.entity';
import {IsDate, IsNotEmpty, Length} from 'class-validator';

@Entity('parcel_tracking')
export class ParcelTracking {
  @PrimaryGeneratedColumn()
  id: number;

  @Column({ name: 'status_date' })
  @IsNotEmpty()
  @IsDate()
  statusDate: Date;

  @Column()
  @IsNotEmpty()
  @Length(2, 30)
  status: string;

  @Column({name: 'user_fk'})
  @IsNotEmpty()
  userId: number;

  @Column({name: 'parcel_fk'})
  @IsNotEmpty()
  parcelId: number;

  @Column()
  comments: string;

  @ManyToOne(type => Parcel)
  @JoinColumn({ name: 'parcel_fk', referencedColumnName: 'id' })
  parcel: Parcel;
}
