import React from 'react';
import { AvatarFashion, Gender } from './pokdeng_game_models';

interface AvatarPainterProps {
  gender: Gender;
  avatar: AvatarFashion;
  size?: number;
  animate?: boolean;
  noBackground?: boolean;
  isDealer?: boolean;
  dealerAnimState?: 'IDLE' | 'DEALING' | 'DRINKING' | 'DONE';
  isClicked?: boolean;
  facingAway?: boolean;
}

export const AvatarPainter: React.FC<AvatarPainterProps> = ({
  gender,
  avatar,
  size = 200,
  animate = false,
  noBackground = false,
  isDealer = false,
  dealerAnimState = 'IDLE',
  isClicked = false,
  facingAway = false,
}) => {
  if (isDealer) {
    const skinColor = '#FCE2DB';
    const shadowSkinColor = '#E3B291';
    
    // Class names for dealer arm state animations
    let leftArmClass = 'idle-arm-left';
    let rightArmClass = 'idle-arm-right';
    if (isClicked) {
      rightArmClass = 'animate-dealer-raise-right';
    } else if (dealerAnimState === 'DEALING') {
      leftArmClass = 'animate-deal-left';
      rightArmClass = 'animate-deal-right';
    } else if (dealerAnimState === 'DRINKING') {
      leftArmClass = 'idle-arm-left';
      rightArmClass = 'animate-drink-beer';
    } else if (dealerAnimState === 'DONE') {
      leftArmClass = 'raise-left';
      rightArmClass = 'raise-right';
    }

    const animationClass = animate ? 'animate-bounce-slow' : '';

    return (
      <div
        style={{ width: size, height: size }}
        className={noBackground ? `relative inline-block ${animationClass}` : `relative inline-block overflow-hidden rounded-full border border-slate-700/50 bg-radial from-slate-800 to-slate-950 shadow-inner ${animationClass}`}
      >
        <svg
          viewBox="0 0 200 250"
          width="100%"
          height="100%"
          xmlns="http://www.w3.org/2000/svg"
          className="drop-shadow-lg"
        >
          {/* Internal self-contained stylesheet for custom dealer arm movements */}
          <style dangerouslySetInnerHTML={{ __html: `
            @keyframes dealLeft {
              0% { transform: rotate(0deg); }
              50% { transform: rotate(-35deg); }
              100% { transform: rotate(0deg); }
            }
            @keyframes dealRight {
              0% { transform: rotate(0deg); }
              50% { transform: rotate(35deg); }
              100% { transform: rotate(0deg); }
            }
            .animate-deal-left {
              animation: dealLeft 0.5s ease-in-out infinite;
              transform-origin: 65px 125px;
            }
            .animate-deal-right {
              animation: dealRight 0.5s ease-in-out infinite;
              transform-origin: 135px 125px;
            }
            .raise-left {
              transform: rotate(-135deg);
              transform-origin: 65px 125px;
              transition: transform 0.6s cubic-bezier(0.175, 0.885, 0.32, 1.275);
            }
            .animate-dealer-raise-right {
              transform: rotate(-165deg);
              transform-origin: 135px 125px;
              transition: transform 0.4s cubic-bezier(0.175, 0.885, 0.32, 1.275);
            }
            .raise-right {
              transform: rotate(135deg);
              transform-origin: 135px 125px;
              transition: transform 0.6s cubic-bezier(0.175, 0.885, 0.32, 1.275);
            }
            .idle-arm-left {
              transform: rotate(0deg);
              transform-origin: 65px 125px;
              transition: transform 0.6s ease;
            }
            .idle-arm-right {
              transform: rotate(0deg);
              transform-origin: 135px 125px;
              transition: transform 0.6s ease;
            }
            @keyframes drinkBeerRight {
              0%, 100% { transform: rotate(0deg); }
              30%, 70% { transform: rotate(115deg) translate(-22px, -30px); }
            }
            .animate-drink-beer {
              animation: drinkBeerRight 2s ease-in-out infinite;
              transform-origin: 135px 125px;
            }
          `}} />

          {/* Back Hair: Flowy twin tails */}
          <g fill="#1A1A24">
            <path d="M 60 50 C 30 45, 10 90, 20 135 C 32 120, 48 80, 60 60 Z" />
            <path d="M 140 50 C 170 45, 190 90, 180 135 C 168 120, 152 80, 140 60 Z" />
            <circle cx="58" cy="52" r="5" fill="#F1C40F" />
            <circle cx="142" cy="52" r="5" fill="#F1C40F" />
          </g>
          <g fill="#E74C3C">
            <circle cx="53" cy="46" r="4" />
            <circle cx="147" cy="46" r="4" />
          </g>

          {/* Neck */}
          <rect x="90" y="100" width="20" height="22" fill={skinColor} />
          <path d="M90 100 C95 105, 105 105, 110 100 L110 108 L90 108 Z" fill={shadowSkinColor} />

          {/* Head */}
          <circle cx="100" cy="74" r="32" fill={skinColor} />
          <circle cx="66" cy="74" r="7" fill={skinColor} />
          <circle cx="134" cy="74" r="7" fill={skinColor} />

          {/* Eyes (Cute big glossy eyes) */}
          <g fill="#1A1A24">
            <ellipse cx="88" cy="74" rx="5.5" ry="7" />
            <ellipse cx="112" cy="74" rx="5.5" ry="7" />
            <circle cx="89.5" cy="71.5" r="2.2" fill="#FFFFFF" />
            <circle cx="113.5" cy="71.5" r="2.2" fill="#FFFFFF" />
            <circle cx="86.5" cy="76.5" r="1" fill="#FFFFFF" />
            <circle cx="110.5" cy="76.5" r="1" fill="#FFFFFF" />
            {/* Long premium eyelashes */}
            <path d="M 80 69 Q 88 65 95 71" stroke="#1A1A24" strokeWidth="2.5" fill="none" strokeLinecap="round" />
            <path d="M 120 69 Q 112 65 105 71" stroke="#1A1A24" strokeWidth="2.5" fill="none" strokeLinecap="round" />
          </g>

          {/* Nose */}
          <path d="M100 73 L98 79 L102 79 Z" fill={shadowSkinColor} />

          {/* Sweet blush & cute smile */}
          <g fill="#FF8A80" opacity="0.6">
            <ellipse cx="76" cy="79" rx="6.5" ry="4.5" />
            <ellipse cx="124" cy="79" rx="6.5" ry="4.5" />
          </g>
          <path d="M 93 84 C 96 90, 104 90, 107 84" stroke="#E74C3C" strokeWidth="3" fill="none" strokeLinecap="round" />

          {/* Front Hair: Cute bangs */}
          <g fill="#1A1A24">
            <path d="M 66 50 C 66 22, 134 22, 134 50 C 115 42, 85 42, 66 50 Z" />
            <path d="M 66 48 L 74 65 L 82 50 L 92 64 L 100 50 L 108 64 L 118 50 L 126 65 L 134 48 Z" />
          </g>

          {/* Wooden Wine Barrel (ถังไม้เก็บเหล้าองุ่น) - sits in background under everything else */}
          <g id="wine-barrel">
            {/* Barrel Body */}
            <path d="M 55 185 Q 38 215 55 250 L 145 250 Q 162 215 145 185 Z" fill="#6D4C41" stroke="#3E2723" strokeWidth="2.5" />
            {/* Wooden Staves (lines on the barrel) */}
            <path d="M 75 185 Q 65 215 75 250" fill="none" stroke="#4E342E" strokeWidth="1.5" />
            <path d="M 100 185 Q 100 215 100 250" fill="none" stroke="#4E342E" strokeWidth="1.5" />
            <path d="M 125 185 Q 135 215 125 250" fill="none" stroke="#4E342E" strokeWidth="1.5" />
            {/* Steel Bands */}
            <path d="M 46 195 Q 100 202 154 195" fill="none" stroke="#78909C" strokeWidth="4.5" />
            <path d="M 44 230 Q 100 238 156 230" fill="none" stroke="#78909C" strokeWidth="4.5" />
            {/* Rivets / Bolts on bands */}
            <circle cx="65" cy="197" r="1.5" fill="#CFD8DC" />
            <circle cx="100" cy="198" r="1.5" fill="#CFD8DC" />
            <circle cx="135" cy="197" r="1.5" fill="#CFD8DC" />
            <circle cx="63" cy="232" r="1.5" fill="#CFD8DC" />
            <circle cx="100" cy="233" r="1.5" fill="#CFD8DC" />
            <circle cx="137" cy="232" r="1.5" fill="#CFD8DC" />
          </g>

          {/* Sitting Legs (ขาของคนแจกไพ่ในท่าทางนั่ง) */}
          <g id="sitting-legs">
            {/* Thighs */}
            <path d="M 78 185 Q 52 192 48 215" stroke={skinColor} strokeWidth="15" strokeLinecap="round" fill="none" />
            <path d="M 122 185 Q 148 192 152 215" stroke={skinColor} strokeWidth="15" strokeLinecap="round" fill="none" />
            {/* Shins dangling down */}
            <path d="M 48 215 Q 42 235 50 248" stroke={skinColor} strokeWidth="13" strokeLinecap="round" fill="none" />
            <path d="M 152 215 Q 158 235 150 248" stroke={skinColor} strokeWidth="13" strokeLinecap="round" fill="none" />
            {/* Cute red shoes */}
            <ellipse cx="50" cy="248" rx="8.5" ry="5.5" fill="#E74C3C" />
            <ellipse cx="150" cy="248" rx="8.5" ry="5.5" fill="#E74C3C" />
          </g>

          {/* Body/Torso Base */}
          <path d="M 70 120 L 130 120 L 125 185 L 75 185 Z" fill={skinColor} />

          {/* Big Breasts with gorgeous Cleavage Shadow (หน้าอกใหญ่) */}
          <circle cx="85" cy="140" r="20" fill={skinColor} />
          <circle cx="115" cy="140" r="20" fill={skinColor} />
          <path d="M 100 124 Q 100 144 95 152" stroke="#E3B291" strokeWidth="2.5" fill="none" strokeLinecap="round" />
          <path d="M 100 124 Q 100 144 105 152" stroke="#E3B291" strokeWidth="2.5" fill="none" strokeLinecap="round" />

          {/* Sexy Red Swimsuit Bikini Top */}
          {/* Bikini cup left */}
          <path d="M 68 140 C 68 118, 97 118, 97 140 C 97 162, 68 162, 68 140 Z" fill="#E74C3C" />
          <circle cx="82.5" cy="140" r="4" fill="#FFFFFF" opacity="0.4" />
          {/* Bikini cup right */}
          <path d="M 103 140 C 103 118, 132 118, 132 140 C 132 162, 103 162, 103 140 Z" fill="#E74C3C" />
          <circle cx="117.5" cy="140" r="4" fill="#FFFFFF" opacity="0.4" />
          {/* Neck halter straps */}
          <path d="M 82 122 L 95 102" stroke="#E74C3C" strokeWidth="2.5" fill="none" />
          <path d="M 118 122 L 105 102" stroke="#E74C3C" strokeWidth="2.5" fill="none" />
          {/* Underbust band */}
          <rect x="68" y="156" width="64" height="7" fill="#C0392B" rx="3.5" />

          {/* Animated Left Arm (shoulder at 65,125) */}
          <g className={leftArmClass}>
            <path d="M 65 125 Q 45 150 50 175" stroke={skinColor} strokeWidth="15" strokeLinecap="round" fill="none" />
            <circle cx="50" cy="175" r="8.5" fill={skinColor} />
          </g>

          {/* Animated Right Arm (shoulder at 135,125) */}
          <g className={rightArmClass}>
            <path d="M 135 125 Q 155 150 150 175" stroke={skinColor} strokeWidth="15" strokeLinecap="round" fill="none" />
            <circle cx="150" cy="175" r="8.5" fill={skinColor} />

            {/* Beer Mug (แก้วเบียร์) - Attached to her hand, rotates with the arm */}
            <g transform="translate(136, 160) scale(0.65)" className="beer-mug">
              {/* Glass Mug body */}
              <rect x="0" y="0" width="22" height="28" rx="3" fill="#FFE082" stroke="#FFB300" strokeWidth="1.5" />
              {/* Glass handle */}
              <path d="M 22 6 L 29 10 L 29 18 L 22 22" fill="none" stroke="#FFB300" strokeWidth="3" strokeLinecap="round" />
              {/* Beer Liquid */}
              <rect x="2" y="8" width="18" height="18" fill="#FFC107" />
              {/* Foam on top */}
              <ellipse cx="11" cy="2" rx="12" ry="5" fill="#FFFFFF" />
              <circle cx="3" cy="1" r="4" fill="#FFFFFF" />
              <circle cx="11" cy="0" r="4" fill="#FFFFFF" />
              <circle cx="19" cy="1" r="4" fill="#FFFFFF" />
            </g>
          </g>

          {/* Red Bikini Bottom band */}
          <path d="M 75 180 L 125 180 L 122 195 L 78 195 Z" fill="#E74C3C" />
        </svg>
      </div>
    );
  }

  const { shirt, pants, hat, hair } = avatar;

  // Colors
  const skinColor = '#FAD2B4';
  const shadowSkinColor = '#E3B291';
  const hairColors = [
    '#332211', // Dark Brown
    '#E6A15C', // Blonde
    '#222222', // Black
    '#B83227', // Crimson
    '#3498DB', // Cyber Blue
    '#2ECC71', // Green
    '#9B59B6', // Violet
    '#F1C40F', // Neon Gold
    '#1ABC9C', // Turquoise
    '#E74C3C', // Royal Red
  ];

  const currentHairCol = hairColors[hair % hairColors.length];

  // Draw Hair
  const renderHair = () => {
    if (gender === 'MALE') {
      switch (hair) {
        case 1: // Spiky
          return (
            <g fill={currentHairCol}>
              <path d="M70 45 L80 15 L90 35 L100 10 L110 35 L120 15 L130 45 Z" />
              <path d="M60 55 C60 40, 140 40, 140 55 C140 60, 60 60, 60 55 Z" />
            </g>
          );
        case 2: // Messy Curly
          return (
            <g fill={currentHairCol}>
              <circle cx="80" cy="40" r="16" />
              <circle cx="100" cy="35" r="18" />
              <circle cx="120" cy="40" r="16" />
              <circle cx="90" cy="45" r="14" />
              <circle cx="110" cy="45" r="14" />
            </g>
          );
        case 3: // Undercut (Side Swept)
          return (
            <g>
              <rect x="68" y="50" width="64" height="20" fill="#4a3b32" rx="5" />
              <path d="M70 45 C70 25, 120 20, 132 35 C135 45, 110 35, 100 35 C80 35, 70 40, 70 45 Z" fill={currentHairCol} />
            </g>
          );
        case 4: // Afro
          return (
            <circle cx="100" cy="45" r="34" fill={currentHairCol} />
          );
        case 5: // Side Part (Gentleman)
          return (
            <path d="M68 45 C68 25, 132 25, 132 45 C120 35, 100 35, 100 45 C80 40, 70 40, 68 45 Z" fill={currentHairCol} />
          );
        case 6: // Dreadlocks
          return (
            <g fill={currentHairCol}>
              <rect x="70" y="30" width="10" height="50" rx="4" />
              <rect x="85" y="25" width="10" height="55" rx="4" />
              <rect x="105" y="25" width="10" height="55" rx="4" />
              <rect x="120" y="30" width="10" height="50" rx="4" />
              <circle cx="100" cy="35" r="15" />
            </g>
          );
        case 7: // Mohawk
          return (
            <path d="M92 10 L108 10 L106 65 L94 65 Z" fill={currentHairCol} />
          );
        case 8: // Neon K-Pop Style
          return (
            <g fill={currentHairCol}>
              <path d="M66 45 C66 20, 134 20, 134 45 C130 50, 115 48, 108 55 C100 48, 85 50, 66 45 Z" />
              <path d="M65 44 L60 62 L70 55 Z" />
              <path d="M135 44 L140 62 L130 55 Z" />
            </g>
          );
        case 9: // Styled Pompadour
          return (
            <g fill={currentHairCol}>
              <path d="M70 45 C70 15, 130 15, 130 45 C130 55, 70 55, 70 45 Z" />
              <path d="M80 30 C80 5, 120 5, 120 30 Z" />
            </g>
          );
        case 0:
        default: // Classic Short
          return (
            <g fill={currentHairCol}>
              <path d="M68 50 C65 30, 135 30, 132 50 C125 40, 75 40, 68 50 Z" />
            </g>
          );
      }
    } else {
      // FEMALE HAIRS
      switch (hair) {
        case 1: // Ponytail
          return (
            <g fill={currentHairCol}>
              {/* Back ponytail */}
              <path d="M120 55 C140 50, 160 80, 150 110 C140 100, 125 75, 120 65 Z" />
              <circle cx="123" cy="58" r="8" fill="#F1C40F" /> {/* Hairtie */}
              {/* Main hair */}
              <path d="M66 50 C66 25, 134 25, 134 50 C120 42, 80 42, 66 50 Z" />
              <path d="M66 48 L64 75 L73 60 Z" />
              <path d="M134 48 L136 75 L127 60 Z" />
            </g>
          );
        case 2: // Long Wavy
          return (
            <g fill={currentHairCol}>
              {/* Back Hair */}
              <path d="M64 50 C50 60, 50 120, 65 140 C60 110, 68 80, 70 60 Z" />
              <path d="M136 50 C150 60, 150 120, 135 140 C140 110, 132 80, 130 60 Z" />
              {/* Front hair */}
              <path d="M66 50 C66 25, 134 25, 134 50 C110 38, 90 38, 66 50 Z" />
            </g>
          );
        case 3: // Twin Braids
          return (
            <g fill={currentHairCol}>
              {/* Braid Left */}
              <path d="M65 60 C55 75, 55 100, 48 125 C55 125, 62 90, 65 70 Z" />
              <circle cx="48" cy="125" r="5" fill="#E74C3C" /> {/* Ribbon */}
              {/* Braid Right */}
              <path d="M135 60 C145 75, 145 100, 152 125 C145 125, 138 90, 135 70 Z" />
              <circle cx="152" cy="125" r="5" fill="#E74C3C" /> {/* Ribbon */}
              {/* Main head hair */}
              <path d="M66 50 C66 25, 134 25, 134 50 C110 40, 90 40, 66 50 Z" />
            </g>
          );
        case 4: // Big Afro Pink/Neon
          return (
            <g fill={currentHairCol}>
              <circle cx="100" cy="45" r="40" />
              <circle cx="70" cy="60" r="25" />
              <circle cx="130" cy="60" r="25" />
            </g>
          );
        case 5: // High Bun
          return (
            <g fill={currentHairCol}>
              <circle cx="100" cy="18" r="22" />
              <circle cx="100" cy="18" r="24" fill="none" stroke="#F1C40F" strokeWidth="3" /> {/* Bun ribbon */}
              <path d="M66 50 C66 25, 134 25, 134 50 C120 40, 80 40, 66 50 Z" />
            </g>
          );
        case 6: // Long Dreadlocks Rainbow
          return (
            <g fill={currentHairCol}>
              <rect x="58" y="45" width="8" height="90" rx="3" />
              <rect x="68" y="40" width="8" height="110" rx="3" />
              <rect x="124" y="40" width="8" height="110" rx="3" />
              <rect x="134" y="45" width="8" height="90" rx="3" />
              <path d="M66 50 C66 25, 134 25, 134 50 C110 38, 90 38, 66 50 Z" />
            </g>
          );
        case 7: // Pixie Cut
          return (
            <g fill={currentHairCol}>
              <path d="M66 50 C66 25, 134 25, 134 50 L130 58 L124 50 L100 56 L76 50 L70 58 Z" />
            </g>
          );
        case 8: // Twin Tails
          return (
            <g fill={currentHairCol}>
              {/* Tail L */}
              <path d="M65 45 C45 35, 35 75, 40 100 C48 90, 55 60, 65 52 Z" />
              <circle cx="60" cy="48" r="6" fill="#2ECC71" />
              {/* Tail R */}
              <path d="M135 45 C155 35, 165 75, 160 100 C152 90, 145 60, 135 52 Z" />
              <circle cx="140" cy="48" r="6" fill="#2ECC71" />
              {/* Mid */}
              <path d="M66 50 C66 25, 134 25, 134 50 C110 40, 90 40, 66 50 Z" />
            </g>
          );
        case 9: // Princess Hime Cut
          return (
            <g fill={currentHairCol}>
              {/* Back long hair flat */}
              <rect x="58" y="50" width="84" height="90" rx="5" />
              {/* Sidestraps */}
              <rect x="60" y="50" width="12" height="40" rx="2" />
              <rect x="128" y="50" width="12" height="40" rx="2" />
              {/* Bangs */}
              <path d="M66 50 C66 25, 134 25, 134 50 L128 53 L118 53 L100 55 L82 53 L72 53 Z" />
            </g>
          );
        case 0:
        default: // Bob Cut
          return (
            <g fill={currentHairCol}>
              <path d="M64 50 C60 60, 58 90, 62 100 L72 100 L68 55 Z" />
              <path d="M136 50 C140 60, 142 90, 138 100 L128 100 L132 55 Z" />
              <path d="M66 50 C66 25, 134 25, 134 50 C110 42, 90 42, 66 50 Z" />
            </g>
          );
      }
    }
  };

  // Draw Hat
  const renderHat = () => {
    switch (hat) {
      case 1: // Red Baseball Cap
        return (
          <g>
            <path d="M66 40 C66 20, 134 20, 134 40 Z" fill="#E74C3C" />
            {/* Visor */}
            <path d="M120 38 C135 38, 165 42, 160 54 C150 56, 125 44, 120 38 Z" fill="#C0392B" />
            <circle cx="100" cy="22" r="4" fill="#34495E" />
          </g>
        );
      case 2: // Cool Beanie
        return (
          <g>
            <path d="M64 48 C64 15, 136 15, 136 48 Z" fill="#34495E" />
            <rect x="60" y="42" width="80" height="12" rx="4" fill="#2C3E50" />
            {/* Pom pom */}
            <circle cx="100" cy="12" r="8" fill="#F1C40F" />
          </g>
        );
      case 3: // Classy Fedora
        return (
          <g>
            {/* Crown */}
            <path d="M72 38 L76 18 L124 18 L128 38 Z" fill="#212121" />
            {/* Black Ribbon */}
            <rect x="74" y="32" width="52" height="6" fill="#E74C3C" />
            {/* Brim */}
            <ellipse cx="100" cy="38" rx="42" ry="5" fill="#212121" />
          </g>
        );
      case 4: // Golden Crown
        return (
          <g fill="#F1C40F" stroke="#D35400" strokeWidth="1">
            <path d="M68 38 L62 14 L80 26 L100 8 L120 26 L138 14 L132 38 Z" />
            {/* Jewels */}
            <circle cx="100" cy="8" r="3" fill="#E74C3C" />
            <circle cx="62" cy="14" r="3" fill="#9B59B6" />
            <circle cx="138" cy="14" r="3" fill="#3498DB" />
            <rect x="75" y="32" width="50" height="4" fill="#2980B9" />
          </g>
        );
      case 5: // Cowboy Hat
        return (
          <g>
            {/* Tall Crown */}
            <path d="M74 36 C74 12, 85 8, 100 14 C115 8, 126 12, 126 36 Z" fill="#8E5A32" />
            <path d="M75 32 C75 32, 100 35, 125 32 L125 36 C125 36, 100 39, 75 36 Z" fill="#D35400" /> {/* Band */}
            {/* Curled Brim */}
            <path d="M55 36 C55 36, 100 45, 145 36 C155 32, 145 28, 140 34 C120 40, 80 40, 60 34 C55 28, 45 32, 55 36 Z" fill="#704214" />
          </g>
        );
      case 6: // Chef Hat
        return (
          <g fill="#EEEEEE" stroke="#CCCCCC" strokeWidth="1">
            <path d="M76 38 C70 30, 70 12, 85 12 C90 12, 92 8, 100 8 C108 8, 110 12, 115 12 C130 12, 130 30, 124 38 Z" />
            <rect x="76" y="32" width="48" height="8" fill="#FFFFFF" stroke="#CCCCCC" />
          </g>
        );
      case 7: // Rainbow Party Hat
        return (
          <g>
            <path d="M100 10 L68 44 L132 44 Z" fill="#9B59B6" />
            <path d="M100 10 L84 44 L116 44 Z" fill="#E74C3C" />
            <path d="M100 10 L100 44 L132 44 Z" fill="#3498DB" />
            {/* Pom pom */}
            <circle cx="100" cy="10" r="6" fill="#F1C40F" />
          </g>
        );
      case 8: // Straw Beach Hat
        return (
          <g>
            {/* Dome */}
            <path d="M74 38 C74 20, 126 20, 126 38 Z" fill="#EED295" />
            {/* Ribbon */}
            <rect x="74" y="34" width="52" height="4" fill="#E74C3C" />
            {/* Large floppy brim */}
            <ellipse cx="100" cy="38" rx="55" ry="6" fill="#F4E0B1" stroke="#EED295" strokeWidth="1" />
          </g>
        );
      case 9: // Pirate Hat
        return (
          <g>
            {/* Tricorn base */}
            <path d="M52 32 C75 24, 125 24, 148 32 C160 44, 140 38, 100 38 C60 38, 40 44, 52 32 Z" fill="#111111" />
            {/* Front gold trim */}
            <path d="M52 32 C75 25, 125 25, 148 32" fill="none" stroke="#F1C40F" strokeWidth="2" />
            {/* Skull motif */}
            <circle cx="100" cy="28" r="4" fill="#FFFFFF" />
            <rect x="98" y="32" width="4" height="3" fill="#FFFFFF" />
            <line x1="95" y1="26" x2="105" y2="34" stroke="#FFFFFF" strokeWidth="1.5" />
            <line x1="105" y1="26" x2="95" y2="34" stroke="#FFFFFF" strokeWidth="1.5" />
          </g>
        );
      case 0:
      default: // None
        return null;
    }
  };

  // Draw Shirt
  const renderShirt = () => {
    switch (shirt) {
      case 1: // Green Hoodie
        return (
          <g>
            <path d="M60 115 L140 115 L155 170 L135 170 L130 135 L125 185 L75 185 L70 135 L65 170 L45 170 Z" fill="#2ECC71" />
            {/* Hoodie cords / pockets */}
            {!facingAway && <path d="M90 120 L90 140" stroke="#FFFFFF" strokeWidth="2" />}
            {!facingAway && <path d="M110 120 L110 140" stroke="#FFFFFF" strokeWidth="2" />}
            {!facingAway && <rect x="85" y="150" width="30" height="20" rx="3" fill="#27AE60" />}
            {/* Inner neck hood hood */}
            <path d="M80 115 C80 100, 120 100, 120 115 Z" fill="#27AE60" />
          </g>
        );
      case 2: // Hawaiian Shirt
        return (
          <g>
            <path d="M60 115 L140 115 L155 170 L135 170 L130 135 L125 185 L75 185 L70 135 L65 170 L45 170 Z" fill="#FF5722" />
            {/* Flower shapes */}
            <circle cx="80" cy="135" r="4" fill="#FFF" />
            <circle cx="120" cy="140" r="4" fill="#FFF" />
            <circle cx="95" cy="165" r="4" fill="#FFF" />
            <circle cx="115" cy="170" r="4" fill="#FFF" />
            {/* Lapels */}
            {!facingAway && <path d="M80 115 L100 135 L90 115 Z" fill="#E64A19" />}
            {!facingAway && <path d="M120 115 L100 135 L110 115 Z" fill="#E64A19" />}
          </g>
        );
      case 3: // Blue Business Suit
        return facingAway ? (
          <path d="M60 115 L140 115 L155 170 L135 170 L130 135 L125 185 L75 185 L70 135 L65 170 L45 170 Z" fill="#2980B9" />
        ) : (
          <g>
            {/* White shirt base */}
            <path d="M60 115 L140 115 L125 185 L75 185 Z" fill="#FFFFFF" />
            {/* Tie */}
            <path d="M96 118 L104 118 L106 145 L100 155 L94 145 Z" fill="#E74C3C" />
            {/* Suit Jacket */}
            <path d="M60 115 L85 115 L100 145 L75 185 L65 170 L45 170 Z" fill="#2980B9" />
            <path d="M140 115 L115 115 L100 145 L125 185 L135 170 L155 170 Z" fill="#2980B9" />
          </g>
        );
      case 4: // Stripy Sailor Tee
        return (
          <g>
            <path d="M60 115 L140 115 L155 170 L135 170 L130 135 L125 185 L75 185 L70 135 L65 170 L45 170 Z" fill="#FFFFFF" />
            {/* Blue stripes */}
            <line x1="58" y1="125" x2="142" y2="125" stroke="#3498DB" strokeWidth="4" />
            <line x1="53" y1="138" x2="147" y2="138" stroke="#3498DB" strokeWidth="4" />
            <line x1="72" y1="150" x2="128" y2="150" stroke="#3498DB" strokeWidth="4" />
            <line x1="74" y1="162" x2="126" y2="162" stroke="#3498DB" strokeWidth="4" />
            <line x1="75" y1="175" x2="125" y2="175" stroke="#3498DB" strokeWidth="4" />
          </g>
        );
      case 5: // Black Tank Top
        return (
          <g>
            {/* Shoulders skin visible, only draw tank top shape */}
            <path d="M75 115 L82 115 L85 135 L115 135 L118 115 L125 115 L128 185 L72 185 Z" fill="#111111" />
            {/* Neck cutout */}
            <path d="M85 115 C85 128, 115 128, 115 115 Z" fill={facingAway ? '#111111' : skinColor} />
          </g>
        );
      case 6: // Cool Leather Jacket
        return facingAway ? (
          <path d="M60 115 L140 115 L155 170 L135 170 L130 135 L125 185 L75 185 L70 135 L65 170 L45 170 Z" fill="#2C3E50" />
        ) : (
          <g>
            {/* Inner shirt gray */}
            <path d="M75 115 L125 115 L125 185 L75 185 Z" fill="#7F8C8D" />
            {/* Leather Jacket outside */}
            <path d="M60 115 L82 115 L95 145 L75 185 L65 170 L45 170 Z" fill="#2C3E50" />
            <path d="M140 115 L118 115 L105 145 L125 185 L135 170 L155 170 Z" fill="#2C3E50" />
            {/* Metal studs / zippers */}
            <circle cx="80" cy="130" r="2.5" fill="#BDC3C7" />
            <circle cx="120" cy="130" r="2.5" fill="#BDC3C7" />
            <line x1="90" y1="145" x2="80" y2="175" stroke="#BDC3C7" strokeWidth="1.5" />
          </g>
        );
      case 7: // Red Sweater
        return (
          <g>
            <path d="M60 115 L140 115 L155 170 L135 170 L130 135 L125 185 L75 185 L70 135 L65 170 L45 170 Z" fill="#C0392B" />
            {/* Collar texture */}
            <path d="M80 115 C80 122, 120 122, 120 115 Z" fill="none" stroke="#962D22" strokeWidth="3" />
            {/* Pattern */}
            <path d="M78 145 L100 135 L122 145" fill="none" stroke="#E74C3C" strokeWidth="3" />
            <path d="M78 155 L100 145 L122 155" fill="none" stroke="#E74C3C" strokeWidth="3" />
          </g>
        );
      case 8: // Fancy Black Tuxedo
        return facingAway ? (
          <path d="M60 115 L140 115 L155 170 L135 170 L130 135 L125 185 L75 185 L70 135 L65 170 L45 170 Z" fill="#111111" />
        ) : (
          <g>
            {/* White shirt base */}
            <path d="M60 115 L140 115 L125 185 L75 185 Z" fill="#FFFFFF" />
            {/* Red Bow Tie */}
            <path d="M92 120 L108 120 L100 125 Z" fill="#E74C3C" />
            <path d="M92 126 L108 126 L100 121 Z" fill="#E74C3C" />
            <circle cx="100" cy="123" r="2.5" fill="#C0392B" />
            {/* Tuxedo Jacket */}
            <path d="M60 115 L80 115 L100 145 L75 185 L65 170 L45 170 Z" fill="#111111" />
            <path d="M140 115 L120 115 L100 145 L125 185 L135 170 L155 170 Z" fill="#111111" />
            {/* Golden Rose pin */}
            <circle cx="78" cy="135" r="3" fill="#F1C40F" />
          </g>
        );
      case 9: // Golden Emperor Vest
        return facingAway ? (
          <path d="M60 115 L140 115 L155 170 L135 170 L130 135 L125 185 L75 185 L70 135 L65 170 L45 170 Z" fill="#F1C40F" />
        ) : (
          <g>
            {/* Inner red lining */}
            <path d="M60 115 L140 115 L125 185 L75 185 Z" fill="#962D22" />
            {/* Vest itself */}
            <path d="M60 115 L85 115 L95 138 L95 185 L75 185 L65 170 L45 170 Z" fill="#F1C40F" />
            <path d="M140 115 L115 115 L105 138 L105 185 L125 185 L135 170 L155 170 Z" fill="#F1C40F" />
            {/* Gold details */}
            <line x1="95" y1="140" x2="105" y2="140" stroke="#F39C12" strokeWidth="2" />
            <line x1="95" y1="155" x2="105" y2="155" stroke="#F39C12" strokeWidth="2" />
            <line x1="95" y1="170" x2="105" y2="170" stroke="#F39C12" strokeWidth="2" />
          </g>
        );
      case 0:
      default: // Basic White Tee
        return (
          <path d="M60 115 L140 115 L155 160 L138 165 L132 135 L125 185 L75 185 L68 135 L62 165 L45 160 Z" fill="#F5F5F5" stroke="#E0E0E0" strokeWidth="1" />
        );
    }
  };

  // Draw Pants
  const renderPants = () => {
    switch (pants) {
      case 1: // Denim Casual Shorts
        return (
          <g>
            <path d="M75 185 L125 185 L125 210 L102 210 L102 195 L98 195 L98 210 L75 210 Z" fill="#5D9CEC" />
            {/* Stitching lines */}
            <line x1="75" y1="188" x2="125" y2="188" stroke="#4A89DC" strokeWidth="1.5" strokeDasharray="3,3" />
          </g>
        );
      case 2: // Dark Formal Trousers
        return (
          <g>
            <path d="M75 185 L125 185 L125 240 L102 240 L102 198 L98 198 L98 240 L75 240 Z" fill="#34495E" />
            {/* Belt */}
            <rect x="74" y="183" width="52" height="5" fill="#111111" />
            {!facingAway && <rect x="96" y="182" width="8" height="7" fill="#F1C40F" />}
          </g>
        );
      case 3: // Skirt (Female) or Cargo Pants (Male)
        if (gender === 'FEMALE') {
          return (
            <g>
              <path d="M76 185 L124 185 L134 220 L66 220 Z" fill="#E74C3C" />
              {/* Pleat lines */}
              <line x1="85" y1="185" x2="80" y2="220" stroke="#C0392B" strokeWidth="1.5" />
              <line x1="100" y1="185" x2="100" y2="220" stroke="#C0392B" strokeWidth="1.5" />
              <line x1="115" y1="185" x2="120" y2="220" stroke="#C0392B" strokeWidth="1.5" />
            </g>
          );
        } else {
          return (
            <g fill="#85929E">
              <path d="M75 185 L125 185 L125 240 L102 240 L102 198 L98 198 L98 240 L75 240 Z" />
              {/* Cargo pockets */}
              <rect x="72" y="202" width="6" height="12" rx="1" />
              <rect x="122" y="202" width="6" height="12" rx="1" />
            </g>
          );
        }
      case 4: // Neon Cyber Pants
        return (
          <g>
            <path d="M75 185 L125 185 L125 240 L102 240 L102 198 L98 198 L98 240 L75 240 Z" fill="#222222" />
            {/* Neon glowing stripes */}
            <line x1="77" y1="190" x2="77" y2="238" stroke="#00FFCC" strokeWidth="2" />
            <line x1="123" y1="190" x2="123" y2="238" stroke="#00FFCC" strokeWidth="2" />
          </g>
        );
      case 5: // Ripped Punk Jeans
        return (
          <g>
            <path d="M75 185 L125 185 L125 240 L102 240 L102 198 L98 198 L98 240 L75 240 Z" fill="#2B3E50" />
            {/* Rip cutouts (skin colored inside) */}
            {!facingAway && <rect x="80" y="205" width="12" height="4" rx="1" fill={skinColor} />}
            {!facingAway && <rect x="108" y="215" width="12" height="4" rx="1" fill={skinColor} />}
            {/* Frayed lines */}
            {!facingAway && <line x1="78" y1="204" x2="94" y2="204" stroke="#FFFFFF" strokeWidth="1" />}
            {!facingAway && <line x1="106" y1="214" x2="122" y2="214" stroke="#FFFFFF" strokeWidth="1" />}
          </g>
        );
      case 6: // Grey Cozy Joggers
        return (
          <g>
            <path d="M75 185 L125 185 L125 240 L102 240 L102 198 L98 198 L98 240 L75 240 Z" fill="#95A5A6" />
            {/* White waist tie */}
            {!facingAway && <path d="M96 190 L92 205" stroke="#FFFFFF" strokeWidth="2" />}
            {!facingAway && <path d="M100 190 L104 205" stroke="#FFFFFF" strokeWidth="2" />}
          </g>
        );
      case 7: // Swimwear / Trunks
        return (
          <path d="M75 185 L125 185 L125 198 L102 198 L102 195 L98 195 L98 198 L75 198 Z" fill="#E67E22" />
        );
      case 8: // Gold Metallic Pants
        return (
          <g>
            <path d="M75 185 L125 185 L125 240 L102 240 L102 198 L98 198 L98 240 L75 240 Z" fill="#F1C40F" />
            <line x1="88" y1="185" x2="84" y2="240" stroke="#F39C12" strokeWidth="1" />
            <line x1="112" y1="185" x2="116" y2="240" stroke="#F39C12" strokeWidth="1" />
          </g>
        );
      case 9: // Royal Ceremonial Pants
        return (
          <g>
            <path d="M75 185 L125 185 L125 240 L102 240 L102 198 L98 198 L98 240 L75 240 Z" fill="#7D3C98" />
            {/* Gold side piping */}
            <line x1="77" y1="185" x2="77" y2="240" stroke="#F1C40F" strokeWidth="2" />
            <line x1="123" y1="185" x2="123" y2="240" stroke="#F1C40F" strokeWidth="2" />
          </g>
        );
      case 0:
      default: // Blue Jeans
        return (
          <g>
            <path d="M75 185 L125 185 L125 240 L102 240 L102 198 L98 198 L98 240 L75 240 Z" fill="#3498DB" />
            {/* Pockets */}
            {!facingAway && <path d="M78 185 C78 192, 88 192, 88 185" fill="none" stroke="#2980B9" strokeWidth="1.5" />}
            {!facingAway && <path d="M122 185 C122 192, 112 192, 112 185" fill="none" stroke="#2980B9" strokeWidth="1.5" />}
          </g>
        );
    }
  };

  // Floating bounce animation class name
  const animationClass = animate ? 'animate-bounce-slow' : '';

  return (
    <div
      style={{ width: size, height: size }}
      className={noBackground ? `relative inline-block ${animationClass}` : `relative inline-block overflow-hidden rounded-full border border-slate-700/50 bg-radial from-slate-800 to-slate-950 shadow-inner ${animationClass}`}
    >
      <svg
        viewBox="0 0 200 250"
        width="100%"
        height="100%"
        xmlns="http://www.w3.org/2000/svg"
        className="drop-shadow-lg"
      >
        {/* Style block for interactive hand wave animation */}
        <style dangerouslySetInnerHTML={{ __html: `
          @keyframes playerHandWaveLeft {
            0%, 100% { transform: translateY(0) rotate(0deg); }
            15%, 45%, 75% { transform: translateY(-20px) translateX(-6px) rotate(-20deg); }
            30%, 60%, 90% { transform: translateY(-10px) translateX(-3px) rotate(12deg); }
          }
          @keyframes playerHandWaveRight {
            0%, 100% { transform: translateY(0) rotate(0deg); }
            15%, 45%, 75% { transform: translateY(-20px) translateX(6px) rotate(20deg); }
            30%, 60%, 90% { transform: translateY(-10px) translateX(3px) rotate(-12deg); }
          }
          .animate-player-hand-left {
            animation: playerHandWaveLeft 1.5s ease-in-out;
            transform-origin: 60px 115px;
          }
          .animate-player-hand-right {
            animation: playerHandWaveRight 1.5s ease-in-out;
            transform-origin: 140px 115px;
          }
        `}} />

        {/* Under layer Hair back for females (only when facing forward) */}
        {!facingAway && gender === 'FEMALE' && (hair === 1 || hair === 2 || hair === 3 || hair === 6 || hair === 8 || hair === 9 || hair === 0) && renderHair()}

        {/* Neck */}
        <rect x="90" y="100" width="20" height="22" fill={skinColor} />
        {/* Neck shadow */}
        <path d="M90 100 C95 105, 105 105, 110 100 L110 108 L90 108 Z" fill={shadowSkinColor} />

        {/* Head */}
        <circle cx="100" cy="74" r="32" fill={skinColor} />
        {/* Ears */}
        <circle cx="66" cy="74" r="7" fill={skinColor} />
        <circle cx="134" cy="74" r="7" fill={skinColor} />

        {/* Face features (only when facing forward) */}
        {!facingAway && (
          <>
            {/* Eyes */}
            <g fill="#212121">
              <circle cx="90" cy="72" r="3.5" />
              <circle cx="110" cy="72" r="3.5" />
              {/* Eyebrows */}
              <path d="M82 66 C85 64, 95 64, 98 67" stroke="#332211" strokeWidth="2.5" fill="none" />
              <path d="M118 66 C115 64, 105 64, 102 67" stroke="#332211" strokeWidth="2.5" fill="none" />
            </g>

            {/* Nose */}
            <path d="M100 72 L98 79 L102 79 Z" fill={shadowSkinColor} />

            {/* Smile */}
            <path d="M92 84 C95 91, 105 91, 108 84" stroke="#E74C3C" strokeWidth="2.5" fill="none" strokeLinecap="round" />

            {/* Cheeks blush for Female */}
            {gender === 'FEMALE' && (
              <g fill="#FF8A80" opacity="0.4">
                <circle cx="76" cy="78" r="4.5" />
                <circle cx="124" cy="78" r="4.5" />
              </g>
            )}
          </>
        )}

        {/* Male Hair (placed in front of ears, facing forward) */}
        {!facingAway && gender === 'MALE' && renderHair()}

        {/* Female Hair front (placed in front of ears, facing forward) */}
        {!facingAway && gender === 'FEMALE' && (hair === 4 || hair === 5 || hair === 7) && renderHair()}

        {/* Hair rendered on top of everything if facing away */}
        {facingAway && renderHair()}

        {/* Hat */}
        {renderHat()}

        {/* Hands */}
        <g className={isClicked ? 'animate-player-hand-left' : ''}>
          <circle cx="50" cy="175" r="8.5" fill={skinColor} />
        </g>
        <g className={isClicked ? 'animate-player-hand-right' : ''}>
          <circle cx="150" cy="175" r="8.5" fill={skinColor} />
        </g>

        {/* Shirt */}
        {renderShirt()}

        {/* Pants */}
        {renderPants()}

        {/* Shoes */}
        <g fill="#34495E">
          <ellipse cx="85" cy="242" rx="11" ry="5" />
          <ellipse cx="115" cy="242" rx="11" ry="5" />
        </g>
      </svg>
    </div>
  );
};
