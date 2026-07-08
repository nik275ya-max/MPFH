<template>
  <div class="result-container">
    <div class="result-card">
      <div v-if="status === 'sending'" class="status-sending">
        <div class="spinner"></div>
        <p class="status-text">Отправка данных...</p>
      </div>

      <div v-else-if="status === 'ready'" class="status-ready">
        <div class="success-icon">
          <svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 24 24" fill="currentColor">
            <path d="M9 16.17L4.83 12l-1.42 1.41L9 19 21 7l-1.41-1.41L9 16.17z"/>
          </svg>
        </div>
        <div class="ready-text">
          <p>Страница с ответами готова!</p>
          <p class="ready-hint">Откройте этот URL на любом устройстве:</p>
        </div>
        <div class="url-box">
          <code class="page-url">{{ pageUrl }}</code>
          <button @click="copyUrl" class="copy-btn">
            <svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 24 24" fill="currentColor">
              <path d="M16 1H4c-1.1 0-2 .9-2 2v14h2V3h12V1zm3 4H8c-1.1 0-2 .9-2 2v14c0 1.1.9 2 2 2h11c1.1 0 2-.9 2-2V7c0-1.1-.9-2-2-2zm0 16H8V7h11v14z"/>
            </svg>
            {{ copied ? 'Скопировано' : 'Копировать' }}
          </button>
        </div>
      </div>

      <div v-else-if="status === 'error'" class="status-error">
        <div class="error-icon">
          <svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 24 24" fill="currentColor">
            <path d="M12 2C6.48 2 2 6.48 2 12s4.48 10 10 10 10-4.48 10-10S17.52 2 12 2zm1 15h-2v-2h2v2zm0-4h-2V7h2v6z"/>
          </svg>
        </div>
        <p class="status-text">Ошибка отправки данных</p>
        <p class="error-detail">{{ errorMessage }}</p>
        <button @click="sendData" class="retry-btn">Повторить</button>
      </div>

      <button @click="$emit('reset')" class="reset-btn">
        <svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 24 24" fill="currentColor">
          <path d="M17.65 6.35C16.2 4.9 14.21 4 12 4c-4.42 0-7.99 3.58-7.99 8s3.57 8 7.99 8c3.73 0 6.84-2.55 7.73-6h-2.08c-.82 2.33-3.04 4-5.65 4-3.31 0-6-2.69-6-6s2.69-6 6-6c1.66 0 3.14.69 4.22 1.78L13 11h7V4l-2.35 2.35z"/>
        </svg>
        Новый фокус
      </button>
    </div>
  </div>
</template>

<script setup lang="ts">
import { ref, onMounted } from 'vue'

const props = defineProps<{
  instruction: string
  replies: string[]
}>()

defineEmits<{
  reset: []
}>()

const PAGE_URL = import.meta.env.VITE_API_URL || 'https://YOUR_API_GATEWAY_URL'

const status = ref<'sending' | 'ready' | 'error'>('sending')
const errorMessage = ref('')
const copied = ref(false)

const getLicense = () => localStorage.getItem('mpfh-license-key') || ''
const pageUrl = ref(PAGE_URL)

const sendData = async () => {
  status.value = 'sending'
  errorMessage.value = ''
  const license = getLicense()

  try {
    const response = await fetch(`${PAGE_URL}/save`, {
      method: 'POST',
      headers: {
        'Content-Type': 'application/json',
      },
      body: JSON.stringify({
        instruction: props.instruction,
        replies: props.replies,
        license: license,
      }),
    })

    if (!response.ok) {
      throw new Error(`HTTP ${response.status}: ${response.statusText}`)
    }

    pageUrl.value = license
      ? `${PAGE_URL}/?license=${encodeURIComponent(license)}`
      : PAGE_URL
    status.value = 'ready'
  } catch (error) {
    status.value = 'error'
    errorMessage.value = error instanceof Error ? error.message : 'Неизвестная ошибка'
  }
}

const copyUrl = async () => {
  try {
    await navigator.clipboard.writeText(pageUrl.value)
    copied.value = true
    setTimeout(() => { copied.value = false }, 2000)
  } catch {
    const textarea = document.createElement('textarea')
    textarea.value = pageUrl.value
    textarea.style.position = 'fixed'
    textarea.style.opacity = '0'
    document.body.appendChild(textarea)
    textarea.select()
    document.execCommand('copy')
    document.body.removeChild(textarea)
    copied.value = true
    setTimeout(() => { copied.value = false }, 2000)
  }
}

onMounted(() => {
  sendData()
})
</script>

<style scoped>
.result-container {
  display: flex;
  align-items: center;
  justify-content: center;
  height: 100%;
  padding: 2rem;
}

