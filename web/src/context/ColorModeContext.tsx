import { createContext, useContext, useState, useMemo } from 'react';
import type { ReactNode } from 'react';

type PaletteMode = 'light' | 'dark';

interface ColorModeContextType {
  toggleColorMode: () => void;
  mode: PaletteMode;
}

const ColorModeContext = createContext<ColorModeContextType | undefined>(undefined);

export function ColorModeProvider({ children }: { children: ReactNode }) {
  const [mode, setMode] = useState<PaletteMode>(() => {
    const saved = localStorage.getItem('theme_mode');
    return (saved as PaletteMode) || 'light';
  });

  const colorMode = useMemo(
    () => ({
      toggleColorMode: () => {
        setMode((prevMode) => {
          const next = prevMode === 'light' ? 'dark' : 'light';
          localStorage.setItem('theme_mode', next);
          return next;
        });
      },
      mode,
    }),
    [mode]
  );

  return (
    <ColorModeContext.Provider value={colorMode}>
      {children}
    </ColorModeContext.Provider>
  );
}

export const useColorMode = () => {
  const context = useContext(ColorModeContext);
  if (!context) throw new Error('useColorMode must be used within ColorModeProvider');
  return context;
};
