import { Entity, PrimaryGeneratedColumn, Column } from 'typeorm';
import 'reflect-metadata';

@Entity('parcel_status')
export class ParcelStatus {
  @PrimaryGeneratedColumn()
  id: number;

  @Column()
  status: string;
}
