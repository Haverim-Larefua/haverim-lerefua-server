import {Entity, PrimaryGeneratedColumn, Column, OneToMany, JoinColumn, OneToOne } from 'typeorm';
import 'reflect-metadata';
import { User } from './user.entity';
import { ParcelTracking } from './parcel.tracking.entity';
import { IsEnum, IsNotEmpty, Length} from 'class-validator';

@Entity('parcel')
export class Parcel {
  @PrimaryGeneratedColumn()
  id: number;

  @Column({ unique: true })
  @IsNotEmpty()
  identity: number;

  @Column()
  @IsNotEmpty()
  @Length(2, 50)
  city: string;

  @Column()
  @IsNotEmpty()
  @Length(2, 100)
  address: string;

  @Column()
  @IsNotEmpty()
  @Length(7, 100)
  phone: string;

  @Column({ name: 'customer_name' })
  @IsNotEmpty()
  @Length(2, 45)
  customerName: string;

  @Column()
  currentUserId: number;

  @Column() // TODO: currentStatus [delivered, sdfdsf]
  @IsNotEmpty() // TODO: in create parcel check if exits and if not set default
  @Length(2, 30)
  @IsEnum(['ready', 'assigned', 'delivered', 'distribution', 'exception'])
  parcelTrackingStatus: string;

  @Column()
  comments: string;

  @Column({ name: 'lastUpdateDate' })
  lastUpdateDate: Date;

  @Column()
  signature: string;

  @Column({ select: false })
  deleted: boolean;

  @OneToOne(type => User)
  @JoinColumn({ name: 'currentUserId', referencedColumnName: 'id' })
  user: User;

  @OneToMany(type => ParcelTracking, tracking => tracking.parcel)
  parcelTracking: ParcelTracking[];
}
