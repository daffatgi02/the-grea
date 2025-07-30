// resources/[thegreatwar]/thegreatwar-ui/html/js/voting-interface.js
class VotingInterface {
    constructor() {
        this.maps = {};
        this.selectedMap = null;
        this.timeLeft = 30;
        this.timerInterval = null;
        this.votes = {};
        this.init();
    }

    init() {
        this.setupEventListeners();
    }

    setupEventListeners() {
        window.addEventListener('message', (event) => {
            const data = event.data;
            
            switch(data.action) {
                case 'showVoting':
                    this.showVoting(data.maps, data.duration);
                    break;
                case 'hideVoting':
                    this.hideVoting();
                    break;
                case 'updateVotes':
                    this.updateVotes(data.votes);
                    break;
                case 'updateTimer':
                    this.updateTimer(data.timeLeft);
                    break;
            }
        });

        // ESC key to close (optional)
        document.addEventListener('keydown', (event) => {
            if (event.key === 'Escape') {
                this.closeVoting();
            }
        });
    }

    showVoting(maps, duration = 30) {
        this.maps = maps;
        this.timeLeft = duration;
        
        this.renderMaps();
        this.startTimer();
        
        document.getElementById('votingModal').style.display = 'block';
        document.body.style.display = 'flex';
    }

    hideVoting() {
        document.getElementById('votingModal').style.display = 'none';
        document.body.style.display = 'none';
        this.stopTimer();
    }

    renderMaps() {
        const mapGrid = document.getElementById('mapGrid');
        mapGrid.innerHTML = '';

        Object.keys(this.maps).forEach(mapKey => {
            const map = this.maps[mapKey];
            const mapElement = this.createMapElement(mapKey, map);
            mapGrid.appendChild(mapElement);
        });
    }

    createMapElement(mapKey, map) {
        const mapElement = document.createElement('div');
        mapElement.className = 'map-option';
        mapElement.dataset.map = mapKey;
        
        mapElement.innerHTML = `
            <div class="map-preview ${mapKey}">
                ${this.getMapIcon(mapKey)}
            </div>
            <div class="map-name">${map.name}</div>
            <div class="map-description">${map.description}</div>
            <div class="map-stats">
                <span class="map-spawns">${map.spawns ? map.spawns.length : 0} spawn points</span>
                <span class="map-votes" id="votes-${mapKey}">0 votes</span>
            </div>
        `;

        mapElement.addEventListener('click', () => this.selectMap(mapKey, mapElement));
        
        return mapElement;
    }

    getMapIcon(mapKey) {
        const icons = {
            city: '🏙️',
            sandy: '🏜️',
            paleto: '🌲',
            airport: '✈️',
            military: '🏭'
        };
        return icons[mapKey] || '🗺️';
    }

    selectMap(mapKey, element) {
        // Remove previous selection
        document.querySelectorAll('.map-option').forEach(opt => {
            opt.classList.remove('selected');
        });

        // Add selection to clicked element
        element.classList.add('selected');
        this.selectedMap = mapKey;

        // Send vote to server
        this.sendVote(mapKey);
        
        // Visual feedback
        this.showVoteConfirmation(this.maps[mapKey].name);
    }

    sendVote(mapKey) {
        fetch(`https://${this.getResourceName()}/voteMap`, {
            method: 'POST',
            headers: {
                'Content-Type': 'application/json'
            },
            body: JSON.stringify({
                map: mapKey
            })
        }).catch(error => {
            console.error('Error sending vote:', error);
        });
    }

    updateVotes(votes) {
        this.votes = votes;
        let totalVotes = 0;

        Object.keys(votes).forEach(mapKey => {
            const voteCount = votes[mapKey] || 0;
            const voteElement = document.getElementById(`votes-${mapKey}`);
            if (voteElement) {
                voteElement.textContent = `${voteCount} votes`;
            }
            totalVotes += voteCount;
        });

        // Update total votes
        const totalElement = document.querySelector('.total-votes');
        if (totalElement) {
            totalElement.textContent = `Total votes: ${totalVotes}`;
        }
    }

    startTimer() {
        this.updateTimerDisplay();
        
        this.timerInterval = setInterval(() => {
            this.timeLeft--;
            this.updateTimerDisplay();
            
            if (this.timeLeft <= 0) {
                this.stopTimer();
                this.hideVoting();
            }
        }, 1000);
    }

    stopTimer() {
        if (this.timerInterval) {
            clearInterval(this.timerInterval);
            this.timerInterval = null;
        }
    }

    updateTimer(timeLeft) {
        this.timeLeft = timeLeft;
        this.updateTimerDisplay();
    }

    updateTimerDisplay() {
        const timerText = document.getElementById('timerText');
        timerText.textContent = `Time remaining: ${this.timeLeft}s`;
        
        // Add urgency styling
        if (this.timeLeft <= 10) {
            timerText.classList.add('urgent');
        } else {
            timerText.classList.remove('urgent');
        }
    }

    showVoteConfirmation(mapName) {
        // Create temporary confirmation popup
        const confirmation = document.createElement('div');
        confirmation.innerHTML = `✓ Voted for ${mapName}`;
        confirmation.style.cssText = `
            position: fixed;
            top: 20px;
            right: 20px;
            background: rgba(255, 107, 53, 0.9);
            color: white;
            padding: 10px 20px;
            border-radius: 10px;
            font-weight: 700;
            z-index: 10000;
            animation: slideInRight 0.3s ease-out;
        `;
        
        document.body.appendChild(confirmation);
        
        setTimeout(() => {
            confirmation.remove();
        }, 2000);
    }

    closeVoting() {
        fetch(`https://${this.getResourceName()}/closeVoting`, {
            method: 'POST',
            headers: {
                'Content-Type': 'application/json'
            },
            body: JSON.stringify({})
        });
    }

    getResourceName() {
        return window.location.hostname || 'thegreatwar-ui';
    }
}

// Add slideInRight animation
const style = document.createElement('style');
style.textContent = `
    @keyframes slideInRight {
        from {
            transform: translateX(100%);
            opacity: 0;
        }
        to {
            transform: translateX(0);
            opacity: 1;
        }
    }
`;
document.head.append(style);

// Initialize Voting Interface
const votingInterface = new VotingInterface();