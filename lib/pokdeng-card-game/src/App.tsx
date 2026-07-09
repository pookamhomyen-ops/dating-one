/**
 * @license
 * SPDX-License-Identifier: Apache-2.0
 */

import React from 'react';
import { PokdengProvider, usePokdeng } from './pokdeng/pokdeng_game_provider';
import { PokdengLobbyScreen } from './pokdeng/pokdeng_lobby_screen';
import { PokdengGameScreen } from './pokdeng/pokdeng_game_screen';
import { PokdengQuestScreen } from './pokdeng/pokdeng_quest_screen';

function PokdengAppContent() {
  const { phase, matchTransitionActive } = usePokdeng();

  return (
    <div className="relative min-h-screen bg-slate-950 overflow-hidden">
      {phase === 'LOBBY' ? (
        <PokdengLobbyScreen />
      ) : phase === 'QUESTS' ? (
        <PokdengQuestScreen />
      ) : (
        <PokdengGameScreen />
      )}

      {/* Full-screen Ace of Spades Transition Overlay */}
      {matchTransitionActive && (
        <div className="fixed inset-0 z-[9999] pointer-events-none flex items-center justify-center overflow-hidden animate-bg-fade-transition bg-slate-950/40">
          {/* Ambient Glow behind card */}
          <div className="absolute top-1/2 left-1/2 w-96 h-96 -translate-x-1/2 -translate-y-1/2 rounded-full bg-radial from-amber-500/25 to-transparent blur-2xl animate-glow-pulse" />

          {/* Huge Ace of Spades Card */}
          <div className="relative w-64 h-88 rounded-3xl bg-white border-4 border-amber-400 shadow-[0_25px_60px_rgba(0,0,0,0.85)] p-5 flex flex-col justify-between select-none animate-ace-card-transition">
            {/* Top-Left Corner Suit */}
            <div className="flex flex-col items-center self-start text-slate-900 leading-none">
              <span className="text-2xl font-serif font-black">A</span>
              <span className="text-lg">♠</span>
            </div>

            {/* Central Giant Ace Symbol */}
            <div className="absolute top-1/2 left-1/2 -translate-x-1/2 -translate-y-1/2 flex flex-col items-center justify-center">
              {/* Outer Golden Ring */}
              <div className="absolute w-36 h-36 rounded-full border border-amber-300/30 animate-spin-slow pointer-events-none" style={{ animationDuration: '8s' }} />
              {/* Inner Decorative Spade Emblem */}
              <span className="text-[100px] text-slate-950 leading-none drop-shadow-md relative z-10 select-none">♠</span>
              <span className="text-[9px] font-black text-amber-600 tracking-widest uppercase mt-2">ACE OF SPADES</span>
            </div>

            {/* Bottom-Right Corner Suit (Flipped) */}
            <div className="flex flex-col items-center self-end text-slate-900 leading-none rotate-180">
              <span className="text-2xl font-serif font-black">A</span>
              <span className="text-lg">♠</span>
            </div>
          </div>
        </div>
      )}
    </div>
  );
}

export default function App() {
  return (
    <PokdengProvider>
      <PokdengAppContent />
    </PokdengProvider>
  );
}

