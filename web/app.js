// Sample clippings for the interactive simulator
const sampleClippings = [
  {
    id: 1,
    title: "1. Swift Package Manager Dependency",
    app: "From Safari",
    content: `.package(url: "https://github.com/apple/swift-package-manager.git", from: "6.0.0")`
  },
  {
    id: 2,
    title: "2. Terminal LaunchAgent Reload Command",
    app: "From Terminal",
    content: `launchctl unload ~/Library/LaunchAgents/com.arjun.arjunclipper.plist\nlaunchctl load ~/Library/LaunchAgents/com.arjun.arjunclipper.plist`
  },
  {
    id: 3,
    title: "3. Docker Run PostgreSQL Database",
    app: "From VS Code",
    content: `docker run --name local-postgres -e POSTGRES_PASSWORD=secret -p 5432:5432 -d postgres:16-alpine`
  },
  {
    id: 4,
    title: "4. Claude Code Fast Execution Prompt",
    app: "From ChatGPT",
    content: `Please review the swift changeCount logic and verify non-blocking Carbon hotkey registration.`
  },
  {
    id: 5,
    title: "5. Git Stash and Branch Switch",
    app: "From Terminal",
    content: `git stash push -m "wip: bezel hud update" && git checkout main && git pull`
  }
];

let currentIndex = 0;

function renderDemoList() {
  const listEl = document.getElementById("clippings-list");
  if (!listEl) return;
  listEl.innerHTML = "";

  sampleClippings.forEach((clip, index) => {
    const item = document.createElement("div");
    item.className = `demo-clip-item ${index === currentIndex ? "active" : ""}`;
    item.innerHTML = `
      <div class="clip-meta-left">
        <span class="clip-index-title">${clip.title}</span>
        <span class="clip-source-tag">${clip.app}</span>
      </div>
      <span class="clip-action-hint">${index === currentIndex ? "Active" : "Click to view"}</span>
    `;
    item.addEventListener("click", () => {
      currentIndex = index;
      updateHudViews();
    });
    listEl.appendChild(item);
  });
}

function updateHudViews() {
  const clip = sampleClippings[currentIndex];
  if (!clip) return;

  // Hero HUD
  const heroTitle = document.getElementById("hud-title");
  const heroApp = document.getElementById("hud-app");
  const heroContent = document.getElementById("hud-content");
  if (heroTitle) heroTitle.textContent = `Clipping #${clip.id} of ${sampleClippings.length}`;
  if (heroApp) heroApp.textContent = clip.app;
  if (heroContent) heroContent.textContent = clip.content;

  // Demo Standalone HUD
  const demoTitle = document.getElementById("demo-hud-title");
  const demoApp = document.getElementById("demo-hud-app");
  const demoContent = document.getElementById("demo-hud-content");
  if (demoTitle) demoTitle.textContent = `Clipping #${clip.id} of ${sampleClippings.length}`;
  if (demoApp) demoApp.textContent = clip.app;
  if (demoContent) demoContent.textContent = clip.content;

  renderDemoList();
}

// Arrow key cycling in demo
window.addEventListener("keydown", (e) => {
  if (e.key === "ArrowDown") {
    currentIndex = (currentIndex + 1) % sampleClippings.length;
    updateHudViews();
    e.preventDefault();
  } else if (e.key === "ArrowUp") {
    currentIndex = (currentIndex - 1 + sampleClippings.length) % sampleClippings.length;
    updateHudViews();
    e.preventDefault();
  }
});

// Auto-rotate hero preview every 4 seconds if idle
let autoRotateTimer = setInterval(() => {
  currentIndex = (currentIndex + 1) % sampleClippings.length;
  updateHudViews();
}, 4500);

// Stop auto rotation once user interacts
window.addEventListener("click", () => {
  clearInterval(autoRotateTimer);
}, { once: true });

document.addEventListener("DOMContentLoaded", () => {
  renderDemoList();
  updateHudViews();
});
