import React, { useEffect, useRef, useState } from 'react';
import { usePokdeng } from './pokdeng_game_provider';
import { AvatarPainter } from './pokdeng_avatar_painter';
import { pokdengVoiceSynth } from './pokdeng_voice_synth';
import { Card, Player } from './pokdeng_game_models';
import { 
  Coins, 
  ArrowLeft, 
  Zap, 
  Sparkles, 
  RefreshCw, 
  Clock,
  Play,
  HelpCircle,
  TrendingUp,
  X,
  Plus,
  SlidersHorizontal
} from 'lucide-react';

// --- HTML5 CANVAS CARD RENDERER ---
interface PokdengCardProps {
  card: Card;
  faceUp: boolean;
  deckSheetUrl: string;
  cardBackUrl: string;
}

const PokdengCard: React.FC<PokdengCardProps> = ({ card, faceUp, deckSheetUrl, cardBackUrl }) => {
  const canvasRef = useRef<HTMLCanvasElement>(null);

  useEffect(() => {
    const canvas = canvasRef.current;
    if (!canvas) return;
    const ctx = canvas.getContext('2d');
    if (!ctx) return;

    // Clear canvas
    ctx.clearRect(0, 0, 72, 96);

    const sheetImg = new Image();
    const backImg = new Image();

    let sheetLoaded = false;
    let backLoaded = false;

    const drawCard = () => {
      if (!faceUp) {
        if (backLoaded && backImg.width > 0) {
          ctx.drawImage(backImg, 0, 0, 72, 96);
        } else {
          // Fallback solid pink back
          ctx.fillStyle = '#EC4899';
          ctx.fillRect(0, 0, 72, 96);
          ctx.strokeStyle = '#FFFFFF';
          ctx.lineWidth = 4;
          ctx.strokeRect(4, 4, 64, 88);
        }
      } else {
        if (sheetLoaded && sheetImg.width > 0) {
          // SPRITE SHEET MAPPING:
          // Row 0 = Clubs, Row 1 = Hearts, Row 2 = Spades, Row 3 = Diamonds
          // Columns 0 to 12 = Ranks 1 (A) to 13 (K)
          const col = card.rank - 1;
          let row = 0;
          if (card.suit === 'CLUBS') row = 0;
          else if (card.suit === 'HEARTS') row = 1;
          else if (card.suit === 'SPADES') row = 2;
          else if (card.suit === 'DIAMONDS') row = 3;

          const sx = col * 72;
          const sy = row * 96;

          ctx.drawImage(sheetImg, sx, sy, 72, 96, 0, 0, 72, 96);
        } else {
          // Text Fallback if sheet hasn't loaded yet
          ctx.fillStyle = '#FFFFFF';
          ctx.fillRect(0, 0, 72, 96);
          ctx.strokeStyle = '#E2E8F0';
          ctx.strokeRect(0, 0, 72, 96);
          ctx.fillStyle = '#0F172A';
          ctx.font = 'bold 12px sans-serif';
          ctx.fillText(`${card.rank} ${card.suit[0]}`, 10, 40);
        }
      }
    };

    sheetImg.onload = () => {
      sheetLoaded = true;
      drawCard();
    };
    backImg.onload = () => {
      backLoaded = true;
      drawCard();
    };

    sheetImg.src = deckSheetUrl;
    backImg.src = cardBackUrl;

    if (sheetImg.complete) sheetLoaded = true;
    if (backImg.complete) backLoaded = true;
    drawCard();
  }, [card, faceUp, deckSheetUrl, cardBackUrl]);

  return (
    <div className="relative h-20 w-15 select-none rounded-lg overflow-hidden border border-slate-700 bg-slate-950 shadow-lg transform hover:scale-105 transition duration-200">
      <canvas ref={canvasRef} width={72} height={96} className="h-full w-full block" />
    </div>
  );
};

