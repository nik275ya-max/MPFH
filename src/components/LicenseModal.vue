<script setup lang="ts">
import { ref, watch } from 'vue'
import { useLicense } from '../composables/useLicense'

const props = defineProps<{
  isOpen: boolean
}>()

const emit = defineEmits<{
  close: []
  licensed: []
}>()

const { setLicenseKey } = useLicense()

const licenseInput = ref('')
const localError = ref<string | null>(null)

watch(() => props.isOpen, (isOpen) => {
  if (!isOpen) {
    licenseInput.value = ''
    localError.value = null
  }
})

const handleSubmit = () => {
  localError.value = null

  if (!licenseInput.value.trim()) {
    localError.value = 'Введите лицензионный ключ'
    return
  }

  // Локальная проверка формата и контрольной суммы
  const result = setLicenseKey(licenseInput.value)

  if (result.valid) {
    emit('licensed')
    emit('close')
  } else {
    localError.value = result.error
  }
}

const handleInput = () => {
  // Автоформатирование ввода: MPFH-XXXX-XXXX-XXXX
  let value = licenseInput.value.toUpperCase().replace(/[^A-Z0-9-]/g, '')
  
  // Удаляем всё кроме MPFH в начале
  if (!value.startsWith('MPFH')) {
    value = value.replace(/^(?!MPFH).*/, '')
  }
  
  // Добавляем дефисы автоматически
  let raw = value.replace(/-/g, '')
  if (raw.length > 4) {
    raw = raw.slice(0, 20) // Максимум 20 символов после MPFH
  }
  
  let formatted = 'MPFH'
  if (raw.length > 4) {
    formatted += '-' + raw.slice(4, 12)
  } else {
    formatted += '-' + raw.slice(4)
  }
  if (raw.length > 12) {
    formatted += '-' + raw.slice(12, 16)
  }
  if (raw.length > 16) {
    formatted += '-' + raw.slice(16, 20)
  }
  
  licenseInput.value = formatted
}
</script>

<template>
  <Transition name="modal">
    <div v-if="isOpen" class="license-modal-overlay" @click.stop>
      <div class="license-modal-content">
        <div class="license-header">
          <div class="license-icon">
            <svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 24 24" fill="currentColor">
              <path d="M12 1L3 5v6c0 5.55 3.84 10.74 9 12 5.16-1.26 9-6.45 9-12V5l-9-4zm0 10.99h7c-.53 4.12-3.28 7.79-7 8.94V12H5V6.3l7-3.11v8.8z"/>
            </svg>
          </div>
          <h2>Активация приложения</h2>
          <p class="license-subtitle">Введите лицензионный ключ для продолжения</p>
        </div>

        <div class="license-body">
          <div class="form-group">
            <label for="license-key">Лицензионный ключ:</label>
            <input
              id="license-key"
              v-model="licenseInput"
              @input="handleInput"
              @keyup.enter="handleSubmit"
              type="text"
              class="form-input license-input"
              placeholder="MPFH-XXXX-XXXX-XXXX"
              autofocus
            />
            <p class="input-hint">
              Формат: MPFH-XXXXXXXX-XXXX-XXXX (24 символа)
            </p>
          </div>

          <div v-if="localError" class="error-message">
            <svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 24 24" fill="currentColor">
              <path d="M12 2C6.48 2 2 6.48 2 12s4.48 10 10 10 10-4.48 10-10S17.52 2 12 2zm1 15h-2v-2h2v2zm0-4h-2V7h2v6z"/>
            </svg>
            <span>{{ localError }}</span>
          </div>

          <button
            @click="handleSubmit"
            class="activate-button"
            :disabled="!licenseInput.trim()"
          >
            Активировать
          </button>

          <p class="license-info">
            Ключ был выдан вам после оплаты. Проверьте email или обратитесь в поддержку.
          </p>
        </div>
      </div>
    </div>
  </Transition>
</template>

<style scoped>
.license-modal-overlay {
  position: fixed;
  top: 0;
  left: 0;
  right: 0;
  bottom: 0;
  background: rgba(0, 0, 0, 0.9);
  backdrop-filter: blur(10px);
  display: flex;
  align-items: center;
  justify-content: center;
  z-index: 2000;
  padding: 1rem;
}

