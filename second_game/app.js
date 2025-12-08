/**
 * Find the Number - Drag & Drop Number Sequencing Game
 * Educational game for toddlers ages 2-4
 */

const CONFIG = {
    version: '1.0.0',
    difficulty: {
        easy: { max: 3, name: '1 to 3', ages: '2' },
        medium: { max: 5, name: '1 to 5', ages: '2-3' },
        hard: { max: 10, name: '1 to 10', ages: '3-4' }
    },
    mastery: { roundsRequired: 3, minAccuracy: 80 }
};

const ENCOURAGEMENT = {
    correct: ["Yes!", "Great!", "Awesome!", "Perfect!", "Amazing!", "Super!", "Wonderful!", "You got it!", "Fantastic!", "Excellent!"],
    tryAgain: ["Not quite!", "Try again!", "Find the right one!", "Almost!", "Look carefully!"],
    roundComplete: ["You did it!", "Amazing work!", "All numbers found!", "Great counting!", "Fantastic job!", "You're a star!"]
};

const GameState = {
    currentTarget: 1,
    maxNumber: 5,
    difficulty: 'medium',
    soundEnabled: true,
    voiceEnabled: true,
    highContrast: false,
    extraLarge: false,
    showDots: true,
    guidedMode: true,
    progress: {
        completedRounds: 0,
        correctDrags: 0,
        incorrectDrags: 0,
        masteredNumbers: {},
        totalSessionTime: 0,
        sessionStartTime: Date.now()
    },

    load() {
        try {
            const saved = localStorage.getItem('findNumberState');
            if (saved) {
                const data = JSON.parse(saved);
                Object.assign(this, data);
                this.progress.sessionStartTime = Date.now();
            }
            // Also load global settings
            const global = localStorage.getItem('countLearnGlobal');
            if (global) {
                const g = JSON.parse(global);
                this.soundEnabled = g.soundEnabled ?? true;
                this.voiceEnabled = g.voiceEnabled ?? true;
                this.highContrast = g.highContrast ?? false;
                this.extraLarge = g.extraLarge ?? false;
            }
        } catch (e) { console.error('Load failed:', e); }
    },

    save() {
        try {
            const currentSession = Date.now() - this.progress.sessionStartTime;
            const data = {
                difficulty: this.difficulty,
                soundEnabled: this.soundEnabled,
                voiceEnabled: this.voiceEnabled,
                highContrast: this.highContrast,
                extraLarge: this.extraLarge,
                showDots: this.showDots,
                guidedMode: this.guidedMode,
                progress: { ...this.progress, totalSessionTime: this.progress.totalSessionTime + currentSession }
            };
            localStorage.setItem('findNumberState', JSON.stringify(data));
        } catch (e) { console.error('Save failed:', e); }
    },

    reset() {
        this.progress = {
            completedRounds: 0, correctDrags: 0, incorrectDrags: 0,
            masteredNumbers: {}, totalSessionTime: 0, sessionStartTime: Date.now()
        };
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
        this.tg.BackButton.show();
        this.tg.BackButton.onClick(() => window.location.href = '../index.html');
    }

    haptic(type = 'light') {
        if (!this.isAvailable) return;
        if (['light', 'medium', 'heavy'].includes(type)) this.tg.HapticFeedback.impactOccurred(type);
        else this.tg.HapticFeedback.notificationOccurred(type);
    }
}

class AudioManager {
    constructor() { this.context = null; this.voicesLoaded = false; }

