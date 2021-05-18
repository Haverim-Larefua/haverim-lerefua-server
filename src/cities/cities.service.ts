import { Injectable } from '@nestjs/common';
import { Repository } from "typeorm";
import { InjectRepository } from '@nestjs/typeorm';
import { City } from 'src/entity/city.entity';

@Injectable()
export class CitiesService {
	constructor(
		@InjectRepository(City)
		private citiesRepository: Repository<City>,
	) { }

	async findAll(): Promise<City[]> {
		return await this.citiesRepository.createQueryBuilder("city")
			.select(["city.id", "city.name", "district.name", "subdistrict.name"])
			.leftJoin("city.district", "district")
			.leftJoin("city.subdistrict", "subdistrict")
			.cache(true)
			.getMany();
	}
}
