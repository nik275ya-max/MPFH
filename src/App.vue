<script setup lang="ts">
import { ref, computed, onMounted } from 'vue'
import RecordButton from './components/RecordButton.vue'
import SettingsModal from './components/SettingsModal.vue'
import QRCodeDisplay from './components/QRCodeDisplay.vue'
import LicenseModal from './components/LicenseModal.vue'
import { useSettings } from './composables/useSettings'
import { useRecording } from './composables/useRecording'
import { useLicense } from './composables/useLicense'

const { settings, updateSettings } = useSettings()
const { replies, clearReplies, isComplete } = useRecording()
const { isLicenseValid, checkLicense } = useLicense()

const isSettingsOpen = ref(false)
const showLicenseModal = ref(false)
const licenseChecked = ref(false)

const showResult = computed(() => isComplete.value(settings.value.repliesCount))
const isAppLocked = computed(() => !isLicenseValid.value && !showLicenseModal.value)

const scaleStyle = computed(() => ({
  transform: `scale(${settings.value.uiScale})`
}))

const handleReset = () => {
  clearReplies()
}

const handleSaveSettings = (newSettings: typeof settings.value) => {
  updateSettings(newSettings)
}

const handleLicensed = () => {
  showLicenseModal.value = false
}

const openLicenseModal = () => {
  showLicenseModal.value = true
}

// Проверка лицензии при запуске
onMounted(() => {
  const result = checkLicense()
  licenseChecked.value = true

  // Если нет лицензии или ошибка валидации — показываем модалку
  if (!result.valid) {
    showLicenseModal.value = true
  }
})
</script>

<template>
  <div class="app-container">
    <div class="app-scene">
      <header class="app-header" :class="{ locked: isAppLocked }" :style="scaleStyle">
        <h1 class="app-title">Master Prediction Free Hand</h1>
        <button
          @click="isSettingsOpen = true"
          class="settings-button"
          :disabled="isAppLocked"
        >
          <svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 24 24" fill="currentColor">
            <path d="M19.14,12.94c0.04-0.3,0.06-0.61,0.06-0.94c0-0.32-0.02-0.64-0.07-0.94l2.03-1.58c0.18-0.14,0.23-0.41,0.12-0.61 l-1.92-3.32c-0.12-0.22-0.37-0.29-0.59-0.22l-2.39,0.96c-0.5-0.38-1.03-0.7-1.62-0.94L14.4,2.81c-0.04-0.24-0.24-0.41-0.48-0.41 h-3.84c-0.24,0-0.43,0.17-0.47,0.41L9.25,5.35C8.66,5.59,8.12,5.92,7.63,6.29L5.24,5.33c-0.22-0.08-0.47,0-0.59,0.22L2.74,8.87 C2.62,9.08,2.66,9.34,2.86,9.48l2.03,1.58C4.84,11.36,4.8,11.69,4.8,12s0.02,0.64,0.07,0.94l-2.03,1.58 c-0.18,0.14-0.23,0.41-0.12,0.61l1.92,3.32c0.12,0.22,0.37,0.29,0.59,0.22l2.39-0.96c0.5,0.38,1.03,0.7,1.62,0.94l0.36,2.54 c0.05,0.24,0.24,0.41,0.48,0.41h3.84c0.24,0,0.44-0.17,0.47-0.41l0.36-2.54c0.59-0.24,1.13-0.56,1.62-0.94l2.39,0.96 c0.22,0.08,0.47,0,0.59-0.22l1.92-3.32c0.12-0.22,0.07-0.47-0.12-0.61L19.14,12.94z M12,15.6c-1.98,0-3.6-1.62-3.6-3.6 s1.62-3.6,3.6-3.6s3.6,1.62,3.6,3.6S13.98,15.6,12,15.6z"/>
          </svg>
        </button>
      </header>

      <main class="app-main" :style="scaleStyle">
        <div v-if="!licenseChecked" class="loading-state">
          <div class="loading-spinner"></div>
          <p class="loading-text">Загрузка...</p>
        </div>

        <div v-else-if="isAppLocked" class="locked-state">
          <div class="lock-icon">
            <svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 24 24" fill="currentColor">
              <path d="M12 1L3 5v6c0 5.55 3.84 10.74 9 12 5.16-1.26 9-6.45 9-12V5l-9-4zm0 10.99h7c-.53 4.12-3.28 7.79-7 8.94V12H5V6.3l7-3.11v8.8z"/>
            </svg>
          </div>
          <h2>Требуется активация</h2>
          <p>Введите лицензионный ключ для продолжения работы</p>
          <button @click="openLicenseModal" class="activate-btn">
            Ввести ключ
          </button>
        </div>

        <Transition name="fade" mode="out-in">
          <RecordButton
            v-if="!showResult && !isAppLocked"
            :max-replies="settings.repliesCount"
          />
          <QRCodeDisplay
            v-else-if="!isAppLocked"
            :instruction="settings.instruction"
            :replies="replies"
            @reset="handleReset"
          />
        </Transition>
      </main>
    </div>

    <SettingsModal
      :is-open="isSettingsOpen"
      :settings="settings"
      @close="isSettingsOpen = false"
      @save="handleSaveSettings"
    />

    <LicenseModal
      :is-open="showLicenseModal"
      @close="showLicenseModal = false"
      @licensed="handleLicensed"
    />
  </div>