    async init() {
        try {
            this.context = new (window.AudioContext || window.webkitAudioContext)();
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
        gain.gain.setValueAtTime(0.25, this.context.currentTime);
        gain.gain.exponentialRampToValueAtTime(0.01, this.context.currentTime + dur);
        osc.start(this.context.currentTime);
        osc.stop(this.context.currentTime + dur);
    }

    playCorrect() { this.playTone(523.25, 0.12); setTimeout(() => this.playTone(659.25, 0.12), 80); setTimeout(() => this.playTone(783.99, 0.15), 160); }
    playIncorrect() { this.playTone(200, 0.25, 'square'); }
    playDrop() { this.playTone(400, 0.08); }
    playPickup() { this.playTone(600, 0.05); }
    playCelebrate() { [523.25, 659.25, 783.99, 1046.50].forEach((f, i) => setTimeout(() => this.playTone(f, 0.2), i * 100)); }

    speak(text) {
        if (!GameState.voiceEnabled || !window.speechSynthesis) return;
        speechSynthesis.cancel();
        const utt = new SpeechSynthesisUtterance(text);
        utt.rate = 0.85; utt.pitch = 1.1; utt.volume = 0.9;
        if (this.voicesLoaded) {
            const voice = speechSynthesis.getVoices().find(v => v.lang.startsWith('en'));
            if (voice) utt.voice = voice;
        }
        speechSynthesis.speak(utt);
    }
}

class CelebrationSystem {
    constructor() {
        this.canvas = document.getElementById('celebrationCanvas');
        this.ctx = this.canvas.getContext('2d');
        this.particles = [];
        this.animationFrame = null;
    }

    init() { this.resize(); window.addEventListener('resize', () => this.resize()); }
    resize() { this.canvas.width = window.innerWidth; this.canvas.height = window.innerHeight; }

    celebrate(level = 1) {
        const colors = ['#4ECDC4', '#FFE66D', '#FF6B6B', '#95E1D3', '#B19CD9'];
        for (let i = 0; i < level * 35; i++) {
            this.particles.push({
                x: this.canvas.width / 2, y: this.canvas.height * 0.4,
                vx: (Math.random() - 0.5) * 14, vy: (Math.random() - 0.5) * 14 - 6,
                color: colors[Math.floor(Math.random() * colors.length)],
                size: Math.random() * 10 + 5, life: 1, decay: Math.random() * 0.012 + 0.008
            });
        }
        this.animate();
        setTimeout(() => this.stop(), 3000);
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
        this.particles = [];
        this.ctx.clearRect(0, 0, this.canvas.width, this.canvas.height);
    }
}

class DragManager {
    constructor(game) {
        this.game = game;
        this.dragging = null;
        this.dragOffset = { x: 0, y: 0 };
        this.originalPos = { x: 0, y: 0 };
    }

    init() {
        const field = document.getElementById('numbersField');
        
        // Mouse events
        field.addEventListener('mousedown', (e) => this.startDrag(e));
        document.addEventListener('mousemove', (e) => this.moveDrag(e));
        document.addEventListener('mouseup', (e) => this.endDrag(e));

        // Touch events
        field.addEventListener('touchstart', (e) => this.startDrag(e), { passive: false });
        document.addEventListener('touchmove', (e) => this.moveDrag(e), { passive: false });
        document.addEventListener('touchend', (e) => this.endDrag(e));
    }

    getPos(e) {
        if (e.touches && e.touches.length > 0) return { x: e.touches[0].clientX, y: e.touches[0].clientY };
        return { x: e.clientX, y: e.clientY };
    }

    startDrag(e) {
        const target = e.target.closest('.draggable-number');
        if (!target || target.classList.contains('correct') || target.classList.contains('hidden')) return;

        e.preventDefault();
        this.dragging = target;
        this.dragging.classList.add('dragging');

        const rect = target.getBoundingClientRect();
        const pos = this.getPos(e);
        this.dragOffset = { x: pos.x - rect.left - rect.width / 2, y: pos.y - rect.top - rect.height / 2 };
        this.originalPos = { x: target.offsetLeft, y: target.offsetTop };

        this.game.audio.playPickup();
        this.game.telegram.haptic('light');
    }

    moveDrag(e) {
        if (!this.dragging) return;
        e.preventDefault();

        const pos = this.getPos(e);
        const field = document.getElementById('numbersField');
        const fieldRect = field.getBoundingClientRect();

        const x = pos.x - fieldRect.left - this.dragging.offsetWidth / 2;
        const y = pos.y - fieldRect.top - this.dragging.offsetHeight / 2;

        this.dragging.style.left = `${x}px`;
        this.dragging.style.top = `${y}px`;

        // Check if over drop zone
        const dropZone = document.getElementById('dropZone');
        const dropRect = dropZone.getBoundingClientRect();
        const isOver = pos.x > dropRect.left && pos.x < dropRect.right && pos.y > dropRect.top && pos.y < dropRect.bottom;
        dropZone.classList.toggle('drag-over', isOver);
    }

