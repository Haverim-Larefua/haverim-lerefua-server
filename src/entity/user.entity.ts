import {Entity, PrimaryGeneratedColumn, Column, OneToMany, Index} from 'typeorm';
import 'reflect-metadata';
import { Parcel } from './parcel.entity';
import {IsNotEmpty, Length} from 'class-validator';

@Entity('users')
export class User {
  @PrimaryGeneratedColumn()
  id: number;

  @Column({ name: 'first_name' })
  @IsNotEmpty()
  @Length(3, 20)
  firstName: string;

  @Column({ name: 'last_name' })
  @IsNotEmpty()
  @Length(3, 30)
  lastName: string;

  @Column({ name: 'delivery_area' })
  @IsNotEmpty()
  @Length(2, 20)
  deliveryArea: string;

  /*
  Note: MySql does not support array of int, so using string here
  The value should look like this: [1,4,5]
  */
  @Column({ name: 'delivery_days' })
  deliveryDays: string;

  @Column()
  @IsNotEmpty()
  phone: string;

  @Column()
  notes: string;

  @Column({ select: false })
  @Index({ unique: true })
  @IsNotEmpty()
  username: string;

  @IsNotEmpty()
  @Length(6)
  @Column({ select: false })
  password: string;

  @Column({ select: false })
  salt: string;

  @OneToMany(type => Parcel, parcel => parcel.user)
  parcels: Parcel[];
}
