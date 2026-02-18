<script setup lang="ts">
</script>

<template>
  <div class="sync-animation">
    <!-- Scene 1: Single Client -->
    <div class="scene">
      <div class="scene-label">Single Client</div>
      <div class="scene-content">
        <div class="node client-node">
          <svg viewBox="0 0 48 48" class="icon">
            <!-- Phone -->
            <rect x="12" y="4" width="24" height="40" rx="4" fill="none" stroke="currentColor" stroke-width="2.5"/>
            <line x1="20" y1="38" x2="28" y2="38" stroke="currentColor" stroke-width="2" stroke-linecap="round"/>
            <rect x="16" y="10" width="16" height="22" rx="1" fill="currentColor" opacity="0.1"/>
          </svg>
          <span class="node-label">App</span>
        </div>

        <div class="connection single-connection">
          <svg viewBox="0 0 120 40" class="connection-line" preserveAspectRatio="none">
            <line x1="0" y1="16" x2="120" y2="16" stroke="currentColor" stroke-width="1.5" opacity="0.15"/>
            <line x1="0" y1="24" x2="120" y2="24" stroke="currentColor" stroke-width="1.5" opacity="0.15"/>
          </svg>
          <!-- Push dots (left to right) -->
          <div class="dot dot-push dot-push-1"></div>
          <div class="dot dot-push dot-push-2"></div>
          <div class="dot dot-push dot-push-3"></div>
          <!-- Pull dots (right to left) -->
          <div class="dot dot-pull dot-pull-1"></div>
          <div class="dot dot-pull dot-pull-2"></div>
          <div class="dot dot-pull dot-pull-3"></div>
          <span class="flow-label flow-push">push</span>
          <span class="flow-label flow-pull">pull</span>
        </div>

        <div class="node server-node">
          <svg viewBox="0 0 48 48" class="icon">
            <!-- Server/Cloud -->
            <rect x="8" y="6" width="32" height="10" rx="3" fill="none" stroke="currentColor" stroke-width="2.5"/>
            <circle cx="14" cy="11" r="2" fill="currentColor" opacity="0.4"/>
            <circle cx="20" cy="11" r="2" fill="currentColor" opacity="0.4"/>
            <rect x="8" y="19" width="32" height="10" rx="3" fill="none" stroke="currentColor" stroke-width="2.5"/>
            <circle cx="14" cy="24" r="2" fill="currentColor" opacity="0.4"/>
            <circle cx="20" cy="24" r="2" fill="currentColor" opacity="0.4"/>
            <rect x="8" y="32" width="32" height="10" rx="3" fill="none" stroke="currentColor" stroke-width="2.5"/>
            <circle cx="14" cy="37" r="2" fill="currentColor" opacity="0.4"/>
            <circle cx="20" cy="37" r="2" fill="currentColor" opacity="0.4"/>
          </svg>
          <span class="node-label">Server</span>
        </div>
      </div>
    </div>

    <!-- Scene 2: Multi Client -->
    <div class="scene scene-multi">
      <div class="scene-label">Multi Client</div>
      <div class="scene-content multi-content">
        <div class="multi-clients">
          <!-- Client 1: Phone -->
          <div class="node client-node multi-node">
            <svg viewBox="0 0 48 48" class="icon icon-sm">
              <rect x="12" y="4" width="24" height="40" rx="4" fill="none" stroke="currentColor" stroke-width="2.5"/>
              <line x1="20" y1="38" x2="28" y2="38" stroke="currentColor" stroke-width="2" stroke-linecap="round"/>
              <rect x="16" y="10" width="16" height="22" rx="1" fill="currentColor" opacity="0.1"/>
            </svg>
          </div>
          <!-- Client 2: Tablet -->
          <div class="node client-node multi-node">
            <svg viewBox="0 0 48 48" class="icon icon-sm">
              <rect x="6" y="8" width="36" height="32" rx="4" fill="none" stroke="currentColor" stroke-width="2.5"/>
              <circle cx="24" cy="34" r="2" fill="currentColor" opacity="0.4"/>
              <rect x="10" y="12" width="28" height="18" rx="1" fill="currentColor" opacity="0.1"/>
            </svg>
          </div>
          <!-- Client 3: Laptop -->
          <div class="node client-node multi-node">
            <svg viewBox="0 0 48 48" class="icon icon-sm">
              <rect x="8" y="10" width="32" height="22" rx="3" fill="none" stroke="currentColor" stroke-width="2.5"/>
              <rect x="12" y="14" width="24" height="14" rx="1" fill="currentColor" opacity="0.1"/>
              <path d="M4 32 L44 32 L40 38 L8 38 Z" fill="none" stroke="currentColor" stroke-width="2.5" stroke-linejoin="round"/>
            </svg>
          </div>
        </div>

        <div class="multi-connections">
          <svg viewBox="0 0 100 120" class="multi-lines" preserveAspectRatio="none">
            <!-- Line from client 1 to server -->
            <line x1="0" y1="20" x2="100" y2="60" stroke="currentColor" stroke-width="1.5" opacity="0.15"/>
            <!-- Line from client 2 to server -->
            <line x1="0" y1="60" x2="100" y2="60" stroke="currentColor" stroke-width="1.5" opacity="0.15"/>
            <!-- Line from client 3 to server -->
            <line x1="0" y1="100" x2="100" y2="60" stroke="currentColor" stroke-width="1.5" opacity="0.15"/>
          </svg>
          <!-- Dots for each connection -->
          <div class="dot-multi dot-m1-push"></div>
          <div class="dot-multi dot-m1-pull"></div>
          <div class="dot-multi dot-m2-push"></div>
          <div class="dot-multi dot-m2-pull"></div>
          <div class="dot-multi dot-m3-push"></div>
          <div class="dot-multi dot-m3-pull"></div>
        </div>

        <div class="node server-node multi-server">
          <svg viewBox="0 0 48 48" class="icon">
            <rect x="8" y="6" width="32" height="10" rx="3" fill="none" stroke="currentColor" stroke-width="2.5"/>
            <circle cx="14" cy="11" r="2" fill="currentColor" opacity="0.4"/>
            <circle cx="20" cy="11" r="2" fill="currentColor" opacity="0.4"/>
            <rect x="8" y="19" width="32" height="10" rx="3" fill="none" stroke="currentColor" stroke-width="2.5"/>
            <circle cx="14" cy="24" r="2" fill="currentColor" opacity="0.4"/>
            <circle cx="20" cy="24" r="2" fill="currentColor" opacity="0.4"/>
            <rect x="8" y="32" width="32" height="10" rx="3" fill="none" stroke="currentColor" stroke-width="2.5"/>
            <circle cx="14" cy="37" r="2" fill="currentColor" opacity="0.4"/>
            <circle cx="20" cy="37" r="2" fill="currentColor" opacity="0.4"/>
          </svg>
          <span class="node-label">Server</span>
        </div>
      </div>
    </div>
  </div>
