import {Entity, PrimaryGeneratedColumn, Column, OneToMany} from 'typeorm';
import 'reflect-metadata';
import { City } from './city.entity';

@Entity('districts')
export class District {
	@PrimaryGeneratedColumn()
  id: number;

	@Column()
	name: string;
	
	@OneToMany(type => City, city => city.district)
	cities: City[];
}
