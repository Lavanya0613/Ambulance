import { ApiPropertyOptional } from '@nestjs/swagger';
import { IsOptional, IsString, IsInt, Min, IsEnum, IsDateString } from 'class-validator';
import { Type } from 'class-transformer';
import { RequestStatus } from '../entities/ambulance-request.entity';

export class ListRequestsDto {
  @ApiPropertyOptional({ description: 'Page number', default: 1 })
  @IsOptional()
  @Type(() => Number)
  @IsInt()
  @Min(1)
  page?: number = 1;

  @ApiPropertyOptional({ description: 'Items per page', default: 10 })
  @IsOptional()
  @Type(() => Number)
  @IsInt()
  @Min(1)
  limit?: number = 10;

  @ApiPropertyOptional({ description: 'Sort field', default: 'createdAt' })
  @IsOptional()
  @IsString()
  sortBy?: string = 'createdAt';

  @ApiPropertyOptional({ description: 'Sort order', enum: ['ASC', 'DESC'], default: 'DESC' })
  @IsOptional()
  @IsEnum(['ASC', 'DESC'])
  sortOrder?: 'ASC' | 'DESC' = 'DESC';

  @ApiPropertyOptional({ description: 'Filter by status', enum: RequestStatus })
  @IsOptional()
  @IsEnum(RequestStatus)
  status?: RequestStatus;

  @ApiPropertyOptional({ description: 'Filter by start date' })
  @IsOptional()
  @IsDateString()
  fromDate?: string;

  @ApiPropertyOptional({ description: 'Filter by end date' })
  @IsOptional()
  @IsDateString()
  toDate?: string;
}
