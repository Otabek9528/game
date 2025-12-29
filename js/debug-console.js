/* ==========================================
   ON-SCREEN DEBUG CONSOLE
   Mobile-friendly debug logging
   ========================================== */

class DebugConsole {
  constructor() {
    this.logs = [];
    this.maxLogs = 100;
    this.isMinimized = false;
    this.isVisible = true;
    this.hasErrors = false;
    this.createConsole();
    this.interceptConsole();
  }

  createConsole() {
    // Create console HTML
    const consoleHTML = `
      <div class="debug-console" id="debugConsole">
        <div class="debug-console-header">
          <div class="debug-console-title">🐛 Debug Console</div>
          <div class="debug-console-controls">
            <button class="debug-console-btn" id="debugClearBtn">Clear</button>
            <button class="debug-console-btn debug-console-toggle" id="debugToggleBtn">Hide</button>
          </div>
        </div>
        <div class="debug-console-logs" id="debugLogs"></div>
      </div>
      <div class="debug-float-btn" id="debugFloatBtn" style="display: none;">🐛</div>
    `;

    // Insert into DOM
    document.body.insertAdjacentHTML('beforeend', consoleHTML);

    // Get elements
    this.consoleEl = document.getElementById('debugConsole');
    this.logsEl = document.getElementById('debugLogs');
    this.toggleBtn = document.getElementById('debugToggleBtn');
    this.clearBtn = document.getElementById('debugClearBtn');
    this.floatBtn = document.getElementById('debugFloatBtn');

    // Attach event listeners
    this.toggleBtn.addEventListener('click', () => this.toggle());
    this.clearBtn.addEventListener('click', () => this.clear());
    this.floatBtn.addEventListener('click', () => this.show());
  }

  interceptConsole() {
    // Save original console methods
    const originalLog = console.log;
    const originalWarn = console.warn;
    const originalError = console.error;

    // Intercept console.log
    console.log = (...args) => {
      originalLog.apply(console, args);
      this.addLog('info', args);
    };

    // Intercept console.warn
    console.warn = (...args) => {
      originalWarn.apply(console, args);
      this.addLog('warning', args);
    };

    // Intercept console.error
    console.error = (...args) => {
      originalError.apply(console, args);
      this.addLog('error', args);
      this.hasErrors = true;
      if (this.floatBtn) {
        this.floatBtn.classList.add('has-errors');
      }
    };
  }

  addLog(type, args) {
    const message = args.map(arg => {
      if (typeof arg === 'object') {
        try {
          return JSON.stringify(arg, null, 2);
        } catch (e) {
          return String(arg);
        }
      }
      return String(arg);
    }).join(' ');

    // Extract emoji and clean message
    const emoji = this.getEmoji(message, type);
    const cleanMessage = message.replace(/^[\u{1F300}-\u{1F9FF}]/u, '').trim();

    const log = {
      type,
      message: cleanMessage,
      emoji,
      timestamp: new Date().toLocaleTimeString('en-US', { hour12: false })
    };

    this.logs.push(log);

    // Limit logs
    if (this.logs.length > this.maxLogs) {
      this.logs.shift();
    }

    this.render();
  }

  getEmoji(message, type) {
    // Extract emoji from message if present
    const emojiMatch = message.match(/^([\u{1F300}-\u{1F9FF}])/u);
    if (emojiMatch) return emojiMatch[1];

    // Default emojis by type
    const emojiMap = {
      info: 'ℹ️',
      success: '✅',
      warning: '⚠️',
      error: '❌'
    };

    // Detect type from message content
    if (message.includes('[AdModal]')) {
      if (message.includes('✅') || message.includes('Success')) return '✅';
      if (message.includes('❌') || message.includes('Error')) return '❌';
      if (message.includes('⚠️') || message.includes('WARNING')) return '⚠️';
      if (message.includes('🚀') || message.includes('Starting')) return '🚀';
      if (message.includes('📡') || message.includes('API')) return '📡';
      if (message.includes('👤') || message.includes('User')) return '👤';
      if (message.includes('🎨') || message.includes('Showing')) return '🎨';
    }

    return emojiMap[type] || 'ℹ️';
  }

  getLogClass(type) {
    // Determine CSS class based on content
    if (type === 'error') return 'debug-log-error';
    if (type === 'warning') return 'debug-log-warning';
    
    // Check message content for success indicators
    const successKeywords = ['✅', 'Success', 'successfully', 'passed', 'received'];
    const lastLog = this.logs[this.logs.length - 1];
    if (lastLog && successKeywords.some(kw => lastLog.message.includes(kw))) {
      return 'debug-log-success';
    }

    return 'debug-log-info';
  }

  render() {
    if (!this.logsEl) return;

    this.logsEl.innerHTML = this.logs.map(log => `
      <div class="debug-log ${this.getLogClass(log.type)}">
        <span class="debug-log-time">${log.timestamp}</span>
        <span class="debug-log-emoji">${log.emoji}</span>
        <span class="debug-log-message">${this.escapeHtml(log.message)}</span>
      </div>
    `).join('');

    // Auto-scroll to bottom
    this.logsEl.scrollTop = this.logsEl.scrollHeight;
  }

  escapeHtml(text) {
    const div = document.createElement('div');
    div.textContent = text;
    return div.innerHTML;
  }

  clear() {
    this.logs = [];
    this.hasErrors = false;
    if (this.floatBtn) {
      this.floatBtn.classList.remove('has-errors');
    }
    this.render();
    console.log('🗑️ Debug console cleared');
  }

  toggle() {
    if (this.isVisible) {
      this.hide();
    } else {
      this.show();
    }
  }

  hide() {
    this.isVisible = false;
    this.consoleEl.style.display = 'none';
    this.floatBtn.style.display = 'flex';
    console.log('👁️ Debug console hidden (tap floating button to show)');
  }

  show() {
    this.isVisible = true;
    this.consoleEl.style.display = 'block';
    this.floatBtn.style.display = 'none';
  }

  minimize() {
    this.isMinimized = !this.isMinimized;
    this.consoleEl.classList.toggle('minimized', this.isMinimized);
  }
}

// Initialize debug console immediately
let debugConsole;

function initDebugConsole() {
  if (!debugConsole) {
    debugConsole = new DebugConsole();
    console.log('🐛 Debug Console initialized');
    console.log('📱 Screen size:', window.innerWidth, 'x', window.innerHeight);
    console.log('🌐 User Agent:', navigator.userAgent.substring(0, 50) + '...');
  }
}

// Initialize as soon as possible
if (document.readyState === 'loading') {
  document.addEventListener('DOMContentLoaded', initDebugConsole);
} else {
  initDebugConsole();
}
