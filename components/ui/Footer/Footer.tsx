import Link from 'next/link';

export default function Footer() {
  return (
    <footer className="mx-auto max-w-[1920px] px-6 bg-zinc-900">
      <div className="grid grid-cols-1 gap-8 py-12 text-white transition-colors duration-150 border-b lg:grid-cols-12 border-zinc-600 bg-zinc-900">
        <div className="col-span-1 lg:col-span-4">
          <div className="flex items-center mb-4">
            <span className="text-3xl mr-3">📬</span>
            <span className="text-xl font-bold">Mei Way Outreach Tracker</span>
          </div>
          <p className="text-zinc-400 text-sm">
            Streamline your mail center customer communication. 
            Reduce outreach time from 5 minutes to under 1 minute per customer.
          </p>
        </div>
        
        <div className="col-span-1 lg:col-span-2">
          <ul className="flex flex-col flex-initial md:flex-1">
            <li className="py-3 md:py-0 md:pb-4">
              <p className="font-bold text-white">NAVIGATION</p>
            </li>
            <li className="py-3 md:py-0 md:pb-4">
              <Link
                href="/dashboard"
                className="text-zinc-400 transition duration-150 ease-in-out hover:text-white"
              >
                Dashboard
              </Link>
            </li>
            <li className="py-3 md:py-0 md:pb-4">
              <Link
                href="/dashboard/contacts"
                className="text-zinc-400 transition duration-150 ease-in-out hover:text-white"
              >
                Contacts
              </Link>
            </li>
            <li className="py-3 md:py-0 md:pb-4">
              <Link
                href="/dashboard/mail-items"
                className="text-zinc-400 transition duration-150 ease-in-out hover:text-white"
              >
                Mail Items
              </Link>
            </li>
          </ul>
        </div>
        
        <div className="col-span-1 lg:col-span-3">
          <ul className="flex flex-col flex-initial md:flex-1">
            <li className="py-3 md:py-0 md:pb-4">
              <p className="font-bold text-white">FEATURES</p>
            </li>
            <li className="py-3 md:py-0 md:pb-4">
              <span className="text-zinc-400">📊 Centralized Dashboard</span>
            </li>
            <li className="py-3 md:py-0 md:pb-4">
              <span className="text-zinc-400">📧 Quick Templates</span>
            </li>
            <li className="py-3 md:py-0 md:pb-4">
              <span className="text-zinc-400">⏰ Auto Follow-ups</span>
            </li>
          </ul>
        </div>
        
        <div className="flex items-start col-span-1 text-white lg:col-span-3 lg:justify-end">
          <div className="flex flex-col">
            <p className="font-bold mb-4">CONTACT</p>
            <p className="text-zinc-400 text-sm mb-2">Mei Way Mail Center</p>
            <p className="text-zinc-400 text-sm">
              Built for efficient customer communication
            </p>
          </div>
        </div>
      </div>
      
      <div className="flex flex-col items-center justify-between py-12 space-y-4 md:flex-row bg-zinc-900">
        <div>
          <span className="text-zinc-400">
            &copy; {new Date().getFullYear()} Mei Way Outreach Tracker. All rights reserved.
          </span>
        </div>
        <div className="flex items-center space-x-4">
          <span className="text-zinc-500 text-sm">Built with ❤️ for mail centers</span>
        </div>
      </div>
    </footer>
  );
}
