class PokdengVoiceSynth {
  private ctx: AudioContext | null = null;

  public initCtx() {
    if (!this.ctx) {
      const AudioCtx = window.AudioContext || (window as any).webkitAudioContext;
      if (AudioCtx) {
        this.ctx = new AudioCtx();
      }
    }
    if (this.ctx && this.ctx.state === 'suspended') {
      this.ctx.resume().catch(() => {});
    }
  }

  public unlock() {
    this.initCtx();
    if (this.ctx && this.ctx.state === 'suspended') {
      this.ctx.resume().then(() => {
        try {
          if (this.ctx) {
            // Warm up audio with an ultra-short inaudible tone to satisfy stricter browser rules
            const osc = this.ctx.createOscillator();
            const gain = this.ctx.createGain();
            osc.connect(gain);
            gain.connect(this.ctx.destination);
            gain.gain.setValueAtTime(0.0001, this.ctx.currentTime);
            osc.start(0);
            osc.stop(0.01);
          }
        } catch (e) {}
      }).catch(() => {});
    }
  }

  public isFullyUnlocked(): boolean {
    return !!(this.ctx && this.ctx.state === 'running');
  }

  playVoice(type: 'female_sweet' | 'female_cute' | 'male_deep' | 'male_goofy' | 'user_voice') {
    try {
      this.initCtx();
      if (!this.ctx) return;

      const now = this.ctx.currentTime;
      
      const osc = this.ctx.createOscillator();
      const osc2 = this.ctx.createOscillator();
      const gainNode = this.ctx.createGain();
      const filter = this.ctx.createBiquadFilter();

      filter.type = 'bandpass';
      filter.Q.value = 8; // Softened resonance for a warmer voice timbre

      switch (type) {
        case 'female_sweet': // Dealer (Beautiful sweet Asian girl style)
          osc.type = 'triangle';
          osc.frequency.setValueAtTime(260, now);
          osc.frequency.exponentialRampToValueAtTime(360, now + 0.15);
          osc.frequency.exponentialRampToValueAtTime(320, now + 0.35);

          osc2.type = 'sine';
          osc2.frequency.setValueAtTime(130, now);
          osc2.frequency.exponentialRampToValueAtTime(180, now + 0.15);

          filter.frequency.setValueAtTime(1000, now);
          filter.frequency.exponentialRampToValueAtTime(1500, now + 0.15);
          filter.frequency.exponentialRampToValueAtTime(1300, now + 0.35);

          gainNode.gain.setValueAtTime(0, now);
          gainNode.gain.linearRampToValueAtTime(0.18, now + 0.05); // Balanced comfortable volume
          gainNode.gain.exponentialRampToValueAtTime(0.001, now + 0.4);
          break;

        case 'female_cute': // Cute anime girl (Bot 2)
          osc.type = 'sine';
          osc.frequency.setValueAtTime(320, now);
          osc.frequency.exponentialRampToValueAtTime(450, now + 0.12);
          osc.frequency.exponentialRampToValueAtTime(400, now + 0.25);

          osc2.type = 'triangle';
          osc2.frequency.setValueAtTime(640, now);
          osc2.frequency.exponentialRampToValueAtTime(900, now + 0.12);

          filter.frequency.setValueAtTime(1200, now);
          filter.frequency.exponentialRampToValueAtTime(1800, now + 0.15);

          gainNode.gain.setValueAtTime(0, now);
          gainNode.gain.linearRampToValueAtTime(0.15, now + 0.04);
          gainNode.gain.exponentialRampToValueAtTime(0.001, now + 0.3);
          break;

        case 'male_deep': // Cool guy (Bot 1)
          osc.type = 'sawtooth';
          osc.frequency.setValueAtTime(110, now);
          osc.frequency.linearRampToValueAtTime(95, now + 0.25);

          osc2.type = 'triangle';
          osc2.frequency.setValueAtTime(220, now);
          osc2.frequency.linearRampToValueAtTime(190, now + 0.25);

          filter.type = 'lowpass';
          filter.frequency.setValueAtTime(250, now); // More low-pass to make it warm and deep

          gainNode.gain.setValueAtTime(0, now);
          gainNode.gain.linearRampToValueAtTime(0.2, now + 0.05);
          gainNode.gain.exponentialRampToValueAtTime(0.001, now + 0.3);
          break;

        case 'male_goofy': // Goofy guy (Bot 3)
          osc.type = 'triangle';
          osc.frequency.setValueAtTime(130, now);
          osc.frequency.exponentialRampToValueAtTime(240, now + 0.1);
          osc.frequency.exponentialRampToValueAtTime(120, now + 0.3);

          osc2.type = 'sawtooth';
          osc2.frequency.setValueAtTime(65, now);
          osc2.frequency.exponentialRampToValueAtTime(120, now + 0.15);

          filter.frequency.setValueAtTime(700, now);
          filter.frequency.exponentialRampToValueAtTime(1000, now + 0.15);
          filter.frequency.exponentialRampToValueAtTime(500, now + 0.35);

          gainNode.gain.setValueAtTime(0, now);
          gainNode.gain.linearRampToValueAtTime(0.18, now + 0.08);
          gainNode.gain.exponentialRampToValueAtTime(0.001, now + 0.45);
          break;

        case 'user_voice': // Player (Cheerful helper)
          osc.type = 'triangle';
          osc.frequency.setValueAtTime(200, now);
          osc.frequency.exponentialRampToValueAtTime(280, now + 0.1);
          osc.frequency.exponentialRampToValueAtTime(260, now + 0.25);

          osc2.type = 'sine';
          osc2.frequency.setValueAtTime(400, now);
          osc2.frequency.exponentialRampToValueAtTime(560, now + 0.12);

          filter.frequency.setValueAtTime(800, now);
          filter.frequency.exponentialRampToValueAtTime(1200, now + 0.12);

          gainNode.gain.setValueAtTime(0, now);
          gainNode.gain.linearRampToValueAtTime(0.18, now + 0.05);
          gainNode.gain.exponentialRampToValueAtTime(0.001, now + 0.35);
          break;
      }

      osc.connect(filter);
      osc2.connect(filter);
      filter.connect(gainNode);
      gainNode.connect(this.ctx.destination);

      osc.start(now);
      osc2.start(now);
      osc.stop(now + 0.6);
      osc2.stop(now + 0.6);
    } catch (e) {
      console.warn('Failed to play voice:', e);
    }
  }

