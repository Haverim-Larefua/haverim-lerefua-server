import { Controller, Get, Post, Body, Patch, Param, Delete } from '@nestjs/common';
import { City } from 'src/entity/city.entity';
import { CitiesService } from './cities.service';

@Controller('cities')
export class CitiesController {
	constructor(private readonly citiesService: CitiesService) { }
	@Get()
	async findAll(): Promise<City[]> {
		return this.citiesService.findAll();
	}
}
