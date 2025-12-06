'use client';

import Link from 'next/link';
import { usePathname } from 'next/navigation';
import { cn } from '@/lib/utils/format';
import {
  LayoutDashboard,
  User,
  FolderKanban,
  MessageSquare,
  Bell,
  Code2,
  FileText,
} from 'lucide-react';

interface SidebarProps {
  isOpen: boolean;
  role: string;
}

const studentLinks = [
  { href: '/dashboard', label: 'Dashboard', icon: LayoutDashboard },
  { href: '/profile', label: 'Profile', icon: User },
  { href: '/projects', label: 'Projects', icon: FolderKanban },
  { href: '/documents', label: 'Documents', icon: FileText },
  { href: '/groups', label: 'Groups', icon: MessageSquare },
  { href: '/announcements', label: 'Announcements', icon: Bell },
];

const superAdminLinks = [
  { href: '/super-admin/dashboard', label: 'Dashboard', icon: LayoutDashboard },
  { href: '/super-admin/students', label: 'Students', icon: User },
  { href: '/super-admin/groups', label: 'Groups', icon: MessageSquare },
  { href: '/super-admin/announcements', label: 'Announcements', icon: Bell },
  { href: '/super-admin/leetcode', label: 'LeetCode Stats', icon: Code2 },
  { href: '/super-admin/admins', label: 'Admins', icon: User },
  { href: '/super-admin/batch-management', label: 'Batch Management', icon: FolderKanban },
];

const classRepLinks = [
  { href: '/class-rep/dashboard', label: 'Dashboard', icon: LayoutDashboard },
  { href: '/class-rep/students', label: 'Students', icon: User },
  { href: '/class-rep/notifications', label: 'Send Notification', icon: Bell },
];

export default function Sidebar({ isOpen, role }: SidebarProps) {
  const pathname = usePathname();

  const links = 
    role === 'SUPER_ADMIN' ? superAdminLinks :
    role === 'CLASS_REP' ? classRepLinks :
    studentLinks;

  return (
    <>
      {/* Mobile backdrop */}
      {isOpen && (
        <div
          className="fixed inset-0 bg-black bg-opacity-50 z-20 lg:hidden"
          onClick={() => {}}
        />
      )}

      {/* Sidebar */}
      <aside
        className={cn(
          'fixed top-16 left-0 z-20 h-[calc(100vh-4rem)] w-64 bg-white border-r border-gray-200 transition-transform duration-300 ease-in-out lg:translate-x-0',
          isOpen ? 'translate-x-0' : '-translate-x-full'
        )}
      >
        <nav className="h-full overflow-y-auto py-4">
          <ul className="space-y-1 px-3">
            {links.map((link) => {
              const Icon = link.icon;
              const isActive = pathname === link.href;

              return (
                <li key={link.href}>
                  <Link
                    href={link.href}
                    className={cn(
                      'flex items-center gap-3 px-4 py-3 rounded-lg transition-colors',
                      isActive
                        ? 'bg-primary text-white'
                        : 'text-gray-700 hover:bg-gray-100'
                    )}
                  >
                    <Icon className="h-5 w-5" />
                    <span className="font-medium">{link.label}</span>
                  </Link>
                </li>
              );
            })}
          </ul>
        </nav>
      </aside>
    </>
  );
}
