import { useState, useEffect } from 'react';
import {
  Zap,
  Flame,
  Sparkles,
  Wind,
  Shield,
  Target,
  Crown,
  Eye,
  Activity,
  Maximize2,
  Volume2,
  VolumeX,
  Play,
  RotateCcw,
  Trophy,
  Code,
  Smartphone,
  ChevronRight,
  User,
  Sword,
  Compass,
  CornerDownRight,
  Info
} from 'lucide-react';
import { GameCanvas } from './components/GameCanvas';
import { CodeExplorer } from './components/CodeExplorer';
import { audioSynth } from './components/AudioSynth';

// Define Roster list with details
const KARTS_ROSTER = [
  {
    id: 'e_eak',
    name: 'อีเอก (E-eak)',
    driver: 'เอกชัย',
    colorName: 'สีแดงชาด (Neon Red)',
    colorClass: 'bg-red-500',
    colorHex: '#EF4444',
    icon: Zap,
    ultName: 'พุ่งชนดุดัน (Eak Dash)',
    ultDesc: 'พุ่งชนกระแทกเป้าหมายข้างหน้าอย่างรวดเร็ว ทำดาเมจ 45 HP และผลักเป้าหมายกระเด็นรุนแรง',
    stats: { speed: 85, armor: 70, power: 90 },
  },
  {
    id: 'p_daeng',
    name: 'พี่แดง (P\'Daeng)',
    driver: 'สมแดง',
    colorName: 'สีส้มเพลิง (Flame Orange)',
    colorClass: 'bg-orange-500',
    colorHex: '#F97316',
    icon: Flame,
    ultName: 'พายุหมุนลูกไฟ (Crimson Vortex)',
    ultDesc: 'สร้างพายุหมุนเพลิงรอบตัวเอง ดึงดูดศัตรูเข้ามาบดทำดาเมจต่อเนื่อง รวม 40 HP นาน 3.5 วินาที',
    stats: { speed: 80, armor: 80, power: 85 },
  },
  {
    id: 'white_tiger',
    name: 'เสือขาว (White Tiger)',
    driver: 'วายุ',
    colorName: 'สีขาวเมฆา (Cloud Slate)',
    colorClass: 'bg-slate-500',
    colorHex: '#64748B',
    icon: Sparkles,
    ultName: 'เลเซอร์จู่โจม (Tiger Beam)',
    ultDesc: 'ยิงแสงเลเซอร์สีฟ้ายักษ์ทำลายล้างตรงยาวไปด้านหน้า ทะลุสิ่งกีดขวางดาเมจหนักหน่วง 50 HP',
    stats: { speed: 75, armor: 90, power: 80 },
  },
  {
    id: 'wind_monkey',
    name: 'ลิงลม (Wind Monkey)',
    driver: 'หนุมาน',
    colorName: 'สีเหลืองทอง (Gold Amber)',
    colorClass: 'bg-amber-500',
    colorHex: '#F59E0B',
    icon: Wind,
    ultName: 'แยกร่างลวงตา (Shadow Mirage)',
    ultDesc: 'สร้างหมอกลวงตารอบตัว บูสต์ความเร็วเต็มสูบ ล่องหนเป็นอมตะ 100% นาน 4.5 วินาที',
    stats: { speed: 95, armor: 60, power: 75 },
  },
  {
    id: 'thunder_hawk',
    name: 'นกสายฟ้า (Thunder Hawk)',
    driver: 'อินทรี',
    colorName: 'สีม่วงดาร์ก (Deep Purple)',
    colorClass: 'bg-purple-500',
    colorHex: '#A855F7',
    icon: Activity,
    ultName: 'พายุสายฟ้าบาเรีย (Electro Shield)',
    ultDesc: 'กางเกราะสะท้อนการโจมตีรอบรถ ช็อตและล็อกศัตรูที่อยู่ใกล้ให้สตันนาน 2 วินาที ทำดาเมจ 30 HP',
    stats: { speed: 80, armor: 75, power: 85 },
  },
  {
    id: 'challenger_turtle',
    name: 'เต่าคะนอง (Challenger Turtle)',
    driver: 'พสุธา',
    colorName: 'สีเขียวมรกต (Emerald)',
    colorClass: 'bg-green-500',
    colorHex: '#22C55E',
    icon: Shield,
    ultName: 'ป้อมปราการหุ้มเกราะ (Iron Shell)',
    ultDesc: 'กลายเป็นเกราะอมตะสมบูรณ์ขยายร่างใหญ่ ชนเบียดศัตรูกระเด้งปลิวกระแทกกำแพง นาน 6 วินาที',
    stats: { speed: 70, armor: 95, power: 80 },
  },
  {
    id: 'wild_rabbit',
    name: 'กระต่ายป่า (Wild Rabbit)',
    driver: 'กระโดดไว',
    colorName: 'สีชมพูคิ้วท์ (Hot Pink)',
    colorClass: 'bg-pink-500',
    colorHex: '#EC4899',
    icon: Target,
    ultName: 'ระเบิดแครอทกระจาย (Carrot Cluster)',
    ultDesc: 'โยนกลุ่มระเบิดกลมลอยฟ้า ตกลงมาบอมบ์รอบทิศทาง 6 จุด ทำดาเมจวงกว้างวงละ 20 HP',
    stats: { speed: 90, armor: 65, power: 80 },
  },
  {
    id: 'golden_dragon',
    name: 'มังกรทอง (Golden Dragon)',
    driver: 'หลงเซียน',
    colorName: 'สีทองคำเหลือง (Yellow)',
    colorClass: 'bg-yellow-500',
    colorHex: '#EAB308',
    icon: Crown,
    ultName: 'คลื่นมังกรคำราม (Dragon Roar)',
    ultDesc: 'ส่งกระแสพลังสั่นสะเทือนกระจาย 360 องศา ผลักศัตรูกระเด็นชน ดาเมจ 35 HP สตันนาน 1.5 วินาที',
    stats: { speed: 75, armor: 85, power: 85 },
  },
  {
    id: 'shadow_wolf',
    name: 'หมาป่าทมิฬ (Shadow Wolf)',
    driver: 'ราตรี',
    colorName: 'สีน้ำเงินเข้ม (Royal Blue)',
    colorClass: 'bg-blue-500',
    colorHex: '#3B82F6',
    icon: Eye,
    ultName: 'เขี้ยวรัตติกาลลอบสังหาร (Fangs of Night)',
    ultDesc: 'ล็อกเป้าและวาร์ปพุ่งทะลวงไปกระแทกบดขยี้ท้ายรถเป้าหมายทันที ดาเมจเด็ดขาด 40 HP',
    stats: { speed: 85, armor: 70, power: 85 },
  },
  {
    id: 'stone_bear',
    name: 'หมีศิลา (Stone Bear)',
    driver: 'โกไลแอท',
    colorName: 'สีน้ำตาลแร่ (Stone Brown)',
    colorClass: 'bg-amber-900',
    colorHex: '#78350F',
    icon: Flame,
    ultName: 'แผ่นดินไหวพสุธา (Giga Slam)',
    ultDesc: 'กระโดดสูงกระแทกพื้นรุนแรง ทำดาเมจ 35 HP รอบบริเวณ และลดความเร็วเหยื่อ 80% นาน 4 วินาที',
    stats: { speed: 70, armor: 90, power: 85 },
  },
];

