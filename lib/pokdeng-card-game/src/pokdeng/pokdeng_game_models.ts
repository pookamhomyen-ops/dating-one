/**
 * Pokdeng Game Models and Types
 * Fully prepared for future offline/online sync and Supabase database binding.
 */

export type CardSuit = 'CLUBS' | 'HEARTS' | 'SPADES' | 'DIAMONDS';

export interface Card {
  suit: CardSuit;
  rank: number; // 1 (A) to 13 (K)
}

export interface AvatarFashion {
  shirt: number; // 0-9
  pants: number; // 0-9
  hat: number; // 0-9
  hair: number; // 0-9
}

export type Gender = 'MALE' | 'FEMALE';

export interface Player {
  id: string;
  name: string;
  gender: Gender;
  avatar: AvatarFashion;
  chips: number;
  isBot: boolean;
  hand: Card[];
  bet: number;
  isPok: boolean; // True if Pok 8 or Pok 9 (needs immediate stand/reveal)
  pokType: string; // e.g., 'ป๊อก 9', 'ป๊อก 8', 'ตอง', 'เรียงดอก', 'เซียน', 'เรียง', 'แต้มปกติ'
  deng: number; // Multiplier (1, 2, 3, 5 เด้ง)
  scorePoints: number; // 0-9 points
  hasDrawnThirdCard: boolean;
  showCards: boolean;
  netWin: number; // Net chip win/loss in the current round
}

export type GamePhase = 
  | 'LOBBY' 
  | 'QUESTS'
  | 'BETTING' // Bot and player choose bets
  | 'DEALING' // Handing out 2 cards each
  | 'PLAYING' // Players and bots make choices (draw 3rd card)
  | 'REVEALING' // Revealing card by card or show hands
  | 'SUMMARY'; // Show scoreboard popup

export interface DailyQuest {
  id: string;
  name: string;
  description: string;
  target: number;
  current: number;
  reward: number;
  completed: boolean;
  claimed: boolean;
}

export interface GameState {
  players: Player[]; // Our seat is always players[0] (Dealer is usually a separate entity or players[3] etc., but here Dealer = system)
  dealer: Player; // System Dealer
  phase: GamePhase;
  currentBet: number; // Active bet selection for next game
  activeTurnIndex: number; // Index of the player whose turn it is to draw a card
  gameLog: string[];
  roundsPlayed: number;
  dailyQuests: DailyQuest[];
  lastAdClaimTime: number; // Timestamp of last simulated ad claim
  dailyLoginClaimed: boolean;
}
