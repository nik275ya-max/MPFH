<template>
  <Transition name="modal">
    <div v-if="isOpen" class="modal-overlay" @click="$emit('close')">
      <div class="modal-content" @click.stop>
        <div class="modal-header">
          <h2>Настройки</h2>
          <button @click="$emit('close')" class="close-button">
            <svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 24 24" fill="currentColor">
              <path d="M19 6.41L17.59 5 12 10.59 6.41 5 5 6.41 10.59 12 5 17.59 6.41 19 12 13.41 17.59 19 19 17.59 13.41 12z"/>
            </svg>
          </button>
        </div>

        <div class="modal-body">
          <div v-if="licenseKey" class="license-display-section">
            <div class="license-badge">
              <div class="license-icon-wrapper">
                <svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 24 24" fill="currentColor">
                  <path d="M12 1L3 5v6c0 5.55 3.84 10.74 9 12 5.16-1.26 9-6.45 9-12V5l-9-4zm0 10.99h7c-.53 4.12-3.28 7.79-7 8.94V12H5V6.3l7-3.11v8.8z"/>
                </svg>
              </div>
              <div class="license-details">
                <span class="license-key">{{ licenseKey }}</span>
                <span class="license-expires">Действует до: {{ licenseExpiresFormatted }}</span>
              </div>
            </div>
          </div>

          <div class="form-group">
            <label for="instruction">Инструкция к фокусу:</label>
            <textarea
              id="instruction"
              v-model="localSettings.instruction"
              rows="4"
              class="form-input"
              placeholder="Введите инструкцию..."
            ></textarea>
          </div>

          <div class="form-group">
            <label for="repliesCount">Количество запоминаемых реплик:</label>
            <input
              id="repliesCount"
              v-model.number="localSettings.repliesCount"
              type="number"
              min="1"
              max="20"
              class="form-input"
            />
          </div>

          <button @click="saveSettings" class="save-button">
            Сохранить
          </button>

          <div v-if="showInstallButton" class="pwa-section">
            <div class="pwa-divider"></div>
            
            <button @click="handleInstall" class="install-button" :class="{ 'ios-only': isIOS }">
              <svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 24 24" fill="currentColor">
                <path d="M18,15V18H15V20H18V23H20V20H23V18H20V15H18M12,2A10,10 0 0,0 2,12A10,10 0 0,0 12,22A10,10 0 0,0 22,12A10,10 0 0,0 12,2M12,4A8,8 0 0,1 20,12C20,14.11 19.2,16 17.92,17.5L16.5,16.08L19,13.5H12V16.5L10.5,15L8,17.5V12H1V10H8V7.5L10.5,10L12,8.5V11.5H16.95L14.5,14L15.92,15.42C17.41,14.1 18.41,12.17 18.41,10A6.41,6.41 0 0,0 12,3.59A6.41,6.41 0 0,0 5.59,10H7.17A4.82,4.82 0 0,1 12,5.17A4.82,4.82 0 0,1 16.82,10H18.41A6.41,6.41 0 0,0 12,4Z"/>
              </svg>
              <span>Установить приложение</span>
            </button>

            <div v-if="isIOS" class="ios-instructions">
              <p><strong>Для установки на iOS:</strong></p>
              <ol>
                <li>Нажмите кнопку <strong>"Поделиться"</strong> в Safari (квадрат со стрелкой)</li>
                <li>Выберите <strong>"На экран «Домой»"</strong></li>
                <li>Нажмите <strong>"Добавить"</strong></li>
              </ol>
            </div>
          </div>
        </div>
      </div>
    </div>
  </Transition>
</template>

<script setup lang="ts">
import { ref, watch, onMounted } from 'vue'
import type { Settings } from '../composables/useSettings'
import { useLicense } from '../composables/useLicense'

const props = defineProps<{
  isOpen: boolean
  settings: Settings
}>()

const emit = defineEmits<{
  close: []
  save: [settings: Settings]
}>()

const localSettings = ref<Settings>({ ...props.settings })

