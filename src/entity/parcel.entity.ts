import {Entity, PrimaryGeneratedColumn, Column, OneToMany, JoinColumn, OneToOne } from 'typeorm';
import 'reflect-metadata';
import { User } from './user.entity';
import { ParcelTracking } from './parcel.tracking.entity';
import {IsDate, IsNotEmpty, Length} from 'class-validator';

@Entity('parcel')
export class Parcel {
  @PrimaryGeneratedColumn()
  id: number;

  @Column({ unique: true })
  @IsNotEmpty()
  no: number;

  @Column()
  @IsNotEmpty()
  @Length(2, 50)
  city: string;

  @Column()
  @IsNotEmpty()
  @Length(2, 100)
  phone: string;

  @Column({ name: 'customer_name' })
  @IsNotEmpty()
  @Length(2, 45)
  customerName: string;

  @Column()
  @IsNotEmpty()
  @Length(2, 100)
  address: string;

  @Column()
  userId: number;

  @Column()
  @Length(3, 100)
  comments: string;

  @Column({ name: 'update_date' })
  updateDate: Date;

  @Column()
  signature: string;

  @OneToOne(type => User)
  @JoinColumn({ name: 'userId', referencedColumnName: 'id' })
  user: User;

  @OneToMany(type => ParcelTracking, tracking => tracking.parcel)
  parcelTracking: ParcelTracking[];
}
