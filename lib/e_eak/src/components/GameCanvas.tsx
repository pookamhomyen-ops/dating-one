import React, { useEffect, useRef, useState } from 'react';
import { audioSynth } from './AudioSynth';

interface Kart {
  id: string;
  name: string;
  driver: string;
  color: string;
  icon: any; // Lucide icon
  ultName: string;
  ultDesc: string;
  x: number;
  y: number;
  vx: number;
  vy: number;
  angle: number;
  hp: number;
  kills: number;
  deaths: number;
  isBot: boolean;
  skills: string[];
  ultCooldown: number;
  stunTimer: number;
  shieldTimer: number;
  boostTimer: number;
  jumpTimer: number;
  isFlipped: boolean;
  flippedTimer: number;
  invincibleTimer: number;
  colorHex: string;
  targetAngle?: number;
  aiActionTimer?: number;
}

interface Projectile {
  id: string;
  x: number;
  y: number;
  vx: number;
  vy: number;
  ownerId: string;
  type: 'bullet' | 'homing' | 'laser' | 'laser_beam' | 'charge';
  damage: number;
  timer: number;
  color: string;
  targetId?: string;
  radius: number;
}

interface Trap {
  id: string;
  x: number;
  y: number;
  type: 'spike' | 'freeze';
  ownerId: string;
  radius: number;
}

interface Particle {
  x: number;
  y: number;
  vx: number;
  vy: number;
  life: number;
  maxLife: number;
  color: string;
  radius: number;
  type: 'spark' | 'smoke' | 'trail' | 'shockwave' | 'ring' | 'laser_beam' | 'text';
  text?: string;
}

interface ItemBox {
  id: string;
  x: number;
  y: number;
  active: boolean;
  respawnTimer: number;
}

interface GameCanvasProps {
  playerKartInfo: {
    id: string;
    name: string;
    driver: string;
    color: any; // material color object
    ultName: string;
    ultDesc: string;
  };
  onGameOver: (scoreboard: any[]) => void;
  isPaused: boolean;
  setIsPaused: (p: boolean) => void;
}

