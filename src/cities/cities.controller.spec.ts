import { Test, TestingModule } from '@nestjs/testing';
import { City } from 'src/entity/city.entity';
import { CitiesController } from './cities.controller';
import { CitiesService } from './cities.service';

describe('CitiesController', () => {
	let controller: CitiesController;
	let service: Partial<CitiesService>;

	beforeEach(async () => {
		const module: TestingModule = await Test.createTestingModule({
			controllers: [CitiesController],
			providers: [
				{
					provide: CitiesService,
					useValue: service
				}
			],
		}).compile();

		service = module.get<CitiesService>(CitiesService);
		controller = module.get<CitiesController>(CitiesController);
	});

	it('should be defined', () => {
		expect(controller).toBeDefined();
	});

	describe('findAll', () => {
		it('should return an array of cities', async () => {
			const cities = [
				{
					id: 1, name: "cityName",
					district: { id: 1, name: "districtName" },
					// subdistrict: { id: 1, name: "subdistrictName" }
				}];
			jest.spyOn(CitiesService, 'findAll').mockImplementation(() => cities);

			expect(await controller.findAll()).toBe(cities);
		});
	});
});
