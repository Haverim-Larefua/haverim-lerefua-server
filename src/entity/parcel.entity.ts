import {
  Entity,
  PrimaryGeneratedColumn,
  Column,
  ManyToOne,
  JoinColumn,
} from 'typeorm';
import 'reflect-metadata';
import { User } from './user.entity';
@Entity('parcel')
export class Parcel {
  @PrimaryGeneratedColumn()
  id: number;
  @Column({ unique: true })
  no: string;
  @Column()
  destination: string;
  @Column({ name: 'destination_address' })
  destinationAddress: string;
  @Column({ name: 'destination_phone' })
  destinationPhone: string;
  @Column()
  address: string;
  @Column()
  userId: number;
  @ManyToOne(type => User)
  @JoinColumn({ name: 'userId', referencedColumnName: 'id' })
  user: User;
  @Column()
  comments: string;
  @Column({ name: 'update_date' })
  updateDate: Date;
}
