// resources/[thegreatwar]/thegreatwar-ui/html/js/champion-hud.js
class ChampionHUD {
    constructor() {
        this.currentChampion = null;
        this.sessionTimer = null;
        this.killStreakTimeout = null;
        this.init();
    }

    init() {
        this.setupEventListeners();
        this.startSessionTimer();
    }

    setupEventListeners() {
        window.addEventListener('message', (event) => {
            const data = event.data;
            
            switch(data.action) {
                case 'updateChampion':
                    this.updateChampion(data.champion);
                    break;
                case 'showKillStreak':
                    this.showKillStreak(data.streak, data.type);
                    break;
                case 'updateSessionTimer':
                    this.updateSessionTimer(data.timeLeft, data.status);
                    break;
                case 'hideChampionHUD':
                    this.hideHUD();
                    break;
                case 'showChampionHUD':
                    this.showHUD();
                    break;
            }
        });
    }

    updateChampion(champion) {
        if (!champion) return;
        
        this.currentChampion = champion;
        
        document.getElementById('championName').textContent = champion.name;
        document.getElementById('championKills').textContent = `${champion.kills} KILLS`;
        document.getElementById('championType').textContent = champion.type.toUpperCase();
        
        // Add champion change animation
        const container = document.querySelector('.champion-container');
        container.style.animation = 'none';
        setTimeout(() => {
            container.style.animation = 'championGlow 2s ease-in-out infinite alternate';
        }, 100);
    }

    showKillStreak(streak, type) {
        const container = document.getElementById('killStreakNotify');
        const text = document.getElementById('killStreakText');
        const count = document.getElementById('killStreakCount');
        
        // Different messages based on streak
        let message = 'KILLING SPREE!';
        if (streak >= 10) message = 'UNSTOPPABLE!';
        else if (streak >= 7) message = 'RAMPAGE!';
        else if (streak >= 5) message = 'DOMINATING!';
        else if (streak >= 3) message = 'KILLING SPREE!';
        
        text.textContent = message;
        count.textContent = `${streak} KILL STREAK`;
        
        container.style.display = 'block';
        container.style.animation = 'killStreakPulse 0.8s ease-in-out';
        
        // Clear previous timeout
        if (this.killStreakTimeout) {
            clearTimeout(this.killStreakTimeout);
        }
        
        // Hide after 3 seconds
        this.killStreakTimeout = setTimeout(() => {
            container.style.display = 'none';
        }, 3000);
    }

    updateSessionTimer(timeLeft, status) {
        const timerElement = document.getElementById('sessionTimer');
        const statusElement = document.getElementById('sessionStatus');
        
        // Convert milliseconds to MM:SS format
        const minutes = Math.floor(timeLeft / 60000);
        const seconds = Math.floor((timeLeft % 60000) / 1000);
        
        timerElement.textContent = `${minutes.toString().padStart(2, '0')}:${seconds.toString().padStart(2, '0')}`;
        statusElement.textContent = status.toUpperCase();
        
        // Change color based on time left
        if (timeLeft < 300000) { // Less than 5 minutes
            timerElement.style.color = '#FF4757';
            timerElement.style.animation = 'timePulse 1s ease-in-out infinite';
        } else {
            timerElement.style.color = '#FFD700';
            timerElement.style.animation = 'none';
        }
    }

    startSessionTimer() {
        // This will be updated by server events
        setInterval(() => {
            // Fallback timer display
        }, 1000);
    }

    hideHUD() {
        document.querySelector('.champion-container').style.display = 'none';
    }

    showHUD() {
        document.querySelector('.champion-container').style.display = 'block';
    }
}

// Add time pulse animation
const style = document.createElement('style');
style.textContent = `
    @keyframes timePulse {
        0% { transform: scale(1); }
        50% { transform: scale(1.1); }
        100% { transform: scale(1); }
    }
`;
document.head.append(style);

// Initialize Champion HUD
const championHUD = new ChampionHUD();