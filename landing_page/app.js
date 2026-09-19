/**
 * PIR-App - Portal de Distribuição
 * Deteção inteligente de plataforma e gestão de downloads/instalação
 */

const CONFIG = {
  version: 'v1.2.0',
  windowsSize: '11.5 MB',
  windowsDownloadUrl: 'downloads/PIR_App_v1.2.0_Setup.exe',
  webAppUrl: 'https://vie1r4.github.io/PIR-app/',
  githubUrl: 'https://github.com/Vie1r4/PIR-app'
};

const SVG_ICONS = {
  windows: `<svg class="cta-icon" viewBox="0 0 24 24" fill="currentColor"><path d="M0 3.449L9.75 2.1v9.451H0m10.949-9.602L24 0v11.4H10.949M0 12.6h9.75v9.451L0 20.699M10.949 12.6H24V24l-12.9-1.801"/></svg>`,
  apple: `<svg class="cta-icon" viewBox="0 0 24 24" fill="currentColor"><path d="M18.71 19.5c-.83 1.24-1.71 2.45-3.05 2.47-1.34.03-1.77-.79-3.29-.79-1.53 0-2 .77-3.27.82-1.31.05-2.3-1.32-3.14-2.53C4.25 17 2.94 12.45 4.7 9.39c.87-1.52 2.43-2.48 4.12-2.51 1.28-.02 2.5.87 3.29.87.78 0 2.26-1.07 3.81-.91.65.03 2.47.26 3.64 1.98-.09.06-2.17 1.28-2.15 3.81.03 3.02 2.65 4.03 2.68 4.04-.03.07-.42 1.44-1.38 2.83M15.97 4.2c.62-.75 1.04-1.8 0.92-2.85-.9.04-1.99.6-2.61 1.35-.55.63-.99 1.68-.86 2.7.99.08 2.02-.45 2.55-1.2"/></svg>`,
  android: `<svg class="cta-icon" viewBox="0 0 24 24" fill="currentColor"><path d="M17.523 15.3414c-.5511 0-.9993-.4486-.9993-1.0003 0-.5517.4482-1.0003.9993-1.0003.5517 0 1.0003.4486 1.0003 1.0003 0 .5517-.4486 1.0003-1.0003 1.0003m-11.046 0c-.5511 0-.9993-.4486-.9993-1.0003 0-.5517.4482-1.0003.9993-1.0003.5517 0 1.0003.4486 1.0003 1.0003 0 .5517-.4486 1.0003-1.0003 1.0003m11.4045-6.02l1.9973-3.4592a.416.416 0 00-.1521-.5676.416.416 0 00-.5676.1521l-2.0223 3.503C15.5902 8.411 13.8533 8.087 12 8.087c-1.8534 0-3.5902.324-5.1368.8627L4.8409 5.4467a.416.416 0 00-.5676-.1521.416.416 0 00-.1521.5676l1.9973 3.4592C2.6889 11.1867.3432 14.6589 0 18.761h24c-.3432-4.1021-2.6889-7.5743-6.1185-9.4396"/></svg>`,
  globe: `<svg class="cta-icon" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2"><circle cx="12" cy="12" r="10"/><path d="M2 12h20M12 2a15.3 15.3 0 0 1 4 10 15.3 15.3 0 0 1-4 10 15.3 15.3 0 0 1-4-10 15.3 15.3 0 0 1 4-10z"/></svg>`
};

function detectPlatform() {
  const ua = navigator.userAgent || navigator.vendor || window.opera;
  const platform = navigator.userAgentData?.platform || navigator.platform || '';

  if (/iPad|iPhone|iPod/.test(ua) || (platform === 'MacIntel' && navigator.maxTouchPoints > 1)) {
    return 'ios';
  }
  if (/Android/.test(ua)) {
    return 'android';
  }
  if (/Win/.test(platform) || /Windows/.test(ua)) {
    return 'windows';
  }
  if (/Mac/.test(platform) || /Macintosh/.test(ua)) {
    return 'mac';
  }
  return 'other';
}

function setupSmartCTA() {
  const os = detectPlatform();
  const ctaBtn = document.getElementById('smart-cta-btn');
  const ctaIconBox = document.getElementById('smart-cta-icon');
  const ctaTitle = document.getElementById('smart-cta-title');
  const ctaSub = document.getElementById('smart-cta-sub');

  if (!ctaBtn) return;

  switch (os) {
    case 'windows':
      ctaIconBox.innerHTML = SVG_ICONS.windows;
      ctaTitle.textContent = 'Descarregar para Windows';
      ctaSub.textContent = `Instalador Oficial • ${CONFIG.version} (${CONFIG.windowsSize})`;
      ctaBtn.href = CONFIG.windowsDownloadUrl;
      ctaBtn.setAttribute('download', 'PIR_App_v1.2.0_Setup.exe');
      ctaBtn.onclick = null;
      break;

    case 'ios':
      ctaIconBox.innerHTML = SVG_ICONS.apple;
      ctaTitle.textContent = 'Instalar no iPhone';
      ctaSub.textContent = 'Adicionar ao Ecrã Principal • Sem App Store';
      ctaBtn.href = '#';
      ctaBtn.removeAttribute('download');
      ctaBtn.onclick = function (e) {
        e.preventDefault();
        openIosModal();
      };
      break;

    case 'android':
      ctaIconBox.innerHTML = SVG_ICONS.android;
      ctaTitle.textContent = 'Abrir Aplicação (Android)';
      ctaSub.textContent = 'Web App Oficial • Instalação Rápida';
      ctaBtn.href = CONFIG.webAppUrl;
      ctaBtn.removeAttribute('download');
      ctaBtn.target = '_blank';
      break;

    default:
      ctaIconBox.innerHTML = SVG_ICONS.globe;
      ctaTitle.textContent = 'Abrir no Navegador';
      ctaSub.textContent = 'Versão Web Completa • Todos os Dispositivos';
      ctaBtn.href = CONFIG.webAppUrl;
      ctaBtn.removeAttribute('download');
      ctaBtn.target = '_blank';
      break;
  }
}

function openIosModal() {
  const modal = document.getElementById('ios-modal');
  if (modal) {
    modal.classList.add('active');
    document.body.style.overflow = 'hidden';
  }
}

function closeIosModal() {
  const modal = document.getElementById('ios-modal');
  if (modal) {
    modal.classList.remove('active');
    document.body.style.overflow = '';
  }
}

document.addEventListener('DOMContentLoaded', () => {
  setupSmartCTA();

  // Fechar modal ao clicar fora do cartão
  const modal = document.getElementById('ios-modal');
  if (modal) {
    modal.addEventListener('click', (e) => {
      if (e.target === modal) {
        closeIosModal();
      }
    });
  }

  // Tecla Escape fecha modal
  document.addEventListener('keydown', (e) => {
    if (e.key === 'Escape') {
      closeIosModal();
    }
  });
});
