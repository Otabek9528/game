/**
 * Count & Learn - Educational Counting Game for Toddlers
 * Production-grade Telegram Web App
 * Ages 1-4, Counts 1-10
 */

// ===================================
// CONFIGURATION & CONSTANTS
// ===================================

const CONFIG = {
    version: '1.0.0',
    difficulty: {
        easy: { max: 3, name: 'Count to 3', ages: '1-2' },
        medium: { max: 5, name: 'Count to 5', ages: '2-3' },
        hard: { max: 10, name: 'Count to 10', ages: '3-4' }
    },
    animation: {
        fast: 200,
        normal: 300,
        slow: 500,
        verySlow: 1000
    },
    celebration: {
        confettiDuration: 3000,
        confettiCount: 150
    },
    session: {
        autoSaveInterval: 10000, // 10 seconds
        autoPauseAfter: 900000  // 15 minutes
    }
};

// Theme definitions with emojis and sounds
const THEMES = {
    farm: {
        name: 'Farm Animals',
        emoji: '🐄',
        objects: ['🐄', '🐷', '🐑', '🐔', '🐴', '🦆', '🐓', '🐇', '🐕', '🐈'],
        sounds: ['moo', 'oink', 'baa', 'cluck', 'neigh', 'quack', 'cock-a-doodle', 'hop', 'woof', 'meow'],
        background: 'linear-gradient(135deg, #95E1D3 0%, #A8E6CF 100%)'
    },
    ocean: {
        name: 'Ocean Creatures',
        emoji: '🐠',
        objects: ['🐠', '🐟', '🐡', '🦈', '🐙', '🦀', '🐚', '🦞', '🐬', '🦑'],
        sounds: ['splash', 'bubble', 'splash', 'splash', 'bubble', 'bubble', 'splash', 'bubble', 'splash', 'bubble'],
        background: 'linear-gradient(135deg, #4ECDC4 0%, #556FB5 100%)'
    },
    forest: {
        name: 'Forest Friends',
        emoji: '🦊',
        objects: ['🦊', '🐻', '🦝', '🦌', '🐿️', '🦉', '🦅', '🐗', '🦫', '🐺'],
        sounds: ['chirp', 'growl', 'chirp', 'chirp', 'chirp', 'hoot', 'screech', 'grunt', 'chirp', 'howl'],
        background: 'linear-gradient(135deg, #A8E6CF 0%, #78C5A8 100%)'
    },
    vehicles: {
        name: 'Vehicles',
        emoji: '🚗',
        objects: ['🚗', '🚕', '🚙', '🚌', '🚎', '🏎️', '🚓', '🚑', '🚒', '🚐'],
        sounds: ['vroom', 'honk', 'vroom', 'honk', 'vroom', 'vroom', 'siren', 'siren', 'siren', 'vroom'],
        background: 'linear-gradient(135deg, #FFD93D 0%, #FFB84D 100%)'
    },
    fruits: {
        name: 'Fruits & Veggies',
        emoji: '🍎',
        objects: ['🍎', '🍌', '🍊', '🍇', '🍓', '🍉', '🥕', '🥦', '🍅', '🫐'],
        sounds: ['crunch', 'squish', 'crunch', 'squish', 'crunch', 'crunch', 'crunch', 'crunch', 'squish', 'squish'],
        background: 'linear-gradient(135deg, #FF6B6B 0%, #FFD93D 100%)'
    },
    party: {
        name: 'Party Time',
        emoji: '🎈',
        objects: ['🎈', '🎁', '🎂', '🎉', '🎊', '🎪', '🎨', '🎭', '🎯', '🎲'],
        sounds: ['pop', 'celebrate', 'celebrate', 'celebrate', 'celebrate', 'celebrate', 'pop', 'pop', 'pop', 'pop'],
        background: 'linear-gradient(135deg, #FFB6C1 0%, #A8E6CF 100%)'
    }
};

// Encouragement phrases for positive reinforcement
const ENCOURAGEMENT = [
    "Awesome!", "You're so smart!", "Great job!", "Wow!", "Amazing!",
    "You did it!", "Perfect!", "Excellent!", "Fantastic!", "Super!",
    "Wonderful!", "Brilliant!", "Outstanding!", "Incredible!", "Magnificent!",
    "Spectacular!", "Terrific!", "Marvelous!", "Fabulous!", "Phenomenal!",
    "Stupendous!", "Superb!", "Splendid!", "Remarkable!", "Extraordinary!",
    "You're a star!", "Keep going!", "Yes!", "Beautiful!", "Love it!",
    "So good!", "Well done!", "Hooray!", "Yay!", "Bravo!",
    "Nice work!", "Good counting!", "Smart cookie!", "You rock!", "High five!"
];

// ===================================
// STATE MANAGEMENT
// ===================================

const GameState = {
    // Current game state
    currentNumber: 0,
    targetNumber: 3,
    currentTheme: 'farm',
    difficulty: 'medium',
    
    // Settings
    soundEnabled: true,
    voiceEnabled: true,
    musicEnabled: false,
    highContrast: false,
    extraLarge: false,
    slowAnimations: false,
    
    // Progress tracking
    progress: {
        totalCounts: 0,
        masteredNumbers: [],
        sessionStartTime: Date.now(),
        sessionTime: 0,
        completedRounds: 0
    },
    
    // Performance tracking
    performance: {
        successRate: 100,
        averageTime: 0,
        consecutiveSuccess: 0
    },
    
    // Initialize from localStorage
    load() {
        try {
            const saved = localStorage.getItem('countLearnState');
            if (saved) {
                const data = JSON.parse(saved);
                Object.assign(this, data);
                
                // Reset session time
                this.progress.sessionStartTime = Date.now();
            }
        } catch (e) {
            console.error('Failed to load state:', e);
        }
    },
    
    // Save to localStorage
    save() {
        try {
            // Calculate session time
            this.progress.sessionTime = Date.now() - this.progress.sessionStartTime;
            
            const data = {
                difficulty: this.difficulty,
                currentTheme: this.currentTheme,
                soundEnabled: this.soundEnabled,
                voiceEnabled: this.voiceEnabled,
                musicEnabled: this.musicEnabled,
                highContrast: this.highContrast,
                extraLarge: this.extraLarge,
                slowAnimations: this.slowAnimations,
                progress: this.progress,
                performance: this.performance
            };
            
            localStorage.setItem('countLearnState', JSON.stringify(data));
            
            // Save to Telegram Cloud Storage if available
            if (window.Telegram?.WebApp?.CloudStorage) {
                Telegram.WebApp.CloudStorage.setItem('gameState', JSON.stringify(data));
            }
        } catch (e) {
            console.error('Failed to save state:', e);
        }
    },
    
    // Reset all progress
    reset() {
        this.progress = {
            totalCounts: 0,
            masteredNumbers: [],
            sessionStartTime: Date.now(),
            sessionTime: 0,
            completedRounds: 0
        };
        this.performance = {
            successRate: 100,
            averageTime: 0,
            consecutiveSuccess: 0
        };
        this.save();
    }
};

// ===================================
// TELEGRAM WEB APP INTEGRATION
// ===================================

class TelegramIntegration {
    constructor() {
        this.tg = window.Telegram?.WebApp;
        this.isAvailable = !!this.tg;
    }
    
    init() {
        if (!this.isAvailable) return;
        
        // Expand to full height
        this.tg.expand();
        
        // Enable closing confirmation
        this.tg.enableClosingConfirmation();
        
        // Set theme colors
        this.updateTheme();
        
        // Setup haptic feedback
        this.enableHaptics = true;
        
        // Handle back button
        this.tg.BackButton.onClick(() => {
            if (document.getElementById('settingsModal').classList.contains('hidden')) {
                this.tg.close();
            } else {
                document.getElementById('settingsModal').classList.add('hidden');
                this.tg.BackButton.hide();
            }
        });
    }
    
    updateTheme() {
        if (!this.isAvailable) return;
        
        const theme = THEMES[GameState.currentTheme];
        if (theme) {
            // Note: Telegram theme colors are limited, but we try
            this.tg.setHeaderColor('secondary_bg_color');
            this.tg.setBackgroundColor('bg_color');
        }
    }
    
    haptic(type = 'light') {
        if (!this.isAvailable || !this.enableHaptics) return;
        
        const hapticTypes = {
            light: 'impact',
            medium: 'impact',
            heavy: 'impact',
            success: 'notification',
            warning: 'notification',
            error: 'notification'
        };
        
        const style = {
            light: 'light',
            medium: 'medium',
            heavy: 'heavy',
            success: 'success',
            warning: 'warning',
            error: 'error'
        };
        
        if (hapticTypes[type] === 'impact') {
            this.tg.HapticFeedback.impactOccurred(style[type]);
        } else {
            this.tg.HapticFeedback.notificationOccurred(style[type]);
        }
    }
    
    showMainButton(text, callback) {
        if (!this.isAvailable) return;
        
        this.tg.MainButton.setText(text);
        this.tg.MainButton.show();
        this.tg.MainButton.onClick(callback);
    }
    
    hideMainButton() {
        if (!this.isAvailable) return;
        this.tg.MainButton.hide();
    }
}

// ===================================
// AUDIO SYSTEM
// ===================================

class AudioManager {
    constructor() {
        this.audioPlayer = document.getElementById('audioPlayer');
        this.bgMusic = document.getElementById('bgMusic');
        this.context = null;
        this.initialized = false;
        
        // Synthesized sounds using Web Audio API
        this.synthSounds = {};
    }
    
    async init() {
        if (this.initialized) return;
        
        try {
            this.context = new (window.AudioContext || window.webkitAudioContext)();
            this.initialized = true;
            
            // Create synthesized sounds
            this.createSynthSounds();
        } catch (e) {
            console.error('Audio init failed:', e);
        }
    }
    
    createSynthSounds() {
        // Pre-generate common sound types
        this.synthSounds = {
            pop: this.generatePop,
            celebrate: this.generateCelebrate,
            success: this.generateSuccess,
            tap: this.generateTap
        };
    }
    
    generatePop() {
        if (!this.context) return;
        
        const oscillator = this.context.createOscillator();
        const gainNode = this.context.createGain();
        
        oscillator.connect(gainNode);
        gainNode.connect(this.context.destination);
        
        oscillator.frequency.value = 800;
        gainNode.gain.setValueAtTime(0.3, this.context.currentTime);
        gainNode.gain.exponentialRampToValueAtTime(0.01, this.context.currentTime + 0.1);
        
        oscillator.start(this.context.currentTime);
        oscillator.stop(this.context.currentTime + 0.1);
    }
    
    generateCelebrate() {
        if (!this.context) return;
        
        const notes = [523.25, 659.25, 783.99]; // C5, E5, G5
        notes.forEach((freq, i) => {
            const oscillator = this.context.createOscillator();
            const gainNode = this.context.createGain();
            
            oscillator.connect(gainNode);
            gainNode.connect(this.context.destination);
            
            oscillator.frequency.value = freq;
            const startTime = this.context.currentTime + (i * 0.1);
            gainNode.gain.setValueAtTime(0.2, startTime);
            gainNode.gain.exponentialRampToValueAtTime(0.01, startTime + 0.3);
            
            oscillator.start(startTime);
            oscillator.stop(startTime + 0.3);
        });
    }
    
    generateSuccess() {
        if (!this.context) return;
        
        const oscillator = this.context.createOscillator();
        const gainNode = this.context.createGain();
        
        oscillator.connect(gainNode);
        gainNode.connect(this.context.destination);
        
        oscillator.type = 'sine';
        oscillator.frequency.setValueAtTime(400, this.context.currentTime);
        oscillator.frequency.exponentialRampToValueAtTime(800, this.context.currentTime + 0.2);
        
        gainNode.gain.setValueAtTime(0.3, this.context.currentTime);
        gainNode.gain.exponentialRampToValueAtTime(0.01, this.context.currentTime + 0.5);
        
        oscillator.start(this.context.currentTime);
        oscillator.stop(this.context.currentTime + 0.5);
    }
    
    generateTap() {
        if (!this.context) return;
        
        const oscillator = this.context.createOscillator();
        const gainNode = this.context.createGain();
        
        oscillator.connect(gainNode);
        gainNode.connect(this.context.destination);
        
        oscillator.frequency.value = 600;
        gainNode.gain.setValueAtTime(0.2, this.context.currentTime);
        gainNode.gain.exponentialRampToValueAtTime(0.01, this.context.currentTime + 0.05);
        
        oscillator.start(this.context.currentTime);
        oscillator.stop(this.context.currentTime + 0.05);
    }
    
    playSound(soundName) {
        if (!GameState.soundEnabled || !this.initialized) return;
        
        const generator = this.synthSounds[soundName];
        if (generator) {
            generator.call(this);
        }
    }
    
    speak(text) {
        if (!GameState.voiceEnabled || !window.speechSynthesis) return;
        
        // Cancel any ongoing speech
        window.speechSynthesis.cancel();
        
        const utterance = new SpeechSynthesisUtterance(text);
        utterance.rate = 0.9; // Slightly slower for toddlers
        utterance.pitch = 1.2; // Slightly higher pitch (friendly)
        utterance.volume = 0.8;
        
        // Try to use a child-friendly voice
        const voices = window.speechSynthesis.getVoices();
        const preferredVoice = voices.find(v => 
            v.name.includes('Female') || v.name.includes('Samantha')
        );
        if (preferredVoice) {
            utterance.voice = preferredVoice;
        }
        
        window.speechSynthesis.speak(utterance);
    }
    
    playBackgroundMusic() {
        if (!GameState.musicEnabled || !this.bgMusic) return;
        
        // For production, you would load actual audio files
        // For now, we'll skip background music to keep it simple
        this.bgMusic.volume = 0.2;
        this.bgMusic.play().catch(e => console.log('Music play failed:', e));
    }
    
    stopBackgroundMusic() {
        if (this.bgMusic) {
            this.bgMusic.pause();
            this.bgMusic.currentTime = 0;
        }
    }
}

// ===================================
// CELEBRATION SYSTEM
// ===================================

class CelebrationSystem {
    constructor() {
        this.canvas = document.getElementById('celebrationCanvas');
        this.ctx = this.canvas.getContext('2d');
        this.particles = [];
        this.animationFrame = null;
    }
    
    init() {
        this.resizeCanvas();
        window.addEventListener('resize', () => this.resizeCanvas());
    }
    
    resizeCanvas() {
        this.canvas.width = window.innerWidth;
        this.canvas.height = window.innerHeight;
    }
    
    createParticle(x, y, color) {
        return {
            x,
            y,
            vx: (Math.random() - 0.5) * 10,
            vy: (Math.random() - 0.5) * 10 - 5,
            color,
            size: Math.random() * 8 + 4,
            life: 1,
            decay: Math.random() * 0.015 + 0.01
        };
    }
    
    celebrate(level = 1) {
        const colors = ['#FF6B6B', '#4ECDC4', '#FFE66D', '#95E1D3', '#FFB6C1'];
        const particleCount = level * 30;
        
        // Create particles
        for (let i = 0; i < particleCount; i++) {
            const x = this.canvas.width / 2;
            const y = this.canvas.height / 2;
            const color = colors[Math.floor(Math.random() * colors.length)];
            this.particles.push(this.createParticle(x, y, color));
        }
        
        // Start animation
        this.animate();
        
        // Auto-stop after duration
        setTimeout(() => {
            this.stop();
        }, CONFIG.celebration.confettiDuration);
    }
    
    animate() {
        this.ctx.clearRect(0, 0, this.canvas.width, this.canvas.height);
        
        // Update and draw particles
        this.particles = this.particles.filter(p => {
            p.x += p.vx;
            p.y += p.vy;
            p.vy += 0.3; // Gravity
            p.life -= p.decay;
            
            if (p.life <= 0) return false;
            
            this.ctx.globalAlpha = p.life;
            this.ctx.fillStyle = p.color;
            this.ctx.beginPath();
            this.ctx.arc(p.x, p.y, p.size, 0, Math.PI * 2);
            this.ctx.fill();
            
            return true;
        });
        
        if (this.particles.length > 0) {
            this.animationFrame = requestAnimationFrame(() => this.animate());
        }
    }
    
    stop() {
        if (this.animationFrame) {
            cancelAnimationFrame(this.animationFrame);
            this.animationFrame = null;
        }
        this.particles = [];
        this.ctx.clearRect(0, 0, this.canvas.width, this.canvas.height);
    }
}

// ===================================
// GAME CONTROLLER
// ===================================

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
        
        this.countedObjects = new Set();
        this.roundStartTime = Date.now();
    }
    
    async init() {
        // Load saved state
        GameState.load();
        
        // Initialize subsystems
        this.telegram.init();
        await this.audio.init();
        this.celebration.init();
        
        // Apply saved settings
        this.applySettings();
        
        // Setup event listeners
        this.setupEventListeners();
        
        // Start game
        setTimeout(() => {
            this.elements.loadingScreen.classList.add('hidden');
            this.elements.gameContainer.classList.remove('hidden');
            this.startNewRound();
        }, 1500);
        
        // Auto-save interval
        setInterval(() => GameState.save(), CONFIG.session.autoSaveInterval);
        
        // Load voices for speech synthesis
        if (window.speechSynthesis) {
            window.speechSynthesis.getVoices();
        }
    }
    
    applySettings() {
        document.body.classList.toggle('high-contrast', GameState.highContrast);
        document.body.classList.toggle('extra-large', GameState.extraLarge);
        document.body.classList.toggle('slow-animations', GameState.slowAnimations);
        
        if (GameState.musicEnabled) {
            this.audio.playBackgroundMusic();
        }
        
        this.updateTheme(GameState.currentTheme);
    }
    
    setupEventListeners() {
        // Settings button
        document.getElementById('settingsBtn').addEventListener('click', () => {
            this.openSettings();
        });
        
        // Theme selector
        document.querySelectorAll('.theme-btn').forEach(btn => {
            btn.addEventListener('click', (e) => {
                const theme = e.currentTarget.dataset.theme;
                this.updateTheme(theme);
                this.telegram.haptic('light');
            });
        });
        
        // Settings modal
        document.querySelector('.close-modal').addEventListener('click', () => {
            this.closeSettings();
        });
        
        // Difficulty buttons
        document.querySelectorAll('.difficulty-btn').forEach(btn => {
            btn.addEventListener('click', (e) => {
                const level = e.currentTarget.dataset.level;
                this.setDifficulty(level);
            });
        });
        
        // Toggle switches
        document.getElementById('soundToggle').addEventListener('change', (e) => {
            GameState.soundEnabled = e.target.checked;
            GameState.save();
        });
        
        document.getElementById('voiceToggle').addEventListener('change', (e) => {
            GameState.voiceEnabled = e.target.checked;
            GameState.save();
        });
        
        document.getElementById('musicToggle').addEventListener('change', (e) => {
            GameState.musicEnabled = e.target.checked;
            if (e.target.checked) {
                this.audio.playBackgroundMusic();
            } else {
                this.audio.stopBackgroundMusic();
            }
            GameState.save();
        });
        
        document.getElementById('contrastToggle').addEventListener('change', (e) => {
            GameState.highContrast = e.target.checked;
            document.body.classList.toggle('high-contrast', e.target.checked);
            GameState.save();
        });
        
        document.getElementById('largeToggle').addEventListener('change', (e) => {
            GameState.extraLarge = e.target.checked;
            document.body.classList.toggle('extra-large', e.target.checked);
            GameState.save();
        });
        
        document.getElementById('slowToggle').addEventListener('change', (e) => {
            GameState.slowAnimations = e.target.checked;
            document.body.classList.toggle('slow-animations', e.target.checked);
            GameState.save();
        });
        
        // Reset button
        document.getElementById('resetProgress').addEventListener('click', () => {
            if (confirm('Are you sure you want to reset all progress?')) {
                GameState.reset();
                this.updateStats();
                this.telegram.haptic('success');
            }
        });
        
        // Next level button
        document.querySelector('.next-level-btn').addEventListener('click', () => {
            this.elements.celebrationOverlay.classList.add('hidden');
            this.celebration.stop();
            this.startNewRound();
        });
        
        // Close modal on overlay click
        this.elements.settingsModal.addEventListener('click', (e) => {
            if (e.target === this.elements.settingsModal) {
                this.closeSettings();
            }
        });
    }
    
    updateTheme(themeName) {
        if (!THEMES[themeName]) return;
        
        GameState.currentTheme = themeName;
        const theme = THEMES[themeName];
        
        // Update background
        document.body.style.background = theme.background;
        
        // Update active theme button
        document.querySelectorAll('.theme-btn').forEach(btn => {
            btn.classList.toggle('active', btn.dataset.theme === themeName);
        });
        
        // Restart round with new theme
        this.startNewRound();
        
        // Update Telegram theme
        this.telegram.updateTheme();
        
        GameState.save();
    }
    
    setDifficulty(level) {
        GameState.difficulty = level;
        GameState.targetNumber = CONFIG.difficulty[level].max;
        
        // Update active button
        document.querySelectorAll('.difficulty-btn').forEach(btn => {
            btn.classList.toggle('active', btn.dataset.level === level);
        });
        
        // Restart round
        this.startNewRound();
        this.telegram.haptic('medium');
        GameState.save();
    }
    
    startNewRound() {
        // Reset state
        GameState.currentNumber = 0;
        this.countedObjects.clear();
        this.roundStartTime = Date.now();
        
        // Update display
        this.elements.numberDisplay.textContent = '0';
        this.elements.numberLabel.textContent = "Let's Count!";
        this.elements.progressBar.style.width = '0%';
        
        // Generate objects
        this.generateObjects();
        
        // Speak introduction
        const targetNum = GameState.targetNumber;
        this.audio.speak(`Let's count to ${targetNum}!`);
    }
    
    generateObjects() {
        const theme = THEMES[GameState.currentTheme];
        const count = GameState.targetNumber;
        
        this.elements.objectsGrid.innerHTML = '';
        
        for (let i = 0; i < count; i++) {
            const obj = document.createElement('div');
            obj.className = 'counting-object';
            obj.textContent = theme.objects[i % theme.objects.length];
            obj.dataset.index = i;
            obj.setAttribute('role', 'button');
            obj.setAttribute('aria-label', `Count ${i + 1}`);
            obj.setAttribute('tabindex', '0');
            
            // Add staggered entrance animation
            obj.style.animationDelay = `${i * 0.1}s`;
            
            obj.addEventListener('click', () => this.handleObjectTap(obj, i));
            obj.addEventListener('keypress', (e) => {
                if (e.key === 'Enter' || e.key === ' ') {
                    this.handleObjectTap(obj, i);
                }
            });
            
            this.elements.objectsGrid.appendChild(obj);
        }
    }
    
    handleObjectTap(obj, index) {
        // Prevent double counting
        if (this.countedObjects.has(index)) return;
        
        // Mark as counted
        this.countedObjects.add(index);
        obj.classList.add('counted');
        
        // Increment count
        GameState.currentNumber++;
        
        // Update display with animation
        this.elements.numberDisplay.classList.add('counting');
        setTimeout(() => {
            this.elements.numberDisplay.classList.remove('counting');
        }, CONFIG.animation.normal);
        
        this.elements.numberDisplay.textContent = GameState.currentNumber;
        
        // Update progress bar
        const progress = (GameState.currentNumber / GameState.targetNumber) * 100;
        this.elements.progressBar.style.width = `${progress}%`;
        
        // Play haptic
        this.telegram.haptic('light');
        
        // Speak number (this is the counting sound)
        this.audio.speak(GameState.currentNumber.toString());
        
        // Check if round complete
        if (GameState.currentNumber === GameState.targetNumber) {
            setTimeout(() => this.completeRound(), 500);
        }
    }
    
    completeRound() {
        // Update statistics
        GameState.progress.totalCounts++;
        GameState.progress.completedRounds++;
        
        if (!GameState.progress.masteredNumbers.includes(GameState.targetNumber)) {
            GameState.progress.masteredNumbers.push(GameState.targetNumber);
        }
        
        // Calculate performance
        const roundTime = Date.now() - this.roundStartTime;
        GameState.performance.consecutiveSuccess++;
        
        // Play celebration
        this.showCelebration();
        
        // Save progress
        GameState.save();
    }
    
    showCelebration() {
        // Random encouragement
        const message = ENCOURAGEMENT[Math.floor(Math.random() * ENCOURAGEMENT.length)];
        
        // Determine celebration level (1-5) based on performance
        const level = Math.min(5, Math.floor(GameState.performance.consecutiveSuccess / 3) + 1);
        
        // Update celebration UI
        this.elements.celebrationText.textContent = message;
        
        const emojis = ['🎉', '⭐', '🌟', '✨', '🎊', '🎈', '🏆', '👏'];
        this.elements.celebrationEmoji.textContent = emojis[Math.floor(Math.random() * emojis.length)];
        
        // Show overlay
        this.elements.celebrationOverlay.classList.remove('hidden');
        
        // Trigger confetti
        this.celebration.celebrate(level);
        
        // Play celebration sound
        this.audio.playSound('celebrate');
        this.telegram.haptic('success');
        
        // Speak encouragement
        this.audio.speak(`${message} You counted to ${GameState.targetNumber}!`);
    }
    
    openSettings() {
        this.elements.settingsModal.classList.remove('hidden');
        this.updateStats();
        
        // Update toggle states
        document.getElementById('soundToggle').checked = GameState.soundEnabled;
        document.getElementById('voiceToggle').checked = GameState.voiceEnabled;
        document.getElementById('musicToggle').checked = GameState.musicEnabled;
        document.getElementById('contrastToggle').checked = GameState.highContrast;
        document.getElementById('largeToggle').checked = GameState.extraLarge;
        document.getElementById('slowToggle').checked = GameState.slowAnimations;
        
        // Update difficulty selection
        document.querySelectorAll('.difficulty-btn').forEach(btn => {
            btn.classList.toggle('active', btn.dataset.level === GameState.difficulty);
        });
        
        // Show Telegram back button
        if (this.telegram.isAvailable) {
            this.telegram.tg.BackButton.show();
        }
    }
    
    closeSettings() {
        this.elements.settingsModal.classList.add('hidden');
        
        if (this.telegram.isAvailable) {
            this.telegram.tg.BackButton.hide();
        }
    }
    
    updateStats() {
        document.getElementById('totalCounts').textContent = GameState.progress.totalCounts;
        
        const minutes = Math.floor(GameState.progress.sessionTime / 60000);
        document.getElementById('sessionTime').textContent = `${minutes}m`;
        
        document.getElementById('masteredNumbers').textContent = 
            GameState.progress.masteredNumbers.length;
    }
}

// ===================================
// INITIALIZE APPLICATION
// ===================================

document.addEventListener('DOMContentLoaded', () => {
    const game = new GameController();
    game.init();
});
