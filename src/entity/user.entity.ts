import {Entity, PrimaryGeneratedColumn, Column, OneToMany, OneToOne, JoinColumn, Index} from 'typeorm';
import 'reflect-metadata';
import { Parcel } from './parcel.entity';
import {Role} from './role.entity';
import {IsInt, IsNotEmpty, IsPhoneNumber, Length} from 'class-validator';

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

  @Column()
  @IsNotEmpty()
  @Length(5, 100)
  address: string;

  @Column({ name: 'delivery_area' })
  @IsNotEmpty()
  @Length(2, 20)
  deliveryArea: string;

  @Column({ name: 'delivery_days' })
  deliveryDays: string;

  @Column()
  @IsNotEmpty()
  @IsPhoneNumber('IL')
  phone: string;

  @Column({name: 'role_fk'})
  @IsInt()
  roleId: number;

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

  @OneToOne(type => Role)
  @JoinColumn({ name: 'role_fk', referencedColumnName: 'id' })
  role: Role;

  @OneToMany(type => Parcel, parcel => parcel.user)
  parcels: Parcel[];
}
