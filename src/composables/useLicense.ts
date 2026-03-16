import { ref, computed } from 'vue'

const STORAGE_KEY = 'mpfh-license-key'

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
  return crc.toString(16).padStart(4, '0').toUpperCase()
}

/**
 * Проверка контрольной суммы
 */
function verifyChecksum(datePart: string, checksum: string): boolean {
  const computedCrc = crc16(datePart)
  const computedChecksum = crcToChecksum(computedCrc)
  return computedChecksum === checksum
}

/**
 * Проверка формата даты YYYYMMDD
 */
function isValidDate(dateStr: string): boolean {
  if (!/^\d{8}$/.test(dateStr)) return false
  
  const year = parseInt(dateStr.substring(0, 4), 10)
  const month = parseInt(dateStr.substring(4, 6), 10)
  const day = parseInt(dateStr.substring(6, 8), 10)
  
  if (month < 1 || month > 12) return false
  if (day < 1 || day > 31) return false
  
  const date = new Date(year, month - 1, day)
  return date.getFullYear() === year && 
         date.getMonth() === month - 1 && 
         date.getDate() === day
}

/**
 * Форматирование даты из YYYYMMDD в читаемый вид
 */
export function formatDate(dateStr: string): string {
  const year = dateStr.substring(0, 4)
  const month = dateStr.substring(4, 6)
  const day = dateStr.substring(6, 8)
  return `${day}.${month}.${year}`
}

export interface LicenseValidationResult {
  valid: boolean
  error: string | null
  expiresDate?: string | null
  expiresFormatted?: string | null
  expired?: boolean
}

/**
 * Валидация формата, контрольной суммы и даты истечения ключа
 */
export function validateKeyFormat(key: string, checkExpiration = true): LicenseValidationResult {
  const normalizedKey = key.toUpperCase().trim()

  // Проверка формата: MPFH-YYYYMMDD-XXXX-XXXX
  const formatRegex = /^MPFH-(\d{8})-([A-Z0-9]{4})-([A-Z0-9]{4})$/
  const match = normalizedKey.match(formatRegex)
  
  if (!match) {
    return { 
      valid: false, 
      error: 'Неверный формат ключа. Ожидался MPFH-YYYYMMDD-XXXX-XXXX',
      expiresDate: null,
      expiresFormatted: null
    }
  }

  const datePart = match[1]      // YYYYMMDD
  const checksum = match[2]      // 4 символа контрольной суммы

  // Проверка формата даты
  if (!isValidDate(datePart)) {
    return { 
      valid: false, 
      error: 'Неверная дата в ключе',
      expiresDate: null,
      expiresFormatted: null
    }
  }

  // Проверка контрольной суммы
  if (!verifyChecksum(datePart, checksum)) {
    return { 
      valid: false, 
      error: 'Неверная контрольная сумма ключа',
      expiresDate: null,
      expiresFormatted: null
    }
  }

  const expiresFormatted = formatDate(datePart)

  // Проверка даты истечения
  if (checkExpiration) {
    const today = new Date()
    today.setHours(0, 0, 0, 0)
    
    const year = parseInt(datePart.substring(0, 4), 10)
    const month = parseInt(datePart.substring(4, 6), 10)
    const day = parseInt(datePart.substring(6, 8), 10)
    const expiresDate = new Date(year, month - 1, day)
    
    if (expiresDate < today) {
      return { 
        valid: false, 
        error: `Срок действия ключа истёк ${expiresFormatted}`,
        expiresDate: datePart,
        expiresFormatted: expiresFormatted,
        expired: true
      }
    }
  }

  return { 
    valid: true, 
    error: null,
    expiresDate: datePart,
    expiresFormatted: expiresFormatted,
    expired: false
  }
}

const licenseKey = ref<string | null>(null)
const isValidated = ref(false)
const isValidating = ref(false)
const validationError = ref<string | null>(null)
const licenseExpiresDate = ref<string | null>(null)
const licenseExpiresFormatted = ref<string | null>(null)

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
export function setLicenseKey(key: string): LicenseValidationResult {
  const normalizedKey = key.toUpperCase().trim()

  // Локальная проверка формата, контрольной суммы и даты
  const validation = validateKeyFormat(normalizedKey, true)
  if (!validation.valid) {
    return validation
  }

  // Сохранение ключа
  licenseKey.value = normalizedKey
  licenseExpiresDate.value = validation.expiresDate || null
  licenseExpiresFormatted.value = validation.expiresFormatted || null
  saveLicense(normalizedKey)
  isValidated.value = true

  return validation
}

/**
 * Проверка лицензии при запуске приложения
 */
export function checkLicense(): LicenseValidationResult {
  const storedKey = loadLicense()

  if (!storedKey) {
    return { 
      valid: false, 
      error: 'Лицензионный ключ не найден',
      expiresDate: null,
      expiresFormatted: null
    }
  }

  // Локальная проверка формата, контрольной суммы и даты истечения
  const validation = validateKeyFormat(storedKey, true)
  if (!validation.valid) {
    clearLicense()
    return validation
  }

  licenseKey.value = storedKey
  licenseExpiresDate.value = validation.expiresDate || null
  licenseExpiresFormatted.value = validation.expiresFormatted || null
  isValidated.value = true

  return validation
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
    licenseExpiresDate,
    licenseExpiresFormatted,
    setLicenseKey,
    checkLicense,
    clearLicense,
    validateKeyFormat,
    formatDate
  }
}
