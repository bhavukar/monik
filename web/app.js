// Manage Your Display Landing Page & Interactive Simulator
import { createPrism } from './prism.js';

document.addEventListener('DOMContentLoaded', () => {
  // 1. Initialize React Bits Prism Component
  const prismContainer = document.getElementById('prism-canvas-container');
  if (prismContainer) {
    createPrism(prismContainer, {
      animationType: 'hover',
      timeScale: 0.5,
      height: 3.5,
      baseWidth: 5.5,
      scale: 3.6,
      hueShift: 0,
      colorFrequency: 1,
      noise: 0.5,
      glow: 1,
      bloom: 1,
      transparent: true,
      hoverStrength: 2,
      inertia: 0.05
    });
  }

  // 2. Live Clock in macOS Menu Bar
  const clockEl = document.getElementById('sim-clock');
  const updateClock = () => {
    if (!clockEl) return;
    const now = new Date();
    const days = ['Sun', 'Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat'];
    const day = days[now.getDay()];
    let hours = now.getHours();
    const minutes = now.getMinutes().toString().padStart(2, '0');
    const ampm = hours >= 12 ? 'PM' : 'AM';
    hours = hours % 12 || 12;
    clockEl.textContent = `${day} ${hours}:${minutes} ${ampm}`;
  };
  updateClock();
  setInterval(updateClock, 30000);

  // 3. Brightness & Volume Sliders
  const bSlider1 = document.getElementById('brightness-slider-1');
  const bVal1 = document.getElementById('brightness-val-1');
  if (bSlider1 && bVal1) {
    bSlider1.addEventListener('input', (e) => {
      bVal1.textContent = `${e.target.value}%`;
    });
  }

  const bSlider2 = document.getElementById('brightness-slider-2');
  const bVal2 = document.getElementById('brightness-val-2');
  if (bSlider2 && bVal2) {
    bSlider2.addEventListener('input', (e) => {
      bVal2.textContent = `${e.target.value}%`;
    });
  }

  const vSlider1 = document.getElementById('volume-slider-1');
  const vVal1 = document.getElementById('volume-val-1');
  if (vSlider1 && vVal1) {
    vSlider1.addEventListener('input', (e) => {
      vVal1.textContent = `${e.target.value}%`;
    });
  }

  // 4. Per-Display Power Toggles (SkyLight Zero-LUT Blackout Simulator)
  const powerToggle1 = document.getElementById('power-toggle-1');
  const card1 = document.getElementById('card-1');
  if (powerToggle1 && card1) {
    powerToggle1.addEventListener('change', (e) => {
      card1.style.opacity = e.target.checked ? '1.0' : '0.35';
      card1.style.filter = e.target.checked ? 'none' : 'grayscale(80%)';
    });
  }

  const powerToggle2 = document.getElementById('power-toggle-2');
  const card2 = document.getElementById('card-2');
  if (powerToggle2 && card2) {
    powerToggle2.addEventListener('change', (e) => {
      card2.style.opacity = e.target.checked ? '1.0' : '0.35';
      card2.style.filter = e.target.checked ? 'none' : 'grayscale(80%)';
    });
  }

  // 5. Presets Switcher
  const presetButtons = document.querySelectorAll('.preset-btn');
  presetButtons.forEach(btn => {
    btn.addEventListener('click', () => {
      presetButtons.forEach(b => b.classList.remove('active'));
      btn.classList.add('active');

      const preset = btn.getAttribute('data-preset');
      if (preset === 'work') {
        if (bSlider1) { bSlider1.value = 100; bVal1.textContent = '100%'; }
        if (bSlider2) { bSlider2.value = 80; bVal2.textContent = '80%'; }
        if (vSlider1) { vSlider1.value = 80; vVal1.textContent = '80%'; }
        if (powerToggle1) { powerToggle1.checked = true; card1.style.opacity = '1.0'; card1.style.filter = 'none'; }
        if (powerToggle2) { powerToggle2.checked = true; card2.style.opacity = '1.0'; card2.style.filter = 'none'; }
      } else if (preset === 'night') {
        if (bSlider1) { bSlider1.value = 15; bVal1.textContent = '15%'; }
        if (bSlider2) { bSlider2.value = 10; bVal2.textContent = '10%'; }
        if (vSlider1) { vSlider1.value = 30; vVal1.textContent = '30%'; }
      } else if (preset === 'gaming') {
        if (bSlider1) { bSlider1.value = 100; bVal1.textContent = '100%'; }
        const resSelect1 = document.getElementById('res-select-1');
        if (resSelect1) resSelect1.value = '1920x1080@144';
      } else if (preset === 'focus') {
        if (powerToggle2) { powerToggle2.checked = false; card2.style.opacity = '0.35'; card2.style.filter = 'grayscale(80%)'; }
      }
    });
  });

  // 6. Platform Installation Tabs
  const tabButtons = document.querySelectorAll('.tab-pill');
  const tabContents = document.querySelectorAll('.terminal-card');

  tabButtons.forEach(btn => {
    btn.addEventListener('click', () => {
      tabButtons.forEach(b => b.classList.remove('active'));
      tabContents.forEach(c => c.classList.remove('active'));

      btn.classList.add('active');
      const tabId = `tab-${btn.getAttribute('data-tab')}`;
      const targetContent = document.getElementById(tabId);
      if (targetContent) {
        targetContent.classList.add('active');
      }
    });
  });
});