// Лицензия
const { licenseKey, licenseExpiresFormatted } = useLicense()

// PWA установка
const showInstallButton = ref(false)
const isIOS = ref(false)
const deferredPrompt = ref<any>(null)

onMounted(() => {
  // Проверка iOS
  isIOS.value = /iPad|iPhone|iPod/.test(navigator.userAgent) && !(window as any).MSStream
  
  // Проверка, запущено ли как PWA (standalone режим)
  const isStandalone = window.matchMedia('(display-mode: standalone)').matches ||
                       (window.navigator as any).standalone === true

  // Слушаем событие установки для Android
  window.addEventListener('beforeinstallprompt', (e) => {
    e.preventDefault()
    deferredPrompt.value = e
    showInstallButton.value = true
  })

  // После установки
  window.addEventListener('appinstalled', () => {
    deferredPrompt.value = null
    showInstallButton.value = false
  })

  // Показываем кнопку если:
  // 1. Android и есть отложенный prompt
  // 2. iOS и не запущено в standalone режиме
  if (deferredPrompt.value) {
    showInstallButton.value = true
  } else if (isIOS.value && !isStandalone) {
    showInstallButton.value = true
  }
})

const handleInstall = async () => {
  if (isIOS.value) {
    return // Для iOS показываем только инструкцию
  }

  if (deferredPrompt.value) {
    deferredPrompt.value.prompt()
    const { outcome } = await deferredPrompt.value.userChoice
    if (outcome === 'accepted') {
      deferredPrompt.value = null
    }
  }
}

watch(() => props.settings, (newSettings) => {
  localSettings.value = { ...newSettings }
}, { deep: true })

const saveSettings = () => {
  emit('save', localSettings.value)
  emit('close')
}
</script>

<style scoped>
.modal-overlay {
  position: fixed;
  top: 0;
  left: 0;
  right: 0;
  bottom: 0;
  background: rgba(0, 0, 0, 0.8);
  backdrop-filter: blur(5px);
  display: flex;
  align-items: center;
  justify-content: center;
  z-index: 1000;
  padding: 1rem;
}

