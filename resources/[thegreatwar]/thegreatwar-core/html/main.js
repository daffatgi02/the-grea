// resources/[thegreatwar]/thegreatwar-core/html/js/main.js
let currentVotingTimer = null;
let selectedMap = null;

// Main message handler
window.addEventListener('message', function(event) {
    const data = event.data;
    
    switch(data.action) {
        case 'showVoting':
            showMapVoting(data.maps);
            break;
        case 'hideVoting':
            hideMapVoting();
            break;
        case 'showKillFeed':
            addKillFeedItem(data);
            break;
        case 'showChampion':
            showChampionAnnouncement(data.champion);
            break;
    }
});

// Map Voting Functions
function showMapVoting(maps) {
    const container = document.getElementById('votingContainer');
    const mapOptions = document.getElementById('mapOptions');
    
    // Clear previous options
    mapOptions.innerHTML = '';
    
    // Create map options
    Object.keys(maps).forEach(mapKey => {
        const map = maps[mapKey];
        const option = document.createElement('div');
        option.className = 'map-option';
        option.dataset.map = mapKey;
        
        option.innerHTML = `
            <div class="map-name">${map.name}</div>
            <div class="map-description">${map.description}</div>
        `;
        
        option.addEventListener('click', () => selectMap(mapKey, option));
        mapOptions.appendChild(option);
    });
    
    // Show voting container
    container.classList.remove('hidden');
    
    // Start countdown timer
    startVotingTimer(30);
}

function selectMap(mapKey, element) {
    // Remove previous selection
    document.querySelectorAll('.map-option').forEach(opt => {
        opt.classList.remove('selected');
    });
    
    // Add selection to clicked element
    element.classList.add('selected');
    selectedMap = mapKey;
    
    // Send vote to server
    fetch(`https://${GetParentResourceName()}/voteMap`, {
        method: 'POST',
        headers: {
            'Content-Type': 'application/json'
        },
        body: JSON.stringify({
            map: mapKey
        })
    });
}

function hideMapVoting() {
    const container = document.getElementById('votingContainer');
    container.classList.add('hidden');
    
    if (currentVotingTimer) {
        clearInterval(currentVotingTimer);
        currentVotingTimer = null;
    }
}

function startVotingTimer(seconds) {
    let timeLeft = seconds;
    const timerText = document.getElementById('timerText');
    
    currentVotingTimer = setInterval(() => {
        timerText.textContent = `Time remaining: ${timeLeft}s`;
        timeLeft--;
        
        if (timeLeft < 0) {
            clearInterval(currentVotingTimer);
            hideMapVoting();
        }
    }, 1000);
}

// Kill Feed Functions
function addKillFeedItem(killData) {
    const killFeed = document.getElementById('killFeed');
    const killItem = document.createElement('div');
    killItem.className = 'kill-item';
    
    let killText = `<span class="killer">${killData.killer}</span> eliminated <span class="victim">${killData.victim}</span>`;
    
    if (killData.distance && killData.distance > 50) {
        killText += ` <span class="distance">(${Math.floor(killData.distance)}m)</span>`;
    }
    
    killItem.innerHTML = killText;
    killFeed.appendChild(killItem);
    
    // Remove item after 5 seconds
    setTimeout(() => {
        killItem.classList.add('fade-out');
        setTimeout(() => {
            if (killItem.parentNode) {
                killItem.parentNode.removeChild(killItem);
            }
        }, 500);
    }, 5000);
    
    // Keep only last 5 kill feed items
    const killItems = killFeed.querySelectorAll('.kill-item');
    if (killItems.length > 5) {
        killItems[0].remove();
    }
}

// Champion Announcement Functions
function showChampionAnnouncement(champion) {
    const modal = document.getElementById('championModal');
    const nameElement = document.getElementById('championName');
    const killsElement = document.getElementById('championKills');
    
    nameElement.textContent = champion.name;
    killsElement.textContent = `${champion.kills} KILLS`;
    
    modal.classList.remove('hidden');
    
    // Hide after 5 seconds
    setTimeout(() => {
        modal.classList.add('hidden');
    }, 5000);
}

// ESC key handling
document.addEventListener('keydown', function(event) {
    if (event.key === 'Escape') {
        // Close voting if open
        if (!document.getElementById('votingContainer').classList.contains('hidden')) {
            fetch(`https://${GetParentResourceName()}/closeVoting`, {
                method: 'POST',
                headers: {
                    'Content-Type': 'application/json'
                },
                body: JSON.stringify({})
            });
        }
    }
});

// Utility function to get resource name
function GetParentResourceName() {
    return window.location.hostname;
}