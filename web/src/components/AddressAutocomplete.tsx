import React, { useState, useEffect } from 'react';
import { 
  Autocomplete, TextField, Box, Typography, 
  CircularProgress, InputAdornment 
} from '@mui/material';
import SearchIcon from '@mui/icons-material/Search';
import LocationOnIcon from '@mui/icons-material/LocationOn';
import axios from 'axios';

export interface LocationResult {
  address: string;
  lat: number;
  lng: number;
  placeId: string;
}

interface AddressAutocompleteProps {
  placeholder: string;
  isHospitalSearch?: boolean;
  value: LocationResult | null;
  inputValue: string;
  onInputValueChange: (newInputValue: string) => void;
  onSelect: (location: LocationResult | null) => void;
  endAdornment?: React.ReactNode;
}

export default function AddressAutocomplete({ 
  placeholder, 
  isHospitalSearch, 
  value,
  inputValue,
  onInputValueChange,
  onSelect, 
  endAdornment 
}: AddressAutocompleteProps) {
  const [open, setOpen] = useState(false);
  const [options, setOptions] = useState<any[]>([]);
  const [loading, setLoading] = useState(false);

  useEffect(() => {
    let active = true;
    // We mock Google Places Autocomplete with Nominatim OpenStreetMap API
    // In a production app with API keys, you would swap this axios call 
    // with the Google Maps Places Service or Google Maps REST API.
    if (inputValue.length < 3) {
      setOptions([]);
      return undefined;
    }

    setLoading(true);
    const delayDebounceFn = setTimeout(async () => {
      try {
        const query = isHospitalSearch ? `hospital ${inputValue}` : inputValue;
        const res = await axios.get(`https://nominatim.openstreetmap.org/search?format=json&q=${encodeURIComponent(query)}&countrycodes=in&limit=5`);
        if (active) {
          setOptions(res.data);
        }
      } catch (e) {
        // ignore error
      } finally {
        if (active) setLoading(false);
      }
    }, 500);

    return () => {
      active = false;
      clearTimeout(delayDebounceFn);
    };
  }, [inputValue, isHospitalSearch]);

  return (
    <Autocomplete
      open={open}
      onOpen={() => setOpen(true)}
      onClose={() => setOpen(false)}
      isOptionEqualToValue={(option, val) => option.place_id === val?.placeId}
      getOptionLabel={(option) => {
        if (typeof option === 'string') return option;
        if (option.display_name) return option.display_name;
        if (option.address) return option.address;
        return '';
      }}
      options={options}
      loading={loading}
      inputValue={inputValue}
      onInputChange={(_e, newInputValue) => {
        onInputValueChange(newInputValue);
      }}
      value={value}
      onChange={(_e, newValue) => {
        if (newValue && typeof newValue !== 'string') {
          onSelect({
            address: newValue.display_name || newValue.address,
            lat: parseFloat(newValue.lat),
            lng: parseFloat(newValue.lon),
            placeId: newValue.place_id?.toString() || crypto.randomUUID(),
          });
        } else {
          onSelect(null);
        }
      }}
      noOptionsText="No locations found"
      renderOption={(props, option) => (
        <li {...props} key={option.place_id}>
          <Box sx={{ display: 'flex', alignItems: 'center', gap: 1.5, py: 0.5 }}>
            <LocationOnIcon sx={{ color: '#9ca3af' }} />
            <Typography variant="body2" sx={{ color: '#1F2937' }}>
              {option.display_name}
            </Typography>
          </Box>
        </li>
      )}
      renderInput={(params) => (
        <TextField
          {...params}
          placeholder={placeholder}
          slotProps={{
            ...params.slotProps,
            input: {
              ...params.slotProps?.input,
              startAdornment: (
                <InputAdornment position="start">
                  <SearchIcon sx={{ color: '#9ca3af', ml: 0.5 }} />
                </InputAdornment>
              ),
              endAdornment: (
                <Box sx={{ display: 'flex', alignItems: 'center' }}>
                  {loading ? <CircularProgress color="inherit" size={20} sx={{ mr: 1 }} /> : null}
                  {params.slotProps?.input?.endAdornment}
                  {endAdornment}
                </Box>
              ),
            }
          }}
          sx={{
            '& .MuiOutlinedInput-root': {
              borderRadius: '16px',
              bgcolor: '#F7F8FA',
            }
          }}
        />
      )}
    />
  );
}
