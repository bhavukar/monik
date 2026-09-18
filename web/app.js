// Manage Your Display Minimalist Simulator & Interactive Script

document.addEventListener('DOMContentLoaded', () => {
  // Brightness Sliders
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

  // Volume Slider
  const vSlider1 = document.getElementById('volume-slider-1');
  const vVal1 = document.getElementById('volume-val-1');
  if (vSlider1 && vVal1) {
    vSlider1.addEventListener('input', (e) => {
      vVal1.textContent = `${e.target.value}%`;
    });
  }

  // Power Toggles
  const powerToggle1 = document.getElementById('power-toggle-1');
  const card1 = document.getElementById('card-1');
  if (powerToggle1 && card1) {
    powerToggle1.addEventListener('change', (e) => {
      card1.style.opacity = e.target.checked ? '1.0' : '0.4';
    });
  }

  const powerToggle2 = document.getElementById('power-toggle-2');
  const card2 = document.getElementById('card-2');
  if (powerToggle2 && card2) {
    powerToggle2.addEventListener('change', (e) => {
      card2.style.opacity = e.target.checked ? '1.0' : '0.4';
    });
  }

  // Presets Bar
  const presetButtons = document.querySelectorAll('.preset-pill');
  presetButtons.forEach(btn => {
    btn.addEventListener('click', () => {
      presetButtons.forEach(b => b.classList.remove('active'));
      btn.classList.add('active');

      const preset = btn.getAttribute('data-preset');
      if (preset === 'work') {
        if (bSlider1) { bSlider1.value = 100; bVal1.textContent = '100%'; }
        if (bSlider2) { bSlider2.value = 80; bVal2.textContent = '80%'; }
        if (powerToggle1) { powerToggle1.checked = true; card1.style.opacity = '1.0'; }
        if (powerToggle2) { powerToggle2.checked = true; card2.style.opacity = '1.0'; }
      } else if (preset === 'night') {
        if (bSlider1) { bSlider1.value = 15; bVal1.textContent = '15%'; }
        if (bSlider2) { bSlider2.value = 10; bVal2.textContent = '10%'; }
      } else if (preset === 'gaming') {
        if (bSlider1) { bSlider1.value = 100; bVal1.textContent = '100%'; }
        const resSelect1 = document.getElementById('res-select-1');
        if (resSelect1) resSelect1.value = '1920x1080@144';
      } else if (preset === 'focus') {
        if (powerToggle2) { powerToggle2.checked = false; card2.style.opacity = '0.4'; }
      }
    });
  });

  // Platform Tabs Switcher
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
