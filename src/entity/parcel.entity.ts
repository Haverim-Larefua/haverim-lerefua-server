import {Entity, PrimaryGeneratedColumn, Column, OneToMany, JoinColumn, OneToOne } from 'typeorm';
import 'reflect-metadata';
import { User } from './user.entity';
import { ParcelTracking } from './parcel.tracking.entity';

@Entity('parcel')
export class Parcel {
  @PrimaryGeneratedColumn()
  id: number;

  @Column({ unique: true })
  no: string;

  @Column()
  city: string;

  @Column()
  phone: string;

  @Column({ name: 'customer_name' })
  customerName: string;

  @Column()
  address: string;

  @Column()
  userId: number;

  @OneToOne(type => User)
  @JoinColumn({ name: 'userId', referencedColumnName: 'id' })
  user: User;

  @Column()
  comments: string;

  @Column({ name: 'update_date' })
  updateDate: Date;

  @OneToMany(type => ParcelTracking, tracking => tracking.parcel)
  parcelTracking: ParcelTracking[];
}
