import {Entity, PrimaryGeneratedColumn, Column, Index, OneToOne, JoinColumn} from 'typeorm';
import 'reflect-metadata';
import {IsNotEmpty, Length} from 'class-validator';
import {User} from './user.entity';

@Entity('push_token')
export class PushToken {
  @PrimaryGeneratedColumn()
  id: number;

  @Column()
  @IsNotEmpty()
  userId: number;

  @Column()
  @IsNotEmpty()
  @Length(10, 300)
  token: string;

  @OneToOne(type => User)
  @JoinColumn({ name: 'userId', referencedColumnName: 'id' })
  user: User;
}
