import {Entity, PrimaryGeneratedColumn, Column, ManyToOne, JoinColumn} from 'typeorm';
import { District } from './district.entity';
import { Subdistrict } from './subdistrict.entity';

@Entity('cities')
export class City {
	@PrimaryGeneratedColumn()
  id: number;

	@Column()
	name: string;

	@ManyToOne(type => District, district => district.id)
	@JoinColumn({ name: 'district_fk', referencedColumnName: 'id' })
	district: District;
	
	@ManyToOne(type => Subdistrict, subdistrict => subdistrict.id)
	@JoinColumn({ name: 'subdistrict_fk', referencedColumnName: 'id' })
	subdistrict: Subdistrict;
}
