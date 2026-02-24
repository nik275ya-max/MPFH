<template>
  <div class="qr-container">
    <div class="qr-wrapper">
      <div class="qr-glow"></div>
      <canvas ref="qrCanvas" class="qr-canvas"></canvas>
    </div>

    <div class="qr-info">
      <h3>QR код успешно создан!</h3>
      <p>Содержимое: {{ repliesCount }} реплик</p>
    </div>

    <button @click="resetRecording" class="reset-button">
      Начать заново
    </button>
  </div>
</template>

<script setup lang="ts">
import { ref, onMounted, watch } from 'vue'
import QRCode from 'qrcode'

const props = defineProps<{
  instruction: string
  replies: string[]
}>()

const emit = defineEmits<{
  reset: []
}>()

const qrCanvas = ref<HTMLCanvasElement | null>(null)
const repliesCount = ref(props.replies.length)

const generateQRCode = async () => {
  if (!qrCanvas.value) return

  const qrData = `${props.instruction}\n\n${props.replies.map((reply, index) => `${index + 1}. ${reply}`).join('\n')}`

  try {
    await QRCode.toCanvas(qrCanvas.value, qrData, {
      width: 300,
      margin: 2,
      color: {
        dark: '#000000',
        light: '#ffffff'
      },
      errorCorrectionLevel: 'M'
    })
  } catch (error) {
    console.error('Failed to generate QR code:', error)
  }
}

const resetRecording = () => {
  emit('reset')
}

onMounted(() => {
  generateQRCode()
})

watch(() => props.replies, () => {
  generateQRCode()
  repliesCount.value = props.replies.length
}, { deep: true })
</script>

<style scoped>
.qr-container {
  display: flex;
  flex-direction: column;
  align-items: center;
  justify-content: center;
  height: 100%;
  padding: 2rem;
  gap: 2rem;
}

.qr-wrapper {
  position: relative;
  padding: 2rem;
  background: white;
  border-radius: 20px;
  box-shadow: 0 20px 60px rgba(0, 0, 0, 0.3);
}

.qr-glow {
  position: absolute;
  top: -10px;
  left: -10px;
  right: -10px;
  bottom: -10px;
  background: linear-gradient(135deg, #667eea 0%, #764ba2 100%);
  border-radius: 25px;
  filter: blur(20px);
  opacity: 0.6;
  z-index: -1;
  animation: qr-glow 3s ease-in-out infinite;
}

@keyframes qr-glow {
  0%, 100% {
    opacity: 0.6;
  }
  50% {
    opacity: 0.9;
  }
}

.qr-canvas {
  display: block;
  border-radius: 10px;
}

.qr-info {
  text-align: center;
  color: white;
}

.qr-info h3 {
  font-size: 1.5rem;
  margin: 0 0 0.5rem 0;
  font-weight: 600;
  background: linear-gradient(135deg, #667eea 0%, #764ba2 100%);
  -webkit-background-clip: text;
  -webkit-text-fill-color: transparent;
  background-clip: text;
}

.qr-info p {
  margin: 0;
  color: rgba(255, 255, 255, 0.7);
  font-size: 1rem;
}

.reset-button {
  padding: 1rem 2rem;
  background: linear-gradient(135deg, #667eea 0%, #764ba2 100%);
  border: none;
  border-radius: 12px;
  color: white;
  font-size: 1.1rem;
  font-weight: 600;
  cursor: pointer;
  transition: all 0.3s;
  position: relative;
  overflow: hidden;
}

.reset-button::before {
  content: '';
  position: absolute;
  top: 0;
  left: 0;
  right: 0;
  bottom: 0;
  background: linear-gradient(135deg, #764ba2 0%, #667eea 100%);
  opacity: 0;
  transition: opacity 0.3s;
}

.reset-button:hover::before {
  opacity: 1;
}

.reset-button:active {
  transform: scale(0.95);
}

.reset-button span {
  position: relative;
  z-index: 1;
}

@media (max-width: 640px) {
  .qr-container {
    padding: 1rem;
  }

  .qr-wrapper {
    padding: 1.5rem;
  }

  .qr-info h3 {
    font-size: 1.2rem;
  }

  .qr-info p {
    font-size: 0.9rem;
  }
}
</style>
