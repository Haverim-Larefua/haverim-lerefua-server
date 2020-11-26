import {
  Entity,
  PrimaryGeneratedColumn,
  Column,
  OneToMany,
  Index,
} from 'typeorm';
import 'reflect-metadata';
import { Parcel } from './parcel.entity';
import { IsNotEmpty, Length } from 'class-validator';
import { Exclude } from 'class-transformer/decorators';

@Entity('users')
export class User {
  @PrimaryGeneratedColumn()
  id: number;

  @Column({ name: 'first_name' })
  @Index({ fulltext: true })
  @IsNotEmpty()
  @Length(2, 20)
  firstName: string;

  @Column({ name: 'last_name' })
  @Index({ fulltext: true })
  @IsNotEmpty()
  @Length(2, 30)
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
  @Index({ fulltext: true })
  @IsNotEmpty()
  phone: string;

  @Column()
  notes: string;

  @Column({ select: true })
  @Index({ unique: true })
  @IsNotEmpty()
  username: string;

  @IsNotEmpty()
  @Length(6)
  @Column({ select: true })
  @Exclude({ toPlainOnly: true })
  password: string;

  @Column({ select: false })
  @Exclude({ toPlainOnly: true })
  salt: string;

  @Column()
  active: boolean;

  @Column({ name: 'refresh_token' })
  @Exclude({ toPlainOnly: true })
  refreshToken: string;

  @OneToMany(type => Parcel, parcel => parcel.user)
  parcels: Parcel[];
}