.modal-content {
  background: linear-gradient(135deg, #1e1e2e 0%, #2a2a3e 100%);
  border-radius: 20px;
  width: 100%;
  max-width: 500px;
  box-shadow: 0 20px 60px rgba(0, 0, 0, 0.5),
              0 0 0 1px rgba(255, 255, 255, 0.1);
  overflow: hidden;
}

.modal-header {
  display: flex;
  justify-content: space-between;
  align-items: center;
  padding: 1.5rem;
  border-bottom: 1px solid rgba(255, 255, 255, 0.1);
}

.modal-header h2 {
  margin: 0;
  font-size: 1.5rem;
  color: white;
  font-weight: 600;
}

.close-button {
  background: none;
  border: none;
  color: rgba(255, 255, 255, 0.7);
  cursor: pointer;
  padding: 0.5rem;
  width: 32px;
  height: 32px;
  border-radius: 8px;
  transition: all 0.2s;
  display: flex;
  align-items: center;
  justify-content: center;
}

.close-button:hover {
  background: rgba(255, 255, 255, 0.1);
  color: white;
}

.modal-body {
  padding: 1.5rem;
}

.form-group {
  margin-bottom: 1.5rem;
}

.form-group label {
  display: block;
  margin-bottom: 0.5rem;
  color: rgba(255, 255, 255, 0.9);
  font-weight: 500;
  font-size: 0.95rem;
}

.form-input {
  width: 100%;
  padding: 0.75rem;
  background: rgba(255, 255, 255, 0.05);
  border: 1px solid rgba(255, 255, 255, 0.1);
  border-radius: 10px;
  color: white;
  font-size: 1rem;
  transition: all 0.2s;
  font-family: inherit;
  resize: vertical;
}

.form-input:focus {
  outline: none;
  background: rgba(255, 255, 255, 0.08);
  border-color: #667eea;
  box-shadow: 0 0 0 3px rgba(102, 126, 234, 0.1);
}

.save-button {
  width: 100%;
  padding: 1rem;
  background: linear-gradient(135deg, #667eea 0%, #764ba2 100%);
  border: none;
  border-radius: 10px;
  color: white;
  font-size: 1.1rem;
  font-weight: 600;
  cursor: pointer;
  transition: all 0.3s;
  position: relative;
  overflow: hidden;
}

.save-button::before {
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

.save-button:hover::before {
  opacity: 1;
}

.save-button:active {
  transform: scale(0.98);
}

.save-button span {
  position: relative;
  z-index: 1;
}

.modal-enter-active,
.modal-leave-active {
  transition: opacity 0.3s;
}

.modal-enter-from,
.modal-leave-to {
  opacity: 0;
}

.modal-enter-active .modal-content,
.modal-leave-active .modal-content {
  transition: transform 0.3s;
}

.modal-enter-from .modal-content,
.modal-leave-to .modal-content {
  transform: scale(0.9);
}

/* PWA section */
.pwa-section {
  margin-top: 1.5rem;
  padding-top: 1.5rem;
}

.pwa-divider {
  height: 1px;
  background: rgba(255, 255, 255, 0.1);
  margin-bottom: 1rem;
}

.install-button {
  width: 100%;
  padding: 0.875rem;
  background: rgba(255, 255, 255, 0.05);
  border: 1px solid rgba(255, 255, 255, 0.2);
  border-radius: 10px;
  color: white;
  font-size: 1rem;
  font-weight: 500;
  cursor: pointer;
  transition: all 0.3s;
  display: flex;
  align-items: center;
  justify-content: center;
  gap: 0.5rem;
}

.install-button svg {
  width: 22px;
  height: 22px;
}

.install-button:hover {
  background: rgba(255, 255, 255, 0.1);
  border-color: rgba(255, 255, 255, 0.3);
}

.install-button:active {
  transform: scale(0.98);
}

.install-button.ios-only {
  cursor: default;
  opacity: 0.7;
}

.install-button.ios-only:hover {
  background: rgba(255, 255, 255, 0.05);
}

.ios-instructions {
  margin-top: 1rem;
  padding: 1rem;
  background: rgba(102, 126, 234, 0.1);
  border: 1px solid rgba(102, 126, 234, 0.3);
  border-radius: 10px;
  color: rgba(255, 255, 255, 0.9);
  font-size: 0.875rem;
  line-height: 1.6;
}

.ios-instructions p {
  margin: 0 0 0.5rem;
}

.ios-instructions ol {
  margin: 0;
  padding-left: 1.25rem;
}

.ios-instructions li {
  margin-bottom: 0.25rem;
}

.ios-instructions strong {
  color: white;
}

/* License display section */
.license-display-section {
  margin-bottom: 1.5rem;
}

.license-badge {
  display: flex;
  align-items: center;
  gap: 1rem;
  padding: 1rem;
  background: rgba(102, 126, 234, 0.1);
  border: 1px solid rgba(102, 126, 234, 0.3);
  border-radius: 12px;
}

.license-icon-wrapper {
  width: 40px;
  height: 40px;
  background: linear-gradient(135deg, #667eea 0%, #764ba2 100%);
  border-radius: 10px;
  display: flex;
  align-items: center;
  justify-content: center;
  color: white;
  flex-shrink: 0;
}

.license-icon-wrapper svg {
  width: 22px;
  height: 22px;
}

.license-details {
  display: flex;
  flex-direction: column;
  gap: 0.25rem;
  min-width: 0;
  flex: 1;
}

.license-key {
  font-family: 'Courier New', monospace;
  font-size: 0.9rem;
  font-weight: 600;
  color: white;
  word-break: break-all;
}

.license-expires {
  font-size: 0.8rem;
  color: rgba(255, 255, 255, 0.6);
}

@media (max-width: 640px) {
  .modal-content {
    max-width: 100%;
    border-radius: 20px 20px 0 0;
    margin-top: auto;
  }

  .modal-overlay {
    align-items: flex-end;
    padding: 0;
  }
}
</style>