</template>

<style scoped>
.sync-animation {
  display: flex;
  flex-direction: column;
  gap: 32px;
  padding: 20px 0;
  user-select: none;
}

.scene {
  background: var(--vp-c-bg-soft);
  border: 1px solid var(--vp-c-divider);
  border-radius: 16px;
  padding: 20px 24px 24px;
}

.scene-label {
  font-size: 0.75em;
  font-weight: 600;
  text-transform: uppercase;
  letter-spacing: 0.08em;
  color: var(--vp-c-text-3);
  margin-bottom: 16px;
  text-align: center;
}

.scene-content {
  display: flex;
  align-items: center;
  justify-content: center;
  gap: 0;
}

.node {
  display: flex;
  flex-direction: column;
  align-items: center;
  gap: 6px;
  flex-shrink: 0;
}

.icon {
  width: 48px;
  height: 48px;
  color: var(--vp-c-brand-1);
}

.icon-sm {
  width: 36px;
  height: 36px;
}

.node-label {
  font-size: 0.7em;
  font-weight: 500;
  color: var(--vp-c-text-2);
}

/* ── Single connection ── */
.connection {
  position: relative;
  width: 120px;
  height: 56px;
  flex-shrink: 0;
}

.connection-line {
  position: absolute;
  top: 0;
  left: 0;
  width: 100%;
  height: 40px;
  color: var(--vp-c-brand-1);
}

.flow-label {
  position: absolute;
  font-size: 0.55em;
  font-weight: 500;
  letter-spacing: 0.05em;
  color: var(--vp-c-text-3);
}
.flow-push { top: 2px; left: 50%; transform: translateX(-50%); }
.flow-pull { bottom: 4px; left: 50%; transform: translateX(-50%); }

/* Dots */
.dot {
  position: absolute;
  width: 7px;
  height: 7px;
  border-radius: 50%;
  opacity: 0;
}

/* Push dots — orange (brand) */
.dot-push {
  top: 12px;
  background: var(--vp-c-brand-1);
  animation: push-dot 3s ease-in-out infinite;
}
.dot-push-1 { animation-delay: 0s; }
.dot-push-2 { animation-delay: 1s; }
.dot-push-3 { animation-delay: 2s; }

