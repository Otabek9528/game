/**
 * Count & Learn - Educational Counting Game for Toddlers
 * REVISED v2.0: Proper sequential counting with learning mechanics
 */

const CONFIG = {
    version: '2.0.0',
    difficulty: {
        easy: { max: 3, name: 'Count to 3', ages: '1-2' },
        medium: { max: 5, name: 'Count to 5', ages: '2-3' },
        hard: { max: 10, name: 'Count to 10', ages: '3-4' }
    },
    animation: { fast: 200, normal: 300, slow: 500 },
    celebration: { confettiDuration: 3000 },
    mastery: { roundsRequired: 3, minAccuracy: 80 }
};

const THEMES = {
    farm: {
        name: 'Farm Animals', emoji: '🐄',
        objects: ['🐄', '🐷', '🐑', '🐔', '🐴', '🦆', '🐓', '🐇', '🐕', '🐈'],
        background: 'linear-gradient(135deg, #95E1D3 0%, #A8E6CF 100%)'
    },
    ocean: {
        name: 'Ocean Creatures', emoji: '🐠',
        objects: ['🐠', '🐟', '🐡', '🦈', '🐙', '🦀', '🐚', '🦞', '🐬', '🦑'],
        background: 'linear-gradient(135deg, #4ECDC4 0%, #556FB5 100%)'
    },
    forest: {
        name: 'Forest Friends', emoji: '🦊',
        objects: ['🦊', '🐻', '🦝', '🦌', '🐿️', '🦉', '🦅', '🐗', '🦫', '🐺'],
        background: 'linear-gradient(135deg, #A8E6CF 0%, #78C5A8 100%)'
    },
    vehicles: {
        name: 'Vehicles', emoji: '🚗',
        objects: ['🚗', '🚕', '🚙', '🚌', '🚎', '🏎️', '🚓', '🚑', '🚒', '🚐'],
        background: 'linear-gradient(135deg, #FFD93D 0%, #FFB84D 100%)'
    },
    fruits: {
        name: 'Fruits & Veggies', emoji: '🍎',
        objects: ['🍎', '🍌', '🍊', '🍇', '🍓', '🍉', '🥕', '🥦', '🍅', '🫐'],
        background: 'linear-gradient(135deg, #FF6B6B 0%, #FFD93D 100%)'
    },
    party: {
        name: 'Party Time', emoji: '🎈',
        objects: ['🎈', '🎁', '🎂', '🎉', '🎊', '🎪', '🎨', '🎭', '🎯', '🎲'],
        background: 'linear-gradient(135deg, #FFB6C1 0%, #A8E6CF 100%)'
    }
};

const ENCOURAGEMENT = {
    correct: ["Yes!", "Great!", "Awesome!", "Perfect!", "Amazing!", "Super!", "Wonderful!", "Excellent!", "Fantastic!", "Good job!"],
    tryAgain: ["Almost!", "Try again!", "Not quite!", "Find the next one!", "Look for the number!", "You can do it!"],
    roundComplete: ["You counted to {n}!", "Amazing counting!", "You're a star!", "Fantastic work!", "Great job!", "You did it!"]
};

