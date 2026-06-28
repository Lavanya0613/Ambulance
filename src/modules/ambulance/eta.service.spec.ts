import { Test, TestingModule } from '@nestjs/testing';
import { EtaService } from './eta.service';

describe('EtaService', () => {
  let service: EtaService;

  beforeEach(async () => {
    const module: TestingModule = await Test.createTestingModule({
      providers: [EtaService],
    }).compile();

    service = module.get<EtaService>(EtaService);
  });

  it('should be defined', () => {
    expect(service).toBeDefined();
  });

  it('should calculate ETA based on distance and speed', () => {
    // Distance from 0,0 to 0,0.01 is ~1.11195 km
    const result = service.calculateEta(0, 0, 0, 0.01, 60);
    expect(result.distanceKm).toBeGreaterThan(1.1);
    expect(result.distanceKm).toBeLessThan(1.2);
    expect(result.etaSeconds).toBeGreaterThan(60);
    expect(result.etaSeconds).toBeLessThan(75);
    expect(result.hasArrived).toBe(false);
  });

  it('should fallback to 40km/h default speed if speed is 0 or undefined', () => {
    const resultNoSpeed = service.calculateEta(0, 0, 0, 0.01);
    const resultZeroSpeed = service.calculateEta(0, 0, 0, 0.01, 0);
    
    // distance ~1.11km at 40km/h -> ~100 seconds
    expect(resultNoSpeed.etaSeconds).toBeGreaterThan(95);
    expect(resultNoSpeed.etaSeconds).toBeLessThan(105);
    expect(resultZeroSpeed.etaSeconds).toEqual(resultNoSpeed.etaSeconds);
  });

  it('should set hasArrived and ETA=0 if within arrival threshold', () => {
    // 0.0001 deg is ~11 meters
    const result = service.calculateEta(0, 0, 0, 0.0001);
    expect(result.distanceKm).toBeLessThan(0.05);
    expect(result.etaSeconds).toBe(0);
    expect(result.hasArrived).toBe(true);
  });

  it('should return exactly 0 ETA if coordinates match', () => {
    const result = service.calculateEta(17.385, 78.486, 17.385, 78.486);
    expect(result.distanceKm).toBe(0);
    expect(result.etaSeconds).toBe(0);
    expect(result.hasArrived).toBe(true);
  });
});
