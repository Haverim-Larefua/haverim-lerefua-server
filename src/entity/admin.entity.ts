import {Entity, PrimaryGeneratedColumn, Column, Index} from 'typeorm';
import 'reflect-metadata';
import {IsNotEmpty, Length} from 'class-validator';

@Entity('admins')
export class Admin {
  @PrimaryGeneratedColumn()
  id: number;

  @Column({ name: 'first_name' })
  @IsNotEmpty()
  @Length(2, 20)
  firstName: string;

  @Column({ name: 'last_name' })
  @IsNotEmpty()
  @Length(2, 30)
  lastName: string;

  @Column()
  phone: string;

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
}