const GameState = {
    currentNumber: 0,
    expectedNumber: 1,
    targetNumber: 3,
    currentTheme: 'farm',
    currentObject: '🐄',
    difficulty: 'medium',
    soundEnabled: true,
    voiceEnabled: true,
    musicEnabled: false,
    highContrast: false,
    extraLarge: false,
    slowAnimations: false,
    showNumbers: true,
    guidedMode: true,
    progress: {
        totalCounts: 0, correctTaps: 0, incorrectTaps: 0,
        masteredNumbers: {}, totalSessionTime: 0,
        sessionStartTime: Date.now(), completedRounds: 0
    },
    performance: { consecutiveSuccess: 0 },

    load() {
        try {
            const saved = localStorage.getItem('countLearnState');
            if (saved) {
                const data = JSON.parse(saved);
                Object.assign(this, data);
                this.progress.sessionStartTime = Date.now();
            }
        } catch (e) { console.error('Load failed:', e); }
    },

    save() {
        try {
            const currentSessionTime = Date.now() - this.progress.sessionStartTime;
            const data = {
                difficulty: this.difficulty, currentTheme: this.currentTheme,
                soundEnabled: this.soundEnabled, voiceEnabled: this.voiceEnabled,
                musicEnabled: this.musicEnabled, highContrast: this.highContrast,
                extraLarge: this.extraLarge, slowAnimations: this.slowAnimations,
                showNumbers: this.showNumbers, guidedMode: this.guidedMode,
                progress: { ...this.progress, totalSessionTime: this.progress.totalSessionTime + currentSessionTime },
                performance: this.performance
            };
            localStorage.setItem('countLearnState', JSON.stringify(data));
            if (window.Telegram?.WebApp?.CloudStorage) {
                Telegram.WebApp.CloudStorage.setItem('gameState', JSON.stringify(data));
            }
        } catch (e) { console.error('Save failed:', e); }
    },

    reset() {
        this.progress = { totalCounts: 0, correctTaps: 0, incorrectTaps: 0, masteredNumbers: {}, totalSessionTime: 0, sessionStartTime: Date.now(), completedRounds: 0 };
        this.performance = { consecutiveSuccess: 0 };
        this.save();
    },

    isMastered(num) {
        const m = this.progress.masteredNumbers[num];
        return m && m.rounds >= CONFIG.mastery.roundsRequired && m.accuracy >= CONFIG.mastery.minAccuracy;
    },

    updateMastery(num, correct, total) {
        if (!this.progress.masteredNumbers[num]) {
            this.progress.masteredNumbers[num] = { rounds: 0, accuracy: 0, totalCorrect: 0, totalAttempts: 0 };
        }
        const m = this.progress.masteredNumbers[num];
        m.rounds++;
        m.totalCorrect += correct;
        m.totalAttempts += total;
        m.accuracy = Math.round((m.totalCorrect / m.totalAttempts) * 100);
    }
};

class TelegramIntegration {
    constructor() {
        this.tg = window.Telegram?.WebApp;
        this.isAvailable = !!this.tg;
    }

    init() {
        if (!this.isAvailable) return;
        this.tg.expand();
        this.tg.enableClosingConfirmation();
        this.tg.BackButton.onClick(() => {
            const modal = document.getElementById('settingsModal');
            if (modal.classList.contains('hidden')) this.tg.close();
            else { modal.classList.add('hidden'); this.tg.BackButton.hide(); }
        });
    }

    haptic(type = 'light') {
        if (!this.isAvailable) return;
        const impacts = ['light', 'medium', 'heavy'];
        if (impacts.includes(type)) this.tg.HapticFeedback.impactOccurred(type);
        else this.tg.HapticFeedback.notificationOccurred(type);
    }
}

class AudioManager {
    constructor() { this.context = null; this.initialized = false; this.voicesLoaded = false; }

    async init() {
        if (this.initialized) return;
        try {
            this.context = new (window.AudioContext || window.webkitAudioContext)();
            this.initialized = true;
            if (window.speechSynthesis) {
                if (speechSynthesis.getVoices().length > 0) this.voicesLoaded = true;
                else speechSynthesis.addEventListener('voiceschanged', () => { this.voicesLoaded = true; }, { once: true });
            }
        } catch (e) { console.error('Audio init failed:', e); }
    }

    playTone(freq, dur, type = 'sine') {
        if (!this.context || !GameState.soundEnabled) return;
        const osc = this.context.createOscillator();
        const gain = this.context.createGain();
        osc.connect(gain); gain.connect(this.context.destination);
        osc.type = type; osc.frequency.value = freq;
        gain.gain.setValueAtTime(0.3, this.context.currentTime);
        gain.gain.exponentialRampToValueAtTime(0.01, this.context.currentTime + dur);
        osc.start(this.context.currentTime);
        osc.stop(this.context.currentTime + dur);
    }

