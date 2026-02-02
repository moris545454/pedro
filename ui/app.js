const app = document.getElementById('app');
const modelSelect = document.getElementById('modelSelect');
const closeButton = document.getElementById('close');
const spawnButton = document.getElementById('spawn');
const followButton = document.getElementById('follow');
const stayButton = document.getElementById('stay');
const dismissButton = document.getElementById('dismiss');
const feedButton = document.getElementById('feed');
const healButton = document.getElementById('heal');
const whistleButton = document.getElementById('whistle');
const playButton = document.getElementById('play');
const renameButton = document.getElementById('rename');
const renameInput = document.getElementById('renameInput');
const trickSelect = document.getElementById('trickSelect');
const trickButton = document.getElementById('trick');
const petName = document.getElementById('petName');
const petMood = document.getElementById('petMood');
const hungerBar = document.getElementById('hungerBar');
const staminaBar = document.getElementById('staminaBar');
const affectionBar = document.getElementById('affectionBar');
const xpBar = document.getElementById('xpBar');
const hungerValue = document.getElementById('hungerValue');
const staminaValue = document.getElementById('staminaValue');
const affectionValue = document.getElementById('affectionValue');
const levelValue = document.getElementById('levelValue');

const sendAction = (action, payload = {}) => {
  fetch(`https://${GetParentResourceName()}/${action}`, {
    method: 'POST',
    headers: {
      'Content-Type': 'application/json; charset=UTF-8'
    },
    body: JSON.stringify(payload)
  });
};

const setVisible = (show) => {
  app.setAttribute('aria-hidden', show ? 'false' : 'true');
};

window.addEventListener('message', (event) => {
  const { action, models, currentModel, name, stats, progress, mood } = event.data;
  if (action === 'open') {
    modelSelect.innerHTML = '';
    models.forEach((model) => {
      const option = document.createElement('option');
      option.value = model;
      option.textContent = model;
      if (model === currentModel) {
        option.selected = true;
      }
      modelSelect.appendChild(option);
    });
    updateState({ name, stats, progress, mood });
    setVisible(true);
  }

  if (action === 'close') {
    setVisible(false);
  }

  if (action === 'state') {
    updateState({ name, stats, progress, mood });
  }
});

spawnButton.addEventListener('click', () => {
  sendAction('spawn', { model: modelSelect.value });
});

followButton.addEventListener('click', () => {
  sendAction('follow');
});

stayButton.addEventListener('click', () => {
  sendAction('stay');
});

dismissButton.addEventListener('click', () => {
  sendAction('dismiss');
});

feedButton.addEventListener('click', () => {
  sendAction('feed');
});

healButton.addEventListener('click', () => {
  sendAction('heal');
});

whistleButton.addEventListener('click', () => {
  sendAction('whistle');
});

playButton.addEventListener('click', () => {
  sendAction('play');
});

renameButton.addEventListener('click', () => {
  const name = renameInput.value.trim();
  if (name.length > 0) {
    sendAction('rename', { name });
    renameInput.value = '';
  }
});

trickButton.addEventListener('click', () => {
  sendAction('trick', { trick: trickSelect.value });
});

closeButton.addEventListener('click', () => {
  sendAction('close');
});

window.addEventListener('keydown', (event) => {
  if (event.key === 'Escape') {
    sendAction('close');
  }
});

const updateState = ({ name, stats, progress, mood }) => {
  if (name) {
    petName.textContent = name;
  }

  if (mood) {
    petMood.textContent = mood;
  }

  if (stats) {
    const { hunger, stamina, affection } = stats;
    hungerBar.style.width = `${hunger}%`;
    staminaBar.style.width = `${stamina}%`;
    affectionBar.style.width = `${affection}%`;
    hungerValue.textContent = hunger;
    staminaValue.textContent = stamina;
    affectionValue.textContent = affection;
  }

  if (progress) {
    const { xp, level, nextXp } = progress;
    const percent = Math.min(100, Math.round((xp / Math.max(nextXp, 1)) * 100));
    xpBar.style.width = `${percent}%`;
    levelValue.textContent = level;
  }
};
