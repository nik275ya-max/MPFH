import { ref, computed } from 'vue'

const STORAGE_KEY = 'mpfh-license-key'
const STATUS_KEY = 'mpfh-license-status'

// Сервер для онлайн-проверки (замените на ваш реальный URL после развёртывания)
// Пример эндпоинта: https://your-domain.com/api/validate-license?key=MPFH-XXXX-XXXX-XXXX
const LICENSE_SERVER_URL = 'https://your-server.com/api/validate-license'

/**
 * Вычисление CRC16 контрольной суммы
 */
function crc16(data: string): number {
  let crc = 0xFFFF
  const table: number[] = []

  // Генерация таблицы CRC16 (полином 0x8005)
  for (let i = 0; i < 256; i++) {
    let c = i
    for (let j = 0; j < 8; j++) {
      c = (c & 1) ? (0xA001 ^ (c >>> 1)) : (c >>> 1)
    }
    table[i] = c
  }

  // Вычисление CRC
  for (let i = 0; i < data.length; i++) {
    crc = table[(crc ^ data.charCodeAt(i)) & 0xFF] ^ (crc >>> 8)
  }

  return crc & 0xFFFF
}

/**
 * Преобразование CRC16 в 4-символьную строку (hex)
 */
function crcToChecksum(crc: number): string {
  // CRC16 = 16 бит = 4 символа hex
  return crc.toString(16).padStart(4, '0').toUpperCase()
}

/**
 * Проверка контрольной суммы
 */
function verifyChecksum(randomPart: string, checksum: string): boolean {
  const computedCrc = crc16(randomPart)
  const computedChecksum = crcToChecksum(computedCrc)
  return computedChecksum === checksum
}

export interface LicenseValidationResult {
  valid: boolean
  error: string | null
}

/**
 * Валидация формата и контрольной суммы ключа (локально)
 */
export function validateKeyFormat(key: string): LicenseValidationResult {
  const normalizedKey = key.toUpperCase().trim()

  // Проверка формата
  const formatRegex = /^MPFH-[A-Z0-9]{8}-[A-Z0-9]{4}-[A-Z0-9]{4}$/
  if (!formatRegex.test(normalizedKey)) {
    return { valid: false, error: 'Неверный формат ключа. Ожидался MPFH-XXXXXXXX-XXXX-XXXX' }
  }

  // Извлечение частей ключа
  const parts = normalizedKey.split('-')
  const randomPart = parts[1] // 8 символов
  const checksum = parts[2]   // 4 символа (контрольная сумма)

  // Проверка контрольной суммы
  if (!verifyChecksum(randomPart, checksum)) {
    return { valid: false, error: 'Неверная контрольная сумма ключа' }
  }

  return { valid: true, error: null }
}

/**
 * Онлайн-проверка ключа на сервере
 */
async function validateKeyOnline(key: string): Promise<LicenseValidationResult> {
  try {
    const response = await fetch(`${LICENSE_SERVER_URL}?key=${encodeURIComponent(key)}`, {
      method: 'GET',
      headers: {
        'Content-Type': 'application/json'
      }
    })

    if (!response.ok) {
      if (response.status === 404 || response.status === 403) {
        return { valid: false, error: 'Ключ не найден или заблокирован' }
      }
      throw new Error(`Server error: ${response.status}`)
    }

    const data = await response.json()
    
    if (data.valid) {
      return { valid: true, error: null }
    } else {
      return { valid: false, error: data.message || 'Ключ недействителен' }
    }
  } catch (error) {
    // Если нет соединения — считаем это ошибкой
    return { 
      valid: false, 
      error: 'Нет соединения с сервером. Проверьте подключение к интернету.' 
    }
  }
}

const licenseKey = ref<string | null>(null)
const isValidated = ref(false)
const isValidating = ref(false)
const validationError = ref<string | null>(null)

/**
 * Загрузка сохранённого ключа из localStorage
 */
function loadLicense(): string | null {
  try {
    return localStorage.getItem(STORAGE_KEY)
  } catch (error) {
    console.error('Failed to load license:', error)
    return null
  }
}

/**
 * Сохранение ключа в localStorage
 */
function saveLicense(key: string): void {
  try {
    localStorage.setItem(STORAGE_KEY, key)
    localStorage.setItem(STATUS_KEY, 'pending')
  } catch (error) {
    console.error('Failed to save license:', error)
  }
}

/**
 * Очистка лицензии
 */
function clearLicense(): void {
  try {
    localStorage.removeItem(STORAGE_KEY)
    localStorage.removeItem(STATUS_KEY)
  } catch (error) {
    console.error('Failed to clear license:', error)
  }
}

/**
 * Инициализация лицензии при загрузке
 */
function initLicense(): void {
  licenseKey.value = loadLicense()
}

/**
 * Установка и валидация нового ключа
 */
async function setLicenseKey(key: string): Promise<LicenseValidationResult> {
  const normalizedKey = key.toUpperCase().trim()
  
  // Сначала локальная проверка формата
  const localValidation = validateKeyFormat(normalizedKey)
  if (!localValidation.valid) {
    return localValidation
  }

  isValidating.value = true
  validationError.value = null

  // Онлайн-проверка
  const onlineValidation = await validateKeyOnline(normalizedKey)
  
  isValidating.value = false

  if (!onlineValidation.valid) {
    validationError.value = onlineValidation.error
    return onlineValidation
  }

  // Сохранение ключа
  licenseKey.value = normalizedKey
  saveLicense(normalizedKey)
  isValidated.value = true

  return { valid: true, error: null }
}

/**
 * Проверка лицензии при запуске приложения
 */
async function checkLicense(): Promise<LicenseValidationResult> {
  const storedKey = loadLicense()
  
  if (!storedKey) {
    return { valid: false, error: 'Лицензионный ключ не найден' }
  }

  isValidating.value = true
  validationError.value = null

  // Локальная проверка формата
  const localValidation = validateKeyFormat(storedKey)
  if (!localValidation.valid) {
    isValidating.value = false
    clearLicense()
    return localValidation
  }

  // Онлайн-проверка
  const onlineValidation = await validateKeyOnline(storedKey)
  isValidating.value = false

  if (!onlineValidation.valid) {
    validationError.value = onlineValidation.error
    // Не очищаем ключ при ошибке сети — даём пользователю шанс
    return onlineValidation
  }

  licenseKey.value = storedKey
  isValidated.value = true

  return { valid: true, error: null }
}

const hasLicense = computed(() => licenseKey.value !== null)
const isLicenseValid = computed(() => isValidated.value)

export function useLicense() {
  // Инициализация при создании
  initLicense()

  return {
    licenseKey,
    hasLicense,
    isLicenseValid,
    isValidated,
    isValidating,
    validationError,
    setLicenseKey,
    checkLicense,
    clearLicense,
    validateKeyFormat
  }
}
