import { Entity, PrimaryGeneratedColumn, Column, ManyToOne, OneToOne, JoinColumn,} from 'typeorm';
import 'reflect-metadata';
import { Parcel } from './parcel.entity';
import { User } from './user.entity';

@Entity('parcel_tracking')
export class ParcelTracking {
  @PrimaryGeneratedColumn()
  id: number;

  @Column({ name: 'status_date' })
  statusDate: Date;

  @Column()
  status: string;

  @Column({name: 'parcel_fk'})
  parselId: number;

  @ManyToOne(type => Parcel)
  @JoinColumn({ name: 'parcel_fk', referencedColumnName: 'id' })
  parcel: Parcel;

  @Column({name: 'user_fk'})
  userId: number;

  @ManyToOne(type => User)
  @JoinColumn({ name: 'user_fk', referencedColumnName: 'id' })
  user: User;

}