// --- MAIN GAME BOARD SCREEN ---
export const PokdengGameScreen: React.FC = () => {
  const {
    players,
    dealer,
    phase,
    currentBet,
    activeTurnIndex,
    gameLog,
    userChips,
    deckSheetUrl,
    cardBackUrl,
    throwItemAtBot,
    activeThrowable,
    cooldownActive,
    cooldownSeconds,
    playerStand,
    playerDrawThirdCard,
    startNewRound,
    exitToLobby,
    sortUserHand,
  } = usePokdeng();

  const [dealActive, setDealActive] = useState(false);
  const [exitConfirmOpen, setExitConfirmOpen] = useState(false);
  const [summaryCountdown, setSummaryCountdown] = useState(5);
  const logContainerRef = useRef<HTMLDivElement>(null);

  // Dealer animation sub-states sequence (dealing -> drinking -> idle/done)
  const [dealerAnimState, setDealerAnimState] = useState<'IDLE' | 'DEALING' | 'DRINKING' | 'DONE'>('IDLE');

  // Interactive click states & handlers
  const [clickedSeat, setClickedSeat] = useState<number | 'dealer' | null>(null);
  const [showLabels, setShowLabels] = useState(true);
  const [facingForwardSeats, setFacingForwardSeats] = useState<number[]>([]);

  // Custom states for golden coins stream and dealer tomato splat events
  const [showBettingCoins, setShowBettingCoins] = useState(false);
  const [tomatoTargetSeat, setTomatoTargetSeat] = useState<number | null>(null);
  const [tomatoFlying, setTomatoFlying] = useState(false);
  const [tomatoSplat, setTomatoSplat] = useState(false);

  const handleCharacterClick = (seat: number | 'dealer') => {
    setClickedSeat(seat);
    
    // Play synthesized voice formant sound
    if (seat === 'dealer') {
      pokdengVoiceSynth.playVoice('female_sweet');
    } else if (seat === 0) {
      pokdengVoiceSynth.playVoice('user_voice');
    } else if (seat === 1) {
      pokdengVoiceSynth.playVoice('male_deep');
    } else if (seat === 2) {
      pokdengVoiceSynth.playVoice('female_cute');
    } else if (seat === 3) {
      pokdengVoiceSynth.playVoice('male_goofy');
    }

    // Reset animation state
    const duration = seat === 'dealer' ? 3000 : 800;
    setTimeout(() => {
      setClickedSeat((prev) => (prev === seat ? null : prev));
      
      // Bottom seats 0 (User) and 3 (Bot 3) turn around facing the screen for 2s after click animation ends
      if (seat === 0 || seat === 3) {
        setFacingForwardSeats((prev) => [...prev, seat]);
        setTimeout(() => {
          setFacingForwardSeats((prev) => prev.filter((s) => s !== seat));
        }, 2000);
      }
    }, duration);
  };

  // Show/Hide labels on phase changes (visible for 5s, always visible in SUMMARY)
  useEffect(() => {
    if (phase === 'SUMMARY') {
      setShowLabels(true);
      return;
    }
    
    setShowLabels(true);
    const timer = setTimeout(() => {
      setShowLabels(false);
    }, 5000);

    return () => clearTimeout(timer);
  }, [phase]);

  // Auto-scroll logs
  useEffect(() => {
    if (logContainerRef.current) {
      logContainerRef.current.scrollTop = logContainerRef.current.scrollHeight;
    }
  }, [gameLog]);

  // Handle distribution animation trigger & dealer state sequence
  useEffect(() => {
    if (phase === 'DEALING') {
      setDealActive(false);
      setDealerAnimState('DEALING');
      setShowBettingCoins(true);

      const timer = setTimeout(() => {
        setDealActive(true);
      }, 100);

      // 3 seconds of dealing arm movement, then 2 seconds of drinking beer
      const drinkTimer = setTimeout(() => {
        setDealerAnimState('DRINKING');
      }, 3000);

      const idleTimer = setTimeout(() => {
        setDealerAnimState('IDLE');
      }, 5000);

      // Turn off coins stream after 3.8s (covering delay stagger)
      const coinTimer = setTimeout(() => {
        setShowBettingCoins(false);
      }, 3800);

      return () => {
        clearTimeout(timer);
        clearTimeout(drinkTimer);
        clearTimeout(idleTimer);
        clearTimeout(coinTimer);
      };
    } else if (phase === 'SUMMARY' || phase === 'REVEALING') {
      setDealerAnimState('DONE');
    } else {
      setDealerAnimState('IDLE');
    }
  }, [phase]);

  // Tomato Splat event handler: 10% chance when entering PLAYING phase
  useEffect(() => {
    if (phase === 'PLAYING') {
      const roll = Math.random() < 0.10;
      if (roll) {
        const randomSeat = Math.floor(Math.random() * 4);
        setTomatoTargetSeat(randomSeat);
        setTomatoFlying(true);
        setTomatoSplat(false);

        const flightTimer = setTimeout(() => {
          setTomatoFlying(false);
          setTomatoSplat(true);

          const splatTimer = setTimeout(() => {
            setTomatoSplat(false);
            setTomatoTargetSeat(null);
          }, 1000);

          return () => clearTimeout(splatTimer);
        }, 1500);

        return () => clearTimeout(flightTimer);
      }
    } else {
      setTomatoFlying(false);
      setTomatoSplat(false);
      setTomatoTargetSeat(null);
    }
  }, [phase]);

  // Round summary countdown timer loop
  useEffect(() => {
    if (phase !== 'SUMMARY') {
      setSummaryCountdown(5);
      return;
    }

    const timer = setInterval(() => {
      setSummaryCountdown(prev => {
        if (prev <= 1) {
          startNewRound();
          return 5;
        }
        return prev - 1;
      });
    }, 1000);

    return () => clearInterval(timer);
  }, [phase, startNewRound]);

  if (players.length < 4) {
    return (
      <div className="flex h-screen flex-col items-center justify-center bg-slate-900 text-slate-100">
        <RefreshCw className="h-8 w-8 animate-spin text-emerald-400 mb-3" />
        <p className="text-slate-400 text-sm font-bold tracking-wide">กำลังดาวน์โหลดข้อมูลโต๊ะเล่นไพ่...</p>
      </div>
    );
  }

  const user = players[0];
  const bots = [players[1], players[2], players[3]]; // Left, Top-Right, Right bots respectively

  const getPointValue = (c: Card) => {
    const r = c.rank;
    if (r >= 10) return 0;
    return r;
  };
  const userPoints = user?.hand ? (user.hand.reduce((acc, c) => acc + getPointValue(c), 0) % 10) : 0;

  // Card Positions corresponding precisely with our Beautiful 3D Isometric Oval Table
  const getCardTransitionStyles = (seatIndex: number, cardIndex: number) => {
    if (!dealActive) {
      return {
        top: '68%',
        left: '50%',
        opacity: 0,
        transform: 'translate(-50%, -50%) rotate(0deg) scale(0.2)',
      };
    }

    // Centered coordinates matching where the oval felt surfaces are
    // Positions: 0 = User (Bottom Right), 1 = Bot 1 (Top Left), 2 = Bot 2 (Top Right), 3 = Bot 3 (Bottom Left), 4 = Dealer (Top Center Felt)
    const positions = [
      { top: '80%', left: `calc(65% + ${(cardIndex - 0.5) * 26}px)` },      // User Bottom Right
      { top: '48%', left: `calc(35% + ${(cardIndex - 0.5) * 26}px)` },      // Bot 1 Top Left
      { top: '48%', left: `calc(65% + ${(cardIndex - 0.5) * 26}px)` },      // Bot 2 Top Right
      { top: '80%', left: `calc(35% + ${(cardIndex - 0.5) * 26}px)` },      // Bot 3 Bottom Left
      { top: '42%', left: `calc(50% + ${(cardIndex - 0.5) * 26}px)` },      // Dealer (Top Center felt)
    ];

    const pos = positions[seatIndex];
    return {
      top: pos.top,
      left: pos.left,
      opacity: 1,
      transform: 'translate(-50%, -50%) scale(1)',
      transition: `all 600ms cubic-bezier(0.175, 0.885, 0.32, 1.1) ${cardIndex * 150 + seatIndex * 100}ms`,
    };
  };

  return (
    <div className="relative h-screen w-full bg-slate-900 text-slate-100 overflow-hidden font-sans select-none">
      
      {/* Dynamic Ambient Background Lights */}
      <div className="absolute top-[-10%] left-[-10%] w-[50%] h-[50%] bg-emerald-500/5 rounded-full blur-[120px] pointer-events-none"></div>
      <div className="absolute bottom-[-10%] right-[-10%] w-[50%] h-[50%] bg-pink-500/5 rounded-full blur-[120px] pointer-events-none"></div>

      {/* HEADER HUD BAR */}
      <div className="absolute top-4 left-4 right-4 z-40 flex items-center justify-between pointer-events-none">
        <button
          onClick={() => setExitConfirmOpen(true)}
          className="pointer-events-auto flex items-center gap-1.5 rounded-xl border border-pink-500/30 bg-slate-950/90 px-4 py-2 text-xs font-bold text-pink-400 hover:bg-pink-500 hover:text-slate-950 transition duration-200 shadow-lg backdrop-blur-xs cursor-pointer hover:border-pink-500"
          id="exit-game-btn"
        >
          <X className="h-4 w-4" />
          ออก
        </button>

        {/* ACTIVE TABLE BET DISPLAY */}
        <div className="rounded-full bg-slate-950/80 px-4 py-2 border border-slate-800 text-center shadow-lg pointer-events-auto flex items-center gap-1.5 backdrop-blur-xs">
          <Zap className="h-4 w-4 text-pink-400 animate-pulse" />
          <span className="text-[11px] text-slate-400 font-extrabold uppercase">เดิมพัน:</span>
          <span className="font-mono text-xs font-black text-emerald-400">{currentBet} ชิป</span>
        </div>

        {/* CURRENT USER CHIPS DISPLAY */}
        <div className="rounded-full bg-slate-950/80 px-4 py-2 border border-slate-800 shadow-lg pointer-events-auto flex items-center gap-1.5 backdrop-blur-xs">
          <Coins className="h-4 w-4 text-emerald-400" />
          <span className="font-mono text-xs font-black text-emerald-400">{userChips.toLocaleString()}</span>
        </div>
      </div>

      {/* GAMEBOARD FIELD CONTAINER */}
      <div className="absolute inset-0 flex items-center justify-center p-4">
        
        {/* ISOMETRIC FIELD BOX (WITH PERSPECTIVE) */}
        <div className="relative w-full max-w-4xl h-[460px] flex items-center justify-center overflow-visible" style={{ perspective: '1200px' }}>
          
          {/* 3D TILTED OVAL CASINO TABLE */}
          {/* Table has z-index 20. It will sit above the player bodies (z-10) and cover their waists/legs, but cards & names have z-30 */}
          <div 
            className="absolute w-[500px] h-[230px] rounded-full border-[10px] border-emerald-950 bg-gradient-to-b from-emerald-600 to-emerald-800 shadow-[0_25px_50px_rgba(0,0,0,0.65),inset_0_2px_15px_rgba(255,255,255,0.15)] flex items-center justify-center"
            style={{ 
              transform: 'rotateX(35deg)', 
              top: '48%',
              left: 'calc(50% - 250px)',
              zIndex: 20 
            }}
          >
            {/* Elegant Double-Stitched Neon Teal Interior Felt Lines */}
            <div className="absolute inset-1.5 rounded-full border border-dashed border-emerald-400/30"></div>
            
            {/* Center Logo Graphic */}
            <div className="absolute inset-12 rounded-full border border-emerald-500/10 flex flex-col items-center justify-center text-center">
              <span className="text-[7px] font-black tracking-widest text-emerald-400/20 uppercase">Teen Club Arena</span>
              <span className="text-emerald-400/30 font-black text-lg tracking-tight mt-0.5">POKDENG</span>
            </div>
          </div>

          {/* CENTER CARDS DECK SHOE (Rotated realistically on the table felt) */}
          <div className="absolute top-[68%] left-[50%] -translate-x-1/2 -translate-y-1/2 flex flex-col items-center z-30">
            <div className="relative h-18 w-13 rounded-lg bg-emerald-950 shadow-xl border border-emerald-500/20 flex items-center justify-center transform rotate-[-12deg]">
              {/* Stack effect */}
              <div className="absolute inset-0 bg-pink-700 rounded-lg border border-pink-500/30 translate-x-[-2px] translate-y-[-2px]"></div>
              <div className="absolute inset-0 bg-pink-800 rounded-lg border border-pink-500/40 translate-x-[-1px] translate-y-[-1px]"></div>
              
              {cardBackUrl ? (
                <img src={cardBackUrl} alt="deck" className="h-full w-full rounded-lg" />
              ) : (
                <div className="h-full w-full rounded-lg bg-pink-600"></div>
              )}
            </div>
          </div>

          {/* ---------------- DEALT CARDS OVERLAYS (Smooth Absolute Animation Layer) ---------------- */}
          {/* All cards render on z-30 so they sit perfectly on top of the table layer */}
          
          {/* 1. Dealer Cards */}
          {dealer.hand.map((card, i) => {
            const isFlipped = dealer.showCards || phase === 'SUMMARY';
            const isThirdCardDrawn = i === 2 && phase !== 'DEALING';
            return (
              <div
                key={`dealer-card-${i}`}
                className={`absolute z-35 pointer-events-none ${isThirdCardDrawn ? 'animate-draw-card' : ''}`}
                style={getCardTransitionStyles(4, i)}
              >
                <PokdengCard card={card} faceUp={isFlipped} deckSheetUrl={deckSheetUrl} cardBackUrl={cardBackUrl} />
              </div>
            );
          })}

          {/* 2. User Cards (Bottom) */}
          {user.hand.map((card, i) => {
            const isFlipped = phase !== 'DEALING';
            const isThirdCardDrawn = i === 2 && phase !== 'DEALING';
            return (
              <div
                key={`user-card-${i}`}
                className={`absolute z-35 pointer-events-none ${isThirdCardDrawn ? 'animate-draw-card' : ''}`}
                style={getCardTransitionStyles(0, i)}
              >
                <PokdengCard card={card} faceUp={isFlipped} deckSheetUrl={deckSheetUrl} cardBackUrl={cardBackUrl} />
              </div>
            );
          })}

          {/* Floating Point Badge for User's Hand */}
          {user.hand.length > 0 && phase !== 'DEALING' && (
            <div 
              className="absolute z-40 bg-gradient-to-br from-amber-400 via-yellow-400 to-amber-500 text-slate-950 font-black text-xl px-3.5 py-1.5 rounded-2xl shadow-[0_4px_15px_rgba(234,179,8,0.5)] border-2 border-yellow-300 flex items-center justify-center gap-1.5 animate-bounce-slow"
              style={{ top: '70%', left: '65%', transform: 'translate(-50%, -50%)' }}
            >
              <span className="text-[10px] font-extrabold text-amber-950/80 uppercase tracking-wider">แต้มในมือ:</span>
              <span className="text-2xl font-black">{userPoints}</span>
            </div>
          )}

          {/* 3. Bots Cards (Left, Top, Right) */}
          {bots.map((bot, botIdx) => {
            return bot.hand.map((card, cardIdx) => {
              const isFlipped = bot.showCards || phase === 'SUMMARY';
              const seatIndex = botIdx + 1; // Seats 1, 2, 3
              const isThirdCardDrawn = cardIdx === 2 && phase !== 'DEALING';
              return (
                <div
                  key={`bot-${botIdx}-card-${cardIdx}`}
                  className={`absolute z-35 pointer-events-none ${isThirdCardDrawn ? 'animate-draw-card' : ''}`}
                  style={getCardTransitionStyles(seatIndex, cardIdx)}
                >
                  <PokdengCard card={card} faceUp={isFlipped} deckSheetUrl={deckSheetUrl} cardBackUrl={cardBackUrl} />
                </div>
              );
            });
          })}


          {/* --- Golden Betting Coins Stream Overlays --- */}
          {showBettingCoins && (
            <div className="absolute inset-0 pointer-events-none z-50 overflow-visible">
              {/* User Coins */}
              {[...Array(6)].map((_, i) => (
                <div
                  key={`coin-p0-${i}`}
                  className="absolute w-5 h-5 rounded-full bg-gradient-to-r from-amber-300 via-yellow-400 to-amber-500 border border-amber-200 shadow-[0_2px_5px_rgba(0,0,0,0.5)] flex items-center justify-center font-bold text-[9px] text-amber-950/85 z-50 select-none"
                  style={{
                    animation: 'coinFlyP0 3s cubic-bezier(0.25, 1, 0.5, 1) forwards',
                    animationDelay: `${i * 120}ms`,
                  }}
                >
                  🪙
                </div>
              ))}
              {/* Bot 1 Coins */}
              {[...Array(6)].map((_, i) => (
                <div
                  key={`coin-p1-${i}`}
                  className="absolute w-5 h-5 rounded-full bg-gradient-to-r from-amber-300 via-yellow-400 to-amber-500 border border-amber-200 shadow-[0_2px_5px_rgba(0,0,0,0.5)] flex items-center justify-center font-bold text-[9px] text-amber-950/85 z-50 select-none"
                  style={{
                    animation: 'coinFlyP1 3s cubic-bezier(0.25, 1, 0.5, 1) forwards',
                    animationDelay: `${i * 120}ms`,
                  }}
                >
                  🪙
                </div>
              ))}
              {/* Bot 2 Coins */}
              {[...Array(6)].map((_, i) => (
                <div
                  key={`coin-p2-${i}`}
                  className="absolute w-5 h-5 rounded-full bg-gradient-to-r from-amber-300 via-yellow-400 to-amber-500 border border-amber-200 shadow-[0_2px_5px_rgba(0,0,0,0.5)] flex items-center justify-center font-bold text-[9px] text-amber-950/85 z-50 select-none"
                  style={{
                    animation: 'coinFlyP2 3s cubic-bezier(0.25, 1, 0.5, 1) forwards',
                    animationDelay: `${i * 120}ms`,
                  }}
                >
                  🪙
                </div>
              ))}
              {/* Bot 3 Coins */}
              {[...Array(6)].map((_, i) => (
                <div
                  key={`coin-p3-${i}`}
                  className="absolute w-5 h-5 rounded-full bg-gradient-to-r from-amber-300 via-yellow-400 to-amber-500 border border-amber-200 shadow-[0_2px_5px_rgba(0,0,0,0.5)] flex items-center justify-center font-bold text-[9px] text-amber-950/85 z-50 select-none"
                  style={{
                    animation: 'coinFlyP3 3s cubic-bezier(0.25, 1, 0.5, 1) forwards',
                    animationDelay: `${i * 120}ms`,
                  }}
                >
                  🪙
                </div>
              ))}
            </div>
          )}

          {/* --- Flying Tomato Overlay --- */}
          {tomatoFlying && tomatoTargetSeat !== null && (
            <div 
              className="absolute z-50 text-5xl select-none pointer-events-none drop-shadow-lg"
              style={{
                animation: `tomatoFlightP${tomatoTargetSeat} 1.5s cubic-bezier(0.25, 0.46, 0.45, 0.94) forwards`
              }}
            >
              🍅
            </div>
          )}


          {/* ---------------- SEATS LAYOUTS (No Borders/Frames. Just Avatars and Tags) ---------------- */}
          {/* Avatars sit at z-10. Table is z-20. Name Tags hover above head at z-30. */}

          {/* DEALER SEAT (TOP RIGHT CORNER - LOWEST LAYER behind table) */}
          <div className="absolute top-[20%] left-[85%] -translate-x-1/2 -translate-y-1/2 flex flex-col items-center z-10">
            {/* Custom Interactive Avatar at z-10 */}
            <div 
              onClick={() => handleCharacterClick('dealer')}
              className="relative z-10 cursor-pointer transition hover:scale-105 active:scale-95"
            >
              <AvatarPainter 
                gender={dealer.gender} 
                avatar={dealer.avatar} 
                size={155} 
                noBackground={true} 
                isDealer={true}
                dealerAnimState={dealerAnimState}
                isClicked={clickedSeat === 'dealer'}
              />
            </div>

            {/* Name & Chips Tag at z-30 */}
            <div className="absolute bottom-[150px] z-30 flex flex-col items-center whitespace-nowrap">
              {showLabels && (
                <div className="bg-slate-950/90 border border-slate-800/80 px-2.5 py-1 rounded-2xl flex items-center gap-1 shadow-lg">
                  <span className="rounded bg-pink-500/20 text-pink-400 text-[8px] font-black px-1.5 py-0.5 border border-pink-500/20 uppercase tracking-widest">เจ้ามือ</span>
                  <span className="text-[11px] font-bold text-white">{dealer.name}</span>
                </div>
              )}

              {/* Dealer Points label */}
              {dealer.hand.length > 0 && (dealer.showCards || phase === 'SUMMARY') && (
                <div className="mt-1.5 rounded-lg bg-pink-500 text-white text-[10px] font-extrabold px-2 py-0.5 border border-pink-400/30 animate-bounce-slow shadow-md">
                  {dealer.pokType} {dealer.deng > 1 ? `(${dealer.deng} เด้ง)` : ''}
                </div>
              )}
            </div>
          </div>

          {/* BOT 1 (TOP LEFT - UNDER TABLE LAYER) */}
          <div className="absolute top-[44%] left-[26%] -translate-x-1/2 -translate-y-1/2 flex flex-col items-center z-10">
            
            {/* THROWABLE SPLAT EFFECT OVERLAYS */}
            {activeThrowable && activeThrowable.botIndex === 1 && (
              <div className="absolute inset-0 z-40 flex items-center justify-center rounded-full overflow-hidden">
                {activeThrowable.type === 'BOMB' ? (
                  <div className="animate-ping bg-pink-500 rounded-full h-11 w-11 flex items-center justify-center font-bold text-[9px] text-white border border-pink-400">
                    💥 BOOM!
                  </div>
                ) : (
                  <div className="text-center p-1">
                    <span className="text-2xl animate-bounce block">🍅</span>
                  </div>
                )}
              </div>
            )}

            {/* DEALER TOMATO SPLAT EVENT */}
            {tomatoTargetSeat === 1 && tomatoSplat && (
              <div className="absolute inset-0 z-45 flex items-center justify-center pointer-events-none">
                <span className="text-5xl animate-scale-up select-none transform rotate-[-12deg]">💥🍅💦</span>
              </div>
            )}

            {/* Clickable Avatar */}
            <div 
              onClick={() => handleCharacterClick(1)}
              className={`relative z-10 cursor-pointer transition hover:scale-105 active:scale-95 ${phase === 'SUMMARY' && bots[0].netWin > 0 ? 'animate-jump-three' : ''}`}
            >
              <AvatarPainter gender={bots[0].gender} avatar={bots[0].avatar} size={115} noBackground={true} isClicked={clickedSeat === 1} />
            </div>

            {/* Name/Money Hover Tag */}
            <div className="absolute bottom-[115px] z-30 flex flex-col items-center whitespace-nowrap">
              {showLabels && (
                <div className="bg-slate-950/90 border border-slate-800/80 px-2.5 py-1 rounded-2xl text-center shadow-lg">
                  <p className="text-[11px] font-bold text-white leading-none">{bots[0].name}</p>
                  <p className="font-mono text-[9px] text-emerald-400 mt-1 font-extrabold">{bots[0].chips.toLocaleString()}</p>
                </div>
              )}

              {/* Bot Points label */}
              {bots[0].hand.length > 0 && (bots[0].showCards || phase === 'SUMMARY') && (
                <div className="mt-1.5 rounded-lg bg-slate-950 border border-slate-800 text-[9px] font-bold text-pink-400 px-2.5 py-0.5 shadow-md">
                  {bots[0].pokType} {bots[0].deng > 1 ? `(${bots[0].deng} เด้ง)` : ''}
                </div>
              )}

              {/* QUICK THROWAWAY FLINGS */}
              {(phase === 'SUMMARY' || phase === 'REVEALING') && (
                <div className="mt-2 flex gap-1 justify-center z-40">
                  <button
                    onClick={(e) => { e.stopPropagation(); throwItemAtBot('BOMB', 1); }}
                    disabled={cooldownActive}
                    className="rounded-full bg-slate-950/90 hover:bg-slate-850 p-1 text-[10px] border border-slate-800 transition active:scale-90 cursor-pointer shadow-sm pointer-events-auto"
                    title="ปาระเบิด"
                  >
                    💣
                  </button>
                  <button
                    onClick={(e) => { e.stopPropagation(); throwItemAtBot('TOMATO', 1); }}
                    disabled={cooldownActive}
                    className="rounded-full bg-slate-950/90 hover:bg-slate-850 p-1 text-[10px] border border-slate-800 transition active:scale-90 cursor-pointer shadow-sm pointer-events-auto"
                    title="ปามะเขือเทศ"
                  >
                    🍅
                  </button>
                </div>
              )}
            </div>
          </div>

          {/* BOT 2 (TOP RIGHT - UNDER TABLE LAYER) */}
          <div className="absolute top-[44%] left-[74%] -translate-x-1/2 -translate-y-1/2 flex flex-col items-center z-10">
            
            {/* THROWABLE SPLAT EFFECT OVERLAYS */}
            {activeThrowable && activeThrowable.botIndex === 2 && (
              <div className="absolute inset-0 z-40 flex items-center justify-center rounded-full overflow-hidden">
                {activeThrowable.type === 'BOMB' ? (
                  <div className="animate-ping bg-pink-500 rounded-full h-11 w-11 flex items-center justify-center font-bold text-[9px] text-white border border-pink-400">
                    💥 BOOM!
                  </div>
                ) : (
                  <div className="text-center p-1">
                    <span className="text-2xl animate-bounce block">🍅</span>
                  </div>
                )}
              </div>
            )}

            {/* DEALER TOMATO SPLAT EVENT */}
            {tomatoTargetSeat === 2 && tomatoSplat && (
              <div className="absolute inset-0 z-45 flex items-center justify-center pointer-events-none">
                <span className="text-5xl animate-scale-up select-none transform rotate-[12deg]">💥🍅💦</span>
              </div>
            )}

            {/* Clickable Avatar */}
            <div 
              onClick={() => handleCharacterClick(2)}
              className={`relative z-10 cursor-pointer transition hover:scale-105 active:scale-95 ${phase === 'SUMMARY' && bots[1].netWin > 0 ? 'animate-jump-three' : ''}`}
            >
              <AvatarPainter gender={bots[1].gender} avatar={bots[1].avatar} size={115} noBackground={true} isClicked={clickedSeat === 2} />
            </div>

            {/* Name/Money Hover Tag */}
            <div className="absolute bottom-[115px] z-30 flex flex-col items-center whitespace-nowrap">
              {showLabels && (
                <div className="bg-slate-950/90 border border-slate-800/80 px-2.5 py-1 rounded-2xl text-center shadow-lg">
                  <p className="text-[11px] font-bold text-white leading-none">{bots[1].name}</p>
                  <p className="font-mono text-[9px] text-emerald-400 mt-1 font-extrabold">{bots[1].chips.toLocaleString()}</p>
                </div>
              )}

              {/* Bot Points label */}
              {bots[1].hand.length > 0 && (bots[1].showCards || phase === 'SUMMARY') && (
                <div className="mt-1.5 rounded-lg bg-slate-950 border border-slate-800 text-[9px] font-bold text-pink-400 px-2.5 py-0.5 shadow-md">
                  {bots[1].pokType} {bots[1].deng > 1 ? `(${bots[1].deng} เด้ง)` : ''}
                </div>
              )}

              {/* QUICK THROWAWAY FLINGS */}
              {(phase === 'SUMMARY' || phase === 'REVEALING') && (
                <div className="mt-2 flex gap-1 justify-center z-40">
                  <button
                    onClick={(e) => { e.stopPropagation(); throwItemAtBot('BOMB', 2); }}
                    disabled={cooldownActive}
                    className="rounded-full bg-slate-950/90 hover:bg-slate-850 p-1 text-[10px] border border-slate-800 transition active:scale-90 cursor-pointer shadow-sm pointer-events-auto"
                    title="ปาระเบิด"
                  >
                    💣
                  </button>
                  <button
                    onClick={(e) => { e.stopPropagation(); throwItemAtBot('TOMATO', 2); }}
                    disabled={cooldownActive}
                    className="rounded-full bg-slate-950/90 hover:bg-slate-850 p-1 text-[10px] border border-slate-800 transition active:scale-90 cursor-pointer shadow-sm pointer-events-auto"
                    title="ปามะเขือเทศ"
                  >
                    🍅
                  </button>
                </div>
              )}
            </div>
          </div>

          {/* BOT 3 (BOTTOM LEFT - ABOVE TABLE LAYER) */}
          <div className="absolute top-[92%] left-[26%] -translate-x-1/2 -translate-y-1/2 flex flex-col items-center z-30">
            
            {/* THROWABLE SPLAT EFFECT OVERLAYS */}
            {activeThrowable && activeThrowable.botIndex === 3 && (
              <div className="absolute inset-0 z-40 flex items-center justify-center rounded-full overflow-hidden">
                {activeThrowable.type === 'BOMB' ? (
                  <div className="animate-ping bg-pink-500 rounded-full h-11 w-11 flex items-center justify-center font-bold text-[9px] text-white border border-pink-400">
                    💥 BOOM!
                  </div>
                ) : (
                  <div className="text-center p-1">
                    <span className="text-2xl animate-bounce block">🍅</span>
                  </div>
                )}
              </div>
            )}

            {/* DEALER TOMATO SPLAT EVENT */}
            {tomatoTargetSeat === 3 && tomatoSplat && (
              <div className="absolute inset-0 z-45 flex items-center justify-center pointer-events-none">
                <span className="text-5xl animate-scale-up select-none transform rotate-[-12deg]">💥🍅💦</span>
              </div>
            )}

            {/* Clickable Avatar */}
            <div 
              onClick={() => handleCharacterClick(3)}
              className={`relative z-10 cursor-pointer transition hover:scale-105 active:scale-95 ${phase === 'SUMMARY' && bots[2].netWin > 0 ? 'animate-jump-three' : ''}`}
            >
              <AvatarPainter gender={bots[2].gender} avatar={bots[2].avatar} size={115} noBackground={true} isClicked={clickedSeat === 3} facingAway={!facingForwardSeats.includes(3)} />
            </div>

            {/* Name/Money Hover Tag */}
            <div className="absolute bottom-[115px] z-30 flex flex-col items-center whitespace-nowrap">
              {showLabels && (
                <div className="bg-slate-950/90 border border-slate-800/80 px-2.5 py-1 rounded-2xl text-center shadow-lg">
                  <p className="text-[11px] font-bold text-white leading-none">{bots[2].name}</p>
                  <p className="font-mono text-[9px] text-emerald-400 mt-1 font-extrabold">{bots[2].chips.toLocaleString()}</p>
                </div>
              )}

              {/* Bot Points label */}
              {bots[2].hand.length > 0 && (bots[2].showCards || phase === 'SUMMARY') && (
                <div className="mt-1.5 rounded-lg bg-slate-950 border border-slate-800 text-[9px] font-bold text-pink-400 px-2.5 py-0.5 shadow-md">
                  {bots[2].pokType} {bots[2].deng > 1 ? `(${bots[2].deng} เด้ง)` : ''}
                </div>
              )}

              {/* QUICK THROWAWAY FLINGS */}
              {(phase === 'SUMMARY' || phase === 'REVEALING') && (
                <div className="mt-2 flex gap-1 justify-center z-40">
                  <button
                    onClick={(e) => { e.stopPropagation(); throwItemAtBot('BOMB', 3); }}
                    disabled={cooldownActive}
                    className="rounded-full bg-slate-950/90 hover:bg-slate-850 p-1 text-[10px] border border-slate-800 transition active:scale-90 cursor-pointer shadow-sm pointer-events-auto"
                    title="ปาระเบิด"
                  >
                    💣
                  </button>
                  <button
                    onClick={(e) => { e.stopPropagation(); throwItemAtBot('TOMATO', 3); }}
                    disabled={cooldownActive}
                    className="rounded-full bg-slate-950/90 hover:bg-slate-850 p-1 text-[10px] border border-slate-800 transition active:scale-90 cursor-pointer shadow-sm pointer-events-auto"
                    title="ปามะเขือเทศ"
                  >
                    🍅
                  </button>
                </div>
              )}
            </div>
          </div>

          {/* USER SEAT HUD (BOTTOM RIGHT - ABOVE TABLE LAYER) */}
          <div className="absolute top-[92%] left-[74%] -translate-x-1/2 -translate-y-1/2 flex flex-col items-center z-30">
            {/* DEALER TOMATO SPLAT EVENT */}
            {tomatoTargetSeat === 0 && tomatoSplat && (
              <div className="absolute inset-0 z-45 flex items-center justify-center pointer-events-none">
                <span className="text-6xl animate-scale-up select-none transform rotate-[12deg]">💥🍅💦</span>
              </div>
            )}

            {/* Clickable User Avatar */}
            <div 
              onClick={() => handleCharacterClick(0)}
              className={`relative z-10 cursor-pointer transition hover:scale-105 active:scale-95 ${phase === 'SUMMARY' && user.netWin > 0 ? 'animate-jump-three' : ''}`}
            >
              <AvatarPainter gender={user.gender} avatar={user.avatar} size={125} noBackground={true} isClicked={clickedSeat === 0} facingAway={!facingForwardSeats.includes(0)} />
            </div>

            {/* User Label Hover Tag at z-30 */}
            <div className="absolute bottom-[125px] z-30 flex flex-col items-center whitespace-nowrap">
              {showLabels && (
                <div className="bg-gradient-to-r from-pink-500/90 to-pink-600/90 border border-pink-400 px-3 py-1 rounded-2xl text-center shadow-xl animate-pulse">
                  <p className="text-[11px] font-black text-white flex items-center justify-center gap-1">
                    <Sparkles className="h-3 w-3 animate-spin text-white" />
                    คุณ (วางบิล {user.bet} ชิป)
                  </p>
                </div>
              )}

              {/* Points label */}
              {user.hand.length > 0 && (
                <div className="mt-1.5 rounded-lg bg-emerald-500 text-slate-950 text-[10px] font-black px-2.5 py-0.5 shadow-md flex items-center gap-1 border border-emerald-400">
                  แต้ม: {user.pokType}
                  {user.deng > 1 && (
                    <span className="bg-pink-500 rounded px-1 text-[8px] text-white font-extrabold">
                      {user.deng} เด้ง
                    </span>
                  )}
                </div>
              )}
            </div>
          </div>

        </div>
      </div>

      {/* FOOTER ACTION CONTROLS HUD */}
      <div className="absolute bottom-4 left-4 right-4 z-40 flex flex-wrap items-end justify-between gap-4 pointer-events-none">
        
        {/* GAME LOGGER CONSOLE */}
        <div className="pointer-events-auto w-64 rounded-2xl border border-slate-800 bg-slate-950/80 p-3 shadow-xl backdrop-blur-md flex flex-col">
          <span className="text-[9px] font-black uppercase tracking-wider text-slate-400 border-b border-slate-800 pb-1.5 mb-2 flex items-center gap-1">
            <TrendingUp className="h-3 w-3 text-pink-400" />
            ประวัติการประเมิน (Game Logs)
          </span>
          <div 
            ref={logContainerRef}
            className="h-12 overflow-y-auto space-y-1.5 text-[10px] font-medium text-slate-300 pr-1 scrollbar-thin"
          >
            {gameLog.slice(-5).map((log, i) => (
              <p 
                key={i} 
                className={`leading-relaxed ${
                  log.startsWith('---') 
                    ? 'text-pink-400 font-extrabold text-[11px] mt-1' 
                    : log.includes('ป๊อก') 
                    ? 'text-pink-400 font-black' 
                    : log.includes('ได้') 
                    ? 'text-emerald-400 font-bold'
                    : 'text-slate-300'
                }`}
              >
                {log}
              </p>
            ))}
          </div>
        </div>

        {/* THROWABLE COOLDOWN INDICATOR */}
        {cooldownActive && (
          <div className="pointer-events-auto flex items-center gap-1 rounded-full bg-slate-950/90 px-3.5 py-1.5 border border-slate-800 text-pink-400 shadow-lg text-[10px] font-black animate-pulse">
            ⏳ พักอาวุธ: {cooldownSeconds} วิ
          </div>
        )}

        {/* DECISION BUTTONS MODULE */}
        <div className="pointer-events-auto flex items-center gap-3">
          {user.hand.length > 0 && (
            <button
              onClick={sortUserHand}
              className="rounded-xl border border-slate-800 bg-slate-900/90 hover:bg-slate-800 px-5 py-3 text-xs font-black text-amber-400 hover:text-amber-300 transition active:scale-95 cursor-pointer shadow-lg flex items-center gap-1.5"
              id="player-sort-cards-btn"
            >
              <SlidersHorizontal className="h-3.5 w-3.5" />
              จัดเรียงไพ่
            </button>
          )}

          {phase === 'PLAYING' && activeTurnIndex === 0 && (
            <div className="flex gap-2.5 bg-slate-950/90 p-2 rounded-2xl border border-slate-800 shadow-2xl backdrop-blur-md">
              {/* Stand */}
              <button
                onClick={playerStand}
                className="rounded-xl border border-slate-800 bg-slate-900/60 hover:bg-slate-800 px-5 py-3 text-xs font-black text-slate-300 hover:text-white transition active:scale-95 cursor-pointer"
                id="player-stand-btn"
              >
                หมอบ / ยืนแต้มนี้
              </button>

              {/* Draw 3rd Card */}
              {!user.hasDrawnThirdCard && !user.isPok && (
                <button
                  onClick={playerDrawThirdCard}
                  className="rounded-xl bg-gradient-to-r from-pink-500 to-pink-600 hover:from-pink-600 hover:to-pink-700 px-5 py-3 text-xs font-black text-white transition active:scale-95 shadow-md shadow-pink-500/10 flex items-center gap-1 cursor-pointer"
                  id="player-draw-third-btn"
                >
                  <Play className="h-3.5 w-3.5 fill-white text-white" />
                  จั่วเพิ่ม 1 ใบ
                </button>
              )}
            </div>
          )}

          {/* DEAL NEXT ROUND TRIGGER */}
          {(phase === 'SUMMARY' || phase === 'LOBBY') && (
            <button
              onClick={startNewRound}
              className="rounded-xl bg-gradient-to-r from-emerald-400 to-emerald-500 hover:from-emerald-500 hover:to-emerald-600 px-6 py-3 text-xs font-black text-slate-950 hover:scale-[1.02] active:scale-98 transition shadow-lg shadow-emerald-500/10 flex items-center gap-1 cursor-pointer"
              id="start-new-round-btn"
            >
              <RefreshCw className="h-3.5 w-3.5 animate-spin" />
              เริ่มสับไพ่ตาถัดไป
            </button>
          )}
        </div>
      </div>

      {/* ----------------- END GAME SCOREBOARD POPUP DIALOG ----------------- */}
      {phase === 'SUMMARY' && (
        <div className="fixed inset-0 z-50 flex items-center justify-center bg-slate-950/80 p-4 backdrop-blur-xs">
          <div className="w-full max-w-md rounded-3xl border border-slate-800 bg-slate-900 shadow-2xl overflow-hidden animate-scale-up text-slate-200">
            
            {/* SCOREBOARD HEADER */}
            <div className="bg-slate-950 p-6 text-center border-b border-slate-850">
              <span className="text-[10px] font-black uppercase tracking-widest text-pink-400">สรุปการลุ้นไพ่ป๊อกเด้ง!</span>
              <h3 className="text-lg font-black text-white mt-1">กระดานคะแนนรวมประเมินตา</h3>
              
              {/* COUNTDOWN AUTOMATIC RESTART COUNTER */}
              <div className="mt-3.5 inline-flex items-center gap-1.5 rounded-full bg-slate-900 px-3 py-1 border border-slate-800">
                <Clock className="h-3 w-3 text-pink-400 animate-spin" />
                <span className="text-[10px] font-extrabold text-slate-400">
                  ตาใหม่เริ่มอัตโนมัติใน: <span className="font-mono font-black text-pink-400 text-xs">{summaryCountdown} วินาที</span>
                </span>
              </div>
            </div>

            {/* SEAT SCORES LIST */}
            <div className="p-5 space-y-2.5 bg-slate-900/40">
              {/* User row */}
              <div className="flex items-center justify-between p-3 rounded-2xl border border-pink-500/20 bg-pink-500/5 shadow-inner">
                <div className="flex items-center gap-2.5">
                  <div className="flex h-8 w-8 items-center justify-center rounded-lg bg-pink-500 font-sans text-xs font-black text-white">
                    คุณ
                  </div>
                  <div>
                    <h5 className="text-xs font-black text-white">คุณ (ผู้เล่น)</h5>
                    <p className="text-[10px] text-pink-400 mt-0.5 font-bold">
                      {user.pokType} {user.deng > 1 ? `(${user.deng} เด้ง)` : ''}
                    </p>
                  </div>
                </div>

                <div className="text-right">
                  <span className={`font-mono text-sm font-black ${user.netWin >= 0 ? 'text-emerald-400' : 'text-pink-400'}`}>
                    {user.netWin >= 0 ? `+${user.netWin}` : user.netWin}
                  </span>
                  <p className="text-[9px] text-slate-500 mt-0.5">ชิปสุทธิ: {user.chips.toLocaleString()}</p>
                </div>
              </div>

              {/* Bots list */}
              {bots.map((bot, i) => (
                <div key={i} className="flex items-center justify-between p-3 rounded-2xl border border-slate-800/60 bg-slate-900">
                  <div className="flex items-center gap-2.5">
                    <div className="relative">
                      <AvatarPainter gender={bot.gender} avatar={bot.avatar} size={32} noBackground={true} />
                    </div>
                    <div>
                      <h5 className="text-xs font-bold text-slate-300">{bot.name}</h5>
                      <p className="text-[10px] text-slate-500 mt-0.5 font-medium">
                        {bot.pokType} {bot.deng > 1 ? `(${bot.deng} เด้ง)` : ''}
                      </p>
                    </div>
                  </div>

                  <div className="text-right">
                    <span className={`font-mono text-xs font-black ${bot.netWin >= 0 ? 'text-emerald-400' : 'text-pink-400'}`}>
                      {bot.netWin >= 0 ? `+${bot.netWin}` : bot.netWin}
                    </span>
                    <p className="text-[9px] text-slate-500 mt-0.5">ชิป: {bot.chips.toLocaleString()}</p>
                  </div>
                </div>
              ))}

              {/* Dealer row */}
              <div className="flex items-center justify-between p-3 rounded-2xl border border-slate-800 bg-slate-950/40 border-dashed">
                <div className="flex items-center gap-2.5">
                  <span className="rounded bg-slate-800 border border-slate-750 px-1.5 py-0.5 text-[9px] font-bold text-slate-400">เจ้ามือ</span>
                  <div>
                    <h5 className="text-xs font-bold text-slate-400">{dealer.name}</h5>
                    <p className="text-[10px] text-slate-500 mt-0.5">
                      {dealer.pokType} {dealer.deng > 1 ? `(${dealer.deng} เด้ง)` : ''}
                    </p>
                  </div>
                </div>
              </div>
            </div>

            {/* SCOREBOARD ACTION FOOTER */}
            <div className="bg-slate-950 p-4 border-t border-slate-850 flex gap-2.5">
              <button
                onClick={exitToLobby}
                className="flex-1 rounded-xl bg-slate-900 border border-slate-800 py-2.5 text-xs font-bold text-slate-400 hover:text-white transition active:scale-95 cursor-pointer"
                id="scoreboard-to-lobby-btn"
              >
                กลับไปล็อบบี้
              </button>
              
              <button
                onClick={startNewRound}
                className="flex-1 rounded-xl bg-gradient-to-r from-emerald-400 to-emerald-500 py-2.5 text-xs font-black text-slate-950 hover:brightness-105 active:scale-95 transition cursor-pointer"
                id="scoreboard-next-round-btn"
              >
                จั่วตาใหม่ทันที
              </button>
            </div>
          </div>
        </div>
      )}

      {/* CUTE EXIT CONFIRMATION POPUP */}
      {exitConfirmOpen && (
        <div className="fixed inset-0 z-50 flex items-center justify-center bg-black/80 p-4 backdrop-blur-sm animate-fade-in">
          <div className="relative w-full max-w-xs rounded-3xl border-2 border-pink-500/30 bg-slate-900 p-6 text-center shadow-2xl animate-scale-up">
            
            {/* Cute illustration bubble or icon */}
            <div className="mx-auto mb-4 flex h-14 w-14 items-center justify-center rounded-full bg-pink-500/10 text-pink-400 border border-pink-500/20">
              <X className="h-7 w-7 animate-pulse" />
            </div>

            <h3 className="font-sans text-lg font-black text-white">ต้องการออกจากโต๊ะไพ่?</h3>
            <p className="my-3 text-xs leading-relaxed text-slate-400">
              ตาเล่นของคุณและชิปสะสมได้รับการบันทึกไว้อย่างปลอดภัยแล้ว คุณแน่ใจใช่ไหมที่จะกลับไปล็อบบี้?
            </p>

            <div className="mt-5 flex gap-3">
              <button
                onClick={() => setExitConfirmOpen(false)}
                className="flex-1 rounded-2xl bg-slate-800 hover:bg-slate-700 border border-slate-700 py-2.5 text-xs font-bold text-slate-300 transition active:scale-95 cursor-pointer"
              >
                เล่นต่อป๊อกเก้า
              </button>
              
              <button
                onClick={() => {
                  setExitConfirmOpen(false);
                  exitToLobby();
                }}
                className="flex-1 rounded-2xl bg-gradient-to-r from-pink-500 to-rose-600 hover:from-pink-600 hover:to-rose-700 py-2.5 text-xs font-black text-white transition shadow-lg shadow-pink-500/20 active:scale-95 cursor-pointer"
                id="confirm-exit-btn"
              >
                ออกห้อง
              </button>
            </div>
          </div>
        </div>
      )}
    </div>
  );
};
