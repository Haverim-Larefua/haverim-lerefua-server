import { Entity, PrimaryGeneratedColumn, Column, OneToMany } from 'typeorm';
import 'reflect-metadata';
//import { User } from '../../src/users/entity/user.entity';
@Entity('delivery_days')
export class DeliveryDays {
  @PrimaryGeneratedColumn()
  id: number;
  @Column()
  description: string;
  //@OneToMany(type => User, user => user.deliveryDays)
  // users: User[];
}
