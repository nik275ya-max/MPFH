<template>
  <div class="qr-container">
    <div class="qr-wrapper">
      <div class="qr-glow"></div>
      <canvas ref="qrCanvas" class="qr-canvas"></canvas>
    </div>
  </div>
</template>

<script setup lang="ts">
import { ref, onMounted, watch } from 'vue'
import QRCode from 'qrcode'

const props = defineProps<{
  instruction: string
  replies: string[]
}>()

const qrCanvas = ref<HTMLCanvasElement | null>(null)

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

onMounted(() => {
  generateQRCode()
})

watch(() => props.replies, () => {
  generateQRCode()
}, { deep: true })
</script>

<style scoped>
.qr-container {
  display: flex;
  align-items: center;
  justify-content: center;
  height: 100%;
  padding: 2rem;
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

@media (max-width: 640px) {
  .qr-container {
    padding: 1rem;
  }

  .qr-wrapper {
    padding: 1.5rem;
  }
}
</style>