    playCorrect() { this.playTone(523.25, 0.15); setTimeout(() => this.playTone(659.25, 0.15), 100); }
    playIncorrect() { this.playTone(200, 0.2, 'square'); }
    playCelebrate() { [523.25, 659.25, 783.99, 1046.50].forEach((f, i) => setTimeout(() => this.playTone(f, 0.25), i * 120)); }

    speak(text) {
        if (!GameState.voiceEnabled || !window.speechSynthesis) return;
        speechSynthesis.cancel();
        const utt = new SpeechSynthesisUtterance(text);
        utt.rate = 0.85; utt.pitch = 1.1; utt.volume = 0.9;
        if (this.voicesLoaded) {
            const voice = speechSynthesis.getVoices().find(v => v.lang.startsWith('en') && (v.name.includes('Female') || v.name.includes('Samantha')));
            if (voice) utt.voice = voice;
        }
        speechSynthesis.speak(utt);
    }

    speakNumber(num) { this.speak(num.toString()); }
}

class CelebrationSystem {
    constructor() {
        this.canvas = document.getElementById('celebrationCanvas');
        this.ctx = this.canvas.getContext('2d');
        this.particles = []; this.animationFrame = null;
    }

    init() { this.resizeCanvas(); window.addEventListener('resize', () => this.resizeCanvas()); }
    resizeCanvas() { this.canvas.width = window.innerWidth; this.canvas.height = window.innerHeight; }

    celebrate(level = 1) {
        const colors = ['#FF6B6B', '#4ECDC4', '#FFE66D', '#95E1D3', '#FFB6C1'];
        for (let i = 0; i < level * 40; i++) {
            this.particles.push({
                x: this.canvas.width / 2, y: this.canvas.height * 0.4,
                vx: (Math.random() - 0.5) * 12, vy: (Math.random() - 0.5) * 12 - 5,
                color: colors[Math.floor(Math.random() * colors.length)],
                size: Math.random() * 10 + 5, life: 1, decay: Math.random() * 0.015 + 0.008
            });
        }
        this.animate();
        setTimeout(() => this.stop(), CONFIG.celebration.confettiDuration);
    }

    animate() {
        this.ctx.clearRect(0, 0, this.canvas.width, this.canvas.height);
        this.particles = this.particles.filter(p => {
            p.x += p.vx; p.y += p.vy; p.vy += 0.25; p.life -= p.decay;
            if (p.life <= 0) return false;
            this.ctx.globalAlpha = p.life; this.ctx.fillStyle = p.color;
            this.ctx.beginPath(); this.ctx.arc(p.x, p.y, p.size, 0, Math.PI * 2); this.ctx.fill();
            return true;
        });
        if (this.particles.length > 0) this.animationFrame = requestAnimationFrame(() => this.animate());
    }

    stop() {
        if (this.animationFrame) cancelAnimationFrame(this.animationFrame);
        this.animationFrame = null; this.particles = [];
        this.ctx.clearRect(0, 0, this.canvas.width, this.canvas.height);
    }
}

class GameController {
    constructor() {
        this.telegram = new TelegramIntegration();
        this.audio = new AudioManager();
        this.celebration = new CelebrationSystem();
        this.elements = {
            loadingScreen: document.getElementById('loadingScreen'),
            gameContainer: document.getElementById('gameContainer'),
            numberDisplay: document.querySelector('.number-value'),
            numberLabel: document.querySelector('.number-label'),
            objectsGrid: document.getElementById('objectsGrid'),
            progressBar: document.getElementById('progressBar'),
            celebrationOverlay: document.getElementById('celebrationOverlay'),
            celebrationText: document.querySelector('.celebration-text'),
            celebrationEmoji: document.querySelector('.celebration-emoji'),
            settingsModal: document.getElementById('settingsModal')
        };
        this.roundStats = { correct: 0, incorrect: 0 };
        this.objectElements = [];
    }

