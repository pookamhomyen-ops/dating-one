import React, { useState } from 'react';
import { usePokdeng } from './pokdeng_game_provider';
import { 
  ArrowLeft, 
  Coins, 
  Gift, 
  Tv, 
  CheckCircle, 
  Clock, 
  Sparkles, 
  Trophy, 
  Calendar,
  ArrowRight,
  Crown
} from 'lucide-react';

export const PokdengQuestScreen: React.FC = () => {
  const {
    userChips,
    dailyQuests,
    claimedDailyLogin,
    lastAdClaimTime,
    watchAd,
    claimDailyLogin,
    claimQuest,
    setPhase
  } = usePokdeng();

  const [adLoading, setAdLoading] = useState(false);

  const handleWatchAd = async () => {
    if (adLoading) return;
    const now = Date.now();
    if (now - lastAdClaimTime < 30000) {
      const remaining = Math.ceil((30000 - (now - lastAdClaimTime)) / 1000);
      alert(`โปรดรออีก ${remaining} วินาทีเพื่อดูโฆษณาถัดไป`);
      return;
    }

    setAdLoading(true);
    setTimeout(async () => {
      setAdLoading(false);
      await watchAd();
    }, 3000); // 3 seconds viewing simulation
  };

  return (
    <div className="min-h-screen bg-slate-900 text-slate-100 font-sans relative selection:bg-pink-500 selection:text-white pb-12 overflow-x-hidden">
      {/* Decorative Warm Light BG Orbs */}
      <div className="absolute top-0 right-0 w-96 h-96 bg-pink-500/10 rounded-full blur-[100px] pointer-events-none"></div>
      <div className="absolute bottom-12 left-0 w-80 h-80 bg-emerald-500/10 rounded-full blur-[100px] pointer-events-none"></div>

      {/* HEADER BAR */}
      <header className="sticky top-0 z-30 bg-slate-950/80 backdrop-blur-md border-b border-slate-800/80 px-4 py-4 shadow-md">
        <div className="mx-auto max-w-4xl flex items-center justify-between gap-4">
          <button
            onClick={() => setPhase('LOBBY')}
            className="flex items-center gap-1.5 rounded-xl border border-slate-800 bg-slate-900 px-3.5 py-2 text-xs font-bold text-slate-300 hover:bg-slate-800 hover:text-white transition shadow-sm"
            id="back-to-lobby-btn"
          >
            <ArrowLeft className="h-4 w-4" />
            กลับ
          </button>

          <div className="flex items-center gap-2">
            <Gift className="h-5 w-5 text-pink-400 animate-bounce" />
            <span className="text-sm font-black text-white tracking-tight">
              โบนัสฟรี & ภารกิจประจำวัน
            </span>
          </div>

          <div className="flex items-center gap-1.5 rounded-full bg-slate-900/90 border border-slate-800 px-3 py-1 shadow-inner">
            <Coins className="h-3.5 w-3.5 text-emerald-400" />
            <span className="font-mono text-xs font-black text-emerald-400">
              {userChips.toLocaleString()}
            </span>
          </div>
        </div>
      </header>

      <main className="mx-auto mt-6 max-w-4xl px-4 grid gap-6 md:grid-cols-12 relative z-10">
        
        {/* LEFT COLUMN: DAILY LOGIN */}
        <div className="md:col-span-5 flex flex-col gap-6">
          <div className="bg-slate-950/50 rounded-3xl border border-slate-800 p-6 shadow-xl flex flex-col relative overflow-hidden">
            
            <div className="flex items-center gap-2 border-b border-slate-800/60 pb-3 mb-4">
              <Calendar className="h-4.5 w-4.5 text-pink-400" />
              <h3 className="text-xs font-extrabold uppercase tracking-wider text-slate-400">
                เช็คอินรับชิปฟรีประจำวัน
              </h3>
            </div>

            <div className="text-center py-4">
              <div className="inline-flex h-16 w-16 items-center justify-center rounded-2xl bg-gradient-to-br from-pink-500/10 to-pink-500/20 border border-pink-500/20 text-pink-400 mb-4 shadow-inner">
                <Gift className="h-8 w-8 text-pink-400 animate-pulse" />
              </div>

              <h4 className="text-base font-black text-white">ของขวัญเข้าเล่นประจำวัน</h4>
              <p className="text-xs text-slate-400 mt-1.5 max-w-xs mx-auto">
                เข้าล็อกอินเล่นทุกวันเพื่อเติมทุนกอบโกยชัยชนะบนโต๊ะไพ่ป๊อกเด้ง!
              </p>

              <div className="mt-5">
                {claimedDailyLogin ? (
                  <div className="flex items-center justify-center gap-1.5 py-3 px-4 rounded-xl bg-slate-900 border border-slate-800 text-slate-500 text-xs font-bold w-full">
                    <CheckCircle className="h-4 w-4 text-emerald-400" />
                    เช็คอินวันนี้เรียบร้อยแล้ว (+200 ชิป)
                  </div>
                ) : (
                  <button
                    onClick={claimDailyLogin}
                    className="w-full flex items-center justify-center gap-1.5 py-3 px-4 rounded-xl bg-gradient-to-r from-pink-500 to-pink-600 hover:from-pink-600 hover:to-pink-700 text-white text-xs font-black transition shadow-lg shadow-pink-500/20 active:scale-98"
                    id="claim-daily-login-btn"
                  >
                    <Sparkles className="h-3.5 w-3.5 text-white animate-pulse" />
                    เช็คอินวันนี้รับ 200 ชิป
                  </button>
                )}
              </div>
            </div>

            {/* Weekly calendar preview */}
            <div className="mt-4 border-t border-slate-800/60 pt-4">
              <span className="text-[10px] font-bold text-slate-500 block mb-2">ปฏิทินสัปดาห์นี้</span>
              <div className="grid grid-cols-7 gap-1">
                {[1, 2, 3, 4, 5, 6, 7].map((day) => {
                  const isCurrent = day === 1; // Highlight day 1 for simulation
                  const isClaimed = claimedDailyLogin && isCurrent;
                  return (
                    <div 
                      key={day} 
                      className={`p-1.5 rounded-lg border text-[10px] flex flex-col items-center justify-center transition-all ${
                        isClaimed 
                          ? 'bg-emerald-500/10 border-emerald-500/30 text-emerald-400 font-bold' 
                          : isCurrent 
                          ? 'bg-pink-500/10 border-pink-500/30 text-pink-400 font-black' 
                          : 'bg-slate-900 border-slate-800/60 text-slate-500'
                      }`}
                    >
                      <span className="font-mono block mb-0.5 text-[9px]">วัน {day}</span>
                      {isClaimed ? (
                        <CheckCircle className="h-3 w-3 text-emerald-400" />
                      ) : (
                        <span className="font-black text-[9px] text-pink-400">+200</span>
                      )}
                    </div>
                  );
                })}
              </div>
            </div>
          </div>
        </div>

        {/* RIGHT COLUMN: DAILY QUESTS & ADS */}
        <div className="md:col-span-7 flex flex-col gap-6">
          
          {/* QUESTS LIST */}
          <div className="bg-slate-950/50 rounded-3xl border border-slate-800 p-6 shadow-xl">
            <div className="flex items-center justify-between border-b border-slate-800/60 pb-3 mb-4">
              <div className="flex items-center gap-2">
                <Trophy className="h-4.5 w-4.5 text-emerald-400" />
                <h3 className="text-xs font-extrabold uppercase tracking-wider text-slate-400">
                  ภารกิจประจำวัน
                </h3>
              </div>
              <span className="rounded-full bg-slate-900 border border-slate-800 px-2 py-0.5 text-[9px] font-bold text-slate-400">
                รีเซ็ตทุก 24 ชม.
              </span>
            </div>

            <div className="space-y-3">
              {dailyQuests.map((quest) => {
                const percent = Math.min(100, Math.floor((quest.current / quest.target) * 100));
                return (
                  <div 
                    key={quest.id} 
                    className="p-4 rounded-2xl border border-slate-800 bg-slate-900/60 hover:bg-slate-900/80 transition flex flex-col gap-3"
                  >
                    <div className="flex items-start justify-between gap-3">
                      <div>
                        <span className="rounded bg-emerald-500/10 border border-emerald-500/20 px-1.5 py-0.5 text-[9px] font-bold text-emerald-400">
                          + {quest.reward} ชิป
                        </span>
                        <h4 className="text-xs font-black text-white mt-1.5">{quest.name}</h4>
                        <p className="text-[11px] text-slate-400 mt-0.5">{quest.description}</p>
                      </div>

                      {quest.claimed ? (
                        <span className="rounded-lg bg-slate-800 border border-slate-850 px-2.5 py-1 text-[10px] font-bold text-slate-500 flex items-center gap-0.5">
                          รับแล้ว <CheckCircle className="h-3 w-3 text-emerald-400" />
                        </span>
                      ) : quest.completed ? (
                        <button
                          onClick={() => claimQuest(quest.id)}
                          className="rounded-lg bg-gradient-to-r from-emerald-400 to-emerald-500 hover:from-emerald-500 hover:to-emerald-600 text-slate-950 px-3 py-1.5 text-[11px] font-black transition active:scale-95 flex items-center gap-0.5"
                        >
                          รับชิป
                          <ArrowRight className="h-3 w-3 text-slate-950" />
                        </button>
                      ) : (
                        <span className="rounded-lg bg-slate-800 border border-slate-850 px-2.5 py-1 text-[10px] font-bold text-slate-500">
                          คืบหน้า {percent}%
                        </span>
                      )}
                    </div>

                    <div className="w-full">
                      <div className="flex justify-between text-[9px] text-slate-500 mb-1">
                        <span>ความคืบหน้าภารกิจ</span>
                        <span className="font-mono font-bold">{quest.current} / {quest.target} รอบ</span>
                      </div>
                      <div className="h-1.5 w-full bg-slate-800 rounded-full overflow-hidden">
                        <div 
                          className="h-full bg-gradient-to-r from-emerald-400 to-emerald-500 rounded-full transition-all duration-500" 
                          style={{ width: `${percent}%` }}
                        ></div>
                      </div>
                    </div>
                  </div>
                );
              })}
            </div>
          </div>

          {/* WATCH ADS CARD */}
          <div className="bg-slate-950/50 rounded-3xl border border-slate-800 p-6 shadow-xl relative overflow-hidden">
            
            <div className="flex items-center gap-2 border-b border-slate-800/60 pb-3 mb-4">
              <Tv className="h-4.5 w-4.5 text-pink-400 animate-pulse" />
              <h3 className="text-xs font-extrabold uppercase tracking-wider text-slate-400">
                ตู้แจกชิปฉุกเฉิน (จำลองโฆษณา)
              </h3>
            </div>

            <div className="flex flex-col sm:flex-row items-center justify-between gap-4">
              <div className="text-center sm:text-left">
                <span className="inline-block rounded-full bg-pink-500/10 border border-pink-500/20 px-2 py-0.5 text-[9px] font-bold text-pink-400">
                  สำหรับวัยรุ่นทุนน้อย
                </span>
                <h4 className="text-xs font-black text-white mt-1.5">รับชมคลิปสั้นวิดีโอรับโบนัส 50 ชิป</h4>
                <p className="text-[11px] text-slate-400 mt-0.5 max-w-sm">
                  คลิกเพื่อชมคลิปแนะนำจำลองเป็นเวลา 3 วินาที เพื่อช่วยเพิ่มชิปเมื่อทุนขาดมือ!
                </p>
              </div>

              <button
                onClick={handleWatchAd}
                disabled={adLoading}
                className="w-full sm:w-auto relative flex items-center justify-center gap-1.5 py-2.5 px-4 rounded-xl bg-slate-800 hover:bg-slate-750 border border-slate-700 text-white text-xs font-black transition active:scale-95"
                id="watch-ad-quest-btn"
              >
                {adLoading ? (
                  <div className="flex items-center gap-1">
                    <Clock className="h-3.5 w-3.5 animate-spin text-pink-400" />
                    <span>กำลังรับชม (3 วิ)...</span>
                  </div>
                ) : (
                  <>
                    <Tv className="h-3.5 w-3.5 text-pink-400" />
                    <span>รับ +50 ชิปฟรี</span>
                  </>
                )}
              </button>
            </div>
          </div>

        </div>
      </main>
    </div>
  );
};
