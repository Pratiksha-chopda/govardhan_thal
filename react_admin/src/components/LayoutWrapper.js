'use client';

import { usePathname } from 'next/navigation';
import Sidebar from './Sidebar';
import GlobalNotification from './GlobalNotification';
import AuthGuard from './AuthGuard';

export default function LayoutWrapper({ children }) {
  const pathname = usePathname();
  const isLoginPage = pathname === '/login';

  if (isLoginPage) {
    return <main className="w-full h-screen overflow-hidden">{children}</main>;
  }

  return (
    <AuthGuard>
      <div className="flex h-screen w-full relative z-10 p-4 gap-6">
        <Sidebar />
        <GlobalNotification />
        <main className="flex-1 h-full overflow-y-auto rounded-3xl pb-20 pt-4">
          {children}
        </main>
      </div>
    </AuthGuard>
  );
}
