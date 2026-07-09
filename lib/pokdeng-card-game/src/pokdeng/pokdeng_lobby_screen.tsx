import React, { useState } from 'react';
import { usePokdeng } from './pokdeng_game_provider';
import { AvatarPainter } from './pokdeng_avatar_painter';
import { 
  Coins, 
  Sparkles, 
  Gift, 
  ShoppingBag, 
  Check, 
  ChevronRight, 
  X, 
  RefreshCw, 
  Play, 
  HelpCircle,
  Crown,
  ChevronLeft,
  Shirt,
  Store
} from 'lucide-react';

export const PokdengLobbyScreen: React.FC = () => {
  const {
    userChips,
    addChips,
    currentBet,
    isSearching,
    searchCountdown,
    changeGender,
    updateAvatarStyle,
    setBetAmount,
    startMatchmaking,
    cancelMatchmaking,
    roundsPlayed,
    setPhase,
    gender,
    avatar,
    ownedItems,
  } = usePokdeng();

  // Dialog States
  const [wardrobeOpen, setWardrobeOpen] = useState(false);
  const [shopOpen, setShopOpen] = useState(false);
  const [showHowToPlay, setShowHowToPlay] = useState(false);
  const [googlePayOpen, setGooglePayOpen] = useState(false);

  // Google Pay Simulation States
  const [payingTier, setPayingTier] = useState<null | { baht: number; chips: number }>(null);
  const [isProcessingPay, setIsProcessingPay] = useState(false);
  const [paySuccess, setPaySuccess] = useState(false);

  // Active Tab States
  const [wardrobeTab, setWardrobeTab] = useState<'hair' | 'hat' | 'shirt' | 'pants'>('hair');
  const [shopTab, setShopTab] = useState<'hair' | 'hat' | 'shirt' | 'pants'>('hair');

  // Waving animation state
  const [isWaving, setIsWaving] = useState(false);

  const handleAvatarClick = () => {
    if (isWaving) return;
    setIsWaving(true);
    setTimeout(() => {
      setIsWaving(false);
    }, 1500); // 1.5s wave animation
  };

  // List of descriptive item names and colors
  const fashionDetails = {
    hair: [
      { name: 'ทรงบ๊อบคลาสสิก / ผมสั้นพื้นฐาน', desc: 'สไตล์เรียบง่ายสบายหัว' },
      { name: 'ผมทรงหนามเปรี้ยว / โพนี่เทลน่ารัก', desc: 'มีความทะมัดทะแมงพร้อมสู้' },
      { name: 'ผมหยิกยุ่งเซอ / ผมลอนคลื่นยาว', desc: 'เพิ่มความพริ้วไหวรอบตัว' },
      { name: 'ทรงอันเดอร์คัทสุดเท่ / เปียคู่เรียบร้อย', desc: 'สไตล์โมเดิร์นที่ทุกคนจับจ้อง' },
      { name: 'ทรงแอฟโฟรกลมโต / แอฟโฟรนีออนหวาน', desc: 'เด่นสะดุดตาระยะร้อยเมตร' },
      { name: 'สุภาพบุรุษแสกข้าง / มวยผมทรงสูงสุภาพ', desc: 'เรียบร้อย เหมาะกับวันแต่งงาน' },
      { name: 'เดรดล็อคเซอร์ / เดรดล็อคหลากสี', desc: 'จังหวะเร็กเก้บนโต๊ะไพ่' },
      { name: 'โมฮอคพังก์สุดขีด / พิกซี่คัตเปรี้ยวเฉี่ยว', desc: 'แฟชั่นสุดเหวี่ยงไร้ขีดจำกัด' },
      { name: 'เคป๊อปนีออนสว่าง / ทรงทวินเทลสายแบ๊ว', desc: 'ไอดอลยอดนิยมครองบัลลังก์' },
      { name: 'เซตแฮร์แกรนด์ / ทรงฮิเมะคัตราชนิกุล', desc: 'หรูหราระดับเจ้าหญิงเจ้าชาย' },
    ],
    hat: [
      { name: 'ไม่สวมหมวก', desc: 'โชว์ทรงผมสุดสลวย' },
      { name: 'หมวกแก๊ปสีแดงเบสบอล', desc: 'สปอร์ตตี้ขาลุยลื่นไหล' },
      { name: 'หมวกบีนนี่ไหมพรมอบอุ่น', desc: 'หนาวแค่ไหนโต๊ะไพ่ก็อุ่น' },
      { name: 'หมวกสไตล์เฟโดร่าสุภาพบุรุษ', desc: 'ความคลาสสิกที่ไม่เคยจางหาย' },
      { name: 'มงกุฎทองฝังอัญมณีล้ำค่า', desc: 'สัญลักษณ์ผู้ชนะของโต๊ะ' },
      { name: 'หมวกคาวบอยหนังแท้ตะวันตก', desc: 'นักดวลปืนแห่งที่ราบสูง' },
      { name: 'หมวกเชฟกระทะเหล็ก', desc: 'เตรียมเสิร์ฟตองเสิร์ฟป๊อกร้อนๆ' },
      { name: 'หมวกปาร์ตี้สายรุ้งร่าเริง', desc: 'ฉลองแต้มป๊อกตลอดคืน' },
      { name: 'หมวกฟางชายหาดรับลมร้อน', desc: 'ชิลขั้นสุดริมทะเลกระบี่' },
      { name: 'หมวกโจรสลัดกัปตันผู้พิชิต', desc: 'ล่องเรือสำรวจชิปทองคำ' },
    ],
    shirt: [
      { name: 'เสื้อยืดสีขาวมินิมอล', desc: 'เบสิคเรียบหรูดูดี' },
      { name: 'เสื้อฮู้ดสีเขียวอบอุ่น', desc: 'พับฮู้ดลุยลุ้นไพ่สามใบ' },
      { name: 'เสื้อฮาวายลายดอกไม้สว่าง', desc: 'เหมือนกำลังนั่งเล่นริมหาดพัทยา' },
      { name: 'สูทธุรกิจสีกรมท่าเนี๊ยบ', desc: 'นักวิเคราะห์สถิติแต้มเด้ง' },
      { name: 'เสื้อกะลาสีลายขวางขาวน้ำเงิน', desc: 'ล่องเรือล่าขุมทรัพย์เจ้ามือ' },
      { name: 'เสื้อกล้ามสีดำสายโหด', desc: 'โชว์มัดกล้ามข่มคู่แข่ง' },
      { name: 'เสื้อแจ็คเก็ตหนังไบค์เกอร์เท่', desc: 'เท่ ดิบ เร็ว แรง ในโต๊ะเดียว' },
      { name: 'เสื้อสเวตเตอร์สีแดงทอลาย', desc: 'หนานุ่ม อุ่นกายสบายมือ' },
      { name: 'ทักซิโด้สีดำสุดพรีเมียม', desc: 'หรูหราระดับดินเนอร์กาล่า' },
      { name: 'เสื้อคลุมจักรพรรดิสีทองโบราณ', desc: 'บารมีสะกดสายตาทั้งโต๊ะ' },
    ],
    pants: [
      { name: 'กางเกงยีนส์เดนิมสีฟ้าคลาสสิก', desc: 'สวมใส่กระชับ คล่องตัวทุกการลื่น' },
      { name: 'กางเกงขาสั้นเดนิมลำลอง', desc: 'พักผ่อนสบายๆ ในวันกักตุนชิป' },
      { name: 'กางเกงทำงานขากระบอกเข้ม', desc: 'สุภาพ เรียบร้อย ตึงตัง' },
      { name: 'กางเกงคาร์โก้เขียว / กระโปรงสั้นแดง', desc: 'กระชับ เท่ น่ารักลงตัว' },
      { name: 'กางเกงนีออนไซเบอร์ส่องแสง', desc: 'เปล่งประกายในความมืด' },
      { name: 'กางเกงยีนส์ขาดเข่าสไตล์พังก์', desc: 'หัวใจขบถลุยป๊อกเด้งสุดตัว' },
      { name: 'กางเกงจ็อกเกอร์เทาสวมสบาย', desc: 'สายชิล นั่งแช่เล่นได้ทั้งวัน' },
      { name: 'กางเกงว่ายน้ำสีส้ม / บิกินี่ลุยหาด', desc: 'พร้อมโดดน้ำถ้าโดนเจ้ามือป๊อกกิน' },
      { name: 'กางเกงเมทัลลิกสีทองประกาย', desc: 'ความมั่งคั่งสะท้อนเข้าตาคู่แข่ง' },
      { name: 'กางเกงราชาภิเษกสีม่วงขลิบทอง', desc: 'ล้ำเลอเกียรติยศระดับตองเก้า' },
    ],
  };

  return (
    <div className="min-h-screen bg-slate-900 text-slate-100 flex flex-col justify-between p-6 relative overflow-hidden font-sans select-none selection:bg-pink-500 selection:text-white">
      {/* Playful & Cute Neon Casino Ambient Lights */}
      <div className="absolute top-[-10%] left-[-10%] w-[50%] h-[50%] bg-emerald-500/10 rounded-full blur-[120px] pointer-events-none"></div>
      <div className="absolute bottom-[-10%] right-[-10%] w-[50%] h-[50%] bg-pink-500/10 rounded-full blur-[120px] pointer-events-none"></div>

      {/* HEADER: Minimalist, clean chips indicator & title with non-functional Back arrow */}
      <header className="w-full max-w-md mx-auto flex items-center justify-between z-10">
        <div className="flex items-center gap-1">
          {/* Back Button (Non-functional as requested) */}
          <button 
            type="button"
            className="p-1.5 rounded-xl bg-slate-800/80 hover:bg-slate-700/80 border border-slate-700/40 text-slate-400 mr-1.5 hover:text-white transition duration-200 cursor-pointer"
            title="ย้อนกลับ"
          >
            <ChevronLeft className="h-5 w-5" />
          </button>

          <div className="flex items-center gap-2">
            <div className="h-9 w-9 rounded-xl bg-gradient-to-br from-emerald-400 to-emerald-600 flex items-center justify-center shadow-lg shadow-emerald-500/20">
              <Crown className="h-5 w-5 text-slate-900" />
            </div>
            <div>
              <h1 className="text-sm md:text-base font-black tracking-tight text-white flex items-center gap-1">
                ป๊อกเด้งคลับ
                <span className="text-[8px] bg-pink-500/20 text-pink-400 font-extrabold px-1 py-0.5 rounded-full border border-pink-500/30">
                  วัยรุ่น
                </span>
              </h1>
            </div>
          </div>
        </div>

        {/* CHIP DISPLAY */}
        <button
          onClick={() => setGooglePayOpen(true)}
          className="flex items-center gap-1.5 rounded-full bg-gradient-to-r from-slate-800 to-slate-950 border border-slate-700/60 hover:border-emerald-500/50 px-3 py-1.5 shadow-sm hover:shadow-emerald-500/10 active:scale-95 transition-all cursor-pointer group"
          title="กดเพื่อเติมชิปด้วย Google Pay"
          id="lobby-chips-topup-btn"
        >
          <Coins className="h-4 w-4 text-emerald-400 group-hover:scale-110 transition-transform" />
          <span className="font-mono text-xs font-black text-emerald-400">
            {userChips.toLocaleString()}
          </span>
          <span className="text-[9px] bg-emerald-500/20 text-emerald-400 font-extrabold px-1.5 py-0.5 rounded-full border border-emerald-500/30 group-hover:bg-emerald-500 group-hover:text-slate-950 transition-all">
            + เติมเงิน
          </span>
        </button>
      </header>

      {/* MAIN CONTAINER: Optimized for a clean visual hierarchy */}
      <main className="flex-1 w-full max-w-md mx-auto flex flex-col justify-center items-center gap-5 my-auto z-10">
        
        {/* CHARACTER PORTION: Centered on a cute glowing stage pad */}
        <div className="relative flex flex-col items-center justify-center w-full">
          {/* Glowing pedestal/pad */}
          <div className="absolute bottom-4 w-36 h-8 bg-gradient-to-r from-emerald-500/20 to-pink-500/20 rounded-full blur-md animate-pulse"></div>
          <div className="absolute bottom-5 w-32 h-6 bg-slate-800 border border-slate-700/60 rounded-full shadow-inner"></div>

          {/* Transparent character avatar with click wave interaction */}
          <div 
            onClick={handleAvatarClick}
            className="relative z-10 transform hover:scale-105 active:scale-95 transition duration-300 cursor-pointer"
            title="กดเพื่อโบกมือทักทาย!"
          >
            <AvatarPainter 
              gender={gender} 
              avatar={avatar} 
              size={190} 
              animate={!isWaving} 
              noBackground={true} 
              isClicked={isWaving} 
            />
            
            {/* Quick gender swap overlay button */}
            <button
              onClick={(e) => {
                e.stopPropagation(); // Stop trigger wave animation on click swap gender
                changeGender();
              }}
              className="absolute bottom-6 right-2 p-2 rounded-full bg-slate-800 hover:bg-slate-700 border border-slate-700 text-pink-400 hover:text-pink-300 transition shadow-lg"
              title="สลับเพศ"
              id="lobby-swap-gender-btn"
            >
              <RefreshCw className="h-3.5 w-3.5" />
            </button>
          </div>

          <div className="mt-3 text-center">
            <h2 className="text-xs font-extrabold text-slate-300 flex items-center justify-center gap-1">
              {gender === 'MALE' ? 'เด็กป๊อกแปด' : 'สาวป๊อกเก้า'}
              <Sparkles className="h-3.5 w-3.5 text-pink-400 animate-pulse" />
            </h2>
          </div>
        </div>

        {/* MID-BAR: SYSTEM NAVIGATION ICONS */}
        {/* Divided Wardrobe and Shop as independent buttons */}
        <div className="flex items-center justify-center gap-7 w-full py-2.5 border-y border-slate-800/40">
          
          {/* WARDROBE (ตู้เสื้อผ้า) BUTTON */}
          <button
            onClick={() => setWardrobeOpen(true)}
            className="flex flex-col items-center gap-1.5 group"
            id="lobby-wardrobe-icon-btn"
          >
            <div className="h-12 w-12 rounded-full bg-gradient-to-br from-indigo-500 to-purple-600 hover:from-indigo-600 hover:to-purple-700 flex items-center justify-center text-white shadow-md shadow-purple-500/10 hover:shadow-purple-500/20 active:scale-95 transition-all">
              <Shirt className="h-5.5 w-5.5" />
            </div>
            <span className="text-[10px] font-bold text-slate-400 group-hover:text-purple-400 transition-colors">ตู้เสื้อผ้า</span>
          </button>

          {/* FASHION SHOP (ร้านค้า) BUTTON */}
          <button
            onClick={() => setShopOpen(true)}
            className="flex flex-col items-center gap-1.5 group"
            id="lobby-shop-icon-btn"
          >
            <div className="h-12 w-12 rounded-full bg-gradient-to-br from-pink-400 to-pink-600 hover:from-pink-500 hover:to-pink-700 flex items-center justify-center text-white shadow-md shadow-pink-500/10 hover:shadow-pink-500/20 active:scale-95 transition-all">
              <Store className="h-5.5 w-5.5" />
            </div>
            <span className="text-[10px] font-bold text-slate-400 group-hover:text-pink-400 transition-colors">ร้านค้าแฟชั่น</span>
          </button>

          {/* QUESTS / REWARDS BUTTON */}
          <button
            onClick={() => setPhase('QUESTS')}
            className="flex flex-col items-center gap-1.5 group"
            id="lobby-quests-icon-btn"
          >
            <div className="h-12 w-12 rounded-full bg-gradient-to-br from-emerald-400 to-emerald-600 hover:from-emerald-500 hover:to-emerald-700 flex items-center justify-center text-slate-950 shadow-md shadow-emerald-500/10 hover:shadow-emerald-500/20 active:scale-95 transition-all">
              <Gift className="h-5.5 w-5.5" />
            </div>
            <span className="text-[10px] font-bold text-slate-400 group-hover:text-emerald-400 transition-colors">รับรางวัลฟรี</span>
          </button>

        </div>

        {/* BOTTOM STAKES SELECTOR & START MATCHMAKING BUTTON */}
        <div className="w-full flex flex-col gap-4">
          
          {/* Bet Selector - Miniature & Cute Chips style */}
          <div className="flex flex-col gap-1.5">
            <div className="flex items-center justify-center gap-3">
              {[5, 10, 50, 100].map(betOption => (
                <button
                  key={betOption}
                  disabled={isSearching}
                  onClick={() => setBetAmount(betOption)}
                  className={`flex-1 rounded-2xl py-2 px-1 text-xs font-black transition-all border ${
                    currentBet === betOption
                      ? 'bg-emerald-500 border-emerald-400 text-slate-950 scale-105 shadow-md shadow-emerald-500/20'
                      : 'bg-slate-800/80 border-slate-700/50 text-slate-400 hover:bg-slate-800'
                  }`}
                >
                  <span className="block font-mono text-xs">{betOption} ชิป</span>
                </button>
              ))}
            </div>
          </div>

          {/* PLAY/MATCHMAKING TRIGGERS */}
          {isSearching ? (
            <div className="flex flex-col items-center justify-center bg-slate-800/60 rounded-3xl p-4 border border-slate-700/40 text-center animate-pulse">
              <span className="text-xs font-bold text-emerald-400 mb-1 flex items-center gap-1.5">
                <RefreshCw className="h-3 w-3 animate-spin" />
                กำลังจับคู่หาโต๊ะ ({searchCountdown} วินาที)...
              </span>
              <button
                onClick={cancelMatchmaking}
                className="mt-2 text-[11px] font-extrabold text-pink-400 hover:text-pink-300 bg-pink-500/10 px-3 py-1 rounded-full border border-pink-500/20"
              >
                ยกเลิกหาโต๊ะ
              </button>
            </div>
          ) : (
            <button
              onClick={startMatchmaking}
              className="w-full bg-gradient-to-r from-emerald-400 to-emerald-500 hover:from-emerald-500 hover:to-emerald-600 py-3.5 rounded-2xl font-black text-sm tracking-wide text-slate-950 hover:scale-[1.02] active:scale-98 transition shadow-lg shadow-emerald-500/10 flex items-center justify-center gap-2"
              id="lobby-start-game-btn"
            >
              <Play className="h-4.5 w-4.5 fill-slate-950 text-slate-950" />
              เริ่มเล่นไพ่ป๊อกเด้ง
              <ChevronRight className="h-4 w-4 text-slate-950" />
            </button>
          )}

        </div>
      </main>

      {/* FOOTER ACCENTS: Humble, clean with integrated How to Play link */}
      <footer className="w-full max-w-md mx-auto flex items-center justify-between text-[10px] text-slate-600 tracking-wide mt-4 z-10 px-1">
        <span>Pokdeng Teen Casino Classic</span>
        <button
          onClick={() => setShowHowToPlay(true)}
          className="text-slate-500 hover:text-slate-300 underline font-semibold transition flex items-center gap-0.5"
          title="ดูวิธีเล่นและกติกา"
        >
          <HelpCircle className="h-3 w-3" />
          วิธีเล่น
        </button>
      </footer>

      {/* 1. PERSONAL WARDROBE (ตู้เสื้อผ้า) DIALOG */}
      {wardrobeOpen && (
        <div className="fixed inset-0 z-40 flex items-center justify-center bg-slate-950/85 p-4 backdrop-blur-xs">
          <div className="relative flex h-[82vh] w-full max-w-xl flex-col rounded-3xl border border-slate-800 bg-slate-900 shadow-2xl overflow-hidden animate-scale-up text-slate-100">
            
            {/* WARDROBE HEADER */}
            <div className="flex items-center justify-between border-b border-slate-800 p-5 bg-slate-950">
              <div className="flex items-center gap-2.5">
                <div className="rounded-xl bg-purple-500/15 p-2 text-purple-400 border border-purple-500/20">
                  <Shirt className="h-5 w-5" />
                </div>
                <div>
                  <h3 className="text-base font-bold text-white">ตู้เสื้อผ้าส่วนตัว</h3>
                  <p className="text-[11px] text-slate-400">เลือกแต่งตัวตามสไตล์จากเครื่องแต่งกายที่คุณเป็นเจ้าของ</p>
                </div>
              </div>
              
              <button
                onClick={() => setWardrobeOpen(false)}
                className="flex h-8 w-8 items-center justify-center rounded-full bg-slate-800 hover:bg-slate-700 text-slate-400 transition"
              >
                <X className="h-4.5 w-4.5" />
              </button>
            </div>

            {/* WARDROBE MAIN SECTION */}
            <div className="flex-1 grid md:grid-cols-12 overflow-hidden">
              
              {/* INTERACTIVE PREVIEW */}
              <div className="md:col-span-4 border-r border-slate-800 bg-slate-950/40 p-4 flex flex-col items-center justify-center text-center">
                <div className="bg-slate-950 p-4 rounded-2xl border border-slate-800 shadow-inner mb-2">
                  <AvatarPainter gender={gender} avatar={avatar} size={120} animate={true} noBackground={true} />
                </div>
                <h4 className="text-[11px] font-bold text-slate-300">ตัวละครจำลองของคุณ</h4>
                
                {/* PROMO TO SHOP */}
                <div className="mt-4 p-3 rounded-2xl bg-slate-900 border border-slate-800/60 text-center w-full">
                  <p className="text-[10px] text-slate-400 mb-2">เบื่อเครื่องแต่งกายเดิม?</p>
                  <button
                    onClick={() => {
                      setWardrobeOpen(false);
                      setShopOpen(true);
                    }}
                    className="text-[10px] bg-pink-500 hover:bg-pink-600 font-extrabold text-white px-3 py-1.5 rounded-xl transition w-full"
                  >
                    เข้าร้านค้าแฟชั่นแรร์ 🛍️
                  </button>
                </div>
              </div>

              {/* CLOTHES TABS & LIST */}
              <div className="md:col-span-8 flex flex-col h-full overflow-hidden bg-slate-900">
                {/* TABS SELECTOR */}
                <div className="flex border-b border-slate-800 bg-slate-950/40 px-4 py-2 gap-1.5 overflow-x-auto scrollbar-none">
                  {(['hair', 'hat', 'shirt', 'pants'] as const).map(tab => (
                    <button
                      key={tab}
                      onClick={() => setWardrobeTab(tab)}
                      className={`rounded-xl px-3 py-1.5 text-xs font-bold capitalize transition-all shrink-0 ${
                        wardrobeTab === tab
                          ? 'bg-purple-600 text-white'
                          : 'bg-slate-800 text-slate-400 hover:bg-slate-700'
                      }`}
                    >
                      {tab === 'hair' && '💇 ผม'}
                      {tab === 'hat' && '🎩 หมวก'}
                      {tab === 'shirt' && '👕 เสื้อ'}
                      {tab === 'pants' && '👖 กางเกง'}
                    </button>
                  ))}
                </div>

                {/* FILTERED LIST: Only show items owned (index 0 or in ownedItems) */}
                <div className="flex-1 overflow-y-auto p-4 space-y-2">
                  {fashionDetails[wardrobeTab].map((item, idx) => {
                    const itemKey = `${wardrobeTab}-${idx}`;
                    const isOwned = idx === 0 || ownedItems.includes(itemKey);
                    
                    if (!isOwned) return null; // Hide unowned clothing in Wardrobe

                    const isEquipped = avatar[wardrobeTab] === idx;
                    
                    return (
                      <div 
                        key={idx}
                        onClick={() => updateAvatarStyle(wardrobeTab, idx)}
                        className={`group flex items-center justify-between p-2.5 rounded-xl border cursor-pointer transition ${
                          isEquipped 
                            ? 'bg-purple-500/10 border-purple-500/50' 
                            : 'bg-slate-800/40 border-slate-800 hover:border-slate-700 hover:bg-slate-800/80'
                        }`}
                      >
                        <div className="flex items-center gap-2.5">
                          <div className={`h-8 w-8 rounded-lg flex items-center justify-center font-mono font-bold text-xs ${
                            isEquipped 
                              ? 'bg-purple-500 text-white' 
                              : 'bg-slate-800 text-slate-500 group-hover:text-purple-400'
                          }`}>
                            #{idx}
                          </div>
                          <div>
                            <h5 className="text-xs font-black text-slate-200 group-hover:text-purple-400 transition-colors">
                              {item.name}
                            </h5>
                          </div>
                        </div>

                        <div>
                          {isEquipped ? (
                            <span className="rounded-lg bg-purple-500 px-2 py-1 text-[9px] font-bold text-white flex items-center gap-0.5 animate-pulse">
                              <Check className="h-3 w-3" /> สวมใส่อยู่
                            </span>
                          ) : (
                            <span className="rounded-lg bg-slate-800 px-2 py-1 text-[9px] font-bold text-slate-400 group-hover:bg-slate-700 group-hover:text-purple-400">
                              กดเพื่อติดตั้ง
                            </span>
                          )}
                        </div>
                      </div>
                    );
                  })}
                </div>
              </div>

            </div>
          </div>
        </div>
      )}

      {/* 2. RARE FASHION SHOP (ร้านค้า) DIALOG */}
      {shopOpen && (
        <div className="fixed inset-0 z-40 flex items-center justify-center bg-slate-950/85 p-4 backdrop-blur-xs">
          <div className="relative flex h-[82vh] w-full max-w-xl flex-col rounded-3xl border border-slate-800 bg-slate-900 shadow-2xl overflow-hidden animate-scale-up text-slate-100">
            
            {/* SHOP HEADER */}
            <div className="flex items-center justify-between border-b border-slate-800 p-5 bg-slate-950">
              <div className="flex items-center gap-2.5">
                <div className="rounded-xl bg-pink-500/15 p-2 text-pink-400 border border-pink-500/20">
                  <Store className="h-5 w-5" />
                </div>
                <div>
                  <h3 className="text-base font-bold text-white">ร้านค้าแฟชั่นแรร์</h3>
                  <p className="text-[11px] text-slate-400">ปลดล็อกเครื่องแต่งกายพรีเมียม ถาวรตลอดกาล!</p>
                </div>
              </div>
              
              <button
                onClick={() => setShopOpen(false)}
                className="flex h-8 w-8 items-center justify-center rounded-full bg-slate-800 hover:bg-slate-700 text-slate-400 transition"
              >
                <X className="h-4.5 w-4.5" />
              </button>
            </div>

            {/* SHOP GRID MODULE */}
            <div className="flex-1 grid md:grid-cols-12 overflow-hidden">
              
              {/* INTERACTIVE PREVIEW */}
              <div className="md:col-span-4 border-r border-slate-800 bg-slate-950/40 p-4 flex flex-col items-center justify-center text-center">
                <div className="bg-slate-950 p-4 rounded-2xl border border-slate-800 shadow-inner mb-3">
                  <AvatarPainter gender={gender} avatar={avatar} size={120} animate={true} noBackground={true} />
                </div>
                <h4 className="text-[11px] font-bold text-slate-300">ลองแต่งตัวจำลอง</h4>
                
                {/* SHOP CHIPS INDICATOR */}
                <div className="mt-3 rounded-full bg-slate-800/80 px-3 py-1 border border-slate-700/60 inline-flex items-center gap-1.5 animate-pulse">
                  <Coins className="h-3.5 w-3.5 text-emerald-400" />
                  <span className="font-mono text-xs font-bold text-emerald-400">
                    มีชิป: {userChips.toLocaleString()}
                  </span>
                </div>
              </div>

              {/* CONTROLS RIGHT */}
              <div className="md:col-span-8 flex flex-col h-full overflow-hidden bg-slate-900">
                {/* TABS SELECTOR */}
                <div className="flex border-b border-slate-800 bg-slate-950/40 px-4 py-2 gap-1.5 overflow-x-auto scrollbar-none">
                  {(['hair', 'hat', 'shirt', 'pants'] as const).map(tab => (
                    <button
                      key={tab}
                      onClick={() => setShopTab(tab)}
                      className={`rounded-xl px-3 py-1.5 text-xs font-bold capitalize transition-all shrink-0 ${
                        shopTab === tab
                          ? 'bg-pink-500 text-white'
                          : 'bg-slate-800 text-slate-400 hover:bg-slate-700'
                      }`}
                    >
                      {tab === 'hair' && '💇 ผม'}
                      {tab === 'hat' && '🎩 หมวก'}
                      {tab === 'shirt' && '👕 เสื้อ'}
                      {tab === 'pants' && '👖 กางเกง'}
                    </button>
                  ))}
                </div>

                {/* SHOP ITEM DETAILS LIST */}
                <div className="flex-1 overflow-y-auto p-4 space-y-2">
                  {fashionDetails[shopTab].map((item, idx) => {
                    const itemKey = `${shopTab}-${idx}`;
                    const isOwned = idx === 0 || ownedItems.includes(itemKey);
                    const isEquipped = avatar[shopTab] === idx;
                    const cost = idx * 150;
                    
                    return (
                      <div 
                        key={idx}
                        onClick={() => updateAvatarStyle(shopTab, idx)}
                        className={`group flex items-center justify-between p-2.5 rounded-xl border cursor-pointer transition ${
                          isEquipped 
                            ? 'bg-pink-500/10 border-pink-500/50' 
                            : 'bg-slate-800/40 border-slate-800 hover:border-slate-700 hover:bg-slate-800/80'
                        }`}
                      >
                        <div className="flex items-center gap-2.5">
                          <div className={`h-8 w-8 rounded-lg flex items-center justify-center font-mono font-bold text-xs ${
                            isEquipped 
                              ? 'bg-pink-500 text-white' 
                              : isOwned
                                ? 'bg-slate-700 text-slate-300'
                                : 'bg-slate-800 text-slate-500 group-hover:text-pink-400'
                          }`}>
                            #{idx}
                          </div>
                          <div>
                            <h5 className="text-xs font-black text-slate-200 group-hover:text-pink-400 transition-colors">
                              {item.name}
                            </h5>
                          </div>
                        </div>

                        {/* PURCHASE OR EQUIP STATE ACTION */}
                        <div>
                          {isEquipped ? (
                            <span className="rounded-lg bg-pink-500 px-2 py-1 text-[9px] font-bold text-white flex items-center gap-0.5">
                              <Check className="h-3 w-3" /> สวมใส่อยู่
                            </span>
                          ) : isOwned ? (
                            <span className="rounded-lg bg-slate-700 px-2 py-1 text-[9px] font-bold text-slate-300 group-hover:bg-slate-600">
                              มีแล้ว (สวมใส่)
                            </span>
                          ) : cost === 0 ? (
                            <span className="rounded-lg bg-slate-850 px-2 py-1 text-[9px] font-bold text-slate-400 group-hover:bg-slate-700">
                              ใช้งานฟรี
                            </span>
                          ) : (
                            <span className="rounded-lg bg-emerald-500/10 px-2 py-1 font-mono text-[9px] font-black text-emerald-400 border border-emerald-500/20 flex items-center gap-0.5 group-hover:border-emerald-500/40">
                              <Coins className="h-3 w-3 text-emerald-400" /> {cost}
                            </span>
                          )}
                        </div>
                      </div>
                    );
                  })}
                </div>
              </div>

            </div>
          </div>
        </div>
      )}

      {/* RULES / HOW TO PLAY MODAL */}
      {showHowToPlay && (
        <div className="fixed inset-0 z-40 flex items-center justify-center bg-slate-950/80 p-4 backdrop-blur-xs">
          <div className="relative flex h-[80vh] w-full max-w-lg flex-col rounded-3xl border border-slate-800 bg-slate-900 shadow-2xl overflow-hidden text-slate-300">
            <div className="flex items-center justify-between border-b border-slate-800 p-5 bg-slate-950">
              <h3 className="text-base font-bold text-white flex items-center gap-2">
                <HelpCircle className="h-5 w-5 text-emerald-400" />
                กติกาไพ่ป๊อกเด้ง (Pokdeng Rules)
              </h3>
              <button
                onClick={() => setShowHowToPlay(false)}
                className="flex h-8 w-8 items-center justify-center rounded-full bg-slate-800 hover:bg-slate-700 text-slate-400 transition"
              >
                <X className="h-4.5 w-4.5" />
              </button>
            </div>
            
            <div className="flex-1 overflow-y-auto p-5 space-y-4 text-xs leading-relaxed">
              <section>
                <h4 className="font-bold text-emerald-400 mb-1">1. วิธีนับแต้ม</h4>
                <p>รวมแต้มไพ่แล้วคิดเศษหลักหน่วย (A = 1, J/Q/K = 0, 10 = 0). แต้มสูงสุดคือ 9 แต้ม.</p>
              </section>

              <section>
                <h4 className="font-bold text-emerald-400 mb-1">2. ป๊อก 8 และ ป๊อก 9</h4>
                <p>ถ้าไพ่ 2 ใบแรกรวมได้ 8 หรือ 9 แต้ม จะทำการ "ป๊อก" ทันที ห้ามจั่วเพิ่ม ชนะแต้มที่ต่ำกว่า.</p>
              </section>

              <section>
                <h4 className="font-bold text-emerald-400 mb-1">3. จั่วไพ่ใบที่สาม</h4>
                <p>ถ้าแต้มต่ำ (0-5 แต้ม) ต้องจั่วใบที่ 3 เพิ่ม. หากมี 6 หรือ 7 แต้ม แนะนำให้ยืนอยู่เฉยๆ เพื่อความปลอดภัย.</p>
              </section>

              <section>
                <h4 className="font-bold text-emerald-400 mb-1">4. ไพ่พิเศษ (คูณแต้ม 2 เด้ง ถึง 5 เด้ง)</h4>
                <ul className="list-disc pl-4 space-y-1">
                  <li><strong>ตอง:</strong> ไพ่ 3 ใบเลขเหมือนกันทั้งหมด (คูณ 5 เท่า)</li>
                  <li><strong>เรียงดอก:</strong> ไพ่ 3 ใบดอกเดียวและแต้มเรียงกัน (คูณ 5 เท่า)</li>
                  <li><strong>สามเหลือง (เซียน):</strong> ไพ่ 3 ใบเป็นกลุ่ม J, Q, K คละกัน (คูณ 3 เท่า)</li>
                  <li><strong>เรียง:</strong> ไพ่ 3 ใบแต้มต่อกันต่างดอก (คูณ 3 เท่า)</li>
                  <li><strong>2-3 เด้ง:</strong> ดอกเดียวกันหรือเลขเหมือนกันคู่/ตอง (คูณ 2-3 เท่า)</li>
                </ul>
              </section>
            </div>
          </div>
        </div>
      )}

      {/* 3. GOOGLE PAY TOP-UP DIALOG */}
      {googlePayOpen && (
        <div className="fixed inset-0 z-40 flex items-center justify-center bg-slate-950/85 p-4 backdrop-blur-xs">
          <div className="relative flex w-full max-w-md flex-col rounded-3xl border border-slate-800 bg-slate-900 shadow-2xl overflow-hidden animate-scale-up text-slate-100">
            
            {/* GOOGLE PAY HEADER */}
            <div className="flex items-center justify-between border-b border-slate-800 p-5 bg-slate-950">
              <div className="flex items-center gap-2.5">
                {/* Google Pay Stylized Logo */}
                <div className="flex items-center gap-1 bg-white px-2.5 py-1 rounded-lg border border-slate-200">
                  <span className="font-sans font-black text-slate-800 tracking-tight text-xs">Google</span>
                  <span className="font-sans font-black text-blue-600 text-xs">Pay</span>
                </div>
                <div>
                  <h3 className="text-sm font-bold text-white">เติมชิปด่วนทันใจ</h3>
                </div>
              </div>
              
              <button
                onClick={() => {
                  if (!isProcessingPay) {
                    setGooglePayOpen(false);
                    setPayingTier(null);
                    setPaySuccess(false);
                  }
                }}
                disabled={isProcessingPay}
                className="flex h-8 w-8 items-center justify-center rounded-full bg-slate-800 hover:bg-slate-700 text-slate-400 transition disabled:opacity-50"
              >
                <X className="h-4.5 w-4.5" />
              </button>
            </div>

            {/* DIALOG MAIN PANEL */}
            <div className="p-5 flex flex-col gap-4">
              {!payingTier && !paySuccess ? (
                <>
                  <div className="text-center py-2">
                    <p className="text-xs text-slate-400">เลือกแพ็กเกจที่คุณต้องการเติมเงินเพื่อเพิ่มชิปในบัญชีของคุณ</p>
                  </div>

                  {/* PRODUCTS LIST */}
                  <div className="flex flex-col gap-3">
                    {[
                      { baht: 10, chips: 50, desc: 'แพ็กเริ่มต้นจิ๋วแจ๋ว ลุยเบาๆ' },
                      { baht: 50, chips: 100, desc: 'แพ็กคุ้มค่าสำหรับวัยรุ่นป๊อกเด้ง' },
                      { baht: 100, chips: 500, desc: 'แพ็กเศรษฐีป๊อกแปดป๊อกเก้า จุกๆ' },
                    ].map((tier, idx) => (
                      <button
                        key={idx}
                        onClick={() => {
                          setPayingTier(tier);
                          setIsProcessingPay(true);
                          // Simulate payment flow
                          setTimeout(() => {
                            setIsProcessingPay(false);
                            setPaySuccess(true);
                            addChips(tier.chips);
                          }, 2000);
                        }}
                        className="group flex items-center justify-between p-4 rounded-2xl bg-slate-800/40 border border-slate-800 hover:border-emerald-500/50 hover:bg-slate-800/80 transition-all text-left cursor-pointer active:scale-98"
                      >
                        <div className="flex items-center gap-3">
                          <div className="h-10 w-10 rounded-xl bg-emerald-500/10 flex items-center justify-center text-emerald-400 border border-emerald-500/20 group-hover:scale-105 transition-transform">
                            <Coins className="h-5 w-5" />
                          </div>
                          <div>
                            <div className="flex items-center gap-1.5">
                              <span className="font-mono text-base font-black text-emerald-400">+{tier.chips}</span>
                              <span className="text-xs font-bold text-slate-200">ชิป</span>
                            </div>
                            <p className="text-[10px] text-slate-500">{tier.desc}</p>
                          </div>
                        </div>

                        <div className="bg-emerald-500 group-hover:bg-emerald-400 text-slate-950 font-black text-xs px-3.5 py-1.5 rounded-xl shadow-md transition-all">
                          ฿{tier.baht}
                        </div>
                      </button>
                    ))}
                  </div>

                  <div className="mt-2 text-center text-[10px] text-slate-500 flex items-center justify-center gap-1">
                    🔒 การทำรายการผ่าน Google Pay ได้รับการเข้ารหัสความปลอดภัยระดับสากล
                  </div>
                </>
              ) : isProcessingPay ? (
                /* PAYMENT LOADER SCREEN */
                <div className="flex flex-col items-center justify-center py-8 text-center gap-4">
                  <div className="relative flex items-center justify-center">
                    <div className="h-16 w-16 rounded-full border-4 border-slate-800 border-t-emerald-500 animate-spin"></div>
                    <div className="absolute font-mono text-[10px] font-black text-slate-400">G Pay</div>
                  </div>
                  <div>
                    <h4 className="text-sm font-bold text-white animate-pulse">กำลังประมวลผลธุรกรรม...</h4>
                    <p className="text-[11px] text-slate-400 mt-1">กำลังดำเนินการชำระเงินจำนวน ฿{payingTier?.baht} เพื่อซื้อ {payingTier?.chips} ชิป ผ่านระบบ Google Pay ของคุณ</p>
                  </div>
                </div>
              ) : (
                /* SUCCESS SCREEN */
                <div className="flex flex-col items-center justify-center py-6 text-center gap-4 animate-scale-up">
                  <div className="h-14 w-14 rounded-full bg-emerald-500/10 flex items-center justify-center text-emerald-400 border-2 border-emerald-500/30 shadow-lg shadow-emerald-500/10">
                    <Check className="h-8 w-8 animate-bounce" />
                  </div>
                  <div>
                    <h4 className="text-base font-black text-white">เติมเงินสำเร็จแล้ว! 🎉</h4>
                    <p className="text-xs text-slate-400 mt-1">ชิปของคุณได้รับการปรับเพิ่มขึ้น <span className="text-emerald-400 font-bold">+{payingTier?.chips} ชิป</span> เรียบร้อยแล้ว</p>
                  </div>

                  <div className="w-full bg-slate-950/60 rounded-2xl p-3 border border-slate-800 text-left font-mono text-[10px] space-y-1 text-slate-400 mt-2">
                    <div className="flex justify-between">
                      <span>ช่องทางชำระเงิน:</span>
                      <span className="text-white">Google Pay (Simulated)</span>
                    </div>
                    <div className="flex justify-between">
                      <span>ยอดเงินที่หัก:</span>
                      <span className="text-emerald-400">฿{payingTier?.baht}.00 บาท</span>
                    </div>
                    <div className="flex justify-between">
                      <span>จำนวนชิปที่ได้รับ:</span>
                      <span className="text-emerald-400">+{payingTier?.chips} CHIPS</span>
                    </div>
                    <div className="flex justify-between border-t border-slate-800 pt-1 mt-1">
                      <span>รหัสอ้างอิง:</span>
                      <span>G-PAY-POKDENG-{Math.floor(100000 + Math.random() * 900000)}</span>
                    </div>
                  </div>

                  <button
                    onClick={() => {
                      setGooglePayOpen(false);
                      setPayingTier(null);
                      setPaySuccess(false);
                    }}
                    className="w-full bg-emerald-500 hover:bg-emerald-600 text-slate-950 font-black text-xs py-2.5 rounded-xl transition mt-2 active:scale-98"
                  >
                    ยืนยันและกลับเข้าสู่เกม
                  </button>
                </div>
              )}
            </div>

          </div>
        </div>
      )}
    </div>
  );
};
