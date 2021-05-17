import {Entity, PrimaryGeneratedColumn, Column, OneToMany} from 'typeorm';
import 'reflect-metadata';
import { City } from './city.entity';

@Entity('subdistricts')
export class Subdistrict {
	@PrimaryGeneratedColumn()
  id: number;

	@Column()
	name: string;
	
	@OneToMany(type => City, city => city.subdistrict)
	cities: City[];
}