.result-card {
  display: flex;
  flex-direction: column;
  align-items: center;
  gap: 1.5rem;
  padding: 2.5rem;
  background: rgba(255, 255, 255, 0.05);
  border-radius: 20px;
  border: 1px solid rgba(255, 255, 255, 0.1);
  backdrop-filter: blur(10px);
  max-width: 440px;
  width: 100%;
}

/* Sending state */
.status-sending {
  display: flex;
  flex-direction: column;
  align-items: center;
  gap: 1rem;
}

.spinner {
  width: 48px;
  height: 48px;
  border: 3px solid rgba(255, 255, 255, 0.2);
  border-top-color: #667eea;
  border-radius: 50%;
  animation: spin 1s linear infinite;
}

@keyframes spin {
  to { transform: rotate(360deg); }
}

.status-text {
  color: rgba(255, 255, 255, 0.8);
  font-size: 1.1rem;
  text-align: center;
  margin: 0;
}

/* Ready state */
.status-ready {
  display: flex;
  flex-direction: column;
  align-items: center;
  gap: 1rem;
  width: 100%;
}

.success-icon {
  width: 64px;
  height: 64px;
  background: linear-gradient(135deg, #667eea 0%, #764ba2 100%);
  border-radius: 50%;
  display: flex;
  align-items: center;
  justify-content: center;
  color: white;
}

.success-icon svg {
  width: 36px;
  height: 36px;
}

.ready-text {
  text-align: center;
}

.ready-text p {
  margin: 0;
  color: rgba(255, 255, 255, 0.9);
  font-size: 1.05rem;
}

.ready-hint {
  margin-top: 0.5rem !important;
  color: rgba(255, 255, 255, 0.5) !important;
  font-size: 0.9rem !important;
}

.url-box {
  display: flex;
  align-items: center;
  gap: 0.5rem;
  width: 100%;
  padding: 0.75rem 1rem;
  background: rgba(0, 0, 0, 0.3);
  border: 1px solid rgba(255, 255, 255, 0.1);
  border-radius: 10px;
}

.page-url {
  flex: 1;
  color: #667eea;
  font-size: 0.85rem;
  word-break: break-all;
  font-family: 'SF Mono', 'Fira Code', monospace;
}

.copy-btn {
  display: flex;
  align-items: center;
  gap: 0.4rem;
  padding: 0.5rem 0.75rem;
  background: linear-gradient(135deg, #667eea 0%, #764ba2 100%);
  border: none;
  border-radius: 8px;
  color: white;
  font-size: 0.8rem;
  cursor: pointer;
  white-space: nowrap;
  transition: all 0.3s;
}

.copy-btn:hover {
  transform: translateY(-1px);
  box-shadow: 0 4px 15px rgba(102, 126, 234, 0.4);
}

.copy-btn:active {
  transform: translateY(0);
}

.copy-btn svg {
  width: 16px;
  height: 16px;
}

/* Error state */
.status-error {
  display: flex;
  flex-direction: column;
  align-items: center;
  gap: 0.75rem;
}

.error-icon {
  width: 64px;
  height: 64px;
  background: rgba(255, 82, 82, 0.2);
  border-radius: 50%;
  display: flex;
  align-items: center;
  justify-content: center;
  color: #ff5252;
}

.error-icon svg {
  width: 36px;
  height: 36px;
}

.error-detail {
  color: rgba(255, 82, 82, 0.7);
  font-size: 0.85rem;
  text-align: center;
  margin: 0;
}

.retry-btn {
  padding: 0.6rem 1.5rem;
  background: linear-gradient(135deg, #667eea 0%, #764ba2 100%);
  border: none;
  border-radius: 10px;
  color: white;
  font-size: 0.95rem;
  cursor: pointer;
  transition: all 0.3s;
}

.retry-btn:hover {
  transform: translateY(-2px);
  box-shadow: 0 10px 30px rgba(102, 126, 234, 0.4);
}

/* Reset button */
.reset-btn {
  display: flex;
  align-items: center;
  gap: 0.5rem;
  padding: 0.6rem 1.5rem;
  background: rgba(255, 255, 255, 0.1);
  border: 1px solid rgba(255, 255, 255, 0.15);
  border-radius: 10px;
  color: rgba(255, 255, 255, 0.8);
  font-size: 0.95rem;
  cursor: pointer;
  transition: all 0.3s;
}

.reset-btn:hover {
  background: rgba(255, 255, 255, 0.15);
  transform: translateY(-2px);
}

.reset-btn:active {
  transform: translateY(0);
}

.reset-btn svg {
  width: 18px;
  height: 18px;
}

@media (max-width: 640px) {
  .result-container {
    padding: 1rem;
  }

  .result-card {
    padding: 1.5rem;
  }

  .url-box {
    flex-direction: column;
  }

  .copy-btn {
    width: 100%;
    justify-content: center;
  }
}
</style>