    async init() {
        GameState.load();
        this.telegram.init();
        await this.audio.init();
        this.celebration.init();
        this.applySettings();
        this.setupEventListeners();
        setTimeout(() => {
            this.elements.loadingScreen.classList.add('hidden');
            this.elements.gameContainer.classList.remove('hidden');
            this.startNewRound();
        }, 1500);
        setInterval(() => GameState.save(), 10000);
    }

    applySettings() {
        document.body.classList.toggle('high-contrast', GameState.highContrast);
        document.body.classList.toggle('extra-large', GameState.extraLarge);
        document.body.classList.toggle('slow-animations', GameState.slowAnimations);
        document.body.classList.toggle('show-numbers', GameState.showNumbers);
        document.body.classList.toggle('guided-mode', GameState.guidedMode);
        this.updateTheme(GameState.currentTheme);
    }

    setupEventListeners() {
        document.getElementById('settingsBtn').addEventListener('click', () => this.openSettings());
        document.querySelectorAll('.theme-btn').forEach(btn => btn.addEventListener('click', e => { this.updateTheme(e.currentTarget.dataset.theme); this.telegram.haptic('light'); }));
        document.querySelector('.close-modal').addEventListener('click', () => this.closeSettings());
        document.querySelectorAll('.difficulty-btn').forEach(btn => btn.addEventListener('click', e => this.setDifficulty(e.currentTarget.dataset.level)));

        const toggles = [
            ['soundToggle', 'soundEnabled'], ['voiceToggle', 'voiceEnabled'], ['musicToggle', 'musicEnabled'],
            ['contrastToggle', 'highContrast', 'high-contrast'], ['largeToggle', 'extraLarge', 'extra-large'],
            ['slowToggle', 'slowAnimations', 'slow-animations'], ['numbersToggle', 'showNumbers', 'show-numbers'],
            ['guidedToggle', 'guidedMode', 'guided-mode']
        ];
        toggles.forEach(([id, prop, cls]) => {
            const el = document.getElementById(id);
            if (el) el.addEventListener('change', e => {
                GameState[prop] = e.target.checked;
                if (cls) document.body.classList.toggle(cls, e.target.checked);
                if (prop === 'guidedMode') this.updateHighlight();
                GameState.save();
            });
        });

        document.getElementById('resetProgress').addEventListener('click', () => {
            if (confirm('Reset all progress?')) { GameState.reset(); this.updateStats(); this.telegram.haptic('success'); }
        });
        document.querySelector('.next-level-btn').addEventListener('click', () => {
            this.elements.celebrationOverlay.classList.add('hidden');
            this.celebration.stop();
            this.startNewRound();
        });
        this.elements.settingsModal.addEventListener('click', e => { if (e.target === this.elements.settingsModal) this.closeSettings(); });
    }

    updateTheme(themeName) {
        if (!THEMES[themeName]) return;
        GameState.currentTheme = themeName;
        document.body.style.background = THEMES[themeName].background;
        document.querySelectorAll('.theme-btn').forEach(btn => btn.classList.toggle('active', btn.dataset.theme === themeName));
        this.startNewRound();
        GameState.save();
    }

    setDifficulty(level) {
        GameState.difficulty = level;
        GameState.targetNumber = CONFIG.difficulty[level].max;
        document.querySelectorAll('.difficulty-btn').forEach(btn => btn.classList.toggle('active', btn.dataset.level === level));
        this.startNewRound();
        this.telegram.haptic('medium');
        GameState.save();
    }