.license-modal-content {
  background: linear-gradient(135deg, #1e1e2e 0%, #2a2a3e 100%);
  border-radius: 24px;
  width: 100%;
  max-width: 480px;
  box-shadow: 0 25px 80px rgba(0, 0, 0, 0.6),
              0 0 0 1px rgba(255, 255, 255, 0.1);
  overflow: hidden;
}

.license-header {
  text-align: center;
  padding: 2rem 2rem 1.5rem;
  border-bottom: 1px solid rgba(255, 255, 255, 0.1);
}

.license-icon {
  width: 64px;
  height: 64px;
  margin: 0 auto 1rem;
  background: linear-gradient(135deg, #667eea 0%, #764ba2 100%);
  border-radius: 16px;
  display: flex;
  align-items: center;
  justify-content: center;
  color: white;
}

.license-icon svg {
  width: 36px;
  height: 36px;
}

.license-header h2 {
  margin: 0 0 0.5rem;
  font-size: 1.5rem;
  color: white;
  font-weight: 600;
}

.license-subtitle {
  margin: 0;
  color: rgba(255, 255, 255, 0.6);
  font-size: 0.95rem;
}

.license-body {
  padding: 2rem;
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

.license-input {
  width: 100%;
  padding: 1rem;
  background: rgba(255, 255, 255, 0.05);
  border: 2px solid rgba(255, 255, 255, 0.1);
  border-radius: 12px;
  color: white;
  font-size: 1.1rem;
  font-weight: 600;
  text-align: center;
  letter-spacing: 2px;
  transition: all 0.2s;
  font-family: 'Courier New', monospace;
}

.license-input:focus {
  outline: none;
  background: rgba(255, 255, 255, 0.08);
  border-color: #667eea;
  box-shadow: 0 0 0 4px rgba(102, 126, 234, 0.15);
}

.input-hint {
  margin-top: 0.5rem;
  color: rgba(255, 255, 255, 0.5);
  font-size: 0.85rem;
  text-align: center;
}

.error-message {
  display: flex;
  align-items: center;
  gap: 0.75rem;
  padding: 0.75rem 1rem;
  background: rgba(245, 87, 108, 0.1);
  border: 1px solid rgba(245, 87, 108, 0.3);
  border-radius: 10px;
  color: #f5576c;
  font-size: 0.9rem;
  margin-bottom: 1.5rem;
}

.error-message svg {
  width: 20px;
  height: 20px;
  flex-shrink: 0;
}

.activate-button {
  width: 100%;
  padding: 1rem;
  background: linear-gradient(135deg, #667eea 0%, #764ba2 100%);
  border: none;
  border-radius: 12px;
  color: white;
  font-size: 1.1rem;
  font-weight: 600;
  cursor: pointer;
  transition: all 0.3s;
  display: flex;
  align-items: center;
  justify-content: center;
  gap: 0.75rem;
}

.activate-button:hover:not(:disabled) {
  transform: translateY(-2px);
  box-shadow: 0 10px 30px rgba(102, 126, 234, 0.4);
}

.activate-button:active:not(:disabled) {
  transform: translateY(0);
}

.activate-button:disabled {
  opacity: 0.6;
  cursor: not-allowed;
}

.license-info {
  margin-top: 1.5rem;
  padding-top: 1.5rem;
  border-top: 1px solid rgba(255, 255, 255, 0.1);
  color: rgba(255, 255, 255, 0.5);
  font-size: 0.85rem;
  text-align: center;
  line-height: 1.6;
}

.modal-enter-active,
.modal-leave-active {
  transition: opacity 0.3s;
}

.modal-enter-from,
.modal-leave-to {
  opacity: 0;
}

.modal-enter-active .license-modal-content,
.modal-leave-active .license-modal-content {
  transition: transform 0.3s, opacity 0.3s;
}

.modal-enter-from .license-modal-content,
.modal-leave-to .license-modal-content {
  transform: scale(0.9) translateY(20px);
  opacity: 0;
}

@media (max-width: 640px) {
  .license-modal-content {
    max-width: 100%;
    border-radius: 24px 24px 0 0;
    margin-top: auto;
  }

  .license-modal-overlay {
    align-items: flex-end;
    padding: 0;
  }

  .license-header {
    padding: 1.5rem 1.5rem 1rem;
  }

  .license-body {
    padding: 1.5rem;
  }
}
</style>
