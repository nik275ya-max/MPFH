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
  width: min(80vw, 80vh);
  height: min(80vw, 80vh);
  max-width: 400px;
  max-height: 400px;
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
  top: -20px;
  left: -20px;
  right: -20px;
  bottom: -20px;
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
  padding: 2rem;
}

.mic-icon {
  width: 80px;
  height: 80px;
  margin-bottom: 1.5rem;
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
  width: 60px;
  height: 60px;
  border: 4px solid white;
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
  font-size: 1.5rem;
  font-weight: 600;
  text-shadow: 0 2px 4px rgba(0, 0, 0, 0.3);
  margin-bottom: 0.5rem;
  text-align: center;
}

.counter {
  font-size: 2rem;
  font-weight: 700;
  text-shadow: 0 2px 4px rgba(0, 0, 0, 0.3);
  margin-top: 0.5rem;
}

@media (max-width: 640px) {
  .mic-icon {
    width: 60px;
    height: 60px;
  }

  .status-text {
    font-size: 1.2rem;
  }

  .counter {
    font-size: 1.5rem;
  }
}
</style>
