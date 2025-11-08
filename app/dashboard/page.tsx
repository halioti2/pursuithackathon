'use client';

import { useEffect, useState } from 'react';
import { useRouter } from 'next/navigation';
import Button from '@/components/ui/Button';
import Link from 'next/link';

interface DashboardStats {
  totalContacts: number;
  activeMailItems: number;
  pendingFollowUps: number;
  recentMailItems: any[];
}

export default function DashboardPage() {
  const router = useRouter();
  const [stats, setStats] = useState<DashboardStats | null>(null);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState('');

  useEffect(() => {
    loadDashboardData();
  }, []);

  const loadDashboardData = async () => {
    try {
      const response = await fetch('/api/dashboard/stats');
      if (response.ok) {
        const data = await response.json();
        setStats(data);
      } else {
        setError('Failed to load dashboard data');
      }
    } catch (err) {
      setError('Error loading dashboard');
    } finally {
      setLoading(false);
    }
  };

  const getTimeAgo = (date: string) => {
    const now = new Date();
    const past = new Date(date);
    const diffMs = now.getTime() - past.getTime();
    const diffHours = Math.floor(diffMs / (1000 * 60 * 60));
    
    if (diffHours < 1) return 'Just now';
    if (diffHours === 1) return '1 hour ago';
    if (diffHours < 24) return `${diffHours} hours ago`;
    const diffDays = Math.floor(diffHours / 24);
    return diffDays === 1 ? '1 day ago' : `${diffDays} days ago`;
  };

  if (loading) {
    return (
      <div className="max-w-6xl mx-auto px-6 py-8">
        <div className="animate-pulse space-y-8">
          <div className="h-8 bg-zinc-700 rounded w-48"></div>
          <div className="grid grid-cols-1 md:grid-cols-3 gap-6">
            {[1, 2, 3].map(i => (
              <div key={i} className="h-32 bg-zinc-900 rounded-lg"></div>
            ))}
          </div>
        </div>
      </div>
    );
  }

  return (
    <div className="max-w-6xl mx-auto px-6 py-8">
      {/* Page Header */}
      <div className="flex justify-between items-center mb-8">
        <h1 className="text-3xl font-bold text-white">Dashboard</h1>
        <div className="flex gap-4">
          <Button variant="slim" onClick={() => router.push('/dashboard/mail-items/new')}>
            + Add Mail Item
          </Button>
          <Button variant="slim" onClick={() => router.push('/dashboard/contacts/new')}>
            + Add Contact
          </Button>
        </div>
      </div>

      {error && (
        <div className="bg-red-500/10 border border-red-500/30 rounded-lg p-6 mb-8">
          <h3 className="text-red-400 font-bold mb-2">✕ Error</h3>
          <p className="text-zinc-300">{error}</p>
        </div>
      )}

      {/* Stats Cards */}
      <div className="grid grid-cols-1 md:grid-cols-3 gap-6 mb-8">
        <div className="bg-zinc-900 border border-zinc-700 rounded-lg p-6">
          <div className="flex items-center justify-between">
            <div>
              <p className="text-zinc-400 text-sm mb-1">Total Contacts</p>
              <p className="text-4xl font-bold text-white">
                {stats?.totalContacts || 0}
              </p>
            </div>
            <div className="text-4xl">📇</div>
          </div>
        </div>

        <div className="bg-zinc-900 border border-zinc-700 rounded-lg p-6">
          <div className="flex items-center justify-between">
            <div>
              <p className="text-zinc-400 text-sm mb-1">Active Mail Items</p>
              <p className="text-4xl font-bold text-white">
                {stats?.activeMailItems || 0}
              </p>
            </div>
            <div className="text-4xl">📦</div>
          </div>
        </div>

        <div className="bg-zinc-900 border border-zinc-700 rounded-lg p-6">
          <div className="flex items-center justify-between">
            <div>
              <p className="text-zinc-400 text-sm mb-1">Pending Follow-ups</p>
              <p className="text-4xl font-bold text-white">
                {stats?.pendingFollowUps || 0}
              </p>
            </div>
            <div className="text-4xl">⏰</div>
          </div>
        </div>
      </div>

      {/* Recent Mail Items */}
      <div className="bg-zinc-900 border border-zinc-700 rounded-lg p-6 mb-8">
        <div className="flex justify-between items-center mb-4">
          <h2 className="text-xl font-bold text-white">Recent Mail Items</h2>
          <Link href="/dashboard/mail-items">
            <button className="text-blue-400 hover:text-blue-300 text-sm">
              View All →
            </button>
          </Link>
        </div>
        
        {stats?.recentMailItems && stats.recentMailItems.length > 0 ? (
          <div className="space-y-2">
            {stats.recentMailItems.slice(0, 5).map((item: any) => (
              <div 
                key={item.mail_item_id} 
                className="flex justify-between items-center p-4 border-b border-zinc-700 last:border-b-0 hover:bg-zinc-800 rounded transition-colors"
              >
                <div className="flex-1">
                  <p className="font-medium text-white">
                    {item.contact?.contact_person || item.contact?.company_name || 'Unknown Contact'}
                  </p>
                  <p className="text-sm text-zinc-400">
                    {item.item_type} • {item.status}
                  </p>
                </div>
                <div className="flex items-center gap-4">
                  <span className="text-sm text-zinc-500">
                    {getTimeAgo(item.received_date)}
                  </span>
                  <span className={`px-2 py-1 rounded text-xs border ${
                    item.status === 'Received' ? 'bg-blue-500/20 text-blue-400 border-blue-500/30' :
                    item.status === 'Notified' ? 'bg-green-500/20 text-green-400 border-green-500/30' :
                    item.status === 'Picked Up' ? 'bg-gray-500/20 text-gray-400 border-gray-500/30' :
                    'bg-yellow-500/20 text-yellow-400 border-yellow-500/30'
                  }`}>
                    {item.status}
                  </span>
                </div>
              </div>
            ))}
          </div>
        ) : (
          <div className="text-center py-12">
            <div className="text-6xl mb-4">📭</div>
            <h3 className="text-xl font-semibold text-white mb-2">No mail items yet</h3>
            <p className="text-zinc-400 mb-6">
              Get started by logging your first package
            </p>
            <Button variant="slim" onClick={() => router.push('/dashboard/mail-items/new')}>
              + Add Mail Item
            </Button>
          </div>
        )}
      </div>

      {/* Follow-ups Needed */}
      {stats && stats.pendingFollowUps > 0 && (
        <div className="bg-yellow-500/10 border border-yellow-500/30 rounded-lg p-6">
          <h2 className="text-xl font-bold text-yellow-400 mb-4">⚠️ Follow-ups Needed</h2>
          <p className="text-zinc-300 mb-4">
            You have {stats.pendingFollowUps} mail item(s) that need follow-up.
          </p>
          <Link href="/dashboard/mail-items?filter=follow-up">
            <Button variant="slim">View Follow-ups</Button>
          </Link>
        </div>
      )}
    </div>
  );
}

