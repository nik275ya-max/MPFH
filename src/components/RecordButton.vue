<template>
  <div class="record-container">
    <button
      @click="toggleRecording"
      class="record-button"
      :class="{ recording: isRecording }"
    >
      <div class="glow-effect"></div>
      <div class="button-content">
        <div class="mic-icon">
          <svg v-if="!isRecording" xmlns="http://www.w3.org/2000/svg" viewBox="0 0 24 24" fill="currentColor">
            <path d="M12 14c1.66 0 3-1.34 3-3V5c0-1.66-1.34-3-3-3S9 3.34 9 5v6c0 1.66 1.34 3 3 3z"/>
            <path d="M17 11c0 2.76-2.24 5-5 5s-5-2.24-5-5H5c0 3.53 2.61 6.43 6 6.92V21h2v-3.08c3.39-.49 6-3.39 6-6.92h-2z"/>
          </svg>
          <div v-else class="pulse-ring"></div>
        </div>
        <div class="status-text">
          {{ isRecording ? 'Идёт запись...' : 'Нажмите для записи' }}
        </div>
        <div v-if="replies.length > 0" class="counter">
          {{ replies.length }} / {{ maxReplies }}
        </div>
      </div>
    </button>
  </div>
</template>

<script setup lang="ts">
import { useRecording } from '../composables/useRecording'

defineProps<{
  maxReplies: number
}>()

const { isRecording, replies, startRecording, stopRecording } = useRecording()

const toggleRecording = () => {
  if (isRecording.value) {
    stopRecording()
  } else {
    startRecording()
  }
}
</script>

<style scoped>
.record-container {
  display: flex;
  align-items: center;
  justify-content: center;
  width: 100%;
  height: 100%;
  padding: 2rem;
}

.record-button {
  position: relative;
  width: calc(min(80vw, 80vh) * var(--ui-scale, 1));
  height: calc(min(80vw, 80vh) * var(--ui-scale, 1));
  max-width: calc(400px * var(--ui-scale, 1));
  max-height: calc(400px * var(--ui-scale, 1));
  border-radius: 50%;
  border: none;
  background: linear-gradient(135deg, #667eea 0%, #764ba2 100%);
  cursor: pointer;
  transition: all 0.3s ease;
  overflow: visible;
}

.record-button:active {
  transform: scale(0.95);
}

.record-button.recording {
  background: linear-gradient(135deg, #f093fb 0%, #f5576c 100%);
  animation: pulse 2s infinite;
}

@keyframes pulse {
  0%, 100% {
    transform: scale(1);
  }
  50% {
    transform: scale(1.05);
  }
}

.glow-effect {
  position: absolute;
  top: calc(-20px * var(--ui-scale, 1));
  left: calc(-20px * var(--ui-scale, 1));
  right: calc(-20px * var(--ui-scale, 1));
  bottom: calc(-20px * var(--ui-scale, 1));
  border-radius: 50%;
  background: inherit;
  filter: blur(30px);
  opacity: 0.6;
  z-index: -1;
  animation: glow 3s ease-in-out infinite;
}

@keyframes glow {
  0%, 100% {
    opacity: 0.6;
  }
  50% {
    opacity: 0.9;
  }
}

.button-content {
  display: flex;
  flex-direction: column;
  align-items: center;
  justify-content: center;
  height: 100%;
  color: white;
  padding: calc(2rem * var(--ui-scale, 1));
}

.mic-icon {
  width: calc(80px * var(--ui-scale, 1));
  height: calc(80px * var(--ui-scale, 1));
  margin-bottom: calc(1.5rem * var(--ui-scale, 1));
  display: flex;
  align-items: center;
  justify-content: center;
}

.mic-icon svg {
  width: 100%;
  height: 100%;
  filter: drop-shadow(0 4px 6px rgba(0, 0, 0, 0.3));
}

.pulse-ring {
  width: calc(60px * var(--ui-scale, 1));
  height: calc(60px * var(--ui-scale, 1));
  border: calc(4px * var(--ui-scale, 1)) solid white;
  border-radius: 50%;
  animation: pulse-ring 1.5s ease-out infinite;
}

@keyframes pulse-ring {
  0% {
    transform: scale(0.8);
    opacity: 1;
  }
  100% {
    transform: scale(1.5);
    opacity: 0;
  }
}

.status-text {
  font-size: calc(1.5rem * var(--ui-scale, 1));
  font-weight: 600;
  text-shadow: 0 2px 4px rgba(0, 0, 0, 0.3);
  margin-bottom: calc(0.5rem * var(--ui-scale, 1));
  text-align: center;
}

.counter {
  font-size: calc(2rem * var(--ui-scale, 1));
  font-weight: 700;
  text-shadow: 0 2px 4px rgba(0, 0, 0, 0.3);
  margin-top: calc(0.5rem * var(--ui-scale, 1));
}

@media (max-width: 640px) {
  .mic-icon {
    width: calc(60px * var(--ui-scale, 1));
    height: calc(60px * var(--ui-scale, 1));
  }

  .status-text {
    font-size: calc(1.2rem * var(--ui-scale, 1));
  }

  .counter {
    font-size: calc(1.5rem * var(--ui-scale, 1));
  }
}
</style>
