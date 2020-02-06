import {Entity, PrimaryGeneratedColumn, Column, OneToOne, JoinColumn} from 'typeorm';
import 'reflect-metadata';
import {IsNotEmpty, Length} from 'class-validator';
import {User} from './user.entity';

@Entity('push_token')
export class PushToken {
  @PrimaryGeneratedColumn()
  id: number;

  @Column({name: 'user_fk'})
  @IsNotEmpty()
  userId: number;

  @Column()
  @IsNotEmpty()
  @Length(10, 300)
  token: string;

  @OneToOne(type => User)
  @JoinColumn({ name: 'user_fk', referencedColumnName: 'id' })
  user: User;
}
