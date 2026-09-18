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

  // 2. Real-Time Web Browser Display Detection Engine
  const detectLiveDisplay = () => {
    const dpr = window.devicePixelRatio || 1;
    const isRetina = dpr > 1;
    const scaledW = window.screen.width;
    const scaledH = window.screen.height;
    const nativeW = Math.round(scaledW * dpr);
    const nativeH = Math.round(scaledH * dpr);

    // Color gamut & HDR detection
    const isP3 = window.matchMedia && window.matchMedia('(color-gamut: p3)').matches;
    const isHDR = window.matchMedia && window.matchMedia('(dynamic-range: high)').matches;
    const colorProfile = isP3 ? 'Display P3' : 'sRGB IEC61966-2.1';
    const hdrTag = isHDR ? ' • HDR' : '';

    // Calculate approximate diagonal & PPI
    const ppi = Math.round(Math.sqrt(nativeW * nativeW + nativeH * nativeH) / (isRetina ? 14.2 : 24.0));

    // Dynamic resolution dropdown options for Card 1
    const resSelect1 = document.getElementById('res-select-1');
    const cardName1 = document.getElementById('card-name-1');
    const badgeDetails = document.getElementById('live-detected-details');

    // Measure live refresh rate
    let frames = 0;
    let startTime = performance.now();
    const measureHz = () => {
      frames++;
      if (frames === 60) {
        const elapsed = performance.now() - startTime;
        const rawFps = Math.round((frames * 1000) / elapsed);
        let hz = 60;
        if (rawFps > 200) hz = 240;
        else if (rawFps > 150) hz = 165;
        else if (rawFps > 130) hz = 144;
        else if (rawFps > 100) hz = 120;
        else if (rawFps > 70) hz = 75;
        else hz = 60;

        // Update live badge
        if (badgeDetails) {
          badgeDetails.textContent = `${nativeW}×${nativeH} @ ${hz}Hz • ${dpr}x Retina • ${colorProfile}${hdrTag}`;
        }

        // Update card 1 dropdown
        if (resSelect1) {
          resSelect1.innerHTML = `
            <option value="native">${nativeW} x ${nativeH} @ ${hz}Hz (Native) ▾</option>
            <option value="retina">${scaledW} x ${scaledH} (${dpr}x Retina) ▾</option>
            <option value="scaled">${Math.round(scaledW * 1.2)} x ${Math.round(scaledH * 1.2)} (Scaled) ▾</option>
          `;
        }

        if (cardName1) {
          const isMac = navigator.userAgent.includes('Mac');
          cardName1.textContent = isMac ? (isRetina ? 'Built-in Retina Display' : 'Mac External Display') : 'Your Primary Display';
        }
      } else {
        requestAnimationFrame(measureHz);
      }
    };
    requestAnimationFrame(measureHz);

    // Initial fallback
    if (badgeDetails) {
      badgeDetails.textContent = `${nativeW}×${nativeH} • ${dpr}x Scale • ${colorProfile}`;
    }
  };

  detectLiveDisplay();
  window.addEventListener('resize', detectLiveDisplay);

  // 3. Live macOS Menu Bar Clock
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

  // 4. Brightness & Volume Sliders
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
  wireSlider('volume-slider-1', 'volume-val-1');
  wireSlider('volume-slider-2', 'volume-val-2');

  // 5. Power Toggles
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

  // 6. Presets Switcher
  const presetButtons = document.querySelectorAll('.pill-btn');
  const b1 = document.getElementById('brightness-slider-1');
  const b2 = document.getElementById('brightness-slider-2');
  const bv1 = document.getElementById('brightness-val-1');
  const bv2 = document.getElementById('brightness-val-2');

  presetButtons.forEach(btn => {
    btn.addEventListener('click', () => {
      presetButtons.forEach(b => b.classList.remove('active'));
      btn.classList.add('active');

      const preset = btn.getAttribute('data-preset');
      if (preset === 'work') {
        if (b1) { b1.value = 100; if (bv1) bv1.textContent = '100%'; }
        if (b2) { b2.value = 90; if (bv2) bv2.textContent = '90%'; }
      } else if (preset === 'night') {
        if (b1) { b1.value = 20; if (bv1) bv1.textContent = '20%'; }
        if (b2) { b2.value = 15; if (bv2) bv2.textContent = '15%'; }
      } else if (preset === 'gaming') {
        if (b1) { b1.value = 100; if (bv1) bv1.textContent = '100%'; }
        if (b2) { b2.value = 100; if (bv2) bv2.textContent = '100%'; }
      }
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
