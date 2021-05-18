import { Repository } from 'typeorm';
import { Test, TestingModule } from '@nestjs/testing';
import { City } from 'src/entity/city.entity';
import { CitiesService } from './cities.service';
import { getRepositoryToken } from '@nestjs/typeorm';

export type MockType<T> = {
	[P in keyof T]?: jest.Mock<{}>;
};

export const repositoryMockFactory: () => MockType<Repository<any>> = jest.fn(() => ({
	createQueryBuilder: jest.fn(() => ({
		select: jest.fn().mockReturnThis(),
		leftJoin: jest.fn().mockReturnThis(),
		cache: jest.fn().mockReturnThis(),
		getManyAndCount: jest.fn().mockReturnValueOnce(cities),
	})),
}));

const cities = [];

describe('CitiesService', () => {
	let service: CitiesService;
	let repositoryMock: MockType<Repository<City>>;

	beforeEach(async () => {
		const module: TestingModule = await Test.createTestingModule({
			providers: [
				CitiesService,
				{
					provide: getRepositoryToken(City),
					useFactory: repositoryMockFactory
				},
			],
		}).compile();
		repositoryMock = module.get(getRepositoryToken(City));
		service = module.get<CitiesService>(CitiesService);
	});

	it('should be defined', () => {
		expect(service).toBeDefined();
	});

	it('should return an array of cities', async () => {
		const result = await service.findAll();
		expect(result).toEqual(cities);
	});
});