  playGameStart() {
    try {
      this.initCtx();
      if (!this.ctx) return;
      const now = this.ctx.currentTime;
      // Cheerful elegant pentatonic chime arpeggio: C5, E5, G5, C6 (Very warm, non-harsh)
      const notes = [523.25, 659.25, 783.99, 1046.50];
      const masterFilter = this.ctx.createBiquadFilter();
      masterFilter.type = 'lowpass';
      masterFilter.frequency.setValueAtTime(2000, now); // Soften transients

      notes.forEach((freq, i) => {
        const osc = this.ctx!.createOscillator();
        const gainNode = this.ctx!.createGain();
        osc.type = 'sine'; // Sine waves are pure and peaceful
        osc.frequency.setValueAtTime(freq, now + i * 0.08);
        
        gainNode.gain.setValueAtTime(0, now + i * 0.08);
        gainNode.gain.linearRampToValueAtTime(0.10, now + i * 0.08 + 0.03);
        gainNode.gain.exponentialRampToValueAtTime(0.001, now + i * 0.08 + 0.4);
        
        osc.connect(gainNode);
        gainNode.connect(masterFilter);
        osc.start(now + i * 0.08);
        osc.stop(now + i * 0.08 + 0.45);
      });

      masterFilter.connect(this.ctx.destination);
    } catch (e) {
      console.warn('Failed to play start sound:', e);
    }
  }

  playGameOver() {
    try {
      this.initCtx();
      if (!this.ctx) return;
      const now = this.ctx.currentTime;
      // Cozy pleasant major scale chord: G5, B5, D6, G6 with lowpass
      const notes = [783.99, 987.77, 1174.66, 1567.98];
      const masterFilter = this.ctx.createBiquadFilter();
      masterFilter.type = 'lowpass';
      masterFilter.frequency.setValueAtTime(1800, now);

      notes.forEach((freq, i) => {
        const osc = this.ctx!.createOscillator();
        const gainNode = this.ctx!.createGain();
        osc.type = 'sine';
        osc.frequency.setValueAtTime(freq, now + i * 0.05);
        osc.frequency.exponentialRampToValueAtTime(freq * 1.02, now + i * 0.05 + 0.3);
        
        gainNode.gain.setValueAtTime(0, now + i * 0.05);
        gainNode.gain.linearRampToValueAtTime(0.06, now + i * 0.05 + 0.03);
        gainNode.gain.exponentialRampToValueAtTime(0.001, now + i * 0.05 + 0.65);
        
        osc.connect(gainNode);
        gainNode.connect(masterFilter);
        osc.start(now + i * 0.05);
        osc.stop(now + i * 0.05 + 0.7);
      });

      masterFilter.connect(this.ctx.destination);
    } catch (e) {
      console.warn('Failed to play game over sound:', e);
    }
  }