    endDrag(e) {
        if (!this.dragging) return;

        const dropZone = document.getElementById('dropZone');
        dropZone.classList.remove('drag-over');

        const pos = e.changedTouches ? { x: e.changedTouches[0].clientX, y: e.changedTouches[0].clientY } : { x: e.clientX, y: e.clientY };
        const dropRect = dropZone.getBoundingClientRect();
        const isOver = pos.x > dropRect.left && pos.x < dropRect.right && pos.y > dropRect.top && pos.y < dropRect.bottom;

        if (isOver) {
            const num = parseInt(this.dragging.dataset.number);
            this.game.handleDrop(this.dragging, num);
        } else {
            // Return to original position
            this.dragging.style.left = `${this.originalPos.x}px`;
            this.dragging.style.top = `${this.originalPos.y}px`;
        }

        this.dragging.classList.remove('dragging');
        this.dragging = null;
    }
}

class GameController {
    constructor() {
        this.telegram = new TelegramIntegration();
        this.audio = new AudioManager();
        this.celebration = new CelebrationSystem();
        this.drag = new DragManager(this);
        this.elements = {
            loadingScreen: document.getElementById('loadingScreen'),
            gameContainer: document.getElementById('gameContainer'),
            numbersField: document.getElementById('numbersField'),
            dropZone: document.getElementById('dropZone'),
            dropPlaceholder: document.querySelector('.drop-placeholder'),
            dropNumber: document.querySelector('.drop-number'),
            dotsDisplay: document.getElementById('dotsDisplay'),
            instructionText: document.getElementById('instructionText'),
            progressBar: document.getElementById('progressBar'),
            currentProgress: document.getElementById('currentProgress'),
            totalProgress: document.getElementById('totalProgress'),
            celebrationOverlay: document.getElementById('celebrationOverlay'),
            celebrationText: document.querySelector('.celebration-text'),
            celebrationEmoji: document.querySelector('.celebration-emoji'),
            settingsModal: document.getElementById('settingsModal')
        };
        this.roundStats = { correct: 0, incorrect: 0 };
        this.numberElements = [];
    }

    async init() {
        GameState.load();
        this.telegram.init();
        await this.audio.init();
        this.celebration.init();
        this.drag.init();
        this.applySettings();
        this.setupEventListeners();

        setTimeout(() => {
            this.elements.loadingScreen.classList.add('hidden');
            this.elements.gameContainer.classList.remove('hidden');
            this.startNewRound();
        }, 1000);

        setInterval(() => GameState.save(), 10000);
    }

    applySettings() {
        document.body.classList.toggle('high-contrast', GameState.highContrast);
        document.body.classList.toggle('extra-large', GameState.extraLarge);
        document.body.classList.toggle('show-dots', GameState.showDots);
        document.body.classList.toggle('guided-mode', GameState.guidedMode);
        GameState.maxNumber = CONFIG.difficulty[GameState.difficulty].max;
    }