/* Pull dots — green */
.dot-pull {
  top: 20px;
  background: var(--vp-c-green-1, #10b981);
  animation: pull-dot 3s ease-in-out infinite;
}
.dot-pull-1 { animation-delay: 0.5s; }
.dot-pull-2 { animation-delay: 1.5s; }
.dot-pull-3 { animation-delay: 2.5s; }

@keyframes push-dot {
  0% { left: 4px; opacity: 0; }
  10% { opacity: 0.9; }
  80% { opacity: 0.9; }
  100% { left: 108px; opacity: 0; }
}

@keyframes pull-dot {
  0% { left: 108px; opacity: 0; }
  10% { opacity: 0.9; }
  80% { opacity: 0.9; }
  100% { left: 4px; opacity: 0; }
}

/* ── Multi client ── */
.multi-content {
  display: flex;
  align-items: center;
  justify-content: center;
  gap: 0;
}

.multi-clients {
  display: flex;
  flex-direction: column;
  gap: 12px;
  flex-shrink: 0;
}

.multi-node {
  gap: 2px;
}

.multi-connections {
  position: relative;
  width: 100px;
  height: 120px;
  flex-shrink: 0;
}

.multi-lines {
  position: absolute;
  top: 0;
  left: 0;
  width: 100%;
  height: 100%;
  color: var(--vp-c-brand-1);
}

.multi-server {
  align-self: center;
}

/* Multi dots */
.dot-multi {
  position: absolute;
  width: 6px;
  height: 6px;
  border-radius: 50%;
  opacity: 0;
}

/* Client 1 → Server (top-left to middle-right, diagonal) */
.dot-m1-push {
  background: var(--vp-c-brand-1);
  animation: m1-push 3.5s ease-in-out infinite;
}
.dot-m1-pull {
  background: var(--vp-c-green-1, #10b981);
  animation: m1-pull 3.5s ease-in-out infinite;
  animation-delay: 0.8s;
}
@keyframes m1-push {
  0% { left: 4px; top: 17px; opacity: 0; }
  10% { opacity: 0.85; }
  80% { opacity: 0.85; }
  100% { left: 90px; top: 57px; opacity: 0; }
}
@keyframes m1-pull {
  0% { left: 90px; top: 57px; opacity: 0; }
  10% { opacity: 0.85; }
  80% { opacity: 0.85; }
  100% { left: 4px; top: 17px; opacity: 0; }
}

/* Client 2 → Server (middle, straight) */
.dot-m2-push {
  background: var(--vp-c-brand-1);
  animation: m2-push 3s ease-in-out infinite;
  animation-delay: 0.4s;
}
.dot-m2-pull {
  background: var(--vp-c-green-1, #10b981);
  animation: m2-pull 3s ease-in-out infinite;
  animation-delay: 1.2s;
}
@keyframes m2-push {
  0% { left: 4px; top: 57px; opacity: 0; }
  10% { opacity: 0.85; }
  80% { opacity: 0.85; }
  100% { left: 90px; top: 57px; opacity: 0; }
}
@keyframes m2-pull {
  0% { left: 90px; top: 57px; opacity: 0; }
  10% { opacity: 0.85; }
  80% { opacity: 0.85; }
  100% { left: 4px; top: 57px; opacity: 0; }
}

/* Client 3 → Server (bottom-left to middle-right, diagonal) */
.dot-m3-push {
  background: var(--vp-c-brand-1);
  animation: m3-push 4s ease-in-out infinite;
  animation-delay: 0.9s;
}
.dot-m3-pull {
  background: var(--vp-c-green-1, #10b981);
  animation: m3-pull 4s ease-in-out infinite;
  animation-delay: 2s;
}
@keyframes m3-push {
  0% { left: 4px; top: 97px; opacity: 0; }
  10% { opacity: 0.85; }
  80% { opacity: 0.85; }
  100% { left: 90px; top: 57px; opacity: 0; }
}
@keyframes m3-pull {
  0% { left: 90px; top: 57px; opacity: 0; }
  10% { opacity: 0.85; }
  80% { opacity: 0.85; }
  100% { left: 4px; top: 97px; opacity: 0; }
}

/* ── Responsive ── */
@media (max-width: 768px) {
  .sync-animation {
    gap: 20px;
    padding: 10px 0;
  }
  .scene {
    padding: 14px 16px 18px;
  }
  .connection { width: 80px; }
  .multi-connections { width: 70px; }

  @keyframes push-dot {
    0% { left: 4px; opacity: 0; }
    10% { opacity: 0.9; }
    80% { opacity: 0.9; }
    100% { left: 70px; opacity: 0; }
  }
  @keyframes pull-dot {
    0% { left: 70px; opacity: 0; }
    10% { opacity: 0.9; }
    80% { opacity: 0.9; }
    100% { left: 4px; opacity: 0; }
  }
}

/* Reduce motion */
@media (prefers-reduced-motion: reduce) {
  .dot, .dot-multi {
    animation-duration: 0s !important;
    opacity: 0.5 !important;
  }
  .dot-push-1 { left: 30px !important; }
  .dot-push-2 { left: 56px !important; }
  .dot-push-3 { left: 82px !important; }
  .dot-pull-1 { left: 82px !important; }
  .dot-pull-2 { left: 56px !important; }
  .dot-pull-3 { left: 30px !important; }
}
</style>
