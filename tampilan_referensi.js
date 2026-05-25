import React, { useState, useEffect } from 'react';
import { 
  Home, 
  Calendar, 
  Camera, 
  User, 
  QrCode, 
  FileText, 
  CheckCircle, 
  WifiOff,
  Wifi,
  LogOut,
  Upload,
  Settings,
  HelpCircle,
  Info,
  MapPin,
  Clock,
  BarChart3,
  ChevronLeft,
  XCircle,
  Users,
  Plus,
  Save,
  Trash2,
  Edit3,
  Mail,
  Send,
  Check,
  X,
  Search,
  CornerDownRight,
  MessageSquareText
} from 'lucide-react';

export default function App() {
  const [role, setRole] = useState(null); // 'member', 'manager'
  const [currentView, setCurrentView] = useState('home'); 
  const [selectedEvent, setSelectedEvent] = useState(null); 
  const [isOffline, setIsOffline] = useState(false);
  const [scanResult, setScanResult] = useState(null);
  const [activeTab, setActiveTab] = useState('mendatang');
  
  const [searchEvent, setSearchEvent] = useState('');
  const [searchMember, setSearchMember] = useState('');

  // Simulasi status offline/online
  useEffect(() => {
    const interval = setInterval(() => {
      setIsOffline(prev => !prev);
    }, 15000);
    return () => clearInterval(interval);
  }, []);

  const handleLogin = (selectedRole) => {
    setRole(selectedRole);
    setCurrentView('home');
  };

  const handleLogout = () => {
    setRole(null);
    setCurrentView('home');
  };

  // --- DATA MOCKUP DENGAN HIERARKI (parentId) ---
  const [eventsData, setEventsData] = useState([
    { 
      id: 1, parentId: null, title: 'Rapat Kerja HIMAKOM', date: '12 Mei 2026', time: '09:00 - 16:00', 
      location: 'Ruang Sidang Utama', type: 'Event Utama', status: 'berlangsung',
      memberAttendance: 'Belum Absen', managerStats: '124/150 Hadir'
    },
    { 
      id: 2, parentId: 1, title: 'Pleno Pagi (Divisi Ristek)', date: '12 Mei 2026', time: '09:30 - 11:30', 
      location: 'Ruang Sidang Utama', type: 'Sub-Event', status: 'berlangsung',
      memberAttendance: 'Hadir', managerStats: '45/50 Hadir'
    },
    { 
      id: 3, parentId: 1, title: 'Sesi Evaluasi Tahunan', date: '12 Mei 2026', time: '13:00 - 15:00', 
      location: 'Lab Komputer A', type: 'Sub-Event', status: 'berlangsung',
      memberAttendance: '-', managerStats: '0/80 Hadir'
    },
    { 
      id: 4, parentId: null, title: 'Musyawarah Besar (MUBES)', date: '20 Mei 2026', time: '08:00 - 16:00', 
      location: 'Auditorium Kampus', type: 'Event Utama', status: 'mendatang',
      memberAttendance: '-', managerStats: '-/150 Target'
    },
    { 
      id: 5, parentId: 4, title: 'Pemilihan Ketua Himpunan', date: '20 Mei 2026', time: '13:00 - 16:00', 
      location: 'Auditorium Kampus', type: 'Sub-Event', status: 'mendatang',
      memberAttendance: '-', managerStats: '-/150 Target'
    }
  ]);

  const [usersData, setUsersData] = useState([
    { id: 1, name: 'Budi Santoso', nim: '123456789', role: 'Member', status: 'Aktif' },
    { id: 2, name: 'Siti Aminah', nim: '123456790', role: 'Manager', status: 'Aktif' },
    { id: 3, name: 'Ahmad Faisal', nim: '123456791', role: 'Eksekutif', status: 'Aktif' },
    { id: 4, name: 'Rina Melati', nim: '123456792', role: 'Organizer', status: 'Aktif' },
    { id: 5, name: 'Dedi Kurniawan', nim: '123456793', role: 'Member', status: 'Aktif' },
  ]);

  const [hasPendingInvitation, setHasPendingInvitation] = useState(true);

  // --- VIEWS ---

  const LoginView = () => (
    <div className="flex flex-col items-center justify-center h-full p-6 bg-blue-600 text-white">
      <div className="bg-white p-4 rounded-full mb-6 shadow-lg">
        <QrCode size={64} className="text-blue-600" />
      </div>
      <h1 className="text-4xl font-bold mb-2 tracking-tight">PRASASTI</h1>
      <p className="text-blue-100 mb-12 text-center text-sm px-4">Sistem Presensi & Administrasi Terintegrasi HIMAKOM</p>
      
      <div className="w-full space-y-4">
        <button 
          onClick={() => handleLogin('member')}
          className="w-full bg-white text-blue-600 py-3.5 rounded-xl font-bold shadow-lg hover:bg-gray-50 active:scale-95 transition-all"
        >
          Masuk sebagai Member
        </button>
        <button 
          onClick={() => handleLogin('manager')}
          className="w-full bg-blue-800 text-white py-3.5 rounded-xl font-bold shadow-lg hover:bg-blue-900 active:scale-95 transition-all"
        >
          Masuk sebagai Manager (Eksekutif)
        </button>
      </div>
    </div>
  );

  const MemberHome = () => (
    <div className="p-4 pb-24 overflow-y-auto h-full space-y-6">
      
      {hasPendingInvitation && (
        <div className="bg-gradient-to-r from-amber-500 to-orange-500 rounded-2xl shadow-lg p-5 text-white relative overflow-hidden">
          <div className="absolute -right-4 -top-4 opacity-20">
            <Mail size={100} />
          </div>
          <div className="relative z-10">
            <div className="flex items-center space-x-2 mb-2">
              <span className="bg-white/20 px-2 py-1 rounded text-[10px] font-bold uppercase tracking-wide">Undangan Baru</span>
            </div>
            <h3 className="text-lg font-bold mb-1">Musyawarah Besar (MUBES)</h3>
            <p className="text-xs text-orange-100 mb-4 flex items-center"><Clock size={12} className="mr-1"/> 20 Mei 2026 • 08:00 WIB</p>
            <button 
              onClick={() => setCurrentView('invitation-detail')}
              className="bg-white text-orange-600 px-4 py-2 rounded-lg text-sm font-bold shadow-sm hover:bg-orange-50 active:scale-95 transition-transform"
            >
              Lihat & Konfirmasi
            </button>
          </div>
        </div>
      )}

      <div className="bg-white rounded-2xl shadow-sm p-6 flex flex-col items-center border border-gray-100">
        <h2 className="text-gray-500 text-sm font-medium mb-4">QR Code Kehadiran Anda</h2>
        <div className="bg-white p-4 rounded-2xl shadow-inner border-2 border-dashed border-gray-200 mb-4">
          <QrCode size={160} className="text-gray-800" />
        </div>
        <h3 className="text-xl font-bold text-gray-800">Budi Santoso</h3>
        <p className="text-sm text-blue-600 font-medium bg-blue-50 px-3 py-1 rounded-full mt-2">NIM: 123456789</p>
      </div>

      <div>
        <div className="flex justify-between items-end mb-3 px-1">
          <h3 className="text-base font-bold text-gray-800">Kegiatan Hari Ini</h3>
          <button onClick={() => setCurrentView('events')} className="text-sm text-blue-600 font-medium">Lihat Semua</button>
        </div>
        <div className="space-y-3">
          {eventsData.filter(e => e.status === 'berlangsung' && e.parentId === null).map(event => (
            <div key={event.id} className="bg-white p-4 rounded-xl shadow-sm border border-gray-100 relative overflow-hidden">
              <div className="absolute top-0 left-0 w-1 h-full bg-blue-500"></div>
              <div className="flex justify-between items-start">
                <div>
                  <span className="text-[10px] font-bold text-blue-600 bg-blue-50 px-2 py-1 rounded-md mb-2 inline-block uppercase tracking-wider">
                    {event.type}
                  </span>
                  <h4 className="font-semibold text-gray-800 text-sm">{event.title}</h4>
                  <div className="flex items-center text-xs text-gray-500 mt-2 space-x-3">
                    <span className="flex items-center"><Clock size={12} className="mr-1" /> {event.time}</span>
                    <span className="flex items-center truncate"><MapPin size={12} className="mr-1" /> {event.location}</span>
                  </div>
                </div>
              </div>
              <div className="mt-4 pt-3 border-t border-gray-50 flex gap-2">
                <button 
                  onClick={() => setCurrentView('izin')}
                  className="flex-1 text-xs bg-orange-50 text-orange-600 py-2 rounded-lg font-semibold border border-orange-100 active:scale-95 transition-transform"
                >
                  Ajukan Izin/Sakit
                </button>
              </div>
            </div>
          ))}
        </div>
      </div>
    </div>
  );

  const ManagerHome = () => (
    <div className="p-4 pb-24 overflow-y-auto h-full space-y-6">
      <div className="grid grid-cols-2 gap-3">
        <button onClick={() => setCurrentView('stats')} className="bg-blue-600 text-white p-4 rounded-2xl shadow-sm text-left active:scale-95 transition-transform">
          <div className="flex justify-between items-start mb-2">
            <p className="text-blue-100 text-xs font-medium">Total Hadir</p>
            <BarChart3 size={16} className="text-blue-200" />
          </div>
          <h2 className="text-3xl font-bold">124</h2>
          <p className="text-[10px] mt-1 bg-blue-500/50 inline-block px-2 py-0.5 rounded-full">+12 dari kemarin</p>
        </button>
        <div className="grid grid-rows-2 gap-3">
          <div className="bg-white p-3 rounded-2xl shadow-sm border border-gray-100 flex justify-between items-center">
            <div>
              <p className="text-gray-500 text-[10px] font-medium uppercase">Izin / Sakit</p>
              <p className="text-xl font-bold text-gray-800 mt-0.5">8</p>
            </div>
            <div className="bg-orange-50 p-2 rounded-full text-orange-500">
              <FileText size={16} />
            </div>
          </div>
          <div className="bg-white p-3 rounded-2xl shadow-sm border border-gray-100 flex justify-between items-center">
            <div>
              <p className="text-gray-500 text-[10px] font-medium uppercase">Perlu Validasi</p>
              <p className="text-xl font-bold text-gray-800 mt-0.5">3</p>
            </div>
            <div className="bg-red-50 p-2 rounded-full text-red-500">
              <CheckCircle size={16} />
            </div>
          </div>
        </div>
      </div>

      <div>
        <h3 className="text-sm font-bold text-gray-800 mb-3 px-1 uppercase tracking-wide">Menu Administrasi</h3>
        <div className="grid grid-cols-3 gap-3">
          <button 
            onClick={() => setCurrentView('event-form')}
            className="bg-white border border-gray-100 p-3 rounded-xl shadow-sm flex flex-col items-center justify-center text-center hover:bg-blue-50 active:scale-95 transition-all"
          >
            <div className="bg-blue-100 text-blue-600 p-2.5 rounded-full mb-2">
              <Calendar size={18} />
            </div>
            <span className="text-[10px] font-bold text-gray-800">Buat Event</span>
          </button>
          
          <button 
            onClick={() => setCurrentView('manage-invitations')}
            className="bg-white border border-gray-100 p-3 rounded-xl shadow-sm flex flex-col items-center justify-center text-center hover:bg-amber-50 active:scale-95 transition-all"
          >
            <div className="bg-amber-100 text-amber-600 p-2.5 rounded-full mb-2">
              <Mail size={18} />
            </div>
            <span className="text-[10px] font-bold text-gray-800">Undangan</span>
          </button>

          <button 
            onClick={() => setCurrentView('members')}
            className="bg-white border border-gray-100 p-3 rounded-xl shadow-sm flex flex-col items-center justify-center text-center hover:bg-indigo-50 active:scale-95 transition-all"
          >
            <div className="bg-indigo-100 text-indigo-600 p-2.5 rounded-full mb-2">
              <Users size={18} />
            </div>
            <span className="text-[10px] font-bold text-gray-800">Anggota</span>
          </button>
        </div>
      </div>

      <div>
        <div className="flex justify-between items-end mb-3 px-1">
          <h3 className="text-base font-bold text-gray-800">Event Berlangsung</h3>
          <button onClick={() => setCurrentView('events')} className="text-sm text-blue-600 font-medium">Lihat Semua</button>
        </div>
        <div className="space-y-3">
          {eventsData.filter(e => e.status === 'berlangsung' && e.parentId === null).map(event => (
            <div key={event.id} className="bg-white p-4 rounded-xl shadow-sm border border-gray-100">
              <div className="flex justify-between items-start mb-3">
                <div>
                  <h4 className="font-semibold text-gray-800 text-sm">{event.title}</h4>
                  <p className="text-[11px] text-gray-500 mt-1">{event.time} • {event.location}</p>
                </div>
                <span className="text-[10px] font-bold text-green-600 bg-green-50 px-2 py-1 rounded-md">
                  {event.managerStats}
                </span>
              </div>
              <button 
                onClick={() => setCurrentView('scan')}
                className="w-full bg-blue-50 text-blue-600 py-2.5 rounded-lg text-sm font-bold flex items-center justify-center border border-blue-100 active:bg-blue-100"
              >
                <Camera size={16} className="mr-2" /> Buka Scanner
              </button>
            </div>
          ))}
        </div>
      </div>
    </div>
  );

  const EventsView = () => {
    // 1. Filter event berdasarkan status dan pencarian
    const filteredEvents = eventsData.filter(e => 
      e.status === activeTab && 
      e.title.toLowerCase().includes(searchEvent.toLowerCase())
    );

    // 2. Pisahkan Event Utama dan Sub-Event
    const mainEvents = filteredEvents.filter(e => e.parentId === null);
    
    return (
      <div className="flex flex-col h-full bg-gray-50 pb-20">
        <div className="bg-white px-4 pt-4 pb-2 border-b border-gray-200">
          <div className="relative mb-3">
            <Search className="absolute left-3 top-1/2 -translate-y-1/2 text-gray-400" size={18} />
            <input 
              type="text" 
              placeholder="Cari nama event..." 
              value={searchEvent}
              onChange={(e) => setSearchEvent(e.target.value)}
              className="w-full bg-gray-100 text-gray-800 text-sm rounded-xl pl-10 pr-4 py-2.5 focus:outline-none focus:ring-2 focus:ring-blue-500"
            />
          </div>
          
          <div className="flex space-x-2">
            {['berlangsung', 'mendatang', 'selesai'].map(tab => (
              <button
                key={tab} onClick={() => setActiveTab(tab)}
                className={`px-4 py-2 text-sm font-medium rounded-full capitalize transition-colors ${activeTab === tab ? 'bg-blue-600 text-white' : 'bg-gray-100 text-gray-600'}`}
              >
                {tab}
              </button>
            ))}
          </div>
        </div>

        <div className="flex-1 overflow-y-auto p-4 space-y-4">
          {mainEvents.length === 0 ? (
            <div className="text-center text-gray-500 mt-10 text-sm">
              Tidak ada event yang sesuai dengan pencarian Anda.
            </div>
          ) : (
            mainEvents.map(mainEvent => {
              // Cari sub-event yang terhubung dengan mainEvent ini
              const relatedSubEvents = eventsData.filter(sub => sub.parentId === mainEvent.id);

              return (
                <div key={mainEvent.id} className="space-y-2">
                  {/* Kartu Event Utama */}
                  <div 
                    onClick={() => {
                      setSelectedEvent(mainEvent);
                      setCurrentView('event-detail');
                    }}
                    className="bg-white rounded-xl shadow-sm border border-gray-100 p-4 cursor-pointer hover:bg-gray-50 hover:border-blue-200 active:scale-95 transition-all"
                  >
                     <div className="flex justify-between items-start mb-2">
                        <span className="text-[10px] font-bold text-blue-600 bg-blue-50 px-2 py-1 rounded-md uppercase tracking-wider">{mainEvent.type}</span>
                        <span className="text-xs font-semibold text-gray-800">{mainEvent.date}</span>
                      </div>
                      <h4 className="font-bold text-gray-800 text-base mb-2">{mainEvent.title}</h4>
                      <div className="space-y-1 mb-2">
                        <p className="text-xs text-gray-600 flex items-center"><Clock size={12} className="mr-2 text-gray-400"/> {mainEvent.time}</p>
                        <p className="text-xs text-gray-600 flex items-center"><MapPin size={12} className="mr-2 text-gray-400"/> {mainEvent.location}</p>
                      </div>
                  </div>

                  {/* Hierarki Kartu Sub-Event */}
                  {relatedSubEvents.length > 0 && (
                    <div className="ml-6 border-l-2 border-gray-200 pl-3 space-y-2 relative">
                      {relatedSubEvents.map(subEvent => (
                        <div 
                          key={subEvent.id} 
                          onClick={() => {
                            setSelectedEvent(subEvent);
                            setCurrentView('event-detail');
                          }}
                          className="bg-white rounded-xl shadow-sm border border-gray-100 p-3 cursor-pointer hover:bg-gray-50 hover:border-teal-200 active:scale-95 transition-all relative"
                        >
                          <CornerDownRight size={14} className="absolute -left-5 top-4 text-gray-300" />
                          <div className="flex justify-between items-start mb-1">
                            <span className="text-[9px] font-bold text-teal-600 bg-teal-50 px-2 py-0.5 rounded uppercase tracking-wider">{subEvent.type}</span>
                            <span className="text-[10px] font-semibold text-gray-500">{subEvent.time}</span>
                          </div>
                          <h4 className="font-bold text-gray-800 text-sm mb-1">{subEvent.title}</h4>
                        </div>
                      ))}
                    </div>
                  )}
                </div>
              );
            })
          )}
        </div>
      </div>
    );
  };

  const EventDetailView = () => {
    if (!selectedEvent) return null;

    // Cek apakah event ini memiliki parent (jika ini sub-event)
    const parentEvent = selectedEvent.parentId 
      ? eventsData.find(e => e.id === selectedEvent.parentId) 
      : null;

    // Cek apakah event ini memiliki anak (jika ini event utama)
    const subEventsList = eventsData.filter(e => e.parentId === selectedEvent.id);

    // Simulasi data daftar kehadiran
    const attendanceList = [
      { id: 1, name: 'Budi Santoso', role: 'Member', status: 'Hadir', time: '08:45 WIB' },
      { id: 2, name: 'Siti Aminah', role: 'Manager', status: 'Hadir', time: '08:50 WIB' },
      { id: 3, name: 'Ahmad Faisal', role: 'Eksekutif', status: 'Izin', time: '-' },
      { id: 4, name: 'Rina Melati', role: 'Organizer', status: 'Alpha', time: '-' },
      { id: 5, name: 'Dedi Kurniawan', role: 'Member', status: 'Belum Absen', time: '-' },
    ];

    const stats = {
      hadir: attendanceList.filter(u => u.status === 'Hadir').length,
      izin: attendanceList.filter(u => u.status === 'Izin').length,
      alpha: attendanceList.filter(u => u.status === 'Alpha').length,
      belumAbsen: attendanceList.filter(u => u.status === 'Belum Absen').length,
    };

    return (
      <div className="flex flex-col h-full bg-gray-50 pb-20 overflow-y-auto">
         <div className="bg-white p-6 shadow-sm mb-4 border-b border-gray-100">
            {/* Label Hierarki Event */}
            {parentEvent ? (
               <div className="mb-3 text-[10px] font-bold text-gray-500 uppercase tracking-wide flex items-center bg-gray-50 px-3 py-2 rounded-lg border border-gray-100">
                 <CornerDownRight size={12} className="mr-2 text-gray-400" />
                 Bagian dari: <span className="ml-1 text-blue-600 truncate">{parentEvent.title}</span>
               </div>
            ) : (
               <span className="text-[10px] font-bold text-blue-600 bg-blue-50 px-3 py-1.5 rounded-md uppercase tracking-wider">
                 {selectedEvent.type}
               </span>
            )}

            <h2 className="text-2xl font-bold text-gray-800 mt-4 mb-4 leading-tight">{selectedEvent.title}</h2>
            
            <div className="grid grid-cols-4 gap-2 mb-6">
              <div className="bg-green-50 rounded-xl p-2 border border-green-100 text-center flex flex-col justify-center">
                <p className="text-[9px] text-green-600 font-bold uppercase tracking-wide mb-1">Hadir</p>
                <p className="text-lg font-bold text-green-700">{stats.hadir}</p>
              </div>
              <div className="bg-orange-50 rounded-xl p-2 border border-orange-100 text-center flex flex-col justify-center">
                <p className="text-[9px] text-orange-600 font-bold uppercase tracking-wide mb-1">Izin</p>
                <p className="text-lg font-bold text-orange-700">{stats.izin}</p>
              </div>
              <div className="bg-red-50 rounded-xl p-2 border border-red-100 text-center flex flex-col justify-center">
                <p className="text-[9px] text-red-600 font-bold uppercase tracking-wide mb-1">Alpha</p>
                <p className="text-lg font-bold text-red-700">{stats.alpha}</p>
              </div>
              <div className="bg-gray-100 rounded-xl p-2 border border-gray-200 text-center flex flex-col justify-center">
                <p className="text-[9px] text-gray-500 font-bold uppercase tracking-wide mb-1">Belum</p>
                <p className="text-lg font-bold text-gray-700">{stats.belumAbsen}</p>
              </div>
            </div>

            <div className="space-y-3 bg-gray-50 p-4 rounded-xl border border-gray-100">
              <div className="flex items-start">
                <Calendar size={18} className="mr-3 text-blue-500 mt-0.5"/> 
                <div>
                  <p className="text-[10px] font-bold text-gray-400 uppercase tracking-wide">Tanggal</p>
                  <p className="text-sm font-semibold text-gray-800">{selectedEvent.date}</p>
                </div>
              </div>
              <div className="flex items-start">
                <Clock size={18} className="mr-3 text-blue-500 mt-0.5"/> 
                <div>
                  <p className="text-[10px] font-bold text-gray-400 uppercase tracking-wide">Waktu</p>
                  <p className="text-sm font-semibold text-gray-800">{selectedEvent.time} WIB</p>
                </div>
              </div>
              <div className="flex items-start">
                <MapPin size={18} className="mr-3 text-blue-500 mt-0.5"/> 
                <div>
                  <p className="text-[10px] font-bold text-gray-400 uppercase tracking-wide">Lokasi</p>
                  <p className="text-sm font-semibold text-gray-800">{selectedEvent.location}</p>
                </div>
              </div>
            </div>
         </div>

         {/* Panel Akses Pengurus (Tanggapan Undangan) */}
         {role === 'manager' && (
           <div className="px-4 mb-6">
              <div className="bg-blue-50 border border-blue-100 p-4 rounded-xl flex items-center justify-between shadow-sm">
                 <div>
                   <h4 className="text-sm font-bold text-blue-800">Tanggapan Undangan</h4>
                   <p className="text-[10px] text-blue-600 mt-0.5">2 Hadir, 1 Izin, 2 Menunggu</p>
                 </div>
                 <button
                   onClick={() => setCurrentView('invitation-responses')}
                   className="bg-blue-600 text-white px-4 py-2 rounded-lg text-xs font-bold shadow-sm active:scale-95 transition-transform"
                 >
                   Kelola
                 </button>
              </div>
           </div>
         )}

         {/* Rangkaian Sub-Event (Hanya muncul jika ini Event Utama & memiliki sub-event) */}
         {subEventsList.length > 0 && (
           <div className="px-4 mb-6">
             <div className="flex justify-between items-end mb-3 px-1">
               <h3 className="text-sm font-bold text-gray-800 uppercase tracking-wide">Rangkaian Sub-Event</h3>
             </div>
             <div className="space-y-2">
               {subEventsList.map(sub => (
                 <div 
                   key={sub.id} 
                   onClick={() => setSelectedEvent(sub)}
                   className="bg-white p-3 rounded-xl shadow-sm border border-gray-100 flex justify-between items-center cursor-pointer hover:bg-gray-50 hover:border-teal-200 transition-all"
                 >
                   <div className="flex items-center space-x-3">
                     <div className="bg-teal-50 text-teal-600 p-2 rounded-lg"><Calendar size={16} /></div>
                     <div>
                       <h4 className="text-sm font-bold text-gray-800">{sub.title}</h4>
                       <p className="text-[10px] text-gray-500">{sub.time} • {sub.location}</p>
                     </div>
                   </div>
                   <ChevronLeft size={16} className="text-gray-400 transform rotate-180" />
                 </div>
               ))}
             </div>
           </div>
         )}

         {/* Daftar Kehadiran (Scan History) */}
         <div className="px-4">
           <div className="flex justify-between items-end mb-3 px-1">
             <h3 className="text-sm font-bold text-gray-800 uppercase tracking-wide">Daftar Kehadiran</h3>
             <span className="text-[10px] font-bold text-gray-500 bg-gray-200 px-2 py-1 rounded-full">{attendanceList.length} Peserta</span>
           </div>
           
           <div className="space-y-3">
             {attendanceList.map(user => (
               <div key={user.id} className="bg-white p-4 rounded-xl shadow-sm border border-gray-100 flex justify-between items-center">
                 <div className="flex items-center space-x-3">
                   <div className={`w-10 h-10 rounded-full flex items-center justify-center font-bold text-sm ${
                      user.status === 'Hadir' ? 'bg-green-100 text-green-700' :
                      user.status === 'Izin' ? 'bg-orange-100 text-orange-700' :
                      'bg-gray-100 text-gray-500'
                   }`}>
                     {user.name.substring(0, 2).toUpperCase()}
                   </div>
                   <div>
                     <h4 className="text-sm font-bold text-gray-800">{user.name}</h4>
                     <p className="text-[10px] text-gray-500">{user.role} • {user.time !== '-' ? `Absen: ${user.time}` : 'Belum ada data'}</p>
                   </div>
                 </div>
                 <span className={`text-[10px] font-bold px-2.5 py-1 rounded uppercase tracking-wide ${
                    user.status === 'Hadir' ? 'bg-green-100 text-green-700' :
                    user.status === 'Izin' ? 'bg-orange-100 text-orange-700' :
                    user.status === 'Alpha' ? 'bg-red-100 text-red-700' :
                    'bg-gray-100 text-gray-600'
                 }`}>
                   {user.status}
                 </span>
               </div>
             ))}
           </div>
         </div>
      </div>
    );
  };

  const InvitationResponsesView = () => {
    const [rsvpFilter, setRsvpFilter] = useState('Semua');
    const [rsvpSearch, setRsvpSearch] = useState('');

    // Simulasi data RSVP
    const rsvpList = [
      { id: 1, name: 'Budi Santoso', nim: '123456789', role: 'Member', status: 'Hadir' },
      { id: 2, name: 'Siti Aminah', nim: '123456790', role: 'Manager', status: 'Hadir' },
      { id: 3, name: 'Ahmad Faisal', nim: '123456791', role: 'Eksekutif', status: 'Izin', reason: 'Terdapat kelas pengganti' },
      { id: 4, name: 'Rina Melati', nim: '123456792', role: 'Organizer', status: 'Menunggu' },
      { id: 5, name: 'Dedi Kurniawan', nim: '123456793', role: 'Member', status: 'Menunggu' },
    ];

    const stats = {
      total: rsvpList.length,
      hadir: rsvpList.filter(r => r.status === 'Hadir').length,
      izin: rsvpList.filter(r => r.status === 'Izin').length,
      menunggu: rsvpList.filter(r => r.status === 'Menunggu').length,
    };

    const filteredRsvp = rsvpList.filter(item => {
      const matchSearch = item.name.toLowerCase().includes(rsvpSearch.toLowerCase()) || item.nim.includes(rsvpSearch);
      const matchFilter = rsvpFilter === 'Semua' || item.status === rsvpFilter;
      return matchSearch && matchFilter;
    });

    return (
      <div className="flex flex-col h-full bg-gray-50 pb-20 overflow-y-auto">
        
        {/* Ringkasan Header */}
        <div className="bg-white p-5 border-b border-gray-100 shadow-sm relative">
          <h2 className="text-xl font-bold text-gray-800 mb-3">{selectedEvent?.title || 'Rapat Kerja HIMAKOM'}</h2>
          
          <div className="grid grid-cols-4 gap-2 mt-4">
            <div className="bg-blue-50 rounded-xl p-2 border border-blue-100 text-center flex flex-col justify-center">
              <p className="text-[9px] text-blue-600 font-bold uppercase tracking-wide mb-1">Total</p>
              <p className="text-lg font-bold text-blue-700">{stats.total}</p>
            </div>
            <div className="bg-green-50 rounded-xl p-2 border border-green-100 text-center flex flex-col justify-center">
              <p className="text-[9px] text-green-600 font-bold uppercase tracking-wide mb-1">Hadir</p>
              <p className="text-lg font-bold text-green-700">{stats.hadir}</p>
            </div>
            <div className="bg-orange-50 rounded-xl p-2 border border-orange-100 text-center flex flex-col justify-center">
              <p className="text-[9px] text-orange-600 font-bold uppercase tracking-wide mb-1">Izin</p>
              <p className="text-lg font-bold text-orange-700">{stats.izin}</p>
            </div>
            <div className="bg-gray-100 rounded-xl p-2 border border-gray-200 text-center flex flex-col justify-center">
              <p className="text-[9px] text-gray-500 font-bold uppercase tracking-wide mb-1">Menunggu</p>
              <p className="text-lg font-bold text-gray-700">{stats.menunggu}</p>
            </div>
          </div>
        </div>

        {/* Pencarian dan Filter */}
        <div className="bg-white px-5 pt-4 pb-2 border-b border-gray-200 shadow-sm sticky top-0 z-10">
          <div className="relative mb-3">
            <Search className="absolute left-3 top-1/2 -translate-y-1/2 text-gray-400" size={18} />
            <input 
              type="text" 
              placeholder="Cari nama atau NIM..." 
              value={rsvpSearch}
              onChange={(e) => setRsvpSearch(e.target.value)}
              className="w-full bg-gray-100 text-gray-800 text-sm rounded-xl pl-10 pr-4 py-2.5 outline-none focus:ring-2 focus:ring-blue-500 transition-all"
            />
          </div>
          
          <div className="flex overflow-x-auto space-x-2 pb-2 hide-scrollbar" style={{ msOverflowStyle: 'none', scrollbarWidth: 'none' }}>
            {['Semua', 'Hadir', 'Izin', 'Menunggu'].map(status => (
              <button
                key={status} 
                onClick={() => setRsvpFilter(status)}
                className={`px-4 py-1.5 text-xs font-bold rounded-full whitespace-nowrap transition-colors border ${
                  rsvpFilter === status 
                  ? 'bg-blue-600 text-white border-blue-600 shadow-sm' 
                  : 'bg-white text-gray-600 border-gray-200 hover:bg-gray-50'
                }`}
              >
                {status}
              </button>
            ))}
          </div>
        </div>

        {/* Daftar Tanggapan */}
        <div className="p-4 space-y-3">
          {filteredRsvp.length === 0 ? (
            <div className="text-center text-gray-500 mt-10 text-sm">
              Tidak ada data yang sesuai.
            </div>
          ) : (
            filteredRsvp.map(user => (
              <div key={user.id} className="bg-white p-4 rounded-xl shadow-sm border border-gray-100">
                <div className="flex justify-between items-center mb-2">
                  <div className="flex items-center space-x-3">
                    <div className="w-10 h-10 rounded-full flex items-center justify-center font-bold text-sm bg-gray-100 text-gray-600">
                      {user.name.substring(0, 2).toUpperCase()}
                    </div>
                    <div>
                      <h4 className="text-sm font-bold text-gray-800">{user.name}</h4>
                      <p className="text-[10px] text-gray-500">{user.role} • {user.nim}</p>
                    </div>
                  </div>
                  <span className={`text-[10px] font-bold px-2.5 py-1 rounded uppercase tracking-wide ${
                      user.status === 'Hadir' ? 'bg-green-100 text-green-700' :
                      user.status === 'Izin' ? 'bg-orange-100 text-orange-700' :
                      'bg-gray-100 text-gray-500'
                  }`}>
                    {user.status}
                  </span>
                </div>
                
                {/* Tampilkan detail alasan jika statusnya Izin */}
                {user.status === 'Izin' && user.reason && (
                  <div className="mt-3 pt-3 border-t border-gray-50 flex items-start justify-between">
                    <p className="text-[11px] text-gray-600 italic bg-orange-50/50 p-2 rounded-lg border border-orange-100/50 flex-1 mr-2">
                      "{user.reason}"
                    </p>
                    <button className="text-[10px] font-bold bg-orange-50 text-orange-600 px-3 py-1.5 rounded-lg active:scale-95 transition-transform whitespace-nowrap border border-orange-100">
                      Lihat Bukti
                    </button>
                  </div>
                )}
              </div>
            ))
          )}
        </div>
      </div>
    );
  };

  const ProfileView = () => (
    <div className="p-4 pb-24 h-full bg-gray-50 overflow-y-auto">
      <div className="bg-blue-600 rounded-3xl p-6 text-white mb-6 shadow-lg relative overflow-hidden">
        <div className="absolute -right-10 -top-10 w-32 h-32 bg-blue-500 rounded-full opacity-50 blur-2xl"></div>
        <div className="flex items-center space-x-4 relative z-10">
          <div className="w-16 h-16 bg-white rounded-full flex items-center justify-center text-blue-600 text-2xl font-bold">BS</div>
          <div>
            <h2 className="text-xl font-bold">Budi Santoso</h2>
            <p className="text-blue-100 text-sm">NIM: 123456789</p>
            <div className="mt-1 inline-block bg-blue-800/50 px-2 py-0.5 rounded text-xs font-medium border border-blue-500/30">
              {role === 'manager' ? 'Pengurus (Manager)' : 'Anggota (Member)'}
            </div>
          </div>
        </div>
      </div>
      <button onClick={handleLogout} className="w-full bg-red-50 text-red-600 p-4 rounded-xl flex items-center justify-center border border-red-100 font-bold">
        <LogOut size={18} className="mr-2" /> Keluar Aplikasi
      </button>
    </div>
  );

  const MembersView = () => {
    const filteredMembers = usersData.filter(user => 
      user.name.toLowerCase().includes(searchMember.toLowerCase()) || 
      user.nim.includes(searchMember) ||
      user.role.toLowerCase().includes(searchMember.toLowerCase())
    );

    return (
      <div className="flex flex-col h-full bg-gray-50 pb-20">
        <div className="bg-white px-4 py-3 border-b border-gray-200">
          <div className="relative">
            <Search className="absolute left-3 top-1/2 -translate-y-1/2 text-gray-400" size={18} />
            <input 
              type="text" 
              placeholder="Cari nama, NIM, atau peran..." 
              value={searchMember}
              onChange={(e) => setSearchMember(e.target.value)}
              className="w-full bg-gray-100 text-gray-800 text-sm rounded-xl pl-10 pr-4 py-2.5 focus:outline-none focus:ring-2 focus:ring-blue-500"
            />
          </div>
        </div>
        
        <div className="flex-1 overflow-y-auto p-4 space-y-3">
          {filteredMembers.length === 0 ? (
            <div className="text-center text-gray-500 mt-10 text-sm">
              Tidak ada anggota yang ditemukan.
            </div>
          ) : (
            filteredMembers.map(user => (
              <div key={user.id} className="bg-white rounded-xl shadow-sm border border-gray-100 p-4 flex justify-between items-center">
                <div className="flex items-center space-x-3">
                  <div className="w-10 h-10 bg-gray-100 rounded-full flex items-center justify-center text-gray-600 font-bold text-sm">
                    {user.name.substring(0, 2).toUpperCase()}
                  </div>
                  <div>
                    <h4 className="font-bold text-gray-800 text-sm">{user.name}</h4>
                    <p className="text-xs text-gray-500">{user.nim}</p>
                  </div>
                </div>
                <div className="flex flex-col items-end">
                  <span className={`text-[10px] font-bold px-2 py-1 rounded uppercase tracking-wide mb-1 ${
                    user.role === 'Eksekutif' ? 'bg-purple-100 text-purple-700' :
                    user.role === 'Manager' ? 'bg-blue-100 text-blue-700' :
                    user.role === 'Organizer' ? 'bg-orange-100 text-orange-700' :
                    'bg-gray-100 text-gray-700'
                  }`}>
                    {user.role}
                  </span>
                  <button className="text-gray-400 hover:text-blue-600">
                    <Edit3 size={16} />
                  </button>
                </div>
              </div>
            ))
          )}
        </div>
      </div>
    );
  };

  const MemberFormView = () => (
    <div className="p-4 h-full bg-white overflow-y-auto pb-24">
      <div className="space-y-4">
        <div>
          <label className="block text-xs font-bold text-gray-700 mb-1 uppercase tracking-wide">Nama Lengkap</label>
          <input type="text" placeholder="Masukkan nama lengkap" className="w-full border border-gray-200 rounded-xl p-3.5 bg-gray-50 text-gray-800 focus:outline-none focus:ring-2 focus:ring-blue-500 focus:border-transparent text-sm" />
        </div>

        <div>
          <label className="block text-xs font-bold text-gray-700 mb-1 uppercase tracking-wide">NIM (Nomor Induk Mahasiswa)</label>
          <input type="number" placeholder="Contoh: 123456789" className="w-full border border-gray-200 rounded-xl p-3.5 bg-gray-50 text-gray-800 focus:outline-none focus:ring-2 focus:ring-blue-500 focus:border-transparent text-sm" />
        </div>
        
        <div>
          <label className="block text-xs font-bold text-gray-700 mb-1 uppercase tracking-wide">Peran (Role Sistem)</label>
          <select className="w-full border border-gray-200 rounded-xl p-3.5 bg-gray-50 text-gray-800 focus:outline-none focus:ring-2 focus:ring-blue-500 focus:border-transparent text-sm">
            <option>Member (Anggota Biasa)</option>
            <option>Organizer (Ketua/Waka Dept)</option>
            <option>Manager (Admin/Kesekretariatan)</option>
            <option>Eksekutif (Ketua Himpunan)</option>
          </select>
        </div>

        <button 
          onClick={() => {
            alert("Simulasi: Data anggota berhasil disimpan ke database lokal (Hive).");
            setCurrentView('members');
          }}
          className="w-full bg-blue-600 text-white py-4 rounded-xl font-bold shadow-lg shadow-blue-200 hover:bg-blue-700 mt-6 active:scale-95 transition-all flex justify-center items-center"
        >
          <Save size={18} className="mr-2" /> Simpan Data Anggota
        </button>
      </div>
    </div>
  );

  const EventFormView = () => (
    <div className="p-4 h-full bg-white overflow-y-auto pb-24">
      <div className="space-y-4">
        <div>
          <label className="block text-xs font-bold text-gray-700 mb-1 uppercase tracking-wide">Nama Kegiatan</label>
          <input type="text" placeholder="Contoh: Musyawarah Besar" className="w-full border border-gray-200 rounded-xl p-3.5 bg-gray-50 text-gray-800 focus:outline-none focus:ring-2 focus:ring-blue-500 focus:border-transparent text-sm" />
        </div>

        <div>
          <label className="block text-xs font-bold text-gray-700 mb-1 uppercase tracking-wide">Jenis Kegiatan</label>
          <select className="w-full border border-gray-200 rounded-xl p-3.5 bg-gray-50 text-gray-800 focus:outline-none focus:ring-2 focus:ring-blue-500 focus:border-transparent text-sm">
            <option>Event Utama</option>
            <option>Sub-Event</option>
          </select>
        </div>

        <div className="grid grid-cols-2 gap-4">
          <div>
            <label className="block text-xs font-bold text-gray-700 mb-1 uppercase tracking-wide">Tanggal</label>
            <input type="date" className="w-full border border-gray-200 rounded-xl p-3.5 bg-gray-50 text-gray-800 focus:outline-none focus:ring-2 focus:ring-blue-500 focus:border-transparent text-sm" />
          </div>
          <div>
            <label className="block text-xs font-bold text-gray-700 mb-1 uppercase tracking-wide">Waktu (Mulai)</label>
            <input type="time" className="w-full border border-gray-200 rounded-xl p-3.5 bg-gray-50 text-gray-800 focus:outline-none focus:ring-2 focus:ring-blue-500 focus:border-transparent text-sm" />
          </div>
        </div>

        <div>
          <label className="block text-xs font-bold text-gray-700 mb-1 uppercase tracking-wide">Lokasi / Tempat</label>
          <input type="text" placeholder="Contoh: Ruang Sidang Utama" className="w-full border border-gray-200 rounded-xl p-3.5 bg-gray-50 text-gray-800 focus:outline-none focus:ring-2 focus:ring-blue-500 focus:border-transparent text-sm" />
        </div>

        <div className="bg-blue-50 border border-blue-100 p-4 rounded-xl mt-4">
          <div className="flex items-start">
            <Info size={16} className="text-blue-600 mt-0.5 mr-2 flex-shrink-0" />
            <p className="text-xs text-blue-800 leading-relaxed">
              Karena sistem menggunakan konsep <strong>Offline-First</strong>, data event akan disimpan di memori lokal (Hive) terlebih dahulu dan otomatis disinkronkan ke cloud saat koneksi tersedia.
            </p>
          </div>
        </div>

        <button 
          onClick={() => {
            alert("Simulasi: Event berhasil dibuat. Disimpan ke lokal.");
            setCurrentView('home');
          }}
          className="w-full bg-blue-600 text-white py-4 rounded-xl font-bold shadow-lg shadow-blue-200 hover:bg-blue-700 mt-6 active:scale-95 transition-all flex justify-center items-center"
        >
          <Save size={18} className="mr-2" /> Simpan Event
        </button>
      </div>
    </div>
  );

  const IzinView = () => (
    <div className="p-4 h-full bg-white overflow-y-auto pb-24">
      <div className="space-y-4">
        <div>
          <label className="block text-xs font-bold text-gray-700 mb-1 uppercase tracking-wide">Pilih Event/Kegiatan</label>
          <select className="w-full border border-gray-200 rounded-xl p-3 bg-gray-50 text-gray-800 focus:outline-none focus:ring-2 focus:ring-blue-500 text-sm">
            <option>Musyawarah Besar (MUBES) - 20 Mei 2026</option>
            <option>Rapat Kerja HIMAKOM - 12 Mei 2026</option>
          </select>
        </div>
        <div>
          <label className="block text-xs font-bold text-gray-700 mb-1 uppercase tracking-wide">Keterangan</label>
          <select className="w-full border border-gray-200 rounded-xl p-3 bg-gray-50 text-gray-800 focus:outline-none focus:ring-2 focus:ring-blue-500 text-sm">
            <option>Sakit (Lampirkan Surat)</option>
            <option>Izin - Urusan Akademik/Kuliah</option>
            <option>Izin - Keperluan Keluarga</option>
          </select>
        </div>
        <div>
          <label className="block text-xs font-bold text-gray-700 mb-1 uppercase tracking-wide">Bukti (Opsional)</label>
          <div className="border-2 border-dashed border-gray-300 rounded-xl p-8 flex flex-col items-center justify-center bg-gray-50 text-gray-400">
            <Upload size={32} className="mb-2" />
            <span className="text-sm">Unggah File/Foto</span>
          </div>
        </div>
      </div>

      <button onClick={() => setCurrentView('home')} className="w-full bg-blue-600 text-white py-4 rounded-xl font-bold mt-6 shadow-md hover:bg-blue-700 active:scale-95 transition-all">Kirim Pengajuan</button>
    </div>
  );

  const StatsView = () => (
    <div className="p-4 h-full bg-gray-50 overflow-y-auto pb-24">
    </div>
  );

  const ScanQRView = () => (
    <div className="bg-gray-900 h-full flex flex-col relative">
      <div className="flex-1 flex flex-col items-center justify-center p-6">
        <button onClick={() => setCurrentView('home')} className="bg-blue-600 text-white px-8 py-3.5 rounded-full font-bold">Tutup Pemindai</button>
      </div>
    </div>
  );

  const ManageInvitationsView = () => {
    return (
      <div className="flex flex-col h-full bg-gray-50 pb-20">
        <div className="flex-1 overflow-y-auto p-4 space-y-4">
          <div className="bg-white p-4 rounded-xl shadow-sm border border-gray-100">
            <label className="block text-xs font-bold text-gray-700 mb-2 uppercase tracking-wide">Pilih Event/Sub-Event</label>
            <select className="w-full border border-gray-200 rounded-xl p-3 bg-gray-50 text-gray-800 focus:outline-none focus:ring-2 focus:ring-blue-500 focus:border-transparent text-sm">
              <option>Musyawarah Besar (MUBES) - 20 Mei 2026</option>
              <option>Rapat Kerja HIMAKOM - 12 Mei 2026</option>
              <option>Pelatihan Jaringan - 14 Mei 2026</option>
            </select>
          </div>
          <button 
            onClick={() => {
              alert("Undangan berhasil disebar! Data sinkronisasi tertunda karena offline mode (Simulasi).");
              setCurrentView('home');
            }}
            className="w-full bg-blue-600 text-white py-4 rounded-xl font-bold shadow-lg shadow-blue-200 hover:bg-blue-700 active:scale-95 transition-all flex justify-center items-center"
          >
            <Send size={18} className="mr-2" /> Kirim Undangan Massal
          </button>
        </div>
      </div>
    );
  };

  const InvitationDetailView = () => (
    <div className="flex flex-col h-full bg-white pb-20">
      <div className="p-5 flex-1 overflow-y-auto">
        <div className="flex justify-center mb-6">
          <div className="bg-amber-100 p-4 rounded-full text-amber-500">
            <Mail size={48} />
          </div>
        </div>
        
        <div className="text-center mb-8">
          <h1 className="text-2xl font-bold text-gray-800 mb-2">Musyawarah Besar (MUBES)</h1>
          <p className="text-sm text-gray-500 mb-4">Pengurus HIMAKOM mengundang Anda untuk hadir pada kegiatan ini.</p>
          
          <div className="bg-gray-50 rounded-xl p-4 border border-gray-100 text-left space-y-3">
            <div className="flex items-start">
              <Calendar size={18} className="text-blue-500 mt-0.5 mr-3 flex-shrink-0" />
              <div>
                <p className="text-[10px] font-bold text-gray-400 uppercase tracking-wide">Tanggal</p>
                <p className="text-sm font-semibold text-gray-800">Rabu, 20 Mei 2026</p>
              </div>
            </div>
            <div className="flex items-start">
              <Clock size={18} className="text-blue-500 mt-0.5 mr-3 flex-shrink-0" />
              <div>
                <p className="text-[10px] font-bold text-gray-400 uppercase tracking-wide">Waktu</p>
                <p className="text-sm font-semibold text-gray-800">08:00 - 16:00 WIB</p>
              </div>
            </div>
            <div className="flex items-start">
              <MapPin size={18} className="text-blue-500 mt-0.5 mr-3 flex-shrink-0" />
              <div>
                <p className="text-[10px] font-bold text-gray-400 uppercase tracking-wide">Lokasi</p>
                <p className="text-sm font-semibold text-gray-800">Auditorium Kampus Utama</p>
              </div>
            </div>
          </div>
        </div>

        <div className="space-y-3 border-t border-gray-100 pt-6">
          <h3 className="text-sm font-bold text-gray-800 text-center mb-4">Apakah Anda bersedia hadir?</h3>
          
          <button 
            onClick={() => {
              alert("Terima kasih! Kehadiran Anda telah dikonfirmasi.");
              setHasPendingInvitation(false);
              setCurrentView('home');
            }}
            className="w-full bg-green-600 text-white py-3.5 rounded-xl font-bold shadow-sm shadow-green-200 hover:bg-green-700 active:scale-95 transition-all flex justify-center items-center"
          >
            <Check size={18} className="mr-2" /> Ya, Saya Akan Hadir
          </button>
          
          <button 
            onClick={() => {
              setHasPendingInvitation(false);
              setCurrentView('izin');
            }}
            className="w-full bg-white text-orange-600 border-2 border-orange-100 py-3.5 rounded-xl font-bold hover:bg-orange-50 active:scale-95 transition-all flex justify-center items-center"
          >
            <X size={18} className="mr-2" /> Tidak, Ajukan Izin
          </button>
        </div>
      </div>
    </div>
  );

  // --- LAYOUT COMPONENTS ---
  const Header = () => {
    const viewTitles = {
      home: "PRASASTI",
      events: "Katalog Event",
      'event-detail': "Detail Kegiatan",
      profile: "Profil Pengguna",
      members: "Daftar Anggota",
      'member-form': "Tambah Anggota",
      'event-form': "Buat Event Baru",
      'manage-invitations': "Kelola Target Peserta",
      'invitation-detail': "Detail Undangan",
      'invitation-responses': "Tanggapan Undangan",
      izin: "Pengajuan Izin",
      stats: "Statistik Kehadiran",
      scan: "Pemindai QR",
    };
    
    const title = viewTitles[currentView] || "PRASASTI";
    const showBackButton = currentView !== 'home';

    const handleBack = () => {
      if (currentView === 'member-form') setCurrentView('members');
      else if (currentView === 'event-detail') setCurrentView('events');
      else if (currentView === 'invitation-responses') setCurrentView('event-detail');
      else setCurrentView('home');
    };

    return (
      <div className="bg-white pt-10 pb-4 px-5 flex justify-between items-center shadow-sm z-20 sticky top-0">
        <div className="flex items-center">
          {showBackButton && (
            <button onClick={handleBack} className="mr-3 text-gray-500 bg-gray-100 p-2 rounded-full active:scale-95 transition-transform">
              <ChevronLeft size={20} />
            </button>
          )}
          <div>
            <h1 className="text-xl font-bold text-gray-800 flex items-center tracking-tight">{title}</h1>
            {isOffline ? (
              <div className="flex items-center text-orange-500 text-[10px] mt-1 font-bold bg-orange-50 px-2 py-0.5 rounded-full w-max">
                <WifiOff size={10} className="mr-1" /> OFFLINE (SIMPAN LOKAL)
              </div>
            ) : (
              <div className="flex items-center text-green-600 text-[10px] mt-1 font-bold bg-green-50 px-2 py-0.5 rounded-full w-max">
                <Wifi size={10} className="mr-1" /> TERSINKRONISASI
              </div>
            )}
          </div>
        </div>
        
        {currentView === 'members' && (
          <button 
            onClick={() => setCurrentView('member-form')}
            className="bg-blue-600 text-white p-2 rounded-lg flex items-center justify-center shadow-sm active:scale-95 transition-transform"
          >
            <Plus size={20} />
          </button>
        )}
      </div>
    );
  };

  const BottomNav = () => (
    <div className="absolute bottom-0 w-full bg-white border-t border-gray-100 flex justify-around items-center py-2 px-6 pb-6 z-20 shadow-[0_-4px_20px_rgba(0,0,0,0.05)]">
      <button onClick={() => setCurrentView('home')} className={`flex flex-col items-center p-2 ${['home', 'stats', 'event-form', 'manage-invitations'].includes(currentView) ? 'text-blue-600' : 'text-gray-400'}`}>
        <Home size={22} /><span className="text-[10px] mt-1 font-bold">Beranda</span>
      </button>

      {role === 'manager' && (
        <button onClick={() => setCurrentView('members')} className={`flex flex-col items-center p-2 ${['members', 'member-form'].includes(currentView) ? 'text-blue-600' : 'text-gray-400'}`}>
          <Users size={22} /><span className="text-[10px] mt-1 font-bold">Anggota</span>
        </button>
      )}
      
      {role === 'manager' ? (
        <button onClick={() => setCurrentView('scan')} className={`flex flex-col items-center p-2 -mt-8 bg-blue-600 text-white rounded-full shadow-lg border-4 border-gray-50 h-[68px] w-[68px] justify-center active:scale-95 transition-transform`}>
          <Camera size={28} />
        </button>
      ) : (
        <button onClick={() => setCurrentView('events')} className={`flex flex-col items-center p-2 ${currentView === 'events' ? 'text-blue-600' : 'text-gray-400'}`}>
          <Calendar size={22} /><span className="text-[10px] mt-1 font-bold">Event</span>
        </button>
      )}

      {role === 'manager' && (
         <button onClick={() => setCurrentView('events')} className={`flex flex-col items-center p-2 ${currentView === 'events' ? 'text-blue-600' : 'text-gray-400'}`}>
         <Calendar size={22} /><span className="text-[10px] mt-1 font-bold">Event</span>
       </button>
      )}

      <button onClick={() => setCurrentView('profile')} className={`flex flex-col items-center p-2 ${currentView === 'profile' ? 'text-blue-600' : 'text-gray-400'}`}>
        <User size={22} /><span className="text-[10px] mt-1 font-bold">Profil</span>
      </button>
    </div>
  );

  if (!role) {
    return (
      <div className="flex justify-center bg-gray-900 min-h-screen">
        <div className="w-full max-w-md bg-white h-screen relative overflow-hidden shadow-2xl"><LoginView /></div>
      </div>
    );
  }

  const showBottomNav = !['scan', 'izin', 'invitation-detail', 'event-detail', 'invitation-responses'].includes(currentView);

  return (
    <div className="flex justify-center bg-gray-900 min-h-screen font-sans">
      <div className="w-full max-w-md bg-gray-100 h-screen flex flex-col relative shadow-2xl overflow-hidden">
        <Header />
        <div className="flex-1 overflow-hidden relative">
          {currentView === 'home' && role === 'member' && <MemberHome />}
          {currentView === 'home' && role === 'manager' && <ManagerHome />}
          {currentView === 'events' && <EventsView />}
          {currentView === 'profile' && <ProfileView />}
          {currentView === 'scan' && role === 'manager' && <ScanQRView />}
          {currentView === 'izin' && role === 'member' && <IzinView />}
          {currentView === 'stats' && role === 'manager' && <StatsView />}
          {currentView === 'members' && role === 'manager' && <MembersView />}
          {currentView === 'member-form' && role === 'manager' && <MemberFormView />}
          {currentView === 'event-form' && role === 'manager' && <EventFormView />}
          {currentView === 'manage-invitations' && role === 'manager' && <ManageInvitationsView />}
          {currentView === 'invitation-detail' && role === 'member' && <InvitationDetailView />}
          {currentView === 'event-detail' && <EventDetailView />}
          {currentView === 'invitation-responses' && role === 'manager' && <InvitationResponsesView />}
        </div>
        {showBottomNav && <BottomNav />}
      </div>
    </div>
  );
}