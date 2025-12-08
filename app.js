/**
 * Count & Learn - Main Menu
 * Central hub for all educational games
 */

// Shared settings across all games
const GlobalSettings = {
    soundEnabled: true,
    voiceEnabled: true,
    highContrast: false,
    extraLarge: false,

    load() {
        try {
            const saved = localStorage.getItem('countLearnGlobal');
            if (saved) {
                const data = JSON.parse(saved);
                Object.assign(this, data);
            }
        } catch (e) { console.error('Failed to load global settings:', e); }
    },

    save() {
        try {
            const data = {
                soundEnabled: this.soundEnabled,
                voiceEnabled: this.voiceEnabled,
                highContrast: this.highContrast,
                extraLarge: this.extraLarge
            };
            localStorage.setItem('countLearnGlobal', JSON.stringify(data));
            
            if (window.Telegram?.WebApp?.CloudStorage) {
                Telegram.WebApp.CloudStorage.setItem('globalSettings', JSON.stringify(data));
            }
        } catch (e) { console.error('Failed to save global settings:', e); }
    },

    reset() {
        localStorage.removeItem('countLearnGlobal');
        localStorage.removeItem('countLearnState');
        localStorage.removeItem('findNumberState');
        this.soundEnabled = true;
        this.voiceEnabled = true;
        this.highContrast = false;
        this.extraLarge = false;
        this.save();
    }
};

// Aggregate progress from all games
const GlobalProgress = {
    getData() {
        let totalPlays = 0;
        let totalTime = 0;
        let totalStars = 0;

        try {
            // Game 1: Tap & Count
            const game1 = localStorage.getItem('countLearnState');
            if (game1) {
                const data = JSON.parse(game1);
                totalPlays += data.progress?.completedRounds || 0;
                totalTime += data.progress?.totalSessionTime || 0;
                // Stars based on mastered numbers
                const mastered = data.progress?.masteredNumbers || {};
                totalStars += Object.keys(mastered).filter(k => {
                    const m = mastered[k];
                    return m && m.rounds >= 3 && m.accuracy >= 80;
                }).length;
            }

            // Game 2: Find the Number
            const game2 = localStorage.getItem('findNumberState');
            if (game2) {
                const data = JSON.parse(game2);
                totalPlays += data.progress?.completedRounds || 0;
                totalTime += data.progress?.totalSessionTime || 0;
                const mastered = data.progress?.masteredNumbers || {};
                totalStars += Object.keys(mastered).filter(k => {
                    const m = mastered[k];
                    return m && m.rounds >= 3 && m.accuracy >= 80;
                }).length;
            }

        } catch (e) { console.error('Failed to load progress:', e); }

        return { totalPlays, totalTime, totalStars };
    }
};

// Telegram Integration
class TelegramIntegration {
    constructor() {
        this.tg = window.Telegram?.WebApp;
        this.isAvailable = !!this.tg;
    }

    init() {
        if (!this.isAvailable) return;
        this.tg.expand();
        this.tg.setHeaderColor('secondary_bg_color');
        this.tg.setBackgroundColor('bg_color');
    }

    haptic(type = 'light') {
        if (!this.isAvailable) return;
        if (['light', 'medium', 'heavy'].includes(type)) {
            this.tg.HapticFeedback.impactOccurred(type);
        } else {
            this.tg.HapticFeedback.notificationOccurred(type);
        }
    }
}

// Main Menu Controller
class MenuController {
    constructor() {
        this.telegram = new TelegramIntegration();
        this.elements = {
            loadingScreen: document.getElementById('loadingScreen'),
            mainMenu: document.getElementById('mainMenu'),
            settingsModal: document.getElementById('settingsModal'),
            totalPlays: document.getElementById('totalPlays'),
            totalTime: document.getElementById('totalTime'),
            totalStars: document.getElementById('totalStars')
        };
    }

    init() {
        GlobalSettings.load();
        this.telegram.init();
        this.applySettings();
        this.setupEventListeners();
        this.updateProgress();

        // Show menu after brief loading
        setTimeout(() => {
            this.elements.loadingScreen.classList.add('hidden');
            this.elements.mainMenu.classList.remove('hidden');
        }, 1000);
    }

    applySettings() {
        document.body.classList.toggle('high-contrast', GlobalSettings.highContrast);
        document.body.classList.toggle('extra-large', GlobalSettings.extraLarge);
    }

    setupEventListeners() {
        // Settings button
        document.getElementById('settingsBtn').addEventListener('click', () => {
            this.openSettings();
            this.telegram.haptic('light');
        });

        // Close modal
        document.querySelector('.close-modal').addEventListener('click', () => {
            this.closeSettings();
        });

        // Modal backdrop click
        this.elements.settingsModal.addEventListener('click', (e) => {
            if (e.target === this.elements.settingsModal) this.closeSettings();
        });

        // Toggle switches
        document.getElementById('soundToggle').addEventListener('change', (e) => {
            GlobalSettings.soundEnabled = e.target.checked;
            GlobalSettings.save();
        });

        document.getElementById('voiceToggle').addEventListener('change', (e) => {
            GlobalSettings.voiceEnabled = e.target.checked;
            GlobalSettings.save();
        });

        document.getElementById('contrastToggle').addEventListener('change', (e) => {
            GlobalSettings.highContrast = e.target.checked;
            document.body.classList.toggle('high-contrast', e.target.checked);
            GlobalSettings.save();
        });

        document.getElementById('largeToggle').addEventListener('change', (e) => {
            GlobalSettings.extraLarge = e.target.checked;
            document.body.classList.toggle('extra-large', e.target.checked);
            GlobalSettings.save();
        });

        // Reset button
        document.getElementById('resetAllProgress').addEventListener('click', () => {
            if (confirm('Reset ALL progress from ALL games? This cannot be undone.')) {
                GlobalSettings.reset();
                this.updateProgress();
                this.telegram.haptic('success');
                alert('All progress has been reset.');
            }
        });

        // Game card clicks (haptic feedback)
        document.querySelectorAll('.game-card:not(.locked)').forEach(card => {
            card.addEventListener('click', () => {
                this.telegram.haptic('medium');
            });
        });

        // Locked card click
        document.querySelectorAll('.game-card.locked').forEach(card => {
            card.addEventListener('click', (e) => {
                e.preventDefault();
                this.telegram.haptic('warning');
            });
        });
    }

    openSettings() {
        this.elements.settingsModal.classList.remove('hidden');
        
        // Update toggle states
        document.getElementById('soundToggle').checked = GlobalSettings.soundEnabled;
        document.getElementById('voiceToggle').checked = GlobalSettings.voiceEnabled;
        document.getElementById('contrastToggle').checked = GlobalSettings.highContrast;
        document.getElementById('largeToggle').checked = GlobalSettings.extraLarge;
    }

    closeSettings() {
        this.elements.settingsModal.classList.add('hidden');
    }

    updateProgress() {
        const progress = GlobalProgress.getData();
        
        this.elements.totalPlays.textContent = progress.totalPlays;
        
        const minutes = Math.floor(progress.totalTime / 60000);
        this.elements.totalTime.textContent = minutes < 60 ? `${minutes}m` : `${Math.floor(minutes/60)}h`;
        
        this.elements.totalStars.textContent = progress.totalStars;
    }
}

// Initialize
document.addEventListener('DOMContentLoaded', () => {
    const menu = new MenuController();
    menu.init();
});
