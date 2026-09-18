// Manage Your Display Landing Page & Interactive Simulator
import { createPrism } from './prism.js';

document.addEventListener('DOMContentLoaded', () => {
  // 1. Initialize React Bits Prism Component (Subtle ambient glow)
  const prismContainer = document.getElementById('prism-canvas-container');
  if (prismContainer) {
    createPrism(prismContainer, {
      animationType: 'hover',
      timeScale: 0.35,
      height: 3.5,
      baseWidth: 5.5,
      scale: 1.5,
      hueShift: 0,
      colorFrequency: 1.0,
      noise: 0.02,
      glow: 1.1,
      bloom: 1.15,
      transparent: true,
      hoverStrength: 1.6,
      inertia: 0.06
    });
  }

  // 2. Live macOS Menu Bar Clock
  const clockEl = document.getElementById('sim-clock');
  const updateClock = () => {
    if (!clockEl) return;
    const now = new Date();
    const days = ['Sun', 'Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat'];
    const months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
    const day = days[now.getDay()];
    const date = now.getDate();
    const month = months[now.getMonth()];
    let hours = now.getHours();
    const minutes = now.getMinutes().toString().padStart(2, '0');
    const ampm = hours >= 12 ? 'PM' : 'AM';
    hours = hours % 12 || 12;
    clockEl.textContent = `${day} ${date} ${month} ${hours}:${minutes} ${ampm}`;
  };
  updateClock();
  setInterval(updateClock, 30000);

  // 3. Brightness Sliders for 3 Displays
  const wireSlider = (sliderId, valId) => {
    const slider = document.getElementById(sliderId);
    const val = document.getElementById(valId);
    if (slider && val) {
      slider.addEventListener('input', (e) => {
        val.textContent = `${e.target.value}%`;
      });
    }
  };
  wireSlider('brightness-slider-1', 'brightness-val-1');
  wireSlider('brightness-slider-2', 'brightness-val-2');
  wireSlider('brightness-slider-3', 'brightness-val-3');
  wireSlider('volume-slider-1', 'volume-val-1');
  wireSlider('volume-slider-2', 'volume-val-2');
  wireSlider('volume-slider-3', 'volume-val-3');

  // 4. Power Toggles for 3 Displays
  const wirePower = (toggleId, cardId) => {
    const toggle = document.getElementById(toggleId);
    const card = document.getElementById(cardId);
    if (toggle && card) {
      toggle.addEventListener('change', (e) => {
        card.style.opacity = e.target.checked ? '1.0' : '0.35';
        card.style.filter = e.target.checked ? 'none' : 'grayscale(80%)';
      });
    }
  };
  wirePower('power-toggle-1', 'pop-card-1');
  wirePower('power-toggle-2', 'pop-card-2');
  wirePower('power-toggle-3', 'pop-card-3');

  // 5. Presets Switcher
  const presetButtons = document.querySelectorAll('.pill-btn');
  const b1 = document.getElementById('brightness-slider-1');
  const b2 = document.getElementById('brightness-slider-2');
  const b3 = document.getElementById('brightness-slider-3');
  const bv1 = document.getElementById('brightness-val-1');
  const bv2 = document.getElementById('brightness-val-2');
  const bv3 = document.getElementById('brightness-val-3');

  presetButtons.forEach(btn => {
    btn.addEventListener('click', () => {
      presetButtons.forEach(b => b.classList.remove('active'));
      btn.classList.add('active');

      const preset = btn.getAttribute('data-preset');
      if (preset === 'work') {
        if (b1) { b1.value = 100; if (bv1) bv1.textContent = '100%'; }
        if (b2) { b2.value = 90; if (bv2) bv2.textContent = '90%'; }
        if (b3) { b3.value = 85; if (bv3) bv3.textContent = '85%'; }
      } else if (preset === 'night') {
        if (b1) { b1.value = 20; if (bv1) bv1.textContent = '20%'; }
        if (b2) { b2.value = 15; if (bv2) bv2.textContent = '15%'; }
        if (b3) { b3.value = 10; if (bv3) bv3.textContent = '10%'; }
      } else if (preset === 'gaming') {
        if (b1) { b1.value = 100; if (bv1) bv1.textContent = '100%'; }
        if (b2) { b2.value = 100; if (bv2) bv2.textContent = '100%'; }
        if (b3) { b3.value = 100; if (bv3) bv3.textContent = '100%'; }
        const r2 = document.getElementById('res-select-2');
        if (r2) r2.value = '1920x1080@144';
      }
    });
  });

  // 6. Settings Sidebar & Device Tabs
  const sbBtns = document.querySelectorAll('.sb-btn');
  sbBtns.forEach(btn => {
    btn.addEventListener('click', () => {
      sbBtns.forEach(b => b.classList.remove('active'));
      btn.classList.add('active');
    });
  });

  const devTabs = document.querySelectorAll('.dev-tab');
  devTabs.forEach(tab => {
    tab.addEventListener('click', () => {
      devTabs.forEach(t => t.classList.remove('active'));
      tab.classList.add('active');
    });
  });

  // 7. Platform Installation Tabs
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
