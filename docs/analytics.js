const GA_MEASUREMENT_ID = "G-REPLACE-ME";
const CONSENT_KEY = "quibly_analytics_consent";

if (!GA_MEASUREMENT_ID.includes("REPLACE-ME")) {
  const storedConsent = localStorage.getItem(CONSENT_KEY);

  if (storedConsent === "granted") {
    loadAnalytics();
  } else if (storedConsent !== "denied") {
    showConsentBanner();
  }
}

function loadAnalytics() {
  if (window.gtag) {
    return;
  }

  window.dataLayer = window.dataLayer || [];
  window.gtag = function gtag() {
    window.dataLayer.push(arguments);
  };

  const gtagScript = document.createElement("script");
  gtagScript.async = true;
  gtagScript.src = `https://www.googletagmanager.com/gtag/js?id=${GA_MEASUREMENT_ID}`;
  document.head.appendChild(gtagScript);

  window.gtag("js", new Date());
  window.gtag("config", GA_MEASUREMENT_ID);

  document.addEventListener("click", (event) => {
    if (!(event.target instanceof Element)) {
      return;
    }

    const link = event.target.closest("a[href]");

    if (!link || !window.gtag) {
      return;
    }

    const href = link.getAttribute("href");

    if (href?.startsWith("mailto:")) {
      window.gtag("event", "contact_click", {
        event_category: "engagement",
        event_label: href,
      });
    }
  });
}

function showConsentBanner() {
  const banner = document.createElement("div");
  banner.className = "cookie-consent";
  banner.setAttribute("role", "dialog");
  banner.setAttribute("aria-label", "Analytics toestemming");
  banner.innerHTML = `
    <p>Quibly gebruikt Google Analytics om de website te verbeteren.</p>
    <div class="cookie-consent-actions">
      <button type="button" class="button button-secondary" data-consent="denied">Weigeren</button>
      <button type="button" class="button button-primary" data-consent="granted">Akkoord</button>
    </div>
  `;

  banner.addEventListener("click", (event) => {
    if (!(event.target instanceof HTMLButtonElement)) {
      return;
    }

    const consent = event.target.dataset.consent;

    if (!consent) {
      return;
    }

    localStorage.setItem(CONSENT_KEY, consent);
    banner.remove();

    if (consent === "granted") {
      loadAnalytics();
    }
  });

  document.addEventListener("DOMContentLoaded", () => {
    document.body.appendChild(banner);
  });
}