    startNewRound() {
        GameState.currentNumber = 0;
        GameState.expectedNumber = 1;
        GameState.targetNumber = CONFIG.difficulty[GameState.difficulty].max;
        this.roundStats = { correct: 0, incorrect: 0 };
        this.objectElements = [];

        const theme = THEMES[GameState.currentTheme];
        GameState.currentObject = theme.objects[Math.floor(Math.random() * theme.objects.length)];

        this.elements.numberDisplay.textContent = '0';
        this.elements.numberLabel.textContent = 'Tap number 1!';
        this.elements.progressBar.style.width = '0%';
        this.generateObjects();
        setTimeout(() => this.audio.speak(`Let's count to ${GameState.targetNumber}! Tap number 1.`), 300);
    }

    generateObjects() {
        const count = GameState.targetNumber;
        this.elements.objectsGrid.innerHTML = '';
        this.objectElements = [];

        const positions = Array.from({ length: count }, (_, i) => i);
        for (let i = positions.length - 1; i > 0; i--) { const j = Math.floor(Math.random() * (i + 1)); [positions[i], positions[j]] = [positions[j], positions[i]]; }

        for (let i = 0; i < count; i++) {
            const obj = document.createElement('div');
            obj.className = 'counting-object';
            obj.dataset.number = i + 1;

            const emoji = document.createElement('span');
            emoji.className = 'object-emoji';
            emoji.textContent = GameState.currentObject;

            const num = document.createElement('span');
            num.className = 'object-number';
            num.textContent = i + 1;

            obj.appendChild(emoji);
            obj.appendChild(num);
            obj.setAttribute('role', 'button');
            obj.setAttribute('aria-label', `Number ${i + 1}`);
            obj.setAttribute('tabindex', '0');
            obj.style.animationDelay = `${positions[i] * 0.08}s`;

            obj.addEventListener('click', () => this.handleObjectTap(obj, i + 1));
            obj.addEventListener('keypress', e => { if (e.key === 'Enter' || e.key === ' ') this.handleObjectTap(obj, i + 1); });

            this.objectElements.push(obj);
            this.elements.objectsGrid.appendChild(obj);
        }
        this.updateHighlight();
    }

    handleObjectTap(obj, number) {
        if (obj.classList.contains('counted')) return;
        if (number === GameState.expectedNumber) this.handleCorrectTap(obj, number);
        else this.handleIncorrectTap(obj, number, GameState.expectedNumber);
    }

    handleCorrectTap(obj, number) {
        this.roundStats.correct++;
        GameState.progress.correctTaps++;
        GameState.progress.totalCounts++;
        GameState.currentNumber = number;
        GameState.expectedNumber = number + 1;

        obj.classList.add('counted', 'correct-tap');
        this.elements.numberDisplay.classList.add('counting');
        setTimeout(() => this.elements.numberDisplay.classList.remove('counting'), CONFIG.animation.normal);
        this.elements.numberDisplay.textContent = number;
        this.elements.progressBar.style.width = `${(number / GameState.targetNumber) * 100}%`;

        this.audio.playCorrect();
        this.audio.speakNumber(number);
        this.telegram.haptic('light');

        if (number < GameState.targetNumber) {
            this.elements.numberLabel.textContent = `Great! Now tap ${number + 1}!`;
            this.updateHighlight();
        } else {
            setTimeout(() => this.completeRound(), 600);
        }
    }

    handleIncorrectTap(obj, tapped, expected) {
        this.roundStats.incorrect++;
        GameState.progress.incorrectTaps++;

        obj.classList.add('shake', 'wrong-tap');
        setTimeout(() => obj.classList.remove('shake', 'wrong-tap'), 500);

        this.audio.playIncorrect();
        this.telegram.haptic('warning');
        this.elements.numberLabel.textContent = `That's ${tapped}. Find ${expected}!`;
        this.audio.speak(`That's ${tapped}. Find number ${expected}!`);

        if (GameState.guidedMode) {
            const correct = this.objectElements.find(o => parseInt(o.dataset.number) === expected);
            if (correct) { correct.classList.add('hint-pulse'); setTimeout(() => correct.classList.remove('hint-pulse'), 1000); }
        }
    }