  playDrawCard() {
    try {
      this.initCtx();
      if (!this.ctx) return;
      const now = this.ctx.currentTime;
      const osc = this.ctx.createOscillator();
      const gainNode = this.ctx.createGain();
      const filter = this.ctx.createBiquadFilter();
      
      osc.type = 'triangle';
      osc.frequency.setValueAtTime(150, now);
      osc.frequency.exponentialRampToValueAtTime(300, now + 0.08);
      
      filter.type = 'lowpass';
      filter.frequency.setValueAtTime(600, now);
      filter.frequency.linearRampToValueAtTime(250, now + 0.08);
      
      gainNode.gain.setValueAtTime(0, now);
      gainNode.gain.linearRampToValueAtTime(0.10, now + 0.02);
      gainNode.gain.exponentialRampToValueAtTime(0.001, now + 0.12);
      
      osc.connect(filter);
      filter.connect(gainNode);
      gainNode.connect(this.ctx.destination);
      
      osc.start(now);
      osc.stop(now + 0.15);
    } catch (e) {
      console.warn('Failed to play draw card sound:', e);
    }
  }

  playRevealCard() {
    try {
      this.initCtx();
      if (!this.ctx) return;
      const now = this.ctx.currentTime;
      
      const osc = this.ctx.createOscillator();
      const gainNode = this.ctx.createGain();
      const filter = this.ctx.createBiquadFilter();

      osc.type = 'sine';
      osc.frequency.setValueAtTime(659.25, now); // E5
      osc.frequency.exponentialRampToValueAtTime(987.77, now + 0.05); // B5
      
      filter.type = 'lowpass';
      filter.frequency.setValueAtTime(1500, now); // Soften click

      gainNode.gain.setValueAtTime(0, now);
      gainNode.gain.linearRampToValueAtTime(0.08, now + 0.02);
      gainNode.gain.exponentialRampToValueAtTime(0.001, now + 0.18);
      
      osc.connect(filter);
      filter.connect(gainNode);
      gainNode.connect(this.ctx.destination);
      
      osc.start(now);
      osc.stop(now + 0.2);
    } catch (e) {
      console.warn('Failed to play reveal card sound:', e);
    }
  }

  playThrowTomato() {
    try {
      this.initCtx();
      if (!this.ctx) return;
      const now = this.ctx.currentTime;
      
      // 1. Ascending Whoosh (0.0 -> 0.3s)
      const osc = this.ctx.createOscillator();
      const gainNode = this.ctx.createGain();
      
      osc.type = 'sine';
      osc.frequency.setValueAtTime(140, now);
      osc.frequency.exponentialRampToValueAtTime(500, now + 0.25);
      
      gainNode.gain.setValueAtTime(0, now);
      gainNode.gain.linearRampToValueAtTime(0.06, now + 0.04);
      gainNode.gain.exponentialRampToValueAtTime(0.001, now + 0.28);
      
      osc.connect(gainNode);
      gainNode.connect(this.ctx.destination);
      osc.start(now);
      osc.stop(now + 0.3);
      
      // 2. Soft tomato splash at 0.25s
      const splatOsc = this.ctx.createOscillator();
      const splatGain = this.ctx.createGain();
      const splatFilter = this.ctx.createBiquadFilter();
      
      splatOsc.type = 'triangle';
      splatOsc.frequency.setValueAtTime(150, now + 0.25);
      splatOsc.frequency.exponentialRampToValueAtTime(35, now + 0.45);
      
      splatFilter.type = 'lowpass';
      splatFilter.frequency.setValueAtTime(300, now + 0.25);
      
      splatGain.gain.setValueAtTime(0, now + 0.25);
      splatGain.gain.linearRampToValueAtTime(0.10, now + 0.27);
      splatGain.gain.exponentialRampToValueAtTime(0.001, now + 0.48);
      
      splatOsc.connect(splatFilter);
      splatFilter.connect(splatGain);
      splatGain.connect(this.ctx.destination);
      
      splatOsc.start(now + 0.25);
      splatOsc.stop(now + 0.5);
    } catch (e) {
      console.warn('Failed to play throw sound:', e);
    }
  }
}

export const pokdengVoiceSynth = new PokdengVoiceSynth();

// Auto-unlock AudioContext on first user interaction inside the document to prevent autoplay blocking.
if (typeof window !== 'undefined') {
  const unlockHandler = () => {
    pokdengVoiceSynth.unlock();
    if (pokdengVoiceSynth.isFullyUnlocked()) {
      window.removeEventListener('click', unlockHandler, true);
      window.removeEventListener('touchstart', unlockHandler, true);
      window.removeEventListener('mousedown', unlockHandler, true);
    }
  };
  window.addEventListener('click', unlockHandler, true);
  window.addEventListener('touchstart', unlockHandler, true);
  window.addEventListener('mousedown', unlockHandler, true);
}
