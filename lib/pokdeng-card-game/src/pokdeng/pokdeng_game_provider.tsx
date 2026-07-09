import React, { createContext, useContext, useState, useEffect } from 'react';
import { Player, Card, CardSuit, GamePhase, DailyQuest, GameState, AvatarFashion, Gender } from './pokdeng_game_models';
import { pokdengVoiceSynth } from './pokdeng_voice_synth';

// Context Type definition
interface PokdengContextType {
  players: Player[];
  dealer: Player;
  phase: GamePhase;
  currentBet: number;
  activeTurnIndex: number;
  gameLog: string[];
  roundsPlayed: number;
  dailyQuests: DailyQuest[];
  claimedDailyLogin: boolean;
  lastAdClaimTime: number;
  userChips: number;
  addChips: (amount: number) => void;
  deckSheetUrl: string;
  cardBackUrl: string;
  isSearching: boolean;
  searchCountdown: number;
  selectedItemToBuy: { category: string; index: number; cost: number } | null;
  changeGender: () => void;
  updateAvatarStyle: (category: 'shirt' | 'pants' | 'hat' | 'hair', index: number) => void;
  setBetAmount: (amount: number) => void;
  watchAd: () => Promise<void>;
  claimDailyLogin: () => void;
  claimQuest: (id: string) => void;
  startMatchmaking: () => void;
  cancelMatchmaking: () => void;
  playerStand: () => void;
  playerDrawThirdCard: () => void;
  startNewRound: () => void;
  throwItemAtBot: (itemType: 'BOMB' | 'TOMATO', botIndex: number) => void;
  activeThrowable: { type: 'BOMB' | 'TOMATO'; botIndex: number } | null;
  cooldownActive: boolean;
  cooldownSeconds: number;
  exitToLobby: () => void;
  setPhase: (phase: GamePhase) => void;
  sortUserHand: () => void;
  gender: Gender;
  avatar: AvatarFashion;
  ownedItems: string[];
  matchTransitionActive: boolean;
  setMatchTransitionActive: (val: boolean) => void;
}

const PokdengContext = createContext<PokdengContextType | undefined>(undefined);

// LocalStorage Keys
const CHIPS_KEY = 'pokdeng_user_chips';
const GENDER_KEY = 'pokdeng_user_gender';
const AVATAR_KEY = 'pokdeng_user_avatar';
const QUEST_KEY = 'pokdeng_daily_quests';
const DAILY_LOGIN_KEY = 'pokdeng_daily_login_claimed';
const ROUNDS_KEY = 'pokdeng_rounds_played';

