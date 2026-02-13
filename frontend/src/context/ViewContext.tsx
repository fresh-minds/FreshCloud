import { createContext, useContext, useEffect, useMemo, useState } from 'react';
import type { PropsWithChildren } from 'react';
import type { RoleMode } from '@/types/platform';

interface ViewContextValue {
  role: RoleMode;
  explainMode: boolean;
  setRole: (role: RoleMode) => void;
  setExplainMode: (enabled: boolean) => void;
}

const ViewContext = createContext<ViewContextValue | undefined>(undefined);

const ROLE_STORAGE_KEY = 'freshcloud-role';
const EXPLAIN_STORAGE_KEY = 'freshcloud-explain-mode';

function readRole(): RoleMode {
  const stored = localStorage.getItem(ROLE_STORAGE_KEY);
  return stored === 'viewer' ? 'viewer' : 'operator';
}

function readExplainMode(): boolean {
  return localStorage.getItem(EXPLAIN_STORAGE_KEY) === 'true';
}

export function ViewProvider({ children }: PropsWithChildren): JSX.Element {
  const [role, setRoleState] = useState<RoleMode>(() => readRole());
  const [explainMode, setExplainModeState] = useState<boolean>(() => readExplainMode());

  useEffect(() => {
    localStorage.setItem(ROLE_STORAGE_KEY, role);
  }, [role]);

  useEffect(() => {
    localStorage.setItem(EXPLAIN_STORAGE_KEY, String(explainMode));
  }, [explainMode]);

  const value = useMemo(
    () => ({
      role,
      explainMode,
      setRole: setRoleState,
      setExplainMode: setExplainModeState
    }),
    [role, explainMode]
  );

  return <ViewContext.Provider value={value}>{children}</ViewContext.Provider>;
}

export function useViewContext(): ViewContextValue {
  const context = useContext(ViewContext);

  if (!context) {
    throw new Error('useViewContext must be used inside ViewProvider');
  }

  return context;
}
