import { ApiProperty } from '@nestjs/swagger';
import { IsEnum, IsNotEmpty, IsNumber, IsObject, IsOptional, IsString, ValidateNested } from 'class-validator';
import { Type } from 'class-transformer';

class LocationDto {
  @ApiProperty({ format: 'double' })
  @IsNumber()
  lat: number;

  @ApiProperty({ format: 'double' })
  @IsNumber()
  lng: number;

  @ApiProperty()
  @IsString()
  address: string;
}

class PatientInfoDto {
  @ApiProperty()
  @IsString()
  name: string;

  @ApiProperty()
  @IsString()
  phoneE164: string;

  @ApiProperty({ required: false })
  @IsOptional()
  @IsNumber()
  age?: number;

  @ApiProperty({ required: false })
  @IsOptional()
  @IsString()
  notes?: string;
}

export class RequestAmbulanceDto {
  @ApiProperty({ description: 'Client-generated idempotency key' })
  @IsString()
  @IsNotEmpty()
  idempotencyKey: string;

  @ApiProperty({ type: LocationDto })
  @IsObject()
  @ValidateNested()
  @Type(() => LocationDto)
  pickup: LocationDto;

  @ApiProperty({ type: LocationDto })
  @IsObject()
  @ValidateNested()
  @Type(() => LocationDto)
  drop: LocationDto;

  @ApiProperty({ enum: ['normal', 'high', 'critical'], default: 'normal' })
  @IsEnum(['normal', 'high', 'critical'])
  priority: 'normal' | 'high' | 'critical';

  @ApiProperty({ type: PatientInfoDto })
  @IsObject()
  @ValidateNested()
  @Type(() => PatientInfoDto)
  patient: PatientInfoDto;

  @ApiProperty({ required: false })
  @IsOptional()
  @IsString()
  notes?: string;
}