    setupEventListeners() {
        document.getElementById('settingsBtn').addEventListener('click', () => this.openSettings());
        document.querySelector('.close-modal').addEventListener('click', () => this.closeSettings());
        this.elements.settingsModal.addEventListener('click', (e) => { if (e.target === this.elements.settingsModal) this.closeSettings(); });

        document.querySelectorAll('.difficulty-btn').forEach(btn => {
            btn.addEventListener('click', (e) => this.setDifficulty(e.currentTarget.dataset.level));
        });

        const toggles = [
            ['soundToggle', 'soundEnabled'], ['voiceToggle', 'voiceEnabled'],
            ['contrastToggle', 'highContrast', 'high-contrast'], ['largeToggle', 'extraLarge', 'extra-large'],
            ['dotsToggle', 'showDots', 'show-dots'], ['guidedToggle', 'guidedMode', 'guided-mode']
        ];
        toggles.forEach(([id, prop, cls]) => {
            const el = document.getElementById(id);
            if (el) el.addEventListener('change', (e) => {
                GameState[prop] = e.target.checked;
                if (cls) document.body.classList.toggle(cls, e.target.checked);
                if (prop === 'guidedMode') this.updateTargetHighlight();
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

        // Back button
        document.querySelector('.back-btn')?.addEventListener('click', () => {
            this.telegram.haptic('light');
        });
    }

    setDifficulty(level) {
        GameState.difficulty = level;
        GameState.maxNumber = CONFIG.difficulty[level].max;
        document.querySelectorAll('.difficulty-btn').forEach(btn => btn.classList.toggle('active', btn.dataset.level === level));
        this.startNewRound();
        this.telegram.haptic('medium');
        GameState.save();
    }

    startNewRound() {
        GameState.currentTarget = 1;
        GameState.maxNumber = CONFIG.difficulty[GameState.difficulty].max;
        this.roundStats = { correct: 0, incorrect: 0 };
        this.numberElements = [];

        this.elements.totalProgress.textContent = GameState.maxNumber;
        this.updateProgress();
        this.updateInstruction();
        this.updateDots();
        this.resetDropZone();
        this.generateNumbers();

        setTimeout(() => this.audio.speak(`Find number 1!`), 300);
    }

    generateNumbers() {
        this.elements.numbersField.innerHTML = '';
        this.numberElements = [];

        const field = this.elements.numbersField;
        const fieldRect = field.getBoundingClientRect();
        const numSize = GameState.extraLarge ? 100 : 70;
        const padding = 15;

        const positions = [];
        
        for (let i = 1; i <= GameState.maxNumber; i++) {
            let attempts = 0;
            let pos;
            
            do {
                pos = {
                    x: padding + Math.random() * (fieldRect.width - numSize - padding * 2),
                    y: padding + Math.random() * (fieldRect.height - numSize - padding * 2)
                };
                attempts++;
            } while (attempts < 50 && positions.some(p => Math.abs(p.x - pos.x) < numSize && Math.abs(p.y - pos.y) < numSize));

            positions.push(pos);

            const el = document.createElement('div');
            el.className = 'draggable-number';
            el.dataset.number = i;
            el.textContent = i;
            el.style.left = `${pos.x}px`;
            el.style.top = `${pos.y}px`;
            el.setAttribute('role', 'button');
            el.setAttribute('aria-label', `Number ${i}`);

            this.numberElements.push(el);
            field.appendChild(el);
        }

        this.updateTargetHighlight();
    }

    updateTargetHighlight() {
        this.numberElements.forEach(el => {
            const num = parseInt(el.dataset.number);
            el.classList.toggle('target', num === GameState.currentTarget);
        });
    }

    handleDrop(element, number) {
        if (number === GameState.currentTarget) {
            this.handleCorrectDrop(element, number);
        } else {
            this.handleIncorrectDrop(element, number);
        }
    }

    handleCorrectDrop(element, number) {
        this.roundStats.correct++;
        GameState.progress.correctDrags++;

        // Hide the dragged number
        element.classList.add('hidden');

        // Show in drop zone
        this.elements.dropPlaceholder.classList.add('hidden');
        this.elements.dropNumber.textContent = number;
        this.elements.dropNumber.classList.remove('hidden');
        this.elements.dropZone.classList.add('correct');

        // Update dots
        this.updateDots(number);

        // Feedback
        this.audio.playCorrect();
        this.audio.speak(number.toString());
        this.telegram.haptic('success');

        const msg = ENCOURAGEMENT.correct[Math.floor(Math.random() * ENCOURAGEMENT.correct.length)];
        this.elements.instructionText.innerHTML = `<span style="color:#6BCF7F">${msg}</span>`;

        // Next number
        GameState.currentTarget++;

        if (GameState.currentTarget > GameState.maxNumber) {
            setTimeout(() => this.completeRound(), 600);
        } else {
            setTimeout(() => {
                this.resetDropZone();
                this.updateInstruction();
                this.updateProgress();
                this.updateTargetHighlight();
                this.audio.speak(`Find number ${GameState.currentTarget}!`);
            }, 800);
        }
    }

    handleIncorrectDrop(element, number) {
        this.roundStats.incorrect++;
        GameState.progress.incorrectDrags++;

        // Return to original and shake
        element.classList.add('wrong');
        setTimeout(() => element.classList.remove('wrong'), 400);

        this.elements.dropZone.classList.add('wrong');
        setTimeout(() => this.elements.dropZone.classList.remove('wrong'), 400);

        this.audio.playIncorrect();
        this.telegram.haptic('error');

        const msg = ENCOURAGEMENT.tryAgain[Math.floor(Math.random() * ENCOURAGEMENT.tryAgain.length)];
        this.elements.instructionText.innerHTML = `That's ${number}. ${msg} Find <span class="target-number">${GameState.currentTarget}</span>!`;
        this.audio.speak(`That's ${number}. Find number ${GameState.currentTarget}!`);

        // Return element to original position (handled by DragManager)
    }

    resetDropZone() {
        this.elements.dropPlaceholder.classList.remove('hidden');
        this.elements.dropNumber.classList.add('hidden');
        this.elements.dropZone.classList.remove('correct', 'wrong');
    }

    updateInstruction() {
        this.elements.instructionText.innerHTML = `Find and drag number <span class="target-number">${GameState.currentTarget}</span> to the box!`;
    }

    updateProgress() {
        const done = GameState.currentTarget - 1;
        this.elements.currentProgress.textContent = done;
        this.elements.progressBar.style.setProperty('--progress', `${(done / GameState.maxNumber) * 100}%`);
    }

    updateDots(filledCount = 0) {
        this.elements.dotsDisplay.innerHTML = '';
        const target = GameState.currentTarget;
        
        for (let i = 0; i < target; i++) {
            const dot = document.createElement('div');
            dot.className = 'dot' + (i < filledCount ? ' filled' : '');
            this.elements.dotsDisplay.appendChild(dot);
        }
    }

    completeRound() {
        const total = this.roundStats.correct + this.roundStats.incorrect;
        const accuracy = total > 0 ? Math.round((this.roundStats.correct / total) * 100) : 100;

        GameState.updateMastery(GameState.maxNumber, this.roundStats.correct, total);
        GameState.progress.completedRounds++;

        let msg = ENCOURAGEMENT.roundComplete[Math.floor(Math.random() * ENCOURAGEMENT.roundComplete.length)];
        if (GameState.isMastered(GameState.maxNumber)) {
            msg = `🏆 You mastered 1 to ${GameState.maxNumber}!`;
        }

        this.elements.celebrationText.textContent = msg;
        const emojis = accuracy >= 80 ? ['🎉', '⭐', '🌟', '✨', '🎊', '🏆'] : ['👍', '😊', '💪'];
        this.elements.celebrationEmoji.textContent = emojis[Math.floor(Math.random() * emojis.length)];

        const accEl = document.querySelector('.accuracy-display');
        if (accEl) accEl.textContent = `Accuracy: ${accuracy}%`;

        this.elements.celebrationOverlay.classList.remove('hidden');
        this.celebration.celebrate(Math.min(5, Math.floor(accuracy / 20)));
        this.audio.playCelebrate();
        this.telegram.haptic('success');
        this.audio.speak(msg);
        GameState.save();
    }

    openSettings() {
        this.elements.settingsModal.classList.remove('hidden');
        this.updateStats();

        document.getElementById('soundToggle').checked = GameState.soundEnabled;
        document.getElementById('voiceToggle').checked = GameState.voiceEnabled;
        document.getElementById('contrastToggle').checked = GameState.highContrast;
        document.getElementById('largeToggle').checked = GameState.extraLarge;
        document.getElementById('dotsToggle').checked = GameState.showDots;
        document.getElementById('guidedToggle').checked = GameState.guidedMode;

        document.querySelectorAll('.difficulty-btn').forEach(btn => btn.classList.toggle('active', btn.dataset.level === GameState.difficulty));
    }

    closeSettings() {
        this.elements.settingsModal.classList.add('hidden');
    }

    updateStats() {
        document.getElementById('totalRounds').textContent = GameState.progress.completedRounds;
        const totalTime = GameState.progress.totalSessionTime + (Date.now() - GameState.progress.sessionStartTime);
        document.getElementById('totalTime').textContent = `${Math.floor(totalTime / 60000)}m`;
        const total = GameState.progress.correctDrags + GameState.progress.incorrectDrags;
        const acc = total > 0 ? Math.round((GameState.progress.correctDrags / total) * 100) : 100;
        document.getElementById('overallAccuracy').textContent = `${acc}%`;
    }
}

document.addEventListener('DOMContentLoaded', () => new GameController().init());