</template>

<style scoped>
.app-container {
  display: flex;
  flex-direction: column;
  height: 100vh;
  width: 100vw;
  overflow: hidden;
}

.app-scene {
  flex: 1;
  min-height: 0;
  display: flex;
  flex-direction: column;
}

.app-header {
  display: flex;
  justify-content: space-between;
  align-items: center;
  padding: 1rem 1.5rem;
  background: rgba(0, 0, 0, 0.3);
  backdrop-filter: blur(10px);
  border-bottom: 1px solid rgba(255, 255, 255, 0.1);
  z-index: 100;
  transform-origin: top center;
  transition: transform 0.3s ease;
}

.app-title {
  font-size: 1.2rem;
  font-weight: 700;
  margin: 0;
  background: linear-gradient(135deg, #667eea 0%, #764ba2 100%);
  -webkit-background-clip: text;
  -webkit-text-fill-color: transparent;
  background-clip: text;
}

.settings-button {
  width: 40px;
  height: 40px;
  padding: 0.5rem;
  background: rgba(255, 255, 255, 0.05);
  border: 1px solid rgba(255, 255, 255, 0.1);
  border-radius: 10px;
  color: white;
  cursor: pointer;
  transition: all 0.3s;
  display: flex;
  align-items: center;
  justify-content: center;
}

.settings-button:hover {
  background: rgba(255, 255, 255, 0.1);
  transform: rotate(90deg);
}

.settings-button:active {
  transform: rotate(90deg) scale(0.95);
}

.settings-button:disabled {
  opacity: 0.5;
  cursor: not-allowed;
}

.app-header.locked {
  opacity: 0.5;
  pointer-events: none;
}

.app-main {
  flex: 1;
  display: flex;
  align-items: center;
  justify-content: center;
  overflow: hidden;
  position: relative;
  transform-origin: center center;
  transition: transform 0.3s ease;
}

.fade-enter-active,
.fade-leave-active {
  transition: opacity 0.3s ease;
}

.fade-enter-from,
.fade-leave-to {
  opacity: 0;
}

/* Loading state */
.loading-state {
  display: flex;
  flex-direction: column;
  align-items: center;
  justify-content: center;
  gap: 1.5rem;
}

.loading-spinner {
  width: 48px;
  height: 48px;
  border: 3px solid rgba(255, 255, 255, 0.2);
  border-top-color: #667eea;
  border-radius: 50%;
  animation: spin 1s linear infinite;
}

@keyframes spin {
  to {
    transform: rotate(360deg);
  }
}

.loading-text {
  color: rgba(255, 255, 255, 0.7);
  font-size: 1rem;
}

/* Locked state */
.locked-state {
  display: flex;
  flex-direction: column;
  align-items: center;
  justify-content: center;
  gap: 1rem;
  text-align: center;
  padding: 2rem;
}

.lock-icon {
  width: 80px;
  height: 80px;
  background: linear-gradient(135deg, #667eea 0%, #764ba2 100%);
  border-radius: 20px;
  display: flex;
  align-items: center;
  justify-content: center;
  color: white;
  margin-bottom: 0.5rem;
}

.lock-icon svg {
  width: 48px;
  height: 48px;
}

.locked-state h2 {
  color: white;
  font-size: 1.5rem;
  margin: 0;
}

.locked-state p {
  color: rgba(255, 255, 255, 0.6);
  font-size: 0.95rem;
  margin: 0;
}

.activate-btn {
  margin-top: 1rem;
  padding: 0.75rem 2rem;
  background: linear-gradient(135deg, #667eea 0%, #764ba2 100%);
  border: none;
  border-radius: 10px;
  color: white;
  font-size: 1rem;
  font-weight: 600;
  cursor: pointer;
  transition: all 0.3s;
}

.activate-btn:hover {
  transform: translateY(-2px);
  box-shadow: 0 10px 30px rgba(102, 126, 234, 0.4);
}

.activate-btn:active {
  transform: translateY(0);
}

@media (max-width: 640px) {
  .app-title {
    font-size: 1rem;
  }

  .app-header {
    padding: 0.75rem 1rem;
  }

  .settings-button {
    width: 36px;
    height: 36px;
  }
}
</style>
