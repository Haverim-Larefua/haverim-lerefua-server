import {
  Entity,
  PrimaryGeneratedColumn,
  Column,
  OneToMany,
  JoinColumn,
  OneToOne,
  Index,
} from 'typeorm';
import 'reflect-metadata';
import { User } from './user.entity';
import { ParcelTracking } from './parcel.tracking.entity';
import { IsEnum, IsNotEmpty, Length } from 'class-validator';
import { ParcelStatus } from 'src/enum/status.model';

@Entity('parcel')
export class Parcel {
  @PrimaryGeneratedColumn()
  id: number;

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
  @Index({ fulltext: true })
  @Length(7, 100)
  phone: string;

  @Column()
  @Index({ fulltext: true })
  @Length(0, 100)
  phone2: string;

  @Column({ name: 'customer_name' })
  @IsNotEmpty()
  @Index({ fulltext: true })
  @Length(2, 45)
  customerName: string;

  @Column({ name: 'customer_id' })
  @IsNotEmpty()
  @Index({ fulltext: true })
  @Length(9)
  customerId: string;

  @Column()
  currentUserId: number;

  @Column() // TODO: currentStatus [delivered, sdfdsf]
  @IsNotEmpty() // TODO: in create parcel check if exits and if not set default
  @Length(2, 30)
  @IsEnum(['ready', 'assigned', 'delivered', 'distribution'])
  parcelTrackingStatus: ParcelStatus;

  @Column()
  comments: string;

  @Column({ name: 'start_date' })
  startDate: string;

  @Column({ name: 'start_time' })
  startTime: string;

  @Column({ name: 'lastUpdateDate' })
  lastUpdateDate: Date;

  @Column()
  signature: string;

  @Column({ select: false })
  deleted: boolean;

  @Column()
  exception: boolean;

  @OneToOne(type => User)
  @JoinColumn({ name: 'currentUserId', referencedColumnName: 'id' })
  user: User;

  @OneToMany(type => ParcelTracking, tracking => tracking.parcel)
  parcelTracking: ParcelTracking[];
}