export const PokdengProvider: React.FC<{ children: React.ReactNode }> = ({ children }) => {
  // --- STATE ---
  const [userChips, setUserChips] = useState<number>(() => {
    const saved = localStorage.getItem(CHIPS_KEY);
    return saved ? parseInt(saved) : 5000; // Default starts with 5000 chips
  });

  const [gender, setGender] = useState<Gender>(() => {
    const saved = localStorage.getItem(GENDER_KEY);
    return (saved as Gender) || 'MALE';
  });

  const [avatar, setAvatar] = useState<AvatarFashion>(() => {
    const saved = localStorage.getItem(AVATAR_KEY);
    return saved ? JSON.parse(saved) : { shirt: 0, pants: 0, hat: 0, hair: 0 };
  });

  const [roundsPlayed, setRoundsPlayed] = useState<number>(() => {
    const saved = localStorage.getItem(ROUNDS_KEY);
    return saved ? parseInt(saved) : 0;
  });

  const [claimedDailyLogin, setClaimedDailyLogin] = useState<boolean>(() => {
    const saved = localStorage.getItem(DAILY_LOGIN_KEY);
    // Let's reset every session or check date. For simpler UX, we will let them claim once and can reset on date change
    const todayStr = new Date().toDateString();
    return saved === todayStr;
  });

  const [dailyQuests, setDailyQuests] = useState<DailyQuest[]>(() => {
    const saved = localStorage.getItem(QUEST_KEY);
    if (saved) return JSON.parse(saved);
    return [
      { id: 'play_5_rounds', name: 'เล่นครบ 5 ตา', description: 'เล่นเกมป๊อกเด้งให้ครบ 5 ตา', target: 5, current: 0, reward: 50, completed: false, claimed: false },
    ];
  });

  const [matchTransitionActive, setMatchTransitionActive] = useState<boolean>(false);
  const [ownedItems, setOwnedItems] = useState<string[]>(() => {
    const saved = localStorage.getItem('pokdeng_owned_items');
    return saved ? JSON.parse(saved) : ['hair-0', 'hat-0', 'shirt-0', 'pants-0'];
  });

  const [players, setPlayers] = useState<Player[]>([]);
  const [dealer, setDealer] = useState<Player>({
    id: 'dealer',
    name: 'เจ้ามือบอท',
    gender: 'MALE',
    avatar: { shirt: 8, pants: 2, hat: 9, hair: 5 },
    chips: 100000,
    isBot: true,
    hand: [],
    bet: 0,
    isPok: false,
    pokType: 'แต้มปกติ',
    deng: 1,
    scorePoints: 0,
    hasDrawnThirdCard: false,
    showCards: false,
    netWin: 0,
  });

  const [phase, setPhase] = useState<GamePhase>('LOBBY');
  const [currentBet, setCurrentBet] = useState<number>(10);
  const [activeTurnIndex, setActiveTurnIndex] = useState<number>(-1);
  const [gameLog, setGameLog] = useState<string[]>([]);
  const [lastAdClaimTime, setLastAdClaimTime] = useState<number>(0);

  // Matchmaking
  const [isSearching, setIsSearching] = useState<boolean>(false);
  const [searchCountdown, setSearchCountdown] = useState<number>(5);

  // Dynamic Assets
  const [deckSheetUrl, setDeckSheetUrl] = useState<string>('');
  const [cardBackUrl, setCardBackUrl] = useState<string>('');

  // Interactive Throwable items
  const [activeThrowable, setActiveThrowable] = useState<{ type: 'BOMB' | 'TOMATO'; botIndex: number } | null>(null);
  const [cooldownActive, setCooldownActive] = useState<boolean>(false);
  const [cooldownSeconds, setCooldownSeconds] = useState<number>(0);

  // Selected Item in shop (to confirm buy)
  const [selectedItemToBuy, setSelectedItemToBuy] = useState<{ category: string; index: number; cost: number } | null>(null);

  // --- SAVE STATE WRAPPERS ---
  const saveChips = (val: number) => {
    setUserChips(val);
    localStorage.setItem(CHIPS_KEY, val.toString());
  };

  const saveGender = (val: Gender) => {
    setGender(val);
    localStorage.setItem(GENDER_KEY, val);
  };

  const saveAvatar = (val: AvatarFashion) => {
    setAvatar(val);
    localStorage.setItem(AVATAR_KEY, JSON.stringify(val));
  };

  const saveRoundsPlayed = (val: number) => {
    setRoundsPlayed(val);
    localStorage.setItem(ROUNDS_KEY, val.toString());

    // Update quest progress
    const updatedQuests = dailyQuests.map(q => {
      if (q.id === 'play_5_rounds' && !q.completed) {
        const nextCurrent = Math.min(q.target, val);
        return {
          ...q,
          current: nextCurrent,
          completed: nextCurrent >= q.target,
        };
      }
      return q;
    });
    setDailyQuests(updatedQuests);
    localStorage.setItem(QUEST_KEY, JSON.stringify(updatedQuests));
  };

  // --- PROCEDURAL CARD SPRITESHEET GENERATION (DEFENSIVE FALLBACK) ---
  useEffect(() => {
    const generateAssets = () => {
      // 1. Create DeckSheet_2.png
      const deckCanvas = document.createElement('canvas');
      deckCanvas.width = 936;
      deckCanvas.height = 384;
      const ctx = deckCanvas.getContext('2d');
      if (ctx) {
        const cardW = 72;
        const cardH = 96;
        const suits: CardSuit[] = ['CLUBS', 'HEARTS', 'SPADES', 'DIAMONDS'];
        const suitSymbols = { CLUBS: '♣', HEARTS: '♥', SPADES: '♠', DIAMONDS: '♦' };
        const suitColors = { CLUBS: '#111111', HEARTS: '#E74C3C', SPADES: '#2C3E50', DIAMONDS: '#D35400' };

        for (let row = 0; row < 4; row++) {
          const suit = suits[row];
          const symbol = suitSymbols[suit];
          const color = suitColors[suit];

          for (let col = 0; col < 13; col++) {
            const rank = col + 1;
            let rankText = rank.toString();
            if (rank === 1) rankText = 'A';
            if (rank === 11) rankText = 'J';
            if (rank === 12) rankText = 'Q';
            if (rank === 13) rankText = 'K';

            const x = col * cardW;
            const y = row * cardH;

            // Draw Card Body
            ctx.fillStyle = '#FFFFFF';
            // Smooth card rounding
            ctx.beginPath();
            const r = 6;
            ctx.roundRect(x + 2, y + 2, cardW - 4, cardH - 4, r);
            ctx.fill();

            // Draw Card Border
            ctx.strokeStyle = '#D1D5DB';
            ctx.lineWidth = 1;
            ctx.stroke();

            // Card Inner Shadow/Glow
            ctx.strokeStyle = 'rgba(0,0,0,0.03)';
            ctx.lineWidth = 2;
            ctx.stroke();

            // Suit Text and Icons
            ctx.fillStyle = color;
            ctx.font = 'bold 13px system-ui';
            ctx.textAlign = 'left';
            ctx.textBaseline = 'top';
            ctx.fillText(rankText, x + 7, y + 7);

            // Draw Mini Suit under Rank
            ctx.font = '12px serif';
            ctx.fillText(symbol, x + 7, y + 21);

            // Draw Mirrored Rank/Suit in bottom right
            ctx.save();
            ctx.translate(x + cardW - 7, y + cardH - 7);
            ctx.rotate(Math.PI);
            ctx.font = 'bold 13px system-ui';
            ctx.textAlign = 'left';
            ctx.textBaseline = 'top';
            ctx.fillText(rankText, 0, 0);
            ctx.font = '12px serif';
            ctx.fillText(symbol, 0, 14);
            ctx.restore();

            // Draw Big Center Suit Symbol
            ctx.fillStyle = color;
            ctx.textAlign = 'center';
            ctx.textBaseline = 'middle';

            if (rank > 10) {
              // Royal Face Card Graphics
              ctx.font = '34px serif';
              ctx.fillText(symbol, x + cardW / 2, y + cardH / 2 + 3);
              ctx.strokeStyle = color;
              ctx.lineWidth = 1.5;
              ctx.strokeRect(x + 18, y + 18, cardW - 36, cardH - 36);
              // Draw small crown on royals
              ctx.fillStyle = '#F1C40F';
              ctx.font = '10px serif';
              ctx.fillText('👑', x + cardW / 2, y + 24);
            } else {
              ctx.font = '30px serif';
              ctx.fillText(symbol, x + cardW / 2, y + cardH / 2);
            }
          }
        }
        setDeckSheetUrl(deckCanvas.toDataURL());
      }

      // 2. Create Flipped.png (Card Back)
      const backCanvas = document.createElement('canvas');
      backCanvas.width = 72;
      backCanvas.height = 96;
      const bCtx = backCanvas.getContext('2d');
      if (bCtx) {
        // Red luxury card back
        bCtx.fillStyle = '#FFFFFF';
        bCtx.beginPath();
        bCtx.roundRect(0, 0, 72, 96, 6);
        bCtx.fill();

        // Inner Red box
        bCtx.fillStyle = '#C0392B';
        bCtx.beginPath();
        bCtx.roundRect(4, 4, 64, 88, 4);
        bCtx.fill();

        // Pattern
        bCtx.strokeStyle = '#E74C3C';
        bCtx.lineWidth = 2;
        for (let i = -40; i < 150; i += 8) {
          bCtx.beginPath();
          bCtx.moveTo(i, 4);
          bCtx.lineTo(i + 40, 92);
          bCtx.stroke();
        }

        // Diamond logo in center
        bCtx.fillStyle = '#F1C40F';
        bCtx.beginPath();
        bCtx.moveTo(36, 36);
        bCtx.lineTo(46, 48);
        bCtx.lineTo(36, 60);
        bCtx.lineTo(26, 48);
        bCtx.closePath();
        bCtx.fill();

        // White border inside pattern
        bCtx.strokeStyle = '#FFFFFF';
        bCtx.lineWidth = 1.5;
        bCtx.strokeRect(7, 7, 58, 82);

        setCardBackUrl(backCanvas.toDataURL());
      }
    };

    generateAssets();
  }, []);

  // --- LOGIC: CHIP ADJUSTMENTS ---
  const addChips = (amount: number) => {
    saveChips(userChips + amount);
  };

  const deductChips = (amount: number): boolean => {
    if (userChips >= amount) {
      saveChips(userChips - amount);
      return true;
    }
    return false;
  };

  // --- GENDER & AVATAR EDITING ---
  const changeGender = () => {
    const nextGender = gender === 'MALE' ? 'FEMALE' : 'MALE';
    // Starting change is free, subsequent ones are 100 chips.
    // Let's check if the user has changed gender before. For simplicity, we deduct 100 chips if user is not in pristine state
    const cost = roundsPlayed > 0 ? 100 : 0;
    if (cost > 0) {
      if (userChips < cost) {
        alert('ชิปไม่เพียงพอสำหรับการเปลี่ยนเพศ (ต้องการ 100 ชิป)');
        return;
      }
      deductChips(cost);
      setGameLog(prev => [`เสียค่าธรรมเนียมเปลี่ยนเพศ 100 ชิป`, ...prev]);
    }
    saveGender(nextGender);
    // Reset hairstyle if gender changed
    saveAvatar({ ...avatar, hair: 0 });
  };

  const saveOwnedItems = (newOwned: string[]) => {
    setOwnedItems(newOwned);
    localStorage.setItem('pokdeng_owned_items', JSON.stringify(newOwned));
  };

  const updateAvatarStyle = (category: 'shirt' | 'pants' | 'hat' | 'hair', index: number) => {
    if (avatar[category] === index) return;

    const itemKey = `${category}-${index}`;
    const isOwned = ownedItems.includes(itemKey) || index === 0;

    if (isOwned) {
      saveAvatar({ ...avatar, [category]: index });
      setGameLog(prev => [`สวมใส่ไอเทม ${category} สไตล์ #${index} สำเร็จ`, ...prev]);
      return;
    }

    const cost = index * 150;
    setSelectedItemToBuy({ category, index, cost });
  };

  const confirmPurchase = () => {
    if (!selectedItemToBuy) return;
    const { category, index, cost } = selectedItemToBuy;
    if (userChips >= cost) {
      deductChips(cost);
      const itemKey = `${category}-${index}`;
      const newOwned = [...ownedItems];
      if (!newOwned.includes(itemKey)) {
        newOwned.push(itemKey);
      }
      saveOwnedItems(newOwned);
      saveAvatar({ ...avatar, [category]: index });
      setGameLog(prev => [`ซื้อและติดตั้งไอเทม ${category} สไตล์ #${index} สำเร็จ (-${cost} ชิป)`, ...prev]);
      setSelectedItemToBuy(null);
    } else {
      alert('ชิปของคุณไม่เพียงพอในการซื้อสินค้าแฟชั่นชิ้นนี้!');
      setSelectedItemToBuy(null);
    }
  };

  // --- ECONOMY FEATURES ---
  const watchAd = async () => {
    const now = Date.now();
    // 30 seconds cooldown between ad clicks
    if (now - lastAdClaimTime < 30000) {
      const remaining = Math.ceil((30000 - (now - lastAdClaimTime)) / 1000);
      alert(`โปรดรออีก ${remaining} วินาทีเพื่อดูโฆษณาถัดไป`);
      return;
    }
    setLastAdClaimTime(now);
    // 3 seconds simulated viewing delay handled in screen, but we process payout
    addChips(50);
    setGameLog(prev => [`ได้รับเงินรางวัลจากการรับชมโฆษณา 50 ชิป`, ...prev]);
  };

  const claimDailyLogin = () => {
    if (claimedDailyLogin) return;
    const todayStr = new Date().toDateString();
    setClaimedDailyLogin(true);
    localStorage.setItem(DAILY_LOGIN_KEY, todayStr);
    addChips(50);
    setGameLog(prev => [`รับโบนัสล็อกอินประจำวัน 50 ชิป`, ...prev]);
  };

  const claimQuest = (id: string) => {
    const quest = dailyQuests.find(q => q.id === id);
    if (quest && quest.completed && !quest.claimed) {
      addChips(quest.reward);
      setGameLog(prev => [`รับรางวัลภารกิจ "${quest.name}" สำเร็จ (+${quest.reward} ชิป)`, ...prev]);
      const updated = dailyQuests.map(q => q.id === id ? { ...q, claimed: true } : q);
      setDailyQuests(updated);
      localStorage.setItem(QUEST_KEY, JSON.stringify(updated));
    }
  };

  // --- MATCHMAKING SETUP ---
  const startMatchmaking = () => {
    if (userChips < currentBet) {
      alert('คุณมีชิปน้อยกว่าเงินเดิมพันขั้นต่ำในห้องนี้!');
      return;
    }
    setIsSearching(true);
    // Random matchmaking timer between 3 and 7 seconds
    const randomDuration = Math.floor(Math.random() * 5) + 3; // 3 to 7
    setSearchCountdown(randomDuration);
  };

  const cancelMatchmaking = () => {
    setIsSearching(false);
  };

  // Matchmaking timer loop
  useEffect(() => {
    if (!isSearching) return;
    if (searchCountdown <= 0) {
      setIsSearching(false);
      // Trigger the 1.5s Ace of Spades transition
      setMatchTransitionActive(true);
      initializeGameTable();
      setPhase('DEALING');
      pokdengVoiceSynth.playGameStart();
      setTimeout(() => {
        setMatchTransitionActive(false);
      }, 1500);
      return;
    }

    const timer = setTimeout(() => {
      setSearchCountdown(prev => prev - 1);
    }, 1000);

    return () => clearTimeout(timer);
  }, [isSearching, searchCountdown]);

  // Cooldown timer loop
  useEffect(() => {
    if (!cooldownActive) return;
    if (cooldownSeconds <= 0) {
      setCooldownActive(false);
      return;
    }
    const timer = setTimeout(() => {
      setCooldownSeconds(prev => prev - 1);
    }, 1000);
    return () => clearTimeout(timer);
  }, [cooldownActive, cooldownSeconds]);

  // --- CARD & DECK CALCULATIONS ---
  const buildShuffledDeck = (): Card[] => {
    const suits: CardSuit[] = ['CLUBS', 'HEARTS', 'SPADES', 'DIAMONDS'];
    const tempDeck: Card[] = [];
    for (const suit of suits) {
      for (let rank = 1; rank <= 13; rank++) {
        tempDeck.push({ suit, rank });
      }
    }
    // Fisher-Yates shuffle
    for (let i = tempDeck.length - 1; i > 0; i--) {
      const j = Math.floor(Math.random() * (i + 1));
      const temp = tempDeck[i];
      tempDeck[i] = tempDeck[j];
      tempDeck[j] = temp;
    }
    return tempDeck;
  };

  // POKDENG MATHEMATICS EVALUATOR
  const evaluatePokdengHand = (hand: Card[]): { scorePoints: number; pokType: string; deng: number; totalScore: number } => {
    const cardCount = hand.length;
    if (cardCount === 0) {
      return { scorePoints: 0, pokType: 'แต้มปกติ', deng: 1, totalScore: 0 };
    }

    // Card Point value mapped (10, J, Q, K = 0 points)
    const getPointValue = (c: Card) => {
      const r = c.rank;
      if (r >= 10) return 0;
      return r; // Ace is 1
    };

    // Calculate normal points modulo 10
    const rawSum = hand.reduce((acc, c) => acc + getPointValue(c), 0);
    const scorePoints = rawSum % 10;

    // Check same suit / same rank multipliers (Deng เด้ง)
    let deng = 1;
    if (cardCount === 2) {
      const suitMatch = hand[0].suit === hand[1].suit;
      const rankMatch = hand[0].rank === hand[1].rank;
      if (suitMatch || rankMatch) {
        deng = 2;
      }
    } else if (cardCount === 3) {
      const suitMatch = hand[0].suit === hand[1].suit && hand[1].suit === hand[2].suit;
      if (suitMatch) {
        deng = 3;
      }
    }

    // CHECK SPECIAl HAND TYPES
    // Pok 9 or Pok 8 (Only 2 cards)
    if (cardCount === 2) {
      if (scorePoints === 9) {
        return {
          scorePoints,
          pokType: 'ป๊อก 9',
          deng,
          totalScore: 700 + scorePoints + deng * 0.1, // Highest tier (Tier 7)
        };
      }
      if (scorePoints === 8) {
        return {
          scorePoints,
          pokType: 'ป๊อก 8',
          deng,
          totalScore: 600 + scorePoints + deng * 0.1, // Tier 6
        };
      }
      return {
        scorePoints,
        pokType: 'แต้มปกติ',
        deng,
        totalScore: 100 + scorePoints + deng * 0.1, // Tier 1
      };
    }

    // 3 Cards: Tong (ตอง), Straight Flush (เรียงดอก), Sian (เซียน/สามเหลือง), Straight (เรียง)
    const ranks = hand.map(c => c.rank).sort((a, b) => a - b);
    const suits = hand.map(c => c.suit);

    // 1. ตอง (Tong / Three of a Kind)
    const isTong = ranks[0] === ranks[1] && ranks[1] === ranks[2];
    if (isTong) {
      return {
        scorePoints,
        pokType: 'ตอง',
        deng: 5, // Automatically 5x payout
        totalScore: 500 + ranks[0] * 0.1, // Tier 5
      };
    }

    // Check Sequence for Straight
    const isConsecutive = (ranks[0] + 1 === ranks[1] && ranks[1] + 1 === ranks[2]) ||
      (ranks[0] === 1 && ranks[1] === 12 && ranks[2] === 13); // A-Q-K / Q-K-A consecutive special

    const isSameSuit = suits[0] === suits[1] && suits[1] === suits[2];

    // 2. เรียงดอก (Straight Flush)
    if (isConsecutive && isSameSuit) {
      return {
        scorePoints,
        pokType: 'เรียงดอก',
        deng: 5, // Automatically 5x payout
        totalScore: 400 + ranks[2] * 0.1, // Tier 4
      };
    }

    // 3. เซียน / สามเหลือง (Sian / Three Face Cards J-Q-K only)
    const isSian = hand.every(c => c.rank >= 11);
    if (isSian) {
      return {
        scorePoints,
        pokType: 'เซียน',
        deng: 3, // Automatically 3x payout
        totalScore: 300, // Tier 3
      };
    }

    // 4. เรียง (Straight)
    if (isConsecutive) {
      return {
        scorePoints,
        pokType: 'เรียง',
        deng: 3, // Automatically 3x payout
        totalScore: 200 + ranks[2] * 0.1, // Tier 2
      };
    }

    // 5. Normal Points (3 cards)
    return {
      scorePoints,
      pokType: 'แต้มปกติ',
      deng,
      totalScore: 100 + scorePoints + deng * 0.1, // Tier 1
    };
  };

  // --- INITIALIZE GAME TABLE ---
  const initializeGameTable = () => {
    // Generate our seat + 3 bots
    const userPlayer: Player = {
      id: 'player_user',
      name: 'คุณ (ผู้เล่น)',
      gender,
      avatar,
      chips: userChips,
      isBot: false,
      hand: [],
      bet: currentBet,
      isPok: false,
      pokType: 'แต้มปกติ',
      deng: 1,
      scorePoints: 0,
      hasDrawnThirdCard: false,
      showCards: false,
      netWin: 0,
    };

    const botNames = ['น้องส้ม มะนาวเปรี้ยว', 'เสี่ยเจียง เมืองทอง', 'ป้าแม้น หมอดูไพ่ยิปซี'];
    const botGenders: Gender[] = ['FEMALE', 'MALE', 'FEMALE'];
    const botAvatars: AvatarFashion[] = [
      { shirt: 1, pants: 3, hat: 7, hair: 1 }, // Female energetic
      { shirt: 8, pants: 8, hat: 3, hair: 5 }, // Rich male tuxedo
      { shirt: 7, pants: 9, hat: 8, hair: 3 }, // Elderly wizard
    ];

    const botPlayers: Player[] = botNames.map((name, i) => ({
      id: `bot_${i}`,
      name,
      gender: botGenders[i],
      avatar: botAvatars[i],
      chips: 2000 + Math.floor(Math.random() * 8000), // Bot cash pool
      isBot: true,
      hand: [],
      bet: currentBet, // Bots match our table stakes
      isPok: false,
      pokType: 'แต้มปกติ',
      deng: 1,
      scorePoints: 0,
      hasDrawnThirdCard: false,
      showCards: false,
      netWin: 0,
    }));

    setPlayers([userPlayer, ...botPlayers]);

    // Setup dealer
    setDealer({
      id: 'dealer',
      name: 'เจ้ามือระบบ',
      gender: 'MALE',
      avatar: { shirt: 9, pants: 9, hat: 4, hair: 9 }, // Royal golden styling for dealer
      chips: 1000000,
      isBot: true,
      hand: [],
      bet: 0,
      isPok: false,
      pokType: 'แต้มปกติ',
      deng: 1,
      scorePoints: 0,
      hasDrawnThirdCard: false,
      showCards: false,
      netWin: 0,
    });

    setGameLog(['ยินดีต้อนรับสู่โต๊ะป๊อกเด้ง! เริ่มสับไพ่...']);
  };

  // --- FULL GAME ROUND FLOW ---
  const [deck, setDeck] = useState<Card[]>([]);

  const startNewRound = () => {
    if (userChips < currentBet) {
      alert('ชิปไม่พอ! กรุณากลับหน้าล็อบบี้เพื่อเติมชิปฟรี');
      setPhase('LOBBY');
      return;
    }

    // Refresh user chips & bet in player object
    const updatedPlayers = players.map((p, i) => {
      const activeChips = i === 0 ? userChips : p.chips;
      if (activeChips < currentBet && i > 0) {
        // Reset bot chips if bankrupted
        return {
          ...p,
          chips: 5000,
          bet: currentBet,
          hand: [],
          isPok: false,
          pokType: 'แต้มปกติ',
          deng: 1,
          scorePoints: 0,
          hasDrawnThirdCard: false,
          showCards: false,
          netWin: 0,
        };
      }
      return {
        ...p,
        chips: activeChips,
        bet: currentBet,
        hand: [],
        isPok: false,
        pokType: 'แต้มปกติ',
        deng: 1,
        scorePoints: 0,
        hasDrawnThirdCard: false,
        showCards: false,
        netWin: 0,
      };
    });

    const updatedDealer = {
      ...dealer,
      hand: [],
      isPok: false,
      pokType: 'แต้มปกติ',
      deng: 1,
      scorePoints: 0,
      hasDrawnThirdCard: false,
      showCards: false,
      netWin: 0,
    };

    setPlayers(updatedPlayers);
    setDealer(updatedDealer);
    setGameLog(prev => ['--- เริ่มตาใหม่ ---', 'ทำการสับไพ่และเริ่มแจกไพ่ 2 ใบแรก...', ...prev]);
    setPhase('DEALING');
    pokdengVoiceSynth.playGameStart();

    // Shuffle and Deal
    const newDeck = buildShuffledDeck();

    // Take initial 2 cards for each
    const dealerCards: Card[] = [newDeck.pop()!, newDeck.pop()!];
    const updatedWithCards = updatedPlayers.map(p => {
      const card1 = newDeck.pop()!;
      const card2 = newDeck.pop()!;
      const hand = [card1, card2];
      const evalRes = evaluatePokdengHand(hand);
      const isPok = evalRes.pokType.startsWith('ป๊อก');
      return {
        ...p,
        hand,
        isPok,
        pokType: evalRes.pokType,
        scorePoints: evalRes.scorePoints,
        deng: evalRes.deng,
      };
    });

    const dEval = evaluatePokdengHand(dealerCards);
    const dPok = dEval.pokType.startsWith('ป๊อก');
    const finalDealer = {
      ...updatedDealer,
      hand: dealerCards,
      isPok: dPok,
      pokType: dEval.pokType,
      scorePoints: dEval.scorePoints,
      deng: dEval.deng,
    };

    setDeck(newDeck);

    // Sequence distribution animation delay simulator
    setTimeout(() => {
      setPlayers(updatedWithCards);
      setDealer(finalDealer);

      // If dealer has POK, or Player has POK, go straight to comparison!
      if (dPok) {
        setGameLog(prev => [`เจ้ามือป๊อก! หงายไพ่สรุปทันที (${finalDealer.pokType})`, ...prev]);
        revealAndConclude(updatedWithCards, finalDealer, newDeck);
      } else {
        // Player's turn to act
        setPhase('PLAYING');
        setActiveTurnIndex(0); // Player is index 0
        setGameLog(prev => [`เทิร์นของคุณ: แต้มปัจจุบันของคุณคือ ${updatedWithCards[0].scorePoints} แต้ม (${updatedWithCards[0].pokType})`, ...prev]);
      }
    }, 1200); // 1.2s delay for distribution animations
  };

  // User stand choice
  const playerStand = () => {
    if (phase !== 'PLAYING' || activeTurnIndex !== 0) return;
    setGameLog(prev => [`คุณเลือก "อยู่" ด้วยแต้ม ${players[0].scorePoints} แต้ม`, ...prev]);
    proceedToBots(players, deck);
  };

  // User draw third card choice
  const playerDrawThirdCard = () => {
    if (phase !== 'PLAYING' || activeTurnIndex !== 0) return;
    if (players[0].isPok) {
      alert('ป๊อกแล้ว ไม่สามารถจั่วเพิ่มได้!');
      return;
    }
    const tempDeck = [...deck];
    const drawnCard = tempDeck.pop()!;
    const updatedHand = [...players[0].hand, drawnCard];
    const evalRes = evaluatePokdengHand(updatedHand);

    const updatedPlayers = players.map((p, i) => {
      if (i === 0) {
        return {
          ...p,
          hand: updatedHand,
          hasDrawnThirdCard: true,
          pokType: evalRes.pokType,
          scorePoints: evalRes.scorePoints,
          deng: evalRes.deng,
        };
      }
      return p;
    });

    setDeck(tempDeck);
    setPlayers(updatedPlayers);
    pokdengVoiceSynth.playDrawCard();
    setGameLog(prev => [`คุณจั่วไพ่ใบที่สาม ได้แต้มใหม่คือ ${evalRes.scorePoints} แต้ม (${evalRes.pokType})`, ...prev]);

    proceedToBots(updatedPlayers, tempDeck);
  };

  // Handle Bots action sequences (automatic drawing logic)
  const proceedToBots = (currentPlayers: Player[], currentDeck: Card[]) => {
    let localPlayers = [...currentPlayers];
    let localDeck = [...currentDeck];

    // Bots take action
    for (let i = 1; i < localPlayers.length; i++) {
      const bot = localPlayers[i];
      if (bot.isPok) {
        setGameLog(prev => [`บอท ${bot.name} มีไพ่ป๊อก! ยืนเฉลยผลผล`, ...prev]);
        continue;
      }

      // Traditional Pokdeng strategy: Bots draw 3rd card on 0-5 points, stand on 6-7.
      if (bot.scorePoints <= 5) {
        const drawn = localDeck.pop()!;
        const nextHand = [...bot.hand, drawn];
        const evalRes = evaluatePokdengHand(nextHand);
        localPlayers[i] = {
          ...bot,
          hand: nextHand,
          hasDrawnThirdCard: true,
          pokType: evalRes.pokType,
          scorePoints: evalRes.scorePoints,
          deng: evalRes.deng,
        };
        pokdengVoiceSynth.playDrawCard();
        setGameLog(prev => [`บอท ${bot.name} เลือกจั่วไพ่ใบที่สาม`, ...prev]);
      } else {
        setGameLog(prev => [`บอท ${bot.name} เลือก "อยู่" (${bot.scorePoints} แต้ม)`, ...prev]);
      }
    }

    setDeck(localDeck);
    setPlayers(localPlayers);

    // Dealer turn
    let localDealer = { ...dealer };
    // Dealer rule: Stands on 6 or higher. Draws 3rd card on 5 or lower.
    if (!localDealer.isPok) {
      if (localDealer.scorePoints <= 5) {
        const drawn = localDeck.pop()!;
        const nextHand = [...localDealer.hand, drawn];
        const evalRes = evaluatePokdengHand(nextHand);
        localDealer = {
          ...localDealer,
          hand: nextHand,
          hasDrawnThirdCard: true,
          pokType: evalRes.pokType,
          scorePoints: evalRes.scorePoints,
          deng: evalRes.deng,
        };
        pokdengVoiceSynth.playDrawCard();
        setGameLog(prev => [`เจ้ามือบอท จั่วไพ่ใบที่สามเพิ่มเติม`, ...prev]);
      } else {
        setGameLog(prev => [`เจ้ามือบอท "อยู่" (${localDealer.scorePoints} แต้ม)`, ...prev]);
      }
    }

    setDealer(localDealer);
    setDeck(localDeck);

    // Conclude and resolve earnings
    revealAndConclude(localPlayers, localDealer, localDeck);
  };

  const revealAndConclude = (finalPlayers: Player[], finalDealer: Player, finalDeck: Card[]) => {
    setPhase('REVEALING');
    pokdengVoiceSynth.playRevealCard();

    // Flip animations & timing: Reveal cards to the board
    setTimeout(() => {
      const evaluatedPlayers = finalPlayers.map((p, index) => {
        // Compare with dealer
        // Winner rules:
        // Pok 9 > Pok 8 > Tong > Straight Flush > Sian > Straight > Normal Points
        // Draw chip transaction
        let winStatus = 0; // 1 = Win, -1 = Loss, 0 = Draw
        const pScore = evaluatePokdengHand(p.hand);
        const dScore = evaluatePokdengHand(finalDealer.hand);

        if (pScore.totalScore > dScore.totalScore) {
          winStatus = 1;
        } else if (pScore.totalScore < dScore.totalScore) {
          winStatus = -1;
        } else {
          winStatus = 0; // Same tier and score value
        }

        let multiplier = winStatus === 1 ? pScore.deng : dScore.deng;
        let netWin = winStatus * p.bet * multiplier;

        // Implement Table Tax: 5% table tax rake on net winnings to avoid currency inflation!
        if (netWin > 0) {
          const rake = Math.round(netWin * 0.05);
          netWin = netWin - rake;
        }

        const nextChips = index === 0 
          ? userChips + netWin 
          : p.chips + netWin;

        if (index === 0) {
          saveChips(nextChips);
        }

        return {
          ...p,
          chips: nextChips,
          netWin,
          showCards: true,
        };
      });

      const updatedDealer = {
        ...finalDealer,
        showCards: true,
      };

      setPlayers(evaluatedPlayers);
      setDealer(updatedDealer);
      setPhase('SUMMARY');
      pokdengVoiceSynth.playGameOver();

      // Update round history
      const nextRounds = roundsPlayed + 1;
      saveRoundsPlayed(nextRounds);

      setGameLog(prev => [
        'สรุปผลคะแนนประจำรอบ!',
        `ผลลัพธ์ของคุณ: ${evaluatedPlayers[0].netWin >= 0 ? `ได้ (+${evaluatedPlayers[0].netWin})` : `เสีย (${evaluatedPlayers[0].netWin})`}`,
        ...prev,
      ]);
    }, 1500); // Wait 1.5s for flipping
  };

  // Interactive items thrown at bot
  const throwItemAtBot = (itemType: 'BOMB' | 'TOMATO', botIndex: number) => {
    if (cooldownActive) return;

    // Direct transaction of items: Bombs/Tomatoes costs 10 chips to throw (funny visual sink)
    if (userChips < 10) {
      alert('ชิปไม่เพียงพอ! การขว้างปาไอเทมก่อกวนใช้ชิป 10 เด้ง');
      return;
    }

    deductChips(10);
    setActiveThrowable({ type: itemType, botIndex });
    pokdengVoiceSynth.playThrowTomato();
    setCooldownActive(true);
    setCooldownSeconds(3); // 3s cooldown rule

    // Sound / log feedback
    const botName = players[botIndex]?.name || 'บอท';
    setGameLog(prev => [`คุณปา ${itemType === 'BOMB' ? '💣 ระเบิดตู้ม' : '🍅 มะเขือเทศเละ'} ใส่ ${botName}! (-10 ชิป)`, ...prev]);

    // Disappear throwable after 2 seconds
    setTimeout(() => {
      setActiveThrowable(null);
    }, 2000);
  };

  const exitToLobby = () => {
    setPhase('LOBBY');
  };

  const sortUserHand = () => {
    setPlayers(prev => {
      if (prev.length === 0 || !prev[0]) return prev;
      const newPlayers = [...prev];
      newPlayers[0] = {
        ...newPlayers[0],
        hand: [...newPlayers[0].hand].sort((a, b) => a.rank - b.rank)
      };
      return newPlayers;
    });
    setGameLog(prev => ['จัดเรียงไพ่ในมือเสร็จสิ้น (เรียงจากน้อยไปมาก)', ...prev]);
  };

  const setBetAmount = (amount: number) => {
    if (amount <= 0) return;
    setCurrentBet(amount);
  };

  // --- RENDERING PROVIDER ---
  return (
    <PokdengContext.Provider
      value={{
        players,
        dealer,
        phase,
        currentBet,
        activeTurnIndex,
        gameLog,
        roundsPlayed,
        dailyQuests,
        claimedDailyLogin,
        lastAdClaimTime,
        userChips,
        addChips,
        deckSheetUrl,
        cardBackUrl,
        isSearching,
        searchCountdown,
        selectedItemToBuy,
        changeGender,
        updateAvatarStyle,
        setBetAmount,
        watchAd,
        claimDailyLogin,
        claimQuest,
        startMatchmaking,
        cancelMatchmaking,
        playerStand,
        playerDrawThirdCard,
        startNewRound,
        throwItemAtBot,
        activeThrowable,
        cooldownActive,
        cooldownSeconds,
        exitToLobby,
        setPhase,
        sortUserHand,
        gender,
        avatar,
        ownedItems,
        matchTransitionActive,
        setMatchTransitionActive,
      }}
    >
      {children}

      {/* Confirmation Modal for Fashion Purchases */}
      {selectedItemToBuy && (
        <div className="fixed inset-0 z-50 flex items-center justify-center bg-black/75 p-4 backdrop-blur-xs">
          <div className="w-full max-w-sm rounded-2xl border border-amber-500/40 bg-slate-900 p-6 text-center shadow-2xl">
            <h3 className="font-sans text-xl font-bold text-amber-400">ยืนยันการซื้อสินค้า</h3>
            <p className="my-4 text-slate-300">
              คุณต้องการซื้อและติดตั้งเสื้อผ้าหมวด{' '}
              <span className="font-bold text-amber-300">
                {selectedItemToBuy.category === 'shirt' && 'เสื้อ'}
                {selectedItemToBuy.category === 'pants' && 'กางเกง'}
                {selectedItemToBuy.category === 'hat' && 'หมวก'}
                {selectedItemToBuy.category === 'hair' && 'ทรงผม'}
              </span>{' '}
              สไตล์ #{selectedItemToBuy.index} มูลค่า{' '}
              <span className="font-bold text-amber-400">{selectedItemToBuy.cost}</span> ชิป ใช่หรือไม่?
            </p>
            <div className="flex gap-3">
              <button
                onClick={() => setSelectedItemToBuy(null)}
                className="flex-1 rounded-xl bg-slate-800 py-2.5 font-medium text-slate-300 hover:bg-slate-700 transition"
              >
                ยกเลิก
              </button>
              <button
                onClick={confirmPurchase}
                className="flex-1 rounded-xl bg-gradient-to-r from-amber-500 to-amber-600 py-2.5 font-semibold text-slate-950 hover:brightness-110 shadow-lg shadow-amber-600/20 transition"
              >
                ยืนยันซื้อ
              </button>
            </div>
          </div>
        </div>
      )}
    </PokdengContext.Provider>
  );
};

export const usePokdeng = () => {
  const context = useContext(PokdengContext);
  if (!context) {
    throw new Error('usePokdeng must be used within a PokdengProvider');
  }
  return context;
};
