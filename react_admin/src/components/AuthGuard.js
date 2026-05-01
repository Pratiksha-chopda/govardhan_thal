'use client';

import { useEffect, useState } from 'react';
import { useRouter, usePathname } from 'next/navigation';

export default function AuthGuard({ children }) {
  const router = useRouter();
  const pathname = usePathname();
  const [authorized, setAuthorized] = useState(false);

  useEffect(() => {
    // Check if the current route is protected
    const authCheck = () => {
      const token = localStorage.getItem('adminToken');
      if (!token && pathname !== '/login') {
        setAuthorized(false);
        router.push('/login');
      } else {
        setAuthorized(true);
      }
    };

    authCheck();

    // Re-check auth on route changes
    // But since `pathname` is in dependencies, it will re-run anyway.
  }, [pathname, router]);

  // Optionally show a loading state while checking
  if (!authorized && pathname !== '/login') {
    return (
      <div className="flex items-center justify-center h-screen bg-slate-900">
        <div className="w-12 h-12 border-4 border-slate-300 border-t-amber-500 rounded-full animate-spin"></div>
      </div>
    );
  }

  return <>{children}</>;
}