export default function App() {
  const [activeTab, setActiveTab] = useState<'play' | 'code'>('play');
  const [gameState, setGameState] = useState<'loading' | 'lobby' | 'countdown' | 'playing' | 'summary'>('loading');
  const [loadProgress, setLoadProgress] = useState(0);
  const [selectedKartIndex, setSelectedKartIndex] = useState(0);
  const [isMuted, setIsMuted] = useState(false);
  const [isPaused, setIsPaused] = useState(false);
  const [countdownNum, setCountdownNum] = useState(3);
  const [scoreboard, setScoreboard] = useState<any[]>([]);

  // Simulation of loading progress
  useEffect(() => {
    if (gameState === 'loading') {
      const interval = setInterval(() => {
        setLoadProgress((prev) => {
          if (prev >= 100) {
            clearInterval(interval);
            setGameState('lobby');
            return 100;
          }
          return prev + 10;
        });
      }, 150);
      return () => clearInterval(interval);
    }
  }, [gameState]);

  // Audio Toggle Mute
  const handleToggleMute = () => {
    const nextMuted = audioSynth.toggleMute();
    setIsMuted(nextMuted);
  };

  // Start the battle countdown loop
  const handleStartGame = () => {
    audioSynth.play('click');
    setGameState('countdown');
    setCountdownNum(3);

    const countdownTimer = setInterval(() => {
      setCountdownNum((prev) => {
        if (prev <= 1) {
          clearInterval(countdownTimer);
          setGameState('playing');
          setIsPaused(false);
          return 0;
        }
        audioSynth.play('click');
        return prev - 1;
      });
    }, 1000);
  };

  // Callback on Match Finish
  const handleGameOver = (finalScoreboard: any[]) => {
    setScoreboard(finalScoreboard);
    setGameState('summary');
  };

  // Back from score summaries
  const handleBackToLobby = () => {
    audioSynth.play('click');
    setGameState('lobby');
  };

  return (
    <div className="min-h-screen bg-slate-950 flex flex-col font-sans selection:bg-yellow-500 selection:text-slate-950">
      
      {/* HEADER BAR */}
      <header className="bg-slate-900 border-b border-slate-800 px-6 py-4 flex flex-col md:flex-row justify-between items-center gap-4 sticky top-0 z-50">
        <div className="flex items-center gap-3">
          <div className="bg-yellow-500 text-slate-950 p-2 rounded-xl font-black text-lg shadow-[0_0_15px_rgba(234,179,8,0.3)] flex items-center justify-center">
            🏁
          </div>
          <div>
            <h1 className="text-xl font-black text-white tracking-tight flex items-center gap-2">
              E-eak <span className="text-yellow-400 font-bold text-sm bg-yellow-500/10 px-2 py-0.5 rounded border border-yellow-500/20">อีเอก</span>
            </h1>
            <p className="text-slate-400 text-xs">มินิเกมแข่งรถสไตล์ Kart Battle Arena สำหรับฝังเข้ากับแอปหลัก</p>
          </div>
        </div>

        {/* CONTROLS & NAVIGATION TABS */}
        <div className="flex items-center gap-3">
          {/* Audio controls */}
          <button
            onClick={handleToggleMute}
            className="p-2.5 rounded-lg bg-slate-800 hover:bg-slate-700 text-slate-200 hover:text-white transition-all cursor-pointer"
            title={isMuted ? "เปิดเสียง" : "ปิดเสียง"}
          >
            {isMuted ? <VolumeX size={18} /> : <Volume2 size={18} />}
          </button>

          {/* Navigation Toggle */}
          <div className="bg-slate-950 p-1 rounded-xl border border-slate-800 flex">
            <button
              onClick={() => {
                setActiveTab('play');
                audioSynth.play('click');
              }}
              className={`flex items-center gap-2 px-4 py-2 rounded-lg text-xs font-extrabold transition-all cursor-pointer ${
                activeTab === 'play'
                  ? 'bg-yellow-500 text-slate-950 shadow-md'
                  : 'text-slate-400 hover:text-white'
              }`}
            >
              <Smartphone size={14} />
              จำลองมินิเกม (Play Demo)
            </button>
            <button
              onClick={() => {
                setActiveTab('code');
                audioSynth.play('click');
              }}
              className={`flex items-center gap-2 px-4 py-2 rounded-lg text-xs font-extrabold transition-all cursor-pointer ${
                activeTab === 'code'
                  ? 'bg-yellow-500 text-slate-950 shadow-md'
                  : 'text-slate-400 hover:text-white'
              }`}
            >
              <Code size={14} />
              โค้ด Dart/Flutter (Dart Files)
            </button>
          </div>
        </div>
      </header>

      {/* CORE BODY WORKSPACE */}
      <main className="flex-1 p-6 flex flex-col justify-center items-center">
        
        {/* TAB 1: INTERACTIVE WEB GAMEPLAY SIMULATOR */}
        {activeTab === 'play' && (
          <div className="w-full max-w-5xl flex flex-col gap-6">
            
            {/* STAGE A: GAME LOADING */}
            {gameState === 'loading' && (
              <div className="bg-slate-900 border border-slate-800 rounded-2xl p-10 py-16 text-center shadow-2xl flex flex-col items-center justify-center min-h-[400px]">
                <div className="w-16 h-16 bg-yellow-500/10 text-yellow-500 border border-yellow-500/20 rounded-2xl flex items-center justify-center text-3xl font-bold mb-6 animate-pulse shadow-lg">
                  🏁
                </div>
                <h3 className="text-2xl font-black text-white tracking-wide uppercase">กำลังเตรียมสนามแข่ง "อีเอก"</h3>
                <p className="text-slate-400 text-sm mt-2 max-w-md">
                  จำลองโมเดลฟิสิกส์การชนยืดหยุ่น ยานพาหนะดริฟต์ บอทอัจฉริยะ และสล๊อตสุ่มสกิลอาวุธ
                </p>

                {/* Progress bar */}
                <div className="w-full max-w-sm bg-slate-950 h-3 rounded-full mt-8 overflow-hidden border border-slate-800 p-0.5">
                  <div
                    style={{ width: `${loadProgress}%` }}
                    className="h-full bg-gradient-to-r from-yellow-500 to-amber-600 rounded-full transition-all duration-150 shadow-[0_0_10px_rgba(245,158,11,0.5)]"
                  />
                </div>
                <div className="text-xs font-mono font-bold text-yellow-500 mt-3 tracking-widest">{loadProgress}%</div>
              </div>
            )}

            {/* STAGE B: GAME LOBBY & KART SELECTION */}
            {gameState === 'lobby' && (
              <div className="bg-slate-900 border border-slate-800 rounded-3xl overflow-hidden shadow-2xl flex flex-col lg:flex-row min-h-[460px] animate-fade-in">
                
                {/* Left Side: Select Scroll List (10 Karts) */}
                <div className="flex-1 p-6 md:p-8 border-b lg:border-b-0 lg:border-r border-slate-800 flex flex-col overflow-hidden">
                  <div className="flex justify-between items-center mb-4">
                    <div>
                      <h3 className="text-white text-lg font-black tracking-tight flex items-center gap-2">
                        🏁 ล็อบบี้เลือกรถซิ่งต่อสู้
                      </h3>
                      <p className="text-slate-400 text-xs mt-0.5">มีรถยอดนักรบให้เลือก 10 คัน (ค่าสถานะสมดุล ต่างกันที่อัลติเมต)</p>
                    </div>
                  </div>

                  {/* Karts roster list */}
                  <div className="grid grid-cols-2 sm:grid-cols-3 gap-3 overflow-y-auto pr-1 max-h-[360px] lg:max-h-none py-1">
                    {KARTS_ROSTER.map((kart, idx) => {
                      const isSelected = idx === selectedKartIndex;
                      const Icon = kart.icon;
                      return (
                        <button
                          key={kart.id}
                          onClick={() => {
                            setSelectedKartIndex(idx);
                            audioSynth.play('click');
                          }}
                          className={`p-4 rounded-2xl border text-left flex flex-col gap-3 transition-all cursor-pointer relative overflow-hidden ${
                            isSelected
                              ? 'bg-yellow-500 text-slate-950 border-white shadow-xl shadow-yellow-500/10 scale-98'
                              : 'bg-slate-950/60 text-slate-300 border-slate-800/80 hover:bg-slate-950 hover:text-white hover:border-slate-700'
                          }`}
                        >
                          {/* Selected Active Tag Indicator */}
                          {isSelected && (
                            <span className="absolute top-0 right-0 bg-slate-950 text-yellow-400 text-[9px] font-black tracking-widest uppercase px-2 py-0.5 rounded-bl-lg">
                              เลือกแล้ว
                            </span>
                          )}

                          <div className="flex items-center gap-2">
                            <div className={`p-2 rounded-xl flex items-center justify-center shadow-md ${
                              isSelected ? 'bg-slate-950 text-white' : 'bg-slate-900 text-slate-400'
                            }`}>
                              <Icon size={18} />
                            </div>
                            <div className="truncate">
                              <div className="text-[11px] opacity-75 font-bold uppercase truncate">นักซิ่ง: {kart.driver}</div>
                              <div className="text-sm font-black tracking-tight truncate leading-tight">{kart.name.split(' ')[0]}</div>
                            </div>
                          </div>

                          <div className={`text-[10px] truncate ${isSelected ? 'text-slate-800' : 'text-slate-500'}`}>
                            ตัวถัง: <span className="font-bold">{kart.colorName}</span>
                          </div>
                        </button>
                      );
                    })}
                  </div>
                </div>

                {/* Right Side: Skill & Specs Display panel */}
                <div className="w-full lg:w-96 bg-slate-950 p-6 md:p-8 flex flex-col justify-between gap-6">
                  {/* Visual specs preview */}
                  <div>
                    <span className="text-xs text-yellow-500 font-extrabold tracking-widest uppercase bg-yellow-500/10 px-2.5 py-1 rounded border border-yellow-500/20">
                      รายละเอียดรถที่เลือก
                    </span>
                    <h2 className="text-white text-2xl font-black mt-3 flex items-center gap-2">
                      {KARTS_ROSTER[selectedKartIndex].name}
                    </h2>
                    <p className="text-slate-400 text-xs mt-1">ผู้ขับขี่: <span className="text-white font-bold">{KARTS_ROSTER[selectedKartIndex].driver}</span></p>

                    {/* Stats slider */}
                    <div className="mt-5 flex flex-col gap-3.5 bg-slate-900/60 p-4 rounded-xl border border-slate-800">
                      <div className="flex items-center justify-between">
                        <span className="text-slate-400 text-xs font-bold">🚀 อัตราเร่งความเร็ว</span>
                        <span className="text-white font-mono text-xs font-black">{KARTS_ROSTER[selectedKartIndex].stats.speed}%</span>
                      </div>
                      <div className="w-full bg-slate-950 h-2 rounded-full overflow-hidden">
                        <div style={{ width: `${KARTS_ROSTER[selectedKartIndex].stats.speed}%` }} className="h-full bg-cyan-500 rounded-full" />
                      </div>

                      <div className="flex items-center justify-between">
                        <span className="text-slate-400 text-xs font-bold">🛡️ ความทนทาน/เกราะ</span>
                        <span className="text-white font-mono text-xs font-black">{KARTS_ROSTER[selectedKartIndex].stats.armor}%</span>
                      </div>
                      <div className="w-full bg-slate-950 h-2 rounded-full overflow-hidden">
                        <div style={{ width: `${KARTS_ROSTER[selectedKartIndex].stats.armor}%` }} className="h-full bg-green-500 rounded-full" />
                      </div>

                      <div className="flex items-center justify-between">
                        <span className="text-slate-400 text-xs font-bold">⚡ ความแรงดาเมจสกิล</span>
                        <span className="text-white font-mono text-xs font-black">{KARTS_ROSTER[selectedKartIndex].stats.power}%</span>
                      </div>
                      <div className="w-full bg-slate-950 h-2 rounded-full overflow-hidden">
                        <div style={{ width: `${KARTS_ROSTER[selectedKartIndex].stats.power}%` }} className="h-full bg-red-500 rounded-full" />
                      </div>
                    </div>

                    {/* Ultimate skill desc */}
                    <div className="mt-5 bg-slate-900/40 p-4 rounded-xl border border-slate-800 flex flex-col gap-2">
                      <div className="flex items-center gap-1.5 text-xs font-black text-yellow-400">
                        <Crown size={14} />
                        อัลติเมตประจำตัว (Ultimate Skill)
                      </div>
                      <div className="text-white text-xs font-black mt-1">
                        {KARTS_ROSTER[selectedKartIndex].ultName}
                      </div>
                      <div className="text-slate-400 text-[11px] leading-relaxed">
                        {KARTS_ROSTER[selectedKartIndex].ultDesc}
                      </div>
                      <div className="text-[10px] text-red-400 font-extrabold mt-1 uppercase">
                        คูลดาวน์: 30 วินาที | ความสำคัญ: พลิกเกมสูง
                      </div>
                    </div>
                  </div>

                  {/* Trigger Game button */}
                  <button
                    onClick={handleStartGame}
                    className="w-full py-4 bg-gradient-to-r from-yellow-500 to-amber-600 hover:from-yellow-400 hover:to-amber-500 text-slate-950 font-black text-base rounded-2xl shadow-xl shadow-yellow-600/10 cursor-pointer active:scale-98 flex items-center justify-center gap-2"
                  >
                    <Play size={18} fill="currentColor" />
                    เข้าสนามสตาร์ทความดุเดือด!
                  </button>
                </div>
              </div>
            )}

            {/* STAGE C: COUNTDOWN SCREEN */}
            {gameState === 'countdown' && (
              <div className="bg-slate-900 border border-slate-800 rounded-2xl p-10 py-16 text-center shadow-2xl flex flex-col items-center justify-center min-h-[460px] relative overflow-hidden animate-fade-in">
                <div className="text-slate-500 text-xs font-bold uppercase tracking-widest mb-4">เตรียมพร้อมจับจอยสติ๊ก หรือปุ่มคีย์บอร์ด WASD / ปุ่มลูกศร!</div>
                <div className="text-8xl font-black italic tracking-tighter text-yellow-500 scale-110 select-none animate-bounce">
                  {countdownNum === 0 ? 'ลุยเลย!' : countdownNum}
                </div>
                <div className="text-slate-400 text-xs mt-6 max-w-md mx-auto font-medium leading-relaxed">
                  🕹️ บังคับรถด้วย <span className="text-yellow-400 font-bold">Joystick หน้าจอ</span> หรือ ปุ่ม <span className="text-yellow-400 font-bold">WASD / Arrow Keys</span><br />
                  🚀 กดปุ่ม <span className="text-yellow-400 font-bold">1, 2</span> ปล่อยสกิลปกติ และปุ่ม <span className="text-yellow-400 font-bold">Spacebar</span> ปลดปล่อยท่าไม้ตายสุดอลังการ!
                </div>
              </div>
            )}

            {/* STAGE D: PLAYING GAME - EMBEDDED INSIDE A SLEEK LANDSCAPE TABLET FRAME */}
            {gameState === 'playing' && (
              <div className="flex flex-col items-center">
                {/* Visual Tablet Bezel Frame to enforce Landscape feeling nicely */}
                <div className="w-full bg-slate-950 border-8 border-slate-800 rounded-[30px] p-2 overflow-hidden shadow-2xl relative aspect-[16/9] max-h-[520px]">
                  
                  {/* Tablet notch details */}
                  <div className="absolute top-1/2 left-0.5 transform -translate-y-1/2 w-1.5 h-6 bg-slate-700 rounded-r z-50" />
                  <div className="absolute top-1/2 right-0.5 transform -translate-y-1/2 w-1.5 h-6 bg-slate-700 rounded-l z-50" />

                  {/* Inside Game Content Canvas */}
                  <div className="w-full h-full rounded-2xl overflow-hidden relative">
                    <GameCanvas
                      playerKartInfo={KARTS_ROSTER[selectedKartIndex]}
                      onGameOver={handleGameOver}
                      isPaused={isPaused}
                      setIsPaused={setIsPaused}
                    />
                  </div>
                </div>

                {/* PAUSED GAME OVERLAY MODAL */}
                {isPaused && (
                  <div className="fixed inset-0 bg-slate-950/80 backdrop-blur-sm flex items-center justify-center z-50 animate-fade-in p-6">
                    <div className="bg-slate-900 border border-slate-800 p-8 rounded-2xl text-center max-w-sm w-full shadow-2xl flex flex-col gap-6">
                      <div>
                        <div className="text-yellow-500 text-3xl mb-2 flex justify-center">⏸️</div>
                        <h4 className="text-white text-xl font-black">พักเกมชั่วคราว</h4>
                        <p className="text-slate-400 text-xs mt-1">เกมกำลังหยุดอยู่ คุณต้องการทำสิ่งใดต่อ?</p>
                      </div>

                      <div className="flex flex-col gap-3">
                        <button
                          onClick={() => {
                            setIsPaused(false);
                            audioSynth.play('click');
                          }}
                          className="w-full py-3 bg-yellow-500 hover:bg-yellow-400 text-slate-950 font-black rounded-xl text-xs tracking-wider uppercase cursor-pointer transition-all"
                        >
                          ▶️ เล่นแข่งต่อ (Resume Match)
                        </button>
                        <button
                          onClick={() => {
                            audioSynth.play('click');
                            setGameState('lobby');
                            setIsPaused(false);
                          }}
                          className="w-full py-3 bg-slate-800 hover:bg-slate-700 border border-slate-700 text-white font-extrabold rounded-xl text-xs tracking-wider uppercase cursor-pointer transition-all"
                        >
                          ❌ ออกกลับล็อบบี้เลือกรถ
                        </button>
                      </div>
                    </div>
                  </div>
                )}
              </div>
            )}

            {/* STAGE E: SCORE SUMMARY & MVP DISPLAY */}
            {gameState === 'summary' && (
              <div className="bg-slate-900 border border-slate-800 rounded-3xl overflow-hidden shadow-2xl p-6 md:p-8 animate-fade-in max-w-3xl mx-auto w-full">
                
                {/* Header title */}
                <div className="text-center mb-8 flex flex-col items-center">
                  <div className="w-14 h-14 bg-yellow-500/10 text-yellow-500 border border-yellow-500/20 rounded-2xl flex items-center justify-center text-2xl font-black shadow-lg mb-3">
                    🏆
                  </div>
                  <h3 className="text-2xl font-black text-white tracking-wide uppercase">หมดเวลาสรุปผลคะแนน</h3>
                  <p className="text-slate-400 text-xs mt-1">อันดับผู้เล่นทั้ง 6 คนในสนามรบปิด เรียงตามลำดับยอดการคิลที่ดีที่สุด</p>
                </div>

                {/* MVP card presentation */}
                {scoreboard.length > 0 && (
                  <div className="bg-gradient-to-r from-amber-500/20 via-yellow-500/10 to-amber-500/20 border border-yellow-500/30 p-5 rounded-2xl mb-6 flex flex-col sm:flex-row justify-between items-center gap-4">
                    <div className="flex items-center gap-3.5">
                      <div className="w-12 h-12 bg-yellow-500 text-slate-950 rounded-xl font-black flex items-center justify-center text-xl shadow-lg shadow-yellow-500/20">
                        👑
                      </div>
                      <div>
                        <div className="text-yellow-500 text-[10px] font-black tracking-widest uppercase">ถ้วยรางวัลอันดับ 1 MVP</div>
                        <h4 className="text-white text-lg font-black leading-tight mt-0.5">{scoreboard[0].name}</h4>
                        <p className="text-slate-400 text-[11px]">สถิติจ้าวสังเวียนที่ดุดัน สอยร่วงศัตรูอย่างดุดันสะใจที่สุด!</p>
                      </div>
                    </div>
                    
                    <div className="flex items-center gap-6 bg-slate-950 px-5 py-2.5 rounded-xl border border-slate-800">
                      <div className="text-center">
                        <div className="text-[10px] text-slate-500 font-bold uppercase">ฆ่าศัตรู</div>
                        <div className="text-green-400 text-lg font-black">{scoreboard[0].kills}</div>
                      </div>
                      <div className="w-px h-6 bg-slate-800" />
                      <div className="text-center">
                        <div className="text-[10px] text-slate-500 font-bold uppercase">ความตาย</div>
                        <div className="text-red-400 text-lg font-black">{scoreboard[0].deaths}</div>
                      </div>
                    </div>
                  </div>
                )}

                {/* Score table ranking list */}
                <div className="bg-slate-950 rounded-2xl border border-slate-800 overflow-hidden mb-6">
                  <div className="grid grid-cols-12 bg-slate-900/60 p-3.5 border-b border-slate-800 text-[10px] font-black tracking-wider text-slate-400 uppercase">
                    <div className="col-span-2 text-center">อันดับ</div>
                    <div className="col-span-5">ผู้แข่ง / ตัวละคร</div>
                    <div className="col-span-2 text-center text-green-400">คิล</div>
                    <div className="col-span-2 text-center text-red-400">ตาย</div>
                    <div className="col-span-1 text-center">ประเภท</div>
                  </div>

                  <div className="divide-y divide-slate-800/50">
                    {scoreboard.map((kart, index) => {
                      const isUser = kart.id === 'player';
                      return (
                        <div
                          key={kart.id}
                          className={`grid grid-cols-12 p-4 items-center text-xs transition-all ${
                            isUser ? 'bg-yellow-500/5 text-white' : 'text-slate-300'
                          }`}
                        >
                          <div className="col-span-2 text-center font-mono font-black text-slate-400">
                            {index === 0 ? '🥇' : index === 1 ? '🥈' : index === 2 ? '🥉' : `#${index + 1}`}
                          </div>
                          
                          <div className="col-span-5 flex items-center gap-2.5">
                            <span
                              className="w-3 h-3 rounded-full border border-white/20"
                              style={{ backgroundColor: kart.colorHex }}
                            />
                            <div>
                              <div className="font-extrabold flex items-center gap-1">
                                {kart.name}
                                {isUser && <span className="bg-green-500/10 text-green-400 text-[9px] px-1.5 py-0.2 rounded font-bold">คุณ</span>}
                              </div>
                              <div className="text-[10px] text-slate-500">คนขับ: {kart.driver}</div>
                            </div>
                          </div>

                          <div className="col-span-2 text-center font-mono font-black text-green-400 text-sm">
                            {kart.kills}
                          </div>
                          
                          <div className="col-span-2 text-center font-mono font-bold text-red-500">
                            {kart.deaths}
                          </div>

                          <div className="col-span-1 text-center font-mono text-[9px] font-black uppercase text-slate-500">
                            {isUser ? 'Player' : 'Bot AI'}
                          </div>
                        </div>
                      );
                    })}
                  </div>
                </div>

                {/* Back button */}
                <div className="flex justify-center gap-4">
                  <button
                    onClick={handleBackToLobby}
                    className="px-6 py-3.5 bg-yellow-500 hover:bg-yellow-400 text-slate-950 font-black rounded-xl text-xs tracking-wider uppercase cursor-pointer shadow-md active:scale-98 flex items-center gap-2"
                  >
                    <RotateCcw size={14} />
                    กลับไปเลือกแต่งรถ คันอื่น (Back to Lobby)
                  </button>
                </div>
              </div>
            )}
          </div>
        )}

        {/* TAB 2: EXPORTABLE DART FLUTTER SOURCE FILES EXPLORER */}
        {activeTab === 'code' && (
          <div className="w-full max-w-5xl h-[560px] animate-fade-in">
            <CodeExplorer />
          </div>
        )}

      </main>

      {/* FOOTER BRUTALIST CAPTION */}
      <footer className="bg-slate-900 border-t border-slate-800 px-6 py-4 text-center">
        <p className="text-slate-500 text-xs font-mono">
          E-eak Kart Battle Arena © 2026 | พัฒนาสอดคล้องตามข้อกำหนดฟิสิกส์ร่วมกันด้วย Flame Engine & Forge2D
        </p>
      </footer>
    </div>
  );
}