export const GameCanvas: React.FC<GameCanvasProps> = ({
  playerKartInfo,
  onGameOver,
  isPaused,
  setIsPaused,
}) => {
  const canvasRef = useRef<HTMLCanvasElement>(null);
  const containerRef = useRef<HTMLDivElement>(null);

  // Match state
  const [matchTime, setMatchTime] = useState(180); // 3 minutes in seconds
  const [playerHp, setPlayerHp] = useState(100);
  const [playerKills, setPlayerKills] = useState(0);
  const [playerDeaths, setPlayerDeaths] = useState(0);
  const [skills, setSkills] = useState<string[]>([]);
  const [ultCooldown, setUltCooldown] = useState(0);
  const [killFeed, setKillFeed] = useState<{ id: string; text: string; age: number }[]>([]);
  const [damageIndicator, setDamageIndicator] = useState<'left' | 'right' | 'top' | 'bottom' | null>(null);
  const [screenShake, setScreenShake] = useState(0);
  const [ultimateCinematic, setUltimateCinematic] = useState<string | null>(null);
  const [playerFlipped, setPlayerFlipped] = useState(false);

  // Joystick state
  const joystickOuterRef = useRef<HTMLDivElement>(null);
  const joystickInnerRef = useRef<HTMLDivElement>(null);
  const [joystickActive, setJoystickActive] = useState(false);
  const [joystickPos, setJoystickPos] = useState({ x: 0, y: 0 });
  const [joystickVector, setJoystickVector] = useState({ x: 0, y: 0 });
  const keysPressedRef = useRef<Record<string, boolean>>({});

  // Game Engine Entities Refs
  const kartsRef = useRef<Kart[]>([]);
  const projectilesRef = useRef<Projectile[]>([]);
  const trapsRef = useRef<Trap[]>([]);
  const particlesRef = useRef<Particle[]>([]);
  const itemBoxesRef = useRef<ItemBox[]>([]);

  // Sound controls
  const lastCollisionTimesRef = useRef<Record<string, number>>({});
  const lastCrashTimesRef = useRef<number[]>([]);
  const playCrashSound = (vol: number) => {
    const now = Date.now();
    lastCrashTimesRef.current = lastCrashTimesRef.current.filter(t => now - t < 150);
    if (lastCrashTimesRef.current.length >= 2) return;
    lastCrashTimesRef.current.push(now);
    audioSynth.play('crash', vol);
  };
  
  // Timing / Engine Control Refs
  const gameLoopIdRef = useRef<number | null>(null);
  const lastTimeRef = useRef<number>(0);
  const matchTimeRef = useRef<number>(180);

  // Map Constants
  const mapSize = 1300; // 1300 x 1300 arena

  // Static Obstacles Definition
  const pillars = [
    { x: 350, y: 350, radius: 45 },
    { x: 950, y: 350, radius: 45 },
    { x: 350, y: 950, radius: 45 },
    { x: 950, y: 950, radius: 45 },
    { x: 650, y: 650, radius: 60 },
  ];

  const barriers = [
    { x: 500, y: 480, w: 300, h: 30 }, // Central Top Barrier
    { x: 500, y: 790, w: 300, h: 30 }, // Central Bottom Barrier
    { x: 180, y: 550, w: 30, h: 200 }, // Left Barrier
    { x: 1090, y: 550, w: 30, h: 200 }, // Right Barrier
  ];

  // Jump ramps
  const ramps = [
    { x: 200, y: 200, w: 60, h: 60, name: 'เนินโดดค่ายกลซ้าย' },
    { x: 1100, y: 1100, w: 60, h: 60, name: 'เนินโดดถล่มขวา' },
    { x: 650, y: 950, w: 80, h: 40, name: 'เนินข้ามคูพสุธา' },
  ];

  // Turbo speed pads
  const turbos = [
    { x: 650, y: 180, w: 50, h: 50, dx: 1, dy: 0, angle: 0 },       // Top middle -> right
    { x: 180, y: 650, w: 50, h: 50, dx: 0, dy: -1, angle: -Math.PI / 2 }, // Left middle -> up
    { x: 1120, y: 650, w: 50, h: 50, dx: 0, dy: 1, angle: Math.PI / 2 },  // Right middle -> down
    { x: 650, y: 1120, w: 50, h: 50, dx: -1, dy: 0, angle: Math.PI },      // Bottom middle -> left
  ];

  // Available skills lists by Tier
  const tier1Skills = ['กระสุนปืนไฟ', 'หนามเหล็กแหลม', 'เกราะป้องกันเบื้องต้น'];
  const tier2Skills = ['มิสไซล์ล่าเป้า', 'ระเบิดช็อกเวฟ', 'บาเรียสายฟ้า'];
  const tier3Skills = ['ลำแสงมหาประลัย', 'กับดักน้ำแข็ง'];

  // Initialize Game Entities
  useEffect(() => {
    // Colors mapping
    const getHexColor = (name: string) => {
      if (name.includes('อีเอก')) return '#EF4444';
      if (name.includes('พี่แดง')) return '#F97316';
      if (name.includes('เสือขาว')) return '#64748B';
      if (name.includes('ลิงลม')) return '#F59E0B';
      if (name.includes('นกสายฟ้า')) return '#A855F7';
      if (name.includes('เต่าคะนอง')) return '#22C55E';
      if (name.includes('กระต่าย')) return '#EC4899';
      if (name.includes('มังกร')) return '#EAB308';
      if (name.includes('หมาป่า')) return '#3B82F6';
      if (name.includes('หมีศิลา')) return '#78350F';
      return '#3B82F6';
    };

    // Build Roster
    const botsData = [
      { id: 'p_daeng', name: 'พี่แดง (P\'Daeng)', driver: 'สมแดง', ultName: 'พายุหมุนลูกไฟ', ultDesc: 'หมุนกระแทกดึงรอบตัว' },
      { id: 'white_tiger', name: 'เสือขาว (White Tiger)', driver: 'วายุ', ultName: 'เลเซอร์จู่โจม', ultDesc: 'ยิงแสงทำลายล้างเป็นเส้นตรง' },
      { id: 'wind_monkey', name: 'ลิงลม (Wind Monkey)', driver: 'หนุมาน', ultName: 'แยกร่างลวงตา', ultDesc: 'แยกร่าง เพิ่มความเร็ว ล่องหน' },
      { id: 'thunder_hawk', name: 'นกสายฟ้า (Thunder Hawk)', driver: 'อินทรี', ultName: 'พายุสายฟ้าบาเรีย', ultDesc: 'กางเกราะสะท้อนกระแสไฟช็อตศัตรู' },
      { id: 'challenger_turtle', name: 'เต่าคะนอง (Challenger Turtle)', driver: 'พสุธา', ultName: 'ป้อมปราการหุ้มเกราะ', ultDesc: 'อมตะ เกราะหนาพุ่งทะลวงชนปลิว' },
      { id: 'wild_rabbit', name: 'กระต่ายป่า (Wild Rabbit)', driver: 'กระโดดไว', ultName: 'ระเบิดแครอทกระจาย', ultDesc: 'ฝนระเบิดกลมลอยรอบตัว' },
      { id: 'golden_dragon', name: 'มังกรทอง (Golden Dragon)', driver: 'หลงเซียน', ultName: 'คลื่นมังกรคำราม', ultDesc: 'คลื่นสั่นสะเทือนผลักกระเด็นมึนงง' },
      { id: 'shadow_wolf', name: 'หมาป่าทมิฬ (Shadow Wolf)', driver: 'ราตรี', ultName: 'เขี้ยวรัตติกาลลอบสังหาร', ultDesc: 'วาร์ปพุ่งกัดศัตรูข้าข้างหลังทันที' },
      { id: 'stone_bear', name: 'หมีศิลา (Stone Bear)', driver: 'โกไลแอท', ultName: 'แผ่นดินไหวพสุธา', ultDesc: 'กระโดดกระทืบหลุมยุบ สโลว์หนัก' },
    ];

    // Filter out player's choice to have 5 unique bots
    const filteredBots = botsData.filter(b => b.id !== playerKartInfo.id).slice(0, 5);

    const kartsList: Kart[] = [
      {
        id: 'player',
        name: playerKartInfo.name,
        driver: playerKartInfo.driver,
        color: playerKartInfo.color,
        icon: null,
        ultName: playerKartInfo.ultName,
        ultDesc: playerKartInfo.ultDesc,
        x: 650,
        y: 1150, // Starting at the bottom middle
        vx: 0,
        vy: 0,
        angle: -Math.PI / 2, // Facing North
        hp: 100,
        kills: 0,
        deaths: 0,
        isBot: false,
        skills: [],
        ultCooldown: 0,
        stunTimer: 0,
        shieldTimer: 0,
        boostTimer: 0,
        jumpTimer: 0,
        isFlipped: false,
        flippedTimer: 0,
        invincibleTimer: 2,
        colorHex: getHexColor(playerKartInfo.name),
      },
      ...filteredBots.map((b, i) => {
        const angles = [0, Math.PI / 4, Math.PI / 2, Math.PI, -Math.PI / 4];
        const positions = [
          { x: 150, y: 150 },
          { x: 1150, y: 150 },
          { x: 150, y: 1150 },
          { x: 1150, y: 1150 },
          { x: 650, y: 150 },
        ];
        return {
          id: b.id,
          name: b.name,
          driver: b.driver,
          color: null,
          icon: null,
          ultName: b.ultName,
          ultDesc: b.ultDesc,
          x: positions[i].x,
          y: positions[i].y,
          vx: 0,
          vy: 0,
          angle: angles[i],
          hp: 100,
          kills: 0,
          deaths: 0,
          isBot: true,
          skills: [],
          ultCooldown: 5 + i * 4, // staggered initial cooldowns
          stunTimer: 0,
          shieldTimer: 0,
          boostTimer: 0,
          jumpTimer: 0,
          isFlipped: false,
          flippedTimer: 0,
          invincibleTimer: 2,
          colorHex: getHexColor(b.name),
          targetAngle: 0,
          aiActionTimer: 0,
        } as Kart;
      }),
    ];

    kartsRef.current = kartsList;

    // Create 8 Item Boxes around map
    const boxPositions = [
      { id: 'b1', x: 400, y: 200, active: true, respawnTimer: 0 },
      { id: 'b2', x: 900, y: 200, active: true, respawnTimer: 0 },
      { id: 'b3', x: 200, y: 400, active: true, respawnTimer: 0 },
      { id: 'b4', x: 1100, y: 400, active: true, respawnTimer: 0 },
      { id: 'b5', x: 200, y: 900, active: true, respawnTimer: 0 },
      { id: 'b6', x: 1100, y: 900, active: true, respawnTimer: 0 },
      { id: 'b7', x: 400, y: 1100, active: true, respawnTimer: 0 },
      { id: 'b8', x: 900, y: 1100, active: true, respawnTimer: 0 },
    ];
    itemBoxesRef.current = boxPositions;

    // Reset list refs
    projectilesRef.current = [];
    trapsRef.current = [];
    particlesRef.current = [];
    matchTimeRef.current = 180;
    setMatchTime(180);

    // BGM
    audioSynth.startBGM(false);

    // Initial alert in kill feed
    addFeed('● ยินดีต้อนรับสู่ E-EAK KART BATTLE ARENA (อีเอก)');
    addFeed('● แข่งกันสะสมคิลสูงสุดภายใน 3 นาที! เหยียบเทอร์โบและเก็บกล่องสุ่มสกิลได้รอบสนาม');

    return () => {
      audioSynth.stopBGM();
      if (gameLoopIdRef.current) cancelAnimationFrame(gameLoopIdRef.current);
    };
  }, [playerKartInfo]);

  const addFeed = (text: string) => {
    setKillFeed(prev => [{ id: Math.random().toString(), text, age: 5 }, ...prev].slice(0, 6));
  };

  // Main Loop Handler
  useEffect(() => {
    if (isPaused) {
      if (gameLoopIdRef.current) cancelAnimationFrame(gameLoopIdRef.current);
      audioSynth.stopBGM();
      return;
    }

    audioSynth.startBGM(matchTimeRef.current <= 30);

    const updatePhysicsAndRender = (timestamp: number) => {
      if (!lastTimeRef.current) lastTimeRef.current = timestamp;
      let dt = (timestamp - lastTimeRef.current) / 1000;
      if (dt > 0.1) dt = 0.1; // clamp lag spikes
      lastTimeRef.current = timestamp;

      // Update Match Timer
      matchTimeRef.current -= dt;
      if (matchTimeRef.current <= 0) {
        matchTimeRef.current = 0;
        setMatchTime(0);
        handleMatchFinished();
        return;
      }
      setMatchTime(Math.ceil(matchTimeRef.current));

      // Trigger faster BGM at 30s remaining
      if (Math.ceil(matchTimeRef.current) === 30 && matchTimeRef.current + dt > 30) {
        audioSynth.startBGM(true); // switch to hurry bgm!
        addFeed('⚠️ เหลือเวลาอีก 30 วินาทีสุดท้าย! เพิ่มความดุเดือด!');
      }

      // 1. UPDATE STATE ENGINES
      updateEntities(dt);

      // 2. RENDER GRAPHICS
      renderGame();

      gameLoopIdRef.current = requestAnimationFrame(updatePhysicsAndRender);
    };

    gameLoopIdRef.current = requestAnimationFrame(updatePhysicsAndRender);

    return () => {
      if (gameLoopIdRef.current) cancelAnimationFrame(gameLoopIdRef.current);
    };
  }, [isPaused]);

  // Handle Game Summary Trigger
  const handleMatchFinished = () => {
    audioSynth.play('powerup');
    const sortedScoreboard = [...kartsRef.current].sort((a, b) => b.kills - a.kills || a.deaths - b.deaths);
    onGameOver(sortedScoreboard);
  };

  // Joystick Event Handlers
  const handleJoystickStart = (e: React.TouchEvent | React.MouseEvent) => {
    e.preventDefault();
    setJoystickActive(true);
    updateJoystickPos(e);
  };

  const handleJoystickMove = (e: TouchEvent | MouseEvent) => {
    if (!joystickActive) return;
    updateJoystickPos(e);
  };

  const handleJoystickEnd = () => {
    setJoystickActive(false);
    setJoystickPos({ x: 0, y: 0 });
    setJoystickVector({ x: 0, y: 0 });
  };

  const updateJoystickPos = (e: any) => {
    if (!joystickOuterRef.current) return;
    const rect = joystickOuterRef.current.getBoundingClientRect();
    const centerX = rect.left + rect.width / 2;
    const centerY = rect.top + rect.height / 2;

    let clientX = 0;
    let clientY = 0;

    if (e.touches && e.touches.length > 0) {
      clientX = e.touches[0].clientX;
      clientY = e.touches[0].clientY;
    } else {
      clientX = e.clientX;
      clientY = e.clientY;
    }

    const dx = clientX - centerX;
    const dy = clientY - centerY;
    const distance = Math.sqrt(dx * dx + dy * dy);
    const maxRadius = rect.width / 2 - 10;

    let targetX = dx;
    let targetY = dy;

    if (distance > maxRadius) {
      targetX = (dx / distance) * maxRadius;
      targetY = (dy / distance) * maxRadius;
    }

    setJoystickPos({ x: targetX, y: targetY });

    // Normalize vector
    const normX = dx / (distance || 1);
    const normY = dy / (distance || 1);
    const strength = Math.min(distance / maxRadius, 1.0);
    setJoystickVector({ x: normX * strength, y: normY * strength });
  };

  // Add global touch handlers for smooth joystick response
  useEffect(() => {
    const onGlobalMove = (e: MouseEvent | TouchEvent) => {
      if (joystickActive) {
        updateJoystickPos(e);
      }
    };
    const onGlobalEnd = () => {
      if (joystickActive) {
        handleJoystickEnd();
      }
    };

    window.addEventListener('mousemove', onGlobalMove);
    window.addEventListener('mouseup', onGlobalEnd);
    window.addEventListener('touchmove', onGlobalMove, { passive: false });
    window.addEventListener('touchend', onGlobalEnd);

    return () => {
      window.removeEventListener('mousemove', onGlobalMove);
      window.removeEventListener('mouseup', onGlobalEnd);
      window.removeEventListener('touchmove', onGlobalMove);
      window.removeEventListener('touchend', onGlobalEnd);
    };
  }, [joystickActive]);

  // Add global keyboard controls support (WASD, Arrow Keys, 1, 2, Space, R)
  useEffect(() => {
    const handleKeyDown = (e: KeyboardEvent) => {
      if (['ArrowUp', 'ArrowDown', 'ArrowLeft', 'ArrowRight', ' '].includes(e.key)) {
        e.preventDefault();
      }
      keysPressedRef.current[e.code] = true;
      keysPressedRef.current[e.key] = true;

      if (e.key === '1') {
        handleUseSkill(0);
      } else if (e.key === '2') {
        handleUseSkill(1);
      } else if (e.key === ' ' || e.code === 'Space') {
        handleUseUltimate();
      } else if (e.key === 'r' || e.key === 'R') {
        handleRecover();
      }
    };

    const handleKeyUp = (e: KeyboardEvent) => {
      keysPressedRef.current[e.code] = false;
      keysPressedRef.current[e.key] = false;
    };

    window.addEventListener('keydown', handleKeyDown);
    window.addEventListener('keyup', handleKeyUp);

    return () => {
      window.removeEventListener('keydown', handleKeyDown);
      window.removeEventListener('keyup', handleKeyUp);
    };
  }, [skills, ultCooldown]);

  // Player Manual Recover when flipped
  const handleRecover = () => {
    const player = kartsRef.current.find(k => k.id === 'player');
    if (player && player.isFlipped) {
      player.isFlipped = false;
      player.angle = -Math.PI / 2; // Face North
      player.vx = 0;
      player.vy = 0;
      setPlayerFlipped(false);
      audioSynth.play('respawn');
      spawnExplosion(player.x, player.y, player.colorHex, 15);
      addFeed('🔧 อีเอกกู้รถและตั้งหลักใหม่ได้สำเร็จ!');
    }
  };

  // Skill Activator for Player
  const handleUseSkill = (slotIndex: number) => {
    const player = kartsRef.current.find(k => k.id === 'player');
    if (!player || player.isFlipped || player.stunTimer > 0) return;

    if (slotIndex >= player.skills.length) return;
    const skillName = player.skills[slotIndex];

    // Remove skill from inventory
    const updatedSkills = [...player.skills];
    updatedSkills.splice(slotIndex, 1);
    player.skills = updatedSkills;
    setSkills(updatedSkills);

    triggerSkillLogic(skillName, player);
  };

  // Ultimate Activator for Player
  const handleUseUltimate = () => {
    const player = kartsRef.current.find(k => k.id === 'player');
    if (!player || player.isFlipped || player.stunTimer > 0 || player.ultCooldown > 0) return;

    // Set cooldown
    player.ultCooldown = 30;
    setUltCooldown(30);

    // Cinematic banner
    setUltimateCinematic(`${player.name} ปลดปล่อยอัลติเมต \n"${player.ultName}" !`);
    setTimeout(() => setUltimateCinematic(null), 1800);

    triggerUltimateLogic(player);
  };

  // Core Skill triggers
  const triggerSkillLogic = (skillName: string, caster: Kart) => {
    audioSynth.play('shoot');

    const cos = Math.cos(caster.angle);
    const sin = Math.sin(caster.angle);

    if (skillName === 'กระสุนปืนไฟ') {
      projectilesRef.current.push({
        id: Math.random().toString(),
        x: caster.x + cos * 35,
        y: caster.y + sin * 35,
        vx: cos * 520,
        vy: sin * 520,
        ownerId: caster.id,
        type: 'bullet',
        damage: 20,
        timer: 1.8,
        color: '#EF4444',
        radius: 6,
      });
    } else if (skillName === 'หนามเหล็กแหลม') {
      // Place behind
      trapsRef.current.push({
        id: Math.random().toString(),
        x: caster.x - cos * 30,
        y: caster.y - sin * 30,
        type: 'spike',
        ownerId: caster.id,
        radius: 18,
      });
    } else if (skillName === 'เกราะป้องกันเบื้องต้น') {
      caster.shieldTimer = 4;
      audioSynth.play('powerup');
      spawnRings(caster.x, caster.y, '#3B82F6', 15);
    } else if (skillName === 'มิสไซล์ล่าเป้า') {
      // Find nearest enemy to lock on
      let closestEnemy: Kart | null = null;
      let minDist = 99999;
      kartsRef.current.forEach(k => {
        if (k.id !== caster.id && k.hp > 0) {
          const d = dist(caster.x, caster.y, k.x, k.y);
          if (d < minDist) {
            minDist = d;
            closestEnemy = k;
          }
        }
      });

      projectilesRef.current.push({
        id: Math.random().toString(),
        x: caster.x + cos * 30,
        y: caster.y + sin * 30,
        vx: cos * 380,
        vy: sin * 380,
        ownerId: caster.id,
        type: 'homing',
        damage: 30,
        timer: 3.5,
        color: '#F97316',
        targetId: closestEnemy ? (closestEnemy as Kart).id : undefined,
        radius: 8,
      });
    } else if (skillName === 'ระเบิดช็อกเวฟ') {
      audioSynth.play('explosion');
      spawnRings(caster.x, caster.y, '#A855F7', 25);
      
      // Damage and push all karts in radius 160
      kartsRef.current.forEach(k => {
        if (k.id !== caster.id && k.hp > 0) {
          const d = dist(caster.x, caster.y, k.x, k.y);
          if (d < 160) {
            const angle = Math.atan2(k.y - caster.y, k.x - caster.x);
            k.vx = Math.cos(angle) * 450;
            k.vy = Math.sin(angle) * 450;
            k.hp = Math.max(0, k.hp - 25);
            k.stunTimer = 0.5;
            checkDeath(k, caster);
          }
        }
      });
    } else if (skillName === 'บาเรียสายฟ้า') {
      caster.shieldTimer = 5;
      caster.boostTimer = 2.5;
      audioSynth.play('powerup');
      for (let a = 0; a < Math.PI * 2; a += Math.PI / 4) {
        particlesRef.current.push({
          x: caster.x, y: caster.y,
          vx: Math.cos(a) * 120, vy: Math.sin(a) * 120,
          life: 0.6, maxLife: 0.6, color: '#A855F7', radius: 4, type: 'spark'
        });
      }
    } else if (skillName === 'ลำแสงมหาประลัย') {
      // Direct laser beam
      audioSynth.play('explosion');
      const startX = caster.x + cos * 25;
      const startY = caster.y + sin * 25;
      const endX = caster.x + cos * 600;
      const endY = caster.y + sin * 600;

      projectilesRef.current.push({
        id: Math.random().toString(),
        x: startX,
        y: startY,
        vx: cos * 1500,
        vy: sin * 1500,
        ownerId: caster.id,
        type: 'laser_beam',
        damage: 40,
        timer: 0.3,
        color: '#EF4444',
        radius: 14,
      });

      // Spawn spectacular laser line particles
      for (let i = 0; i < 20; i++) {
        const ratio = i / 20;
        particlesRef.current.push({
          x: startX + (endX - startX) * ratio,
          y: startY + (endY - startY) * ratio,
          vx: (Math.random() - 0.5) * 40,
          vy: (Math.random() - 0.5) * 40,
          life: 0.4,
          maxLife: 0.4,
          color: '#F43F5E',
          radius: 3 + Math.random() * 4,
          type: 'spark',
        });
      }
    } else if (skillName === 'กับดักน้ำแข็ง') {
      trapsRef.current.push({
        id: Math.random().toString(),
        x: caster.x - cos * 30,
        y: caster.y - sin * 30,
        type: 'freeze',
        ownerId: caster.id,
        radius: 20,
      });
    }
  };

  // Core Ultimate Skill Logic based on selected character
  const triggerUltimateLogic = (caster: Kart) => {
    audioSynth.play('powerup');
    const cos = Math.cos(caster.angle);
    const sin = Math.sin(caster.angle);

    if (caster.id === 'player') {
      // Trigger camera zoom in/vibration or nice particle trails
      spawnRings(caster.x, caster.y, caster.colorHex, 30);
    }

    if (caster.name.includes('อีเอก')) {
      // Eak Dash: charges forward with massive speed, dealing immense damage to karts hit
      caster.boostTimer = 2.5;
      caster.vx = cos * 850;
      caster.vy = sin * 850;
      // Add heavy charge projectile wrapper
      projectilesRef.current.push({
        id: Math.random().toString(),
        x: caster.x,
        y: caster.y,
        vx: cos * 850,
        vy: sin * 850,
        ownerId: caster.id,
        type: 'charge',
        damage: 45,
        timer: 1.2,
        color: '#EF4444',
        radius: 28,
      });
    } else if (caster.name.includes('พี่แดง')) {
      // Crimson Vortex: spins and drags surrounding enemies close, ticking damage
      caster.shieldTimer = 3.5;
      caster.boostTimer = 3.5;
      
      let angleOffset = 0;
      const interval = setInterval(() => {
        if (caster.hp <= 0) {
          clearInterval(interval);
          return;
        }
        angleOffset += 0.4;
        audioSynth.play('shoot');
        // Spawn ring particles
        for (let j = 0; j < 8; j++) {
          const a = angleOffset + (j * Math.PI) / 4;
          particlesRef.current.push({
            x: caster.x + Math.cos(a) * 80,
            y: caster.y + Math.sin(a) * 80,
            vx: -Math.cos(a) * 150,
            vy: -Math.sin(a) * 150,
            life: 0.5,
            maxLife: 0.5,
            color: '#F97316',
            radius: 5,
            type: 'spark',
          });
        }
        // Drag in radius 180
        kartsRef.current.forEach(k => {
          if (k.id !== caster.id && k.hp > 0) {
            const d = dist(caster.x, caster.y, k.x, k.y);
            if (d < 180) {
              const dx = caster.x - k.x;
              const dy = caster.y - k.y;
              k.vx += (dx / d) * 160;
              k.vy += (dy / d) * 160;
              k.hp = Math.max(0, k.hp - 3); // Continuous ticks
              checkDeath(k, caster);
            }
          }
        });
      }, 250);
      setTimeout(() => clearInterval(interval), 3000);
    } else if (caster.name.includes('เสือขาว')) {
      // Tiger Beam: massive full screen laser
      const startX = caster.x + cos * 30;
      const startY = caster.y + sin * 30;
      projectilesRef.current.push({
        id: Math.random().toString(),
        x: startX,
        y: startY,
        vx: cos * 1600,
        vy: sin * 1600,
        ownerId: caster.id,
        type: 'laser_beam',
        damage: 50,
        timer: 0.4,
        color: '#E2E8F0',
        radius: 18,
      });
      // Epic beam sparks
      for (let i = 0; i < 35; i++) {
        const ratio = i / 35;
        particlesRef.current.push({
          x: startX + cos * 800 * ratio,
          y: startY + sin * 800 * ratio,
          vx: (Math.random() - 0.5) * 60,
          vy: (Math.random() - 0.5) * 60,
          life: 0.6,
          maxLife: 0.6,
          color: '#94A3B8',
          radius: 4 + Math.random() * 5,
          type: 'spark',
        });
      }
    } else if (caster.name.includes('ลิงลม')) {
      // Shadow Mirage: speed boost, stealth, invincibility
      caster.boostTimer = 4.5;
      caster.shieldTimer = 4.5;
      caster.invincibleTimer = 4.5;
      // Spawn clone particles
      for (let i = 0; i < 3; i++) {
        particlesRef.current.push({
          x: caster.x + (Math.random() - 0.5) * 80,
          y: caster.y + (Math.random() - 0.5) * 80,
          vx: caster.vx * 0.5,
          vy: caster.vy * 0.5,
          life: 3.0,
          maxLife: 3.0,
          color: 'rgba(245,158,11,0.4)',
          radius: 12,
          type: 'smoke',
        });
      }
    } else if (caster.name.includes('นกสายฟ้า')) {
      // Electro Shield: shock shield reflecting damage + stuns close opponents for 2s
      caster.shieldTimer = 5;
      const interval = setInterval(() => {
        if (caster.hp <= 0) {
          clearInterval(interval);
          return;
        }
        audioSynth.play('shoot');
        // Zap closest opponent
        let nearest: Kart | null = null;
        let minDist = 220;
        kartsRef.current.forEach(k => {
          if (k.id !== caster.id && k.hp > 0) {
            const d = dist(caster.x, caster.y, k.x, k.y);
            if (d < minDist) {
              minDist = d;
              nearest = k;
            }
          }
        });
        if (nearest) {
          (nearest as Kart).stunTimer = 2.0;
          (nearest as Kart).hp = Math.max(0, (nearest as Kart).hp - 10);
          audioSynth.play('explosion');
          checkDeath(nearest as Kart, caster);
          // Lightning spark line
          for (let i = 0; i < 10; i++) {
            const ratio = i / 10;
            particlesRef.current.push({
              x: caster.x + ((nearest as Kart).x - caster.x) * ratio,
              y: caster.y + ((nearest as Kart).y - caster.y) * ratio,
              vx: (Math.random() - 0.5) * 40,
              vy: (Math.random() - 0.5) * 40,
              life: 0.3,
              maxLife: 0.3,
              color: '#C084FC',
              radius: 3,
              type: 'spark',
            });
          }
        }
      }, 500);
      setTimeout(() => clearInterval(interval), 4000);
    } else if (caster.name.includes('เต่าคะนอง')) {
      // Iron Shell: invincible, heavy mass, hits enemies back very hard
      caster.shieldTimer = 6;
      caster.boostTimer = 4;
      caster.invincibleTimer = 6;
      spawnRings(caster.x, caster.y, '#22C55E', 25);
    } else if (caster.name.includes('กระต่ายป่า')) {
      // Carrot Cluster: drops 5 flying carrot explosives around
      for (let j = 0; j < 6; j++) {
        const a = (j * Math.PI) / 3;
        const targetX = caster.x + Math.cos(a) * 140;
        const targetY = caster.y + Math.sin(a) * 140;
        setTimeout(() => {
          audioSynth.play('explosion');
          spawnExplosion(targetX, targetY, '#EC4899', 18);
          // Splash radius check
          kartsRef.current.forEach(k => {
            if (k.id !== caster.id && k.hp > 0) {
              const d = dist(targetX, targetY, k.x, k.y);
              if (d < 90) {
                k.hp = Math.max(0, k.hp - 20);
                k.vx += (k.x - targetX) * 3;
                k.vy += (k.y - targetY) * 3;
                checkDeath(k, caster);
              }
            }
          });
        }, j * 200 + 400);
      }
    } else if (caster.name.includes('มังกรทอง')) {
      // Dragon Roar: shockwave push out + 1.5s stun
      audioSynth.play('explosion');
      spawnRings(caster.x, caster.y, '#EAB308', 35);
      kartsRef.current.forEach(k => {
        if (k.id !== caster.id && k.hp > 0) {
          const d = dist(caster.x, caster.y, k.x, k.y);
          if (d < 240) {
            const angle = Math.atan2(k.y - caster.y, k.x - caster.x);
            k.vx = Math.cos(angle) * 700;
            k.vy = Math.sin(angle) * 700;
            k.hp = Math.max(0, k.hp - 35);
            k.stunTimer = 1.5;
            checkDeath(k, caster);
          }
        }
      });
    } else if (caster.name.includes('หมาป่า')) {
      // Fangs of Night: Warp and strike closest enemy from behind
      let target: Kart | null = null;
      let minDist = 300;
      kartsRef.current.forEach(k => {
        if (k.id !== caster.id && k.hp > 0) {
          const d = dist(caster.x, caster.y, k.x, k.y);
          if (d < minDist) {
            minDist = d;
            target = k;
          }
        }
      });
      if (target) {
        audioSynth.play('respawn');
        // Smoke at old pos
        spawnExplosion(caster.x, caster.y, '#3B82F6', 10);
        // Warp behind target
        const oppositeAngle = (target as Kart).angle + Math.PI;
        caster.x = (target as Kart).x + Math.cos(oppositeAngle) * 35;
        caster.y = (target as Kart).y + Math.sin(oppositeAngle) * 35;
        caster.angle = (target as Kart).angle;
        caster.vx = Math.cos(caster.angle) * 550;
        caster.vy = Math.sin(caster.angle) * 550;
        // Hit target
        (target as Kart).hp = Math.max(0, (target as Kart).hp - 40);
        (target as Kart).vx += caster.vx * 0.8;
        (target as Kart).vy += caster.vy * 0.8;
        (target as Kart).stunTimer = 0.5;
        spawnExplosion((target as Kart).x, (target as Kart).y, '#1E40AF', 20);
        checkDeath(target as Kart, caster);
      }
    } else if (caster.name.includes('หมีศิลา')) {
      // Giga Slam: Leap up, smash down causing a slow crater
      caster.jumpTimer = 0.8;
      audioSynth.play('jump');
      setTimeout(() => {
        audioSynth.play('explosion');
        spawnRings(caster.x, caster.y, '#78350F', 30);
        // Damage and slow surrounding enemies by 80% for 4s
        kartsRef.current.forEach(k => {
          if (k.id !== caster.id && k.hp > 0) {
            const d = dist(caster.x, caster.y, k.x, k.y);
            if (d < 180) {
              k.hp = Math.max(0, k.hp - 35);
              k.stunTimer = 1.0;
              // Set speed modifier
              k.boostTimer = -4.0; // Negative values to indicate slow!
              checkDeath(k, caster);
            }
          }
        });
      }, 800);
    }
  };

  const dist = (x1: number, y1: number, x2: number, y2: number) => {
    const dx = x2 - x1;
    const dy = y2 - y1;
    return Math.sqrt(dx * dx + dy * dy);
  };

  const spawnExplosion = (x: number, y: number, color: string, count = 12) => {
    for (let i = 0; i < count; i++) {
      const angle = Math.random() * Math.PI * 2;
      const speed = 60 + Math.random() * 140;
      particlesRef.current.push({
        x,
        y,
        vx: Math.cos(angle) * speed,
        vy: Math.sin(angle) * speed,
        life: 0.5 + Math.random() * 0.4,
        maxLife: 0.8,
        color,
        radius: 2 + Math.random() * 4,
        type: 'spark',
      });
    }
  };

  const spawnRings = (x: number, y: number, color: string, count = 10) => {
    particlesRef.current.push({
      x,
      y,
      vx: 0,
      vy: 0,
      life: 0.6,
      maxLife: 0.6,
      color,
      radius: 10,
      type: 'shockwave',
    });
  };

  const checkDeath = (victim: Kart, attacker: Kart) => {
    if (victim.hp <= 0) {
      victim.deaths++;
      attacker.kills++;

      if (attacker.id === 'player') setPlayerKills(attacker.kills);
      if (victim.id === 'player') setPlayerDeaths(victim.deaths);

      // Trigger spectacular splash feed
      const verbs = ['ถล่มยับ', 'เด็ดชีพ', 'เป่ากระจุย', 'สอยร่วง', 'ชนแหลก'];
      const randomVerb = verbs[Math.floor(Math.random() * verbs.length)];
      addFeed(`⚔️ ${attacker.name} [${randomVerb}] ${victim.name}`);

      audioSynth.play('explosion');
      spawnExplosion(victim.x, victim.y, victim.colorHex, 30);

      // Respawn logic with 2.5s delay
      victim.x = -9999; // hide momentarily
      victim.y = -9999;
      victim.hp = 0;

      setTimeout(() => {
        // Find safe spawn coords
        const respawnPoints = [
          { x: 150, y: 150 },
          { x: 1150, y: 150 },
          { x: 150, y: 1150 },
          { x: 1150, y: 1150 },
          { x: 650, y: 650 },
        ];
        const p = respawnPoints[Math.floor(Math.random() * respawnPoints.length)];
        victim.x = p.x;
        victim.y = p.y;
        victim.vx = 0;
        victim.vy = 0;
        victim.hp = 100;
        victim.isFlipped = false;
        victim.stunTimer = 0;
        victim.shieldTimer = 0;
        victim.boostTimer = 0;
        victim.jumpTimer = 0;
        victim.invincibleTimer = 2.0; // 2 seconds immortal on spawn

        if (victim.id === 'player') {
          setPlayerFlipped(false);
          setPlayerHp(100);
        }

        audioSynth.play('respawn');
        addFeed(`🛡️ ${victim.name} ฟื้นคืนสู่สนามรบพร้อมเกราะป้องกัน!`);
      }, 2500);
    }
  };

  // Update Entity States Frame-by-Frame
  const updateEntities = (dt: number) => {
    const karts = kartsRef.current;
    const projectiles = projectilesRef.current;
    const traps = trapsRef.current;
    const particles = particlesRef.current;
    const itemBoxes = itemBoxesRef.current;

    // 1. UPDATE PLAYERS & BOTS PHYSICS
    karts.forEach(kart => {
      if (kart.hp <= 0) return;

      // Invincibility shield reduction
      if (kart.invincibleTimer > 0) {
        kart.invincibleTimer -= dt;
      }
      if (kart.shieldTimer > 0) {
        kart.shieldTimer -= dt;
      }

      // Handle cooldowns
      if (kart.ultCooldown > 0) {
        kart.ultCooldown = Math.max(0, kart.ultCooldown - dt);
        if (kart.id === 'player') setUltCooldown(kart.ultCooldown);
      }

      // Handle Stuns
      if (kart.stunTimer > 0) {
        kart.stunTimer -= dt;
        // Friction only, cannot steer
        kart.vx *= 0.88;
        kart.vy *= 0.88;
        kart.x += kart.vx * dt;
        kart.y += kart.vy * dt;
        return;
      }

      // Boost timer (can be negative for slows!)
      if (kart.boostTimer !== 0) {
        if (kart.boostTimer > 0) {
          kart.boostTimer = Math.max(0, kart.boostTimer - dt);
        } else {
          kart.boostTimer = Math.min(0, kart.boostTimer + dt);
        }
      }

      // Jump timer
      if (kart.jumpTimer > 0) {
        kart.jumpTimer -= dt;
      }

      // Flipped status physics
      if (kart.isFlipped) {
        kart.vx *= 0.94;
        kart.vy *= 0.94;
        kart.x += kart.vx * dt;
        kart.y += kart.vy * dt;
        kart.angle += 0.15; // keep spinning flipped!

        if (kart.isBot) {
          kart.flippedTimer += dt;
          if (kart.flippedTimer > 3.0) {
            // bot auto-recover
            kart.isFlipped = false;
            kart.flippedTimer = 0;
            kart.angle = Math.random() * Math.PI * 2;
            audioSynth.play('respawn');
            spawnExplosion(kart.x, kart.y, kart.colorHex, 8);
          }
        }
        return;
      }

      // Driving inputs
      let steerX = 0;
      let steerY = 0;

      if (!kart.isBot) {
        // Player Control Input (WASD / Arrows and Joystick merger)
        let kbX = 0;
        let kbY = 0;
        if (keysPressedRef.current['KeyA'] || keysPressedRef.current['ArrowLeft'] || keysPressedRef.current['a'] || keysPressedRef.current['A']) kbX -= 1;
        if (keysPressedRef.current['KeyD'] || keysPressedRef.current['ArrowRight'] || keysPressedRef.current['d'] || keysPressedRef.current['D']) kbX += 1;
        if (keysPressedRef.current['KeyW'] || keysPressedRef.current['ArrowUp'] || keysPressedRef.current['w'] || keysPressedRef.current['W']) kbY -= 1;
        if (keysPressedRef.current['KeyS'] || keysPressedRef.current['ArrowDown'] || keysPressedRef.current['s'] || keysPressedRef.current['S']) kbY += 1;

        if (kbX !== 0 || kbY !== 0) {
          const len = Math.sqrt(kbX * kbX + kbY * kbY);
          steerX = kbX / len;
          steerY = kbY / len;
        } else {
          steerX = joystickVector.x;
          steerY = joystickVector.y;
        }
      } else {
        // BOT AI DECISION MAKING (Every frame direction following)
        kart.aiActionTimer = (kart.aiActionTimer || 0) - dt;
        if (kart.aiActionTimer <= 0) {
          kart.aiActionTimer = 0.5 + Math.random() * 0.5; // decide every 0.5-1.0s

          const player = karts.find(k => k.id === 'player');
          const playerDist = player && player.hp > 0 ? dist(kart.x, kart.y, player.x, player.y) : 9999;

          // Action 1: low hp retreat
          if (kart.hp < 30) {
            // Head to safe corners away from player/enemies
            const corner = kart.x < mapSize / 2 ? { x: mapSize - 100, y: mapSize - 100 } : { x: 100, y: 100 };
            kart.targetAngle = Math.atan2(corner.y - kart.y, corner.x - kart.x);
          }
          // Action 2: grab boxes if slots open
          else if (kart.skills.length < 2 && itemBoxes.some(b => b.active)) {
            let closestBox: ItemBox | null = null;
            let minDist = 9999;
            itemBoxes.forEach(b => {
              if (b.active) {
                const d = dist(kart.x, kart.y, b.x, b.y);
                if (d < minDist) {
                  minDist = d;
                  closestBox = b;
                }
              }
            });
            if (closestBox) {
              kart.targetAngle = Math.atan2((closestBox as ItemBox).y - kart.y, (closestBox as ItemBox).x - kart.x);
            }
          }
          // Action 3: chase player or closest enemy
          else {
            let closestOpponent: Kart | null = null;
            let minDist = 9999;
            karts.forEach(other => {
              if (other.id !== kart.id && other.hp > 0) {
                const d = dist(kart.x, kart.y, other.x, other.y);
                if (d < minDist) {
                  minDist = d;
                  closestOpponent = other;
                }
              }
            });

            if (closestOpponent) {
              kart.targetAngle = Math.atan2((closestOpponent as Kart).y - kart.y, (closestOpponent as Kart).x - kart.x);

              // Use Skill if inside range and has skills
              if (minDist < 250 && kart.skills.length > 0) {
                const skillToUse = kart.skills[0];
                kart.skills = kart.skills.slice(1);
                triggerSkillLogic(skillToUse, kart);
              }

              // Use Ultimate if available
              if (minDist < 180 && kart.ultCooldown <= 0) {
                kart.ultCooldown = 30;
                triggerUltimateLogic(kart);
              }
            }
          }
        }

        // Apply smooth steering angle interpolation for bots
        if (kart.targetAngle !== undefined) {
          const diff = kart.targetAngle - kart.angle;
          kart.angle += Math.sin(diff) * 0.12; // slow rot
          steerX = Math.cos(kart.angle);
          steerY = Math.sin(kart.angle);
        }
      }

      // Physics Engine Acceleration
      let accSpeed = 160; // default acceleration
      if (kart.boostTimer > 0) accSpeed = 290; // turbo boost speed
      if (kart.boostTimer < 0) accSpeed = 60;  // slower debuffed speed

      if (steerX !== 0 || steerY !== 0) {
        // Accelerate along target angle
        const targetAngle = Math.atan2(steerY, steerX);
        if (!kart.isBot) {
          // Smooth rotation for player
          const diff = targetAngle - kart.angle;
          kart.angle += Math.sin(diff) * 0.15;
        }

        const driveCos = Math.cos(kart.angle);
        const driveSin = Math.sin(kart.angle);

        kart.vx += driveCos * accSpeed * dt * 4;
        kart.vy += driveSin * accSpeed * dt * 4;
      }

      // Add small constant crawl forward
      const crawlCos = Math.cos(kart.angle);
      const crawlSin = Math.sin(kart.angle);
      const crawlSpeed = kart.boostTimer > 0 ? 110 : 60;
      kart.vx += crawlCos * crawlSpeed * dt;
      kart.vy += crawlSin * crawlSpeed * dt;

      // Friction & drag damping (replicates standard car friction)
      kart.vx *= 0.94;
      kart.vy *= 0.94;

      // Update position coordinates
      kart.x += kart.vx * dt;
      kart.y += kart.vy * dt;

      // Player HUD bindings
      if (kart.id === 'player') {
        setPlayerHp(Math.ceil(kart.hp));
      }

      // Arena boundaries containment wall collisions
      const boundMin = 25;
      const boundMax = mapSize - 25;

      const currentSpeed = Math.sqrt(kart.vx * kart.vx + kart.vy * kart.vy);
      const obstacleCrashVol = Math.max(0.03, Math.min(0.25, 0.03 + (currentSpeed / 400) * 0.22));

      if (kart.x < boundMin) { kart.x = boundMin; kart.vx = -kart.vx * 0.5; playCrashSound(obstacleCrashVol); setScreenShake(6); }
      if (kart.x > boundMax) { kart.x = boundMax; kart.vx = -kart.vx * 0.5; playCrashSound(obstacleCrashVol); setScreenShake(6); }
      if (kart.y < boundMin) { kart.y = boundMin; kart.vy = -kart.vy * 0.5; playCrashSound(obstacleCrashVol); setScreenShake(6); }
      if (kart.y > boundMax) { kart.y = boundMax; kart.vy = -kart.vy * 0.5; playCrashSound(obstacleCrashVol); setScreenShake(6); }

      // Obstacle: circular pillars physics
      pillars.forEach(pil => {
        const d = dist(kart.x, kart.y, pil.x, pil.y);
        const minDist = pil.radius + 15; // 15 is half-kart radius approximate
        if (d < minDist) {
          // Push out
          const angle = Math.atan2(kart.y - pil.y, kart.x - pil.x);
          kart.x = pil.x + Math.cos(angle) * minDist;
          
          // Rebound velocity vectors
          const normalX = Math.cos(angle);
          const normalY = Math.sin(angle);
          const dot = kart.vx * normalX + kart.vy * normalY;
          kart.vx = (kart.vx - 2 * dot * normalX) * 0.5;
          kart.vy = (kart.vy - 2 * dot * normalY) * 0.5;

          const collSpeed = Math.sqrt(kart.vx * kart.vx + kart.vy * kart.vy);
          const pilVol = Math.max(0.03, Math.min(0.25, 0.03 + (collSpeed / 400) * 0.22));
          playCrashSound(pilVol);
          if (kart.id === 'player') setScreenShake(5);
        }
      });

      // Obstacle: rectangular barriers physics
      barriers.forEach(bar => {
        const kartRadius = 15;
        const bLeft = bar.x - kartRadius;
        const bRight = bar.x + bar.w + kartRadius;
        const bTop = bar.y - kartRadius;
        const bBottom = bar.y + bar.h + kartRadius;

        if (kart.x > bLeft && kart.x < bRight && kart.y > bTop && kart.y < bBottom) {
          // Collision inside box! Project back to closest edge
          const dl = Math.abs(kart.x - bLeft);
          const dr = Math.abs(bRight - kart.x);
          const dt = Math.abs(kart.y - bTop);
          const db = Math.abs(bBottom - kart.y);

          const minEdge = Math.min(dl, dr, dt, db);
          if (minEdge === dl) { kart.x = bLeft; kart.vx = -Math.abs(kart.vx) * 0.5; }
          else if (minEdge === dr) { kart.x = bRight; kart.vx = Math.abs(kart.vx) * 0.5; }
          else if (minEdge === dt) { kart.y = bTop; kart.vy = -Math.abs(kart.vy) * 0.5; }
          else { kart.y = bBottom; kart.vy = Math.abs(kart.vy) * 0.5; }

          const collSpeed = Math.sqrt(kart.vx * kart.vx + kart.vy * kart.vy);
          const barVol = Math.max(0.03, Math.min(0.25, 0.03 + (collSpeed / 400) * 0.22));
          playCrashSound(barVol);
          if (kart.id === 'player') setScreenShake(5);
        }
      });

      // Turbo speed pads intersection
      turbos.forEach(t => {
        if (kart.x > t.x && kart.x < t.x + t.w && kart.y > t.y && kart.y < t.y + t.h) {
          if (kart.boostTimer <= 0) {
            kart.boostTimer = 3.0; // 3 seconds boost
            // Push strongly in pad direction
            kart.vx = t.dx * 750;
            kart.vy = t.dy * 750;
            audioSynth.play('boost');
            spawnExplosion(kart.x, kart.y, '#F59E0B', 8);

            // Notify player
            if (kart.id === 'player') {
              addFeed('⚡ เหยียบแผ่นความเร็วด่วนจี๋ บูสต์เทอร์โบ 3 วินาที!');
            }
          }
        }
      });

      // Jump ramp launching intersection
      ramps.forEach(r => {
        if (kart.x > r.x && kart.x < r.x + r.w && kart.y > r.y && kart.y < r.y + r.h) {
          if (kart.jumpTimer <= 0) {
            kart.jumpTimer = 0.8; // jump for 0.8s
            audioSynth.play('jump');
            // Give forward vector boost
            const speed = Math.sqrt(kart.vx * kart.vx + kart.vy * kart.vy);
            const bounceSpeed = Math.max(speed, 220);
            kart.vx = Math.cos(kart.angle) * bounceSpeed * 1.5;
            kart.vy = Math.sin(kart.angle) * bounceSpeed * 1.5;

            // Notify
            if (kart.id === 'player') {
              addFeed(`🚀 เหินข้ามเนินกระโดด: ${r.name}!`);
            }
          }
        }
      });
    });

    // 2. KART-TO-KART COLLISION DETECTION (Forge2D rigid-body elastic replication)
    for (let i = 0; i < karts.length; i++) {
      for (let j = i + 1; j < karts.length; j++) {
        const k1 = karts[i];
        const k2 = karts[j];

        if (k1.hp <= 0 || k2.hp <= 0) continue;

        const d = dist(k1.x, k1.y, k2.x, k2.y);
        const collisionRadius = 32; // sum of vehicle radii

        if (d < collisionRadius) {
          // Simple elastic overlap correction
          const overlap = collisionRadius - d;
          const angle = Math.atan2(k2.y - k1.y, k2.x - k1.x);

          // Push apart equally
          const correctionX = Math.cos(angle) * (overlap / 2);
          const correctionY = Math.sin(angle) * (overlap / 2);

          k1.x -= correctionX;
          k1.y -= correctionY;
          k2.x += correctionX;
          k2.y += correctionY;

          // Compute pre-collision momentum/relative speed
          const relSpeedSq = (k1.vx - k2.vx) ** 2 + (k1.vy - k2.vy) ** 2;
          const relSpeed = Math.sqrt(relSpeedSq);

          // Physics-based knockback calculation
          const nx = Math.cos(angle);
          const ny = Math.sin(angle);
          const tx = -ny;
          const ty = nx;

          // Project velocities onto normal and tangent vectors
          const v1n = k1.vx * nx + k1.vy * ny;
          const v1t = k1.vx * tx + k1.vy * ty;
          const v2n = k2.vx * nx + k2.vy * ny;
          const v2t = k2.vx * tx + k2.vy * ty;

          const s1 = Math.sqrt(k1.vx * k1.vx + k1.vy * k1.vy);
          const s2 = Math.sqrt(k2.vx * k2.vx + k2.vy * k2.vy);
          const speedDiff = Math.abs(s1 - s2);

          // Crisp, tight knockback impulse (proportional to speed difference + base)
          const baseImpulse = 180;
          const dynamicImpulse = speedDiff * 0.45;
          const totalImpulse = baseImpulse + dynamicImpulse;

          // Distribute sharing: victim (slower car) gets more knockback than the hitter
          let k1Share = 0.5;
          let k2Share = 0.5;
          if (s1 > s2 + 10) {
            k1Share = 0.35;
            k2Share = 0.65;
          } else if (s2 > s1 + 10) {
            k1Share = 0.65;
            k2Share = 0.35;
          }

          // Apply impulse along normal vector
          const newV1n = -totalImpulse * k1Share;
          const newV2n = totalImpulse * k2Share;

          // Reconstruct velocity vectors (tangents remain unchanged)
          k1.vx = newV1n * nx + v1t * tx;
          k1.vy = newV1n * ny + v1t * ty;
          k2.vx = newV2n * nx + v2t * tx;
          k2.vy = newV2n * ny + v2t * ty;

          // Face away from the collision center while being knocked back (Only for the victim, not the hitter)
          if (s1 > s2) {
            // k1 is hitter (faster), k2 is victim. Only rotate k2.
            k2.angle = angle;
          } else if (s2 > s1) {
            // k2 is hitter (faster), k1 is victim. Only rotate k1.
            k1.angle = angle + Math.PI;
          } else {
            // Equal speed, rotate both away
            k1.angle = angle + Math.PI;
            k2.angle = angle;
          }

          // Cooldown for collision sound per pair
          const key = k1.id < k2.id ? `${k1.id}-${k2.id}` : `${k2.id}-${k1.id}`;
          const nowTime = Date.now();
          const lastCollide = lastCollisionTimesRef.current[key] || 0;
          
          let shouldPlaySound = true;
          if (nowTime - lastCollide < 400) { // 0.4s cooldown
            shouldPlaySound = false;
          } else {
            lastCollisionTimesRef.current[key] = nowTime;
          }

          // Collision sound volume based on impact intensity
          const vol = Math.max(0.03, Math.min(0.25, 0.03 + (relSpeed / 400) * 0.22));
          if (shouldPlaySound) {
            playCrashSound(vol);
          }

          spawnExplosion((k1.x + k2.x) / 2, (k1.y + k2.y) / 2, '#EF4444', 4);

          if (k1.id === 'player' || k2.id === 'player') {
            setScreenShake(8);
          }

          // HIGH ACCIDENT FLIP DETECTOR!
          // If relative collision momentum is massive, there's a chance of vehicle flipping over!
          if (relSpeedSq > 35000) {
            const flipCand = Math.random() < 0.5 ? k1 : k2;
            if (!flipCand.isFlipped && flipCand.invincibleTimer <= 0) {
              flipCand.isFlipped = true;
              flipCand.flippedTimer = 0;
              audioSynth.play('explosion');
              spawnExplosion(flipCand.x, flipCand.y, '#F59E0B', 15);
              
              if (flipCand.id === 'player') {
                setPlayerFlipped(true);
                addFeed('💥 รถของคุณพลิกคว่ำ! กดปุ่ม "กู้รถสู้ต่อ" ด่วนกลางจอ!');
              } else {
                addFeed(`💥 รถของ ${flipCand.name} พลิกคว่ำจากการชนรุนแรง!`);
              }
            }
          }
        }
      }
    }

    // 3. UPDATE PROJECTILES & COLLISION CHECKS
    projectilesRef.current = projectiles.filter(p => {
      p.timer -= dt;
      if (p.timer <= 0) return false;

      // Move
      if (p.type === 'homing' && p.targetId) {
        // Track targeted enemy kart
        const target = karts.find(k => k.id === p.targetId);
        if (target && target.hp > 0) {
          const dy = target.y - p.y;
          const dx = target.x - p.x;
          const targetAngle = Math.atan2(dy, dx);
          // Interpolate velocity towards target
          const curAngle = Math.atan2(p.vy, p.vx);
          const nextAngle = curAngle + Math.sin(targetAngle - curAngle) * 0.16;
          p.vx = Math.cos(nextAngle) * 440;
          p.vy = Math.sin(nextAngle) * 440;
        }
      }

      p.x += p.vx * dt;
      p.y += p.vy * dt;

      // Particle smoke trails for projectiles
      if (Math.random() < 0.25) {
        particlesRef.current.push({
          x: p.x, y: p.y, vx: 0, vy: 0,
          life: 0.4, maxLife: 0.4, color: p.color, radius: p.type === 'laser_beam' ? 8 : 4, type: 'smoke'
        });
      }

      // Check weapon hits on karts
      let collided = false;
      for (let k = 0; k < karts.length; k++) {
        const kart = karts[k];
        if (kart.hp <= 0 || kart.id === p.ownerId || kart.invincibleTimer > 0) continue;

        const d = dist(p.x, p.y, kart.x, kart.y);
        const hitDistance = p.radius + 18;

        if (d < hitDistance) {
          collided = true;

          // Apply damage (blocked if shield activated)
          if (kart.shieldTimer > 0) {
            // Shield absorbed!
            audioSynth.play('boost');
            spawnRings(kart.x, kart.y, '#3B82F6', 8);
            addFeed(`🛡️ เกราะของ ${kart.name} ดูดซับดาเมจการยิงได้หมด!`);
          } else {
            // Real hit
            kart.hp = Math.max(0, kart.hp - p.damage);
            
            // Push back
            const angle = Math.atan2(p.vy, p.vx);
            kart.vx += Math.cos(angle) * 350;
            kart.vy += Math.sin(angle) * 350;
            kart.stunTimer = 0.4;

            // Damage direction indicator flash for player
            if (kart.id === 'player') {
              triggerDamageIndicator(p.x - kart.x, p.y - kart.y);
              setScreenShake(12);
            }

            audioSynth.play('explosion');
            spawnExplosion(p.x, p.y, p.color, 12);
            
            // Check victim death
            const attacker = karts.find(att => att.id === p.ownerId) || karts[0];
            checkDeath(kart, attacker);
          }
          break;
        }
      }

      return !collided;
    });

    // 4. UPDATE TRAPS & DETECTION
    trapsRef.current = traps.filter(t => {
      // Check collision with ANY kart
      let triggered = false;

      for (let k = 0; k < karts.length; k++) {
        const kart = karts[k];
        if (kart.hp <= 0 || kart.id === t.ownerId || kart.invincibleTimer > 0) continue;

        const d = dist(t.x, t.y, kart.x, kart.y);
        if (d < t.radius + 15) {
          triggered = true;

          if (kart.shieldTimer > 0) {
            audioSynth.play('boost');
            addFeed(`🛡️ ${kart.name} ทับกับดักแต่เกราะแสงช่วยไว้!`);
          } else {
            if (t.type === 'spike') {
              kart.hp = Math.max(0, kart.hp - 15);
              kart.boostTimer = -2.5; // slows down for 2.5s
              audioSynth.play('explosion');
              spawnExplosion(t.x, t.y, '#EF4444', 10);
              
              if (kart.id === 'player') {
                triggerDamageIndicator(t.x - kart.x, t.y - kart.y);
                setScreenShake(8);
                addFeed('💥 ทับทุ่นกับดักตะปูเรือใบ! ดาเมจ 15 HP และความเร็วตก!');
              }

              const attacker = karts.find(att => att.id === t.ownerId) || karts[0];
              checkDeath(kart, attacker);
            } else if (t.type === 'freeze') {
              kart.stunTimer = 2.5; // Frozen stun 2.5 seconds
              audioSynth.play('powerup');
              spawnRings(t.x, t.y, '#38BDF8', 12);

              if (kart.id === 'player') {
                triggerDamageIndicator(t.x - kart.x, t.y - kart.y);
                setScreenShake(4);
                addFeed('❄️ คุณโดนฟรีซ! แช่แข็งขยับรถไม่ได้ 2.5 วินาที!');
              }
            }
          }
          break;
        }
      }

      return !triggered;
    });

    // 5. ITEM BOX COLLECTS & RESPAWN TIMERS
    itemBoxes.forEach(b => {
      if (!b.active) {
        b.respawnTimer -= dt;
        if (b.respawnTimer <= 0) {
          b.active = true;
          audioSynth.play('respawn');
          // floating sparkly particles on box respawn
          spawnRings(b.x, b.y, '#F59E0B', 6);
        }
      } else {
        // Check collision with ANY alive kart
        for (let k = 0; k < karts.length; k++) {
          const kart = karts[k];
          if (kart.hp <= 0) continue;

          const d = dist(kart.x, kart.y, b.x, b.y);
          if (d < 35) { // item box collision radius
            b.active = false;
            b.respawnTimer = 15.0; // 15 seconds respawn loop

            audioSynth.play('collect');
            spawnExplosion(b.x, b.y, '#EAB308', 8);

            // Give random skill if has empty slot
            if (kart.skills.length < 2) {
              // Rubber-banding: if bot/player has trailing score, give higher tier skills!
              const sortedKarts = [...karts].sort((x, y) => y.kills - x.kills);
              const rank = sortedKarts.findIndex(x => x.id === kart.id);
              
              let skillAwarded = 'กระสุนปืนไฟ';
              const rand = Math.random();

              if (rank >= 4) {
                // Trailing badly - high chance of rare items
                if (rand < 0.35) skillAwarded = tier1Skills[Math.floor(Math.random() * tier1Skills.length)];
                else if (rand < 0.75) skillAwarded = tier2Skills[Math.floor(Math.random() * tier2Skills.length)];
                else skillAwarded = tier3Skills[Math.floor(Math.random() * tier3Skills.length)];
              } else {
                // Regular chances
                if (rand < 0.6) skillAwarded = tier1Skills[Math.floor(Math.random() * tier1Skills.length)];
                else if (rand < 0.9) skillAwarded = tier2Skills[Math.floor(Math.random() * tier2Skills.length)];
                else skillAwarded = tier3Skills[Math.floor(Math.random() * tier3Skills.length)];
              }

              kart.skills.push(skillAwarded);
              if (kart.id === 'player') {
                setSkills([...kart.skills]);
                addFeed(`🎁 เก็บกล่องปริศนาสุ่มได้สกิล: \${skillAwarded}!`);
              }
            } else {
              if (kart.id === 'player') {
                addFeed('❌ สล็อตเก็บของเต็มแล้ว 2 ช่อง! การเก็บครั้งนี้เลยไม่ได้อะไรเพิ่ม');
              }
            }
            break;
          }
        }
      }
    });

    // 6. UPDATE VISUAL PARTICLES
    particlesRef.current = particles.filter(p => {
      p.life -= dt;
      if (p.life <= 0) return false;

      p.x += p.vx * dt;
      p.y += p.vy * dt;

      if (p.type === 'shockwave') {
        p.radius += 180 * dt; // growing ring
      }

      return true;
    });

    // Screen shake decay
    if (screenShake > 0) {
      setScreenShake(prev => Math.max(0, prev - dt * 25));
    }
  };

  // Triggering visual indicators for side of damage
  const triggerDamageIndicator = (dx: number, dy: number) => {
    // Calculate direction of damage relative to player heading direction or static
    if (Math.abs(dx) > Math.abs(dy)) {
      setDamageIndicator(dx > 0 ? 'right' : 'left');
    } else {
      setDamageIndicator(dy > 0 ? 'bottom' : 'top');
    }
    setTimeout(() => setDamageIndicator(null), 600);
  };

  // Master Render Engine (Html5 2D Canvas)
  const renderGame = () => {
    const canvas = canvasRef.current;
    if (!canvas) return;
    const ctx = canvas.getContext('2d');
    if (!ctx) return;

    // Set canvas dimensions relative to display parent
    const rect = canvas.parentElement?.getBoundingClientRect();
    const width = rect?.width || 800;
    const height = rect?.height || 450;
    canvas.width = width;
    canvas.height = height;

    const player = kartsRef.current.find(k => k.id === 'player');
    const px = player ? player.x : mapSize / 2;
    const py = player ? player.y : mapSize / 2;

    // SMOOTH FOLLOW CHASE CAMERA CALCULATIONS
    const camX = px - width / 2;
    const camY = py - height / 2;

    ctx.clearRect(0, 0, width, height);

    ctx.save();
    // Apply camera shake if active
    if (screenShake > 0) {
      const shakeX = (Math.random() - 0.5) * screenShake;
      const shakeY = (Math.random() - 0.5) * screenShake;
      ctx.translate(shakeX, shakeY);
    }
    ctx.translate(-camX, -camY);

    // 1. DRAW TILE MAP GRID
    const gridSize = 80;
    const minGridX = Math.floor(camX / gridSize) * gridSize;
    const maxGridX = Math.ceil((camX + width) / gridSize) * gridSize;
    const minGridY = Math.floor(camY / gridSize) * gridSize;
    const maxGridY = Math.ceil((camY + height) / gridSize) * gridSize;

    // Draw grid tiles
    for (let gx = Math.max(0, minGridX); gx < Math.min(mapSize, maxGridX); gx += gridSize) {
      for (let gy = Math.max(0, minGridY); gy < Math.min(mapSize, maxGridY); gy += gridSize) {
        const isDark = ((gx / gridSize) + (gy / gridSize)) % 2 === 0;
        ctx.fillStyle = isDark ? '#0F172A' : '#1E293B';
        ctx.fillRect(gx, gy, gridSize, gridSize);
        
        // Minor grid inner borders
        ctx.strokeStyle = '#334155';
        ctx.lineWidth = 0.5;
        ctx.strokeRect(gx, gy, gridSize, gridSize);
      }
    }

    // Outer Map boundary walls
    ctx.strokeStyle = '#EF4444';
    ctx.lineWidth = 14;
    ctx.strokeRect(5, 5, mapSize - 10, mapSize - 10);

    // 2. DRAW RAMPS (JUMP PADS)
    ramps.forEach(r => {
      // Draw 3D-like elevated ramp
      ctx.fillStyle = '#475569';
      ctx.fillRect(r.x, r.y, r.w, r.h);
      
      // Highlight ramp yellow stripe arrow
      ctx.fillStyle = '#EAB308';
      ctx.beginPath();
      ctx.moveTo(r.x + r.w / 2, r.y + 10);
      ctx.lineTo(r.x + 10, r.y + r.h - 10);
      ctx.lineTo(r.x + r.w - 10, r.y + r.h - 10);
      ctx.closePath();
      ctx.fill();

      // Text label
      ctx.fillStyle = '#FFFFFF';
      ctx.font = 'bold 9px Arial';
      ctx.textAlign = 'center';
      ctx.fillText('เนินเหินลอยฟ้า', r.x + r.w / 2, r.y - 6);
    });

    // 3. DRAW TURBO SPEED PADS
    turbos.forEach(t => {
      ctx.save();
      ctx.translate(t.x + t.w / 2, t.y + t.h / 2);
      ctx.rotate(t.angle);

      // Yellow neon arrow style
      ctx.fillStyle = '#EAB308';
      ctx.beginPath();
      ctx.moveTo(t.w / 2, 0);
      ctx.lineTo(-t.w / 2, -t.h / 2);
      ctx.lineTo(-t.w / 3, 0);
      ctx.lineTo(-t.w / 2, t.h / 2);
      ctx.closePath();
      ctx.fill();

      // Outer glow boundary
      ctx.strokeStyle = '#F59E0B';
      ctx.lineWidth = 2.5;
      ctx.strokeRect(-t.w / 2, -t.h / 2, t.w, t.h);

      ctx.restore();
    });

    // 4. DRAW STATIC OBSTACLE BARRIERS
    barriers.forEach(bar => {
      // Draw solid metallic grey wall blocks
      ctx.fillStyle = '#334155';
      ctx.fillRect(bar.x, bar.y, bar.w, bar.h);
      ctx.strokeStyle = '#64748B';
      ctx.lineWidth = 3;
      ctx.strokeRect(bar.x, bar.y, bar.w, bar.h);

      // Hazard warning stripes
      ctx.fillStyle = '#EAB308';
      for (let sx = bar.x + 10; sx < bar.x + bar.w; sx += 30) {
        ctx.beginPath();
        ctx.moveTo(sx, bar.y);
        ctx.lineTo(sx + 10, bar.y);
        ctx.lineTo(sx - 10, bar.y + bar.h);
        ctx.lineTo(sx - 20, bar.y + bar.h);
        ctx.closePath();
        ctx.fill();
      }
    });

    // 5. DRAW CIRCULAR PILLARS
    pillars.forEach(p => {
      // Draw outer fence base
      ctx.fillStyle = '#1E293B';
      ctx.beginPath();
      ctx.arc(p.x, p.y, p.radius, 0, Math.PI * 2);
      ctx.fill();
      ctx.strokeStyle = '#475569';
      ctx.lineWidth = 5;
      ctx.stroke();

      // Draw center elevated metal post
      ctx.fillStyle = '#64748B';
      ctx.beginPath();
      ctx.arc(p.x, p.y, p.radius - 12, 0, Math.PI * 2);
      ctx.fill();
    });

    // 6. DRAW ACTIVE TRAPS
    trapsRef.current.forEach(t => {
      ctx.save();
      ctx.translate(t.x, t.y);

      if (t.type === 'spike') {
        // Red spike hazard triangle
        ctx.fillStyle = '#EF4444';
        for (let a = 0; a < Math.PI * 2; a += Math.PI / 4) {
          ctx.beginPath();
          ctx.moveTo(0, 0);
          ctx.lineTo(Math.cos(a - 0.2) * t.radius, Math.sin(a - 0.2) * t.radius);
          ctx.lineTo(Math.cos(a + 0.2) * t.radius, Math.sin(a + 0.2) * t.radius);
          ctx.closePath();
          ctx.fill();
        }
        ctx.fillStyle = '#991B1B';
        ctx.beginPath();
        ctx.arc(0, 0, 5, 0, Math.PI * 2);
        ctx.fill();
      } else if (t.type === 'freeze') {
        // Cyan snowflake style trap
        ctx.strokeStyle = '#38BDF8';
        ctx.lineWidth = 3;
        for (let a = 0; a < Math.PI * 2; a += Math.PI / 3) {
          ctx.beginPath();
          ctx.moveTo(0, 0);
          ctx.lineTo(Math.cos(a) * t.radius, Math.sin(a) * t.radius);
          ctx.stroke();
        }
        ctx.fillStyle = '#E0F2FE';
        ctx.beginPath();
        ctx.arc(0, 0, 6, 0, Math.PI * 2);
        ctx.fill();
      }

      ctx.restore();
    });

    // 7. DRAW ITEM BOXES
    itemBoxesRef.current.forEach(b => {
      if (!b.active) return;

      // Draw floating golden box "?"
      const bob = Math.sin(Date.now() / 150) * 4; // bobbing vertical movement
      const spin = (Date.now() / 400) % (Math.PI * 2);

      ctx.save();
      ctx.translate(b.x, b.y + bob);
      ctx.rotate(spin);

      // Gold glass card body
      ctx.fillStyle = 'rgba(234, 179, 8, 0.7)';
      ctx.strokeStyle = '#FFFFFF';
      ctx.lineWidth = 2;
      ctx.fillRect(-15, -15, 30, 30);
      ctx.strokeRect(-15, -15, 30, 30);

      // Golden inner core symbol
      ctx.fillStyle = '#FFFFFF';
      ctx.font = 'bold 18px Courier New';
      ctx.textAlign = 'center';
      ctx.textBaseline = 'middle';
      ctx.fillText('?', 0, 0);

      ctx.restore();
    });

    // 8. DRAW WEAPON PROJECTILES
    projectilesRef.current.forEach(p => {
      ctx.fillStyle = p.color;
      ctx.shadowColor = p.color;
      ctx.shadowBlur = 10;
      ctx.beginPath();
      ctx.arc(p.x, p.y, p.radius, 0, Math.PI * 2);
      ctx.fill();
      ctx.shadowBlur = 0; // reset shadow
    });

    // 9. DRAW PLAYERS & BOTS (KARTS)
    kartsRef.current.forEach(kart => {
      if (kart.hp <= 0) return;

      ctx.save();
      ctx.translate(kart.x, kart.y);

      // Visual scales for Jump mechanics (Squash and Stretch)
      let scaleX = 1.0;
      let scaleY = 1.0;
      let jumpHeightOffset = 0;

      if (kart.jumpTimer > 0) {
        // Parabolic jump arc peak
        const progress = kart.jumpTimer / 0.8; // 0.0 to 1.0
        jumpHeightOffset = Math.sin(progress * Math.PI) * 40; // max 40px lift

        // Squash on rise, stretch on peak/landing
        scaleX = 1.0 + Math.sin(progress * Math.PI) * 0.15;
        scaleY = 1.0 - Math.sin(progress * Math.PI) * 0.15;

        // Draw shadow on floor underneath
        ctx.fillStyle = 'rgba(0,0,0,0.3)';
        ctx.beginPath();
        ctx.arc(0, jumpHeightOffset, 16 - (jumpHeightOffset / 4), 0, Math.PI * 2);
        ctx.fill();
      }

      ctx.scale(scaleX, scaleY);
      ctx.translate(0, -jumpHeightOffset); // apply jump height lift

      ctx.rotate(kart.angle);

      // Render flipped upside down
      if (kart.isFlipped) {
        // Draw tires pointing outwards and tilted chassis
        ctx.fillStyle = '#000000';
        ctx.fillRect(-18, -20, 8, 12);
        ctx.fillRect(10, -20, 8, 12);
        ctx.fillRect(-18, 8, 8, 12);
        ctx.fillRect(10, 8, 8, 12);

        // Cracked chassis
        ctx.fillStyle = '#374151';
        ctx.fillRect(-14, -14, 28, 28);
        ctx.strokeStyle = '#9CA3AF';
        ctx.lineWidth = 1.5;
        ctx.strokeRect(-14, -14, 28, 28);
        ctx.restore();
        return;
      }

      // STANDARD KART RENDERING (Geometrical highly-polished vector-like card)

      // A. Four rubber tires
      ctx.fillStyle = '#0F172A';
      // Front Left
      ctx.fillRect(-16, -18, 6, 11);
      // Front Right
      ctx.fillRect(10, -18, 6, 11);
      // Back Left
      ctx.fillRect(-16, 8, 6, 11);
      // Back Right
      ctx.fillRect(10, 8, 6, 11);

      // B. Boost flame trail if speed-boosted
      if (kart.boostTimer > 0) {
        ctx.fillStyle = '#F97316';
        ctx.beginPath();
        ctx.moveTo(-6, 18);
        ctx.lineTo(0, 18 + Math.random() * 20 + 10);
        ctx.lineTo(6, 18);
        ctx.closePath();
        ctx.fill();
      }

      // C. Sleek main vehicle body chassis
      ctx.fillStyle = kart.colorHex;
      ctx.beginPath();
      ctx.roundRect(-12, -15, 24, 30, 8); // nice rounded corners
      ctx.fill();
      ctx.strokeStyle = '#FFFFFF';
      ctx.lineWidth = 1.5;
      ctx.stroke();

      // D. Steering hood stripe
      ctx.fillStyle = '#FFFFFF';
      ctx.fillRect(-2, -15, 4, 12);

      // E. Shiny cyan windshield cockpit
      ctx.fillStyle = '#06B6D4';
      ctx.beginPath();
      ctx.roundRect(-7, -4, 14, 8, 3);
      ctx.fill();

      // F. Drivers head sphere
      ctx.fillStyle = '#FFE4E6';
      ctx.beginPath();
      ctx.arc(0, 5, 4, 0, Math.PI * 2);
      ctx.fill();

      // G. Active Ultimate indicators / Shield aura
      if (kart.shieldTimer > 0) {
        ctx.strokeStyle = '#38BDF8';
        ctx.shadowColor = '#38BDF8';
        ctx.shadowBlur = 12;
        ctx.lineWidth = 3.5;
        ctx.beginPath();
        ctx.arc(0, 0, 24, 0, Math.PI * 2);
        ctx.stroke();
        ctx.shadowBlur = 0; // reset
      }

      // If immune post-spawn
      if (kart.invincibleTimer > 0 && Math.floor(Date.now() / 100) % 2 === 0) {
        ctx.fillStyle = 'rgba(255,255,255,0.4)';
        ctx.beginPath();
        ctx.arc(0, 0, 20, 0, Math.PI * 2);
        ctx.fill();
      }

      ctx.restore(); // end kart rotate transform

      // H. Draw driver name overlay above kart (Must remain unrotated, upright!)
      ctx.fillStyle = '#FFFFFF';
      ctx.font = 'bold 9px Arial';
      ctx.textAlign = 'center';
      
      let tagText = `\${kart.name}`;
      if (kart.id === 'player') tagText += ' [คุณ]';
      
      // Background tag capsule
      ctx.fillStyle = 'rgba(15,23,42,0.7)';
      const textW = ctx.measureText(tagText).width;
      ctx.roundRect(kart.x - textW / 2 - 4, kart.y - jumpHeightOffset - 36, textW + 8, 12, 3);
      ctx.fill();

      ctx.fillStyle = kart.id === 'player' ? '#22C55E' : '#FFFFFF';
      ctx.fillText(tagText, kart.x, kart.y - jumpHeightOffset - 27);

      // Tiny HP bar above name
      const barW = 34;
      ctx.fillStyle = 'rgba(0,0,0,0.6)';
      ctx.fillRect(kart.x - barW / 2, kart.y - jumpHeightOffset - 42, barW, 4);
      
      // HP Fill
      const hpRatio = kart.hp / 100;
      ctx.fillStyle = hpRatio > 0.5 ? '#22C55E' : hpRatio > 0.25 ? '#EAB308' : '#EF4444';
      ctx.fillRect(kart.x - barW / 2, kart.y - jumpHeightOffset - 42, barW * hpRatio, 4);
    });

    // 10. DRAW PARTICLES
    particlesRef.current.forEach(p => {
      ctx.save();
      ctx.globalAlpha = p.life / p.maxLife;

      if (p.type === 'shockwave') {
        ctx.strokeStyle = p.color;
        ctx.lineWidth = 3;
        ctx.beginPath();
        ctx.arc(p.x, p.y, p.radius, 0, Math.PI * 2);
        ctx.stroke();
      } else if (p.type === 'smoke') {
        ctx.fillStyle = p.color;
        ctx.beginPath();
        ctx.arc(p.x, p.y, p.radius, 0, Math.PI * 2);
        ctx.fill();
      } else {
        // standard spark spark lines
        ctx.fillStyle = p.color;
        ctx.beginPath();
        ctx.arc(p.x, p.y, p.radius, 0, Math.PI * 2);
        ctx.fill();
      }

      ctx.restore();
    });

    ctx.restore(); // restore camera transform translation
  };

  return (
    <div className="relative w-full h-full flex flex-col select-none overflow-hidden" ref={containerRef}>
      {/* 1. Canvas element filled viewport */}
      <canvas ref={canvasRef} className="w-full h-full bg-slate-900 block" />

      {/* 2. DYNAMIC DAMAGE GLOW OVERLAYS */}
      {damageIndicator && (
        <div
          className={`absolute inset-0 pointer-events-none transition-all duration-300 border-8 z-30 ${
            damageIndicator === 'left' ? 'border-l-red-500/50' :
            damageIndicator === 'right' ? 'border-r-red-500/50' :
            damageIndicator === 'top' ? 'border-t-red-500/50' : 'border-b-red-500/50'
          } animate-pulse shadow-[inset_0_0_40px_rgba(239,68,68,0.4)]`}
        />
      )}

      {/* 3. ULTIMATE SKILL CINEMATIC OVERLAY */}
      {ultimateCinematic && (
        <div className="absolute top-1/4 left-1/2 transform -translate-x-1/2 -translate-y-1/2 bg-yellow-500/90 border-2 border-white px-6 py-3 rounded-lg text-center shadow-2xl animate-bounce z-40">
          <div className="text-black text-xs font-bold tracking-widest uppercase">🚨 สกิลไม้ตายปลดปล่อย!</div>
          <div className="text-slate-950 text-lg font-extrabold whitespace-pre">{ultimateCinematic}</div>
        </div>
      )}

      {/* 4. PLAYER FLIPPED RECOVER ACTION BUTTON */}
      {playerFlipped && (
        <div className="absolute inset-0 flex items-center justify-center bg-black/40 z-30 pointer-events-auto">
          <button
            onClick={handleRecover}
            className="bg-red-600 hover:bg-red-500 text-white border-4 border-yellow-400 text-xl font-black px-8 py-5 rounded-full shadow-[0_0_20px_rgba(239,68,68,0.8)] animate-pulse"
          >
            🔧 กดปุ่ม: กู้รถด่วน!
          </button>
        </div>
      )}

      {/* 5. TOP ROW STATS BAR OVERLAYS (HUD) */}
      <div className="absolute top-3 inset-x-4 flex justify-between items-start pointer-events-none z-20">
        {/* Left Stats Block */}
        <div className="flex flex-col gap-1.5 bg-slate-950/80 p-3 rounded-lg border border-slate-800">
          <div className="text-white text-xs font-extrabold flex items-center gap-1.5">
            <span className="w-2.5 h-2.5 rounded-full bg-red-500 animate-pulse" />
            ผู้เล่น: <span className="text-yellow-400">{playerKartInfo.name}</span>
          </div>
          
          {/* HP Progress Capsule */}
          <div className="flex items-center gap-2">
            <div className="text-white text-[10px] font-bold w-10">HP {playerHp}%</div>
            <div className="w-28 bg-slate-800 h-2.5 rounded-full overflow-hidden border border-slate-700">
              <div
                style={{ width: `${playerHp}%` }}
                className={`h-full transition-all duration-150 ${
                  playerHp > 50 ? 'bg-green-500' : playerHp > 25 ? 'bg-yellow-500' : 'bg-red-500'
                }`}
              />
            </div>
          </div>

          <div className="flex gap-4 mt-0.5">
            <div className="text-green-400 text-xs font-bold">🎯 คิล: {playerKills}</div>
            <div className="text-red-400 text-xs font-bold">💀 ตาย: {playerDeaths}</div>
          </div>
        </div>

        {/* Center Live Kill Feed Logs */}
        <div className="flex flex-col items-center gap-1 max-w-sm">
          {killFeed[0] && (
            <div
              key={killFeed[0].id}
              className="bg-slate-950/90 text-[10px] text-white px-3 py-1 rounded border border-slate-800 shadow shadow-black text-center font-bold animate-fade-in"
            >
              {killFeed[0].text}
            </div>
          )}
        </div>

        {/* Right Corner: Match Timer & Mini-Map Controls */}
        <div className="flex flex-col items-end gap-2">
          {/* Timer Display */}
          <div className="flex items-center gap-2 bg-slate-950/90 border border-slate-800 px-3 py-1.5 rounded-lg">
            <span className="text-slate-400 text-[10px] font-bold">เวลาที่เหลือ:</span>
            <span className={`text-sm font-black tracking-wider ${matchTime <= 30 ? 'text-red-500 animate-pulse' : 'text-emerald-400'}`}>
              {Math.floor(matchTime / 60)}:{(matchTime % 60).toString().padStart(2, '0')}
            </span>
          </div>

          {/* Pause Trigger */}
          <button
            onClick={() => setIsPaused(true)}
            className="pointer-events-auto bg-slate-900 hover:bg-slate-800 border border-slate-700 text-white text-[10px] font-bold py-1 px-3 rounded-lg"
          >
            ⏸️ พักเกม
          </button>
        </div>
      </div>

      {/* 6. BOTTOM LAYER CONTROLLER HANDLES */}
      <div className="absolute bottom-4 inset-x-4 flex justify-between items-end pointer-events-none z-20">
        {/* LEFT CORNER: Virtual 360 Draggable Analog Joystick */}
        <div className="flex flex-col items-center gap-1 pointer-events-auto">
          <div
            ref={joystickOuterRef}
            onMouseDown={handleJoystickStart}
            onTouchStart={handleJoystickStart}
            className="w-24 h-24 bg-slate-950/70 rounded-full border-4 border-slate-700 flex items-center justify-center cursor-crosshair backdrop-blur-sm"
          >
            <div
              ref={joystickInnerRef}
              style={{
                transform: `translate(${joystickPos.x}px, ${joystickPos.y}px)`,
              }}
              className="w-10 h-10 bg-yellow-500 rounded-full border-2 border-white shadow-lg shadow-black transition-transform duration-75"
            />
          </div>
          <div className="text-[10px] text-slate-400 font-bold bg-slate-950/60 px-2 py-0.5 rounded">
            🕹️ บังคับรถ 360°
          </div>
        </div>

        {/* RIGHT CORNER: Skill & Ultimate trigger layout */}
        <div className="flex items-end gap-3 pointer-events-auto">
          {/* Inventory skill item 1 */}
          <div className="flex flex-col items-center gap-1">
            <button
              onClick={() => handleUseSkill(0)}
              disabled={skills.length === 0}
              className={`w-12 h-12 rounded-full border-2 shadow-lg flex items-center justify-center font-bold text-[9px] transition-all ${
                skills.length > 0
                  ? 'bg-blue-600 hover:bg-blue-500 border-white text-white active:scale-95'
                  : 'bg-slate-950/60 border-slate-800 text-slate-600 cursor-not-allowed'
              }`}
            >
              {skills[0] ? skills[0].substring(0, 4) : 'ว่าง'}
            </button>
            <span className="text-[9px] font-bold text-slate-400 bg-slate-950/60 px-1 rounded">สล็อต 1</span>
          </div>

          {/* Inventory skill item 2 */}
          <div className="flex flex-col items-center gap-1">
            <button
              onClick={() => handleUseSkill(1)}
              disabled={skills.length <= 1}
              className={`w-12 h-12 rounded-full border-2 shadow-lg flex items-center justify-center font-bold text-[9px] transition-all ${
                skills.length > 1
                  ? 'bg-blue-600 hover:bg-blue-500 border-white text-white active:scale-95'
                  : 'bg-slate-950/60 border-slate-800 text-slate-600 cursor-not-allowed'
              }`}
            >
              {skills[1] ? skills[1].substring(0, 4) : 'ว่าง'}
            </button>
            <span className="text-[9px] font-bold text-slate-400 bg-slate-950/60 px-1 rounded">สล็อต 2</span>
          </div>

          {/* ULTIMATE SKILL BUTTON */}
          <div className="flex flex-col items-center gap-1">
            <button
              onClick={handleUseUltimate}
              disabled={ultCooldown > 0}
              className={`w-16 h-16 rounded-full border-4 shadow-xl flex flex-col items-center justify-center font-extrabold text-[10px] transition-all relative ${
                ultCooldown === 0
                  ? 'bg-red-600 hover:bg-red-500 border-yellow-400 text-white animate-pulse active:scale-95'
                  : 'bg-slate-950/80 border-slate-800 text-slate-500 cursor-not-allowed'
              }`}
            >
              {ultCooldown > 0 ? (
                <div className="flex flex-col items-center">
                  <span className="text-slate-400 font-extrabold text-sm">{Math.ceil(ultCooldown)}s</span>
                  <span className="text-[8px] text-slate-500 uppercase">คูลดาวน์</span>
                </div>
              ) : (
                <div className="flex flex-col items-center leading-tight">
                  <span className="text-yellow-300 font-black text-xs">ULTIMATE</span>
                  <span className="text-[8px] tracking-wide text-white font-bold">{playerKartInfo.ultName.split(' ')[0]}</span>
                </div>
              )}
            </button>
            <span className="text-[10px] font-black text-yellow-400 bg-slate-950/70 px-2 py-0.5 rounded border border-slate-800">
              ⚡ อัลติเมต
            </span>
          </div>
        </div>
      </div>
    </div>
  );
};
