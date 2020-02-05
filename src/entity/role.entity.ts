import {Entity, PrimaryGeneratedColumn, Column, Index} from 'typeorm';
import 'reflect-metadata';
import {IsNotEmpty} from 'class-validator';

@Entity('roles')
export class Role {
  @PrimaryGeneratedColumn()
  id: number;

  @Column()
  @IsNotEmpty()
  description: string;
}