    updateHighlight() {
        this.objectElements.forEach(obj => obj.classList.remove('next-target'));
        if (GameState.guidedMode && GameState.expectedNumber <= GameState.targetNumber) {
            const next = this.objectElements.find(o => parseInt(o.dataset.number) === GameState.expectedNumber && !o.classList.contains('counted'));
            if (next) next.classList.add('next-target');
        }
    }

    completeRound() {
        const total = this.roundStats.correct + this.roundStats.incorrect;
        const accuracy = total > 0 ? Math.round((this.roundStats.correct / total) * 100) : 100;

        GameState.updateMastery(GameState.targetNumber, this.roundStats.correct, total);
        GameState.progress.completedRounds++;
        GameState.performance.consecutiveSuccess = accuracy >= 80 ? GameState.performance.consecutiveSuccess + 1 : 0;

        let msg = ENCOURAGEMENT.roundComplete[Math.floor(Math.random() * ENCOURAGEMENT.roundComplete.length)].replace('{n}', GameState.targetNumber);
        if (GameState.isMastered(GameState.targetNumber)) msg = `🏆 You mastered counting to ${GameState.targetNumber}!`;

        this.elements.celebrationText.textContent = msg;
        const emojis = accuracy >= 80 ? ['🎉', '⭐', '🌟', '✨', '🎊', '🏆'] : ['👍', '😊', '💪'];
        this.elements.celebrationEmoji.textContent = emojis[Math.floor(Math.random() * emojis.length)];

        const accEl = document.querySelector('.accuracy-display');
        if (accEl) accEl.textContent = `Accuracy: ${accuracy}%`;

        this.elements.celebrationOverlay.classList.remove('hidden');
        this.celebration.celebrate(Math.min(5, Math.floor(GameState.performance.consecutiveSuccess / 2) + 1));
        this.audio.playCelebrate();
        this.telegram.haptic('success');
        this.audio.speak(msg);
        GameState.save();
    }

    openSettings() {
        this.elements.settingsModal.classList.remove('hidden');
        this.updateStats();
        ['soundToggle', 'voiceToggle', 'musicToggle', 'contrastToggle', 'largeToggle', 'slowToggle', 'numbersToggle', 'guidedToggle'].forEach(id => {
            const el = document.getElementById(id);
            if (el) el.checked = GameState[{ soundToggle: 'soundEnabled', voiceToggle: 'voiceEnabled', musicToggle: 'musicEnabled', contrastToggle: 'highContrast', largeToggle: 'extraLarge', slowToggle: 'slowAnimations', numbersToggle: 'showNumbers', guidedToggle: 'guidedMode' }[id]];
        });
        document.querySelectorAll('.difficulty-btn').forEach(btn => btn.classList.toggle('active', btn.dataset.level === GameState.difficulty));
        if (this.telegram.isAvailable) this.telegram.tg.BackButton.show();
    }

    closeSettings() {
        this.elements.settingsModal.classList.add('hidden');
        if (this.telegram.isAvailable) this.telegram.tg.BackButton.hide();
    }

    updateStats() {
        document.getElementById('totalCounts').textContent = GameState.progress.totalCounts;
        const totalTime = GameState.progress.totalSessionTime + (Date.now() - GameState.progress.sessionStartTime);
        document.getElementById('sessionTime').textContent = `${Math.floor(totalTime / 60000)}m`;
        let mastered = 0;
        for (let i = 1; i <= 10; i++) if (GameState.isMastered(i)) mastered++;
        document.getElementById('masteredNumbers').textContent = mastered;
        const total = GameState.progress.correctTaps + GameState.progress.incorrectTaps;
        const acc = total > 0 ? Math.round((GameState.progress.correctTaps / total) * 100) : 100;
        const accEl = document.getElementById('overallAccuracy');
        if (accEl) accEl.textContent = `${acc}%`;
    }
}

document.addEventListener('DOMContentLoaded', () => new GameController().init());
