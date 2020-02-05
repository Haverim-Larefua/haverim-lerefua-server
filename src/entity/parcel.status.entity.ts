import { Entity, PrimaryGeneratedColumn, Column } from 'typeorm';
import 'reflect-metadata';
import {IsNotEmpty, Length} from "class-validator";

@Entity('parcel_statuses')
export class ParcelStatus {
  @PrimaryGeneratedColumn()
  id: number;

  @Column()
  @IsNotEmpty()
  @Length(2, 20)
  status: string;
}
