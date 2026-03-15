/**
 * Скрипт для генерации лицензионных ключей MPFH
 * Формат: MPFH-XXXXXXXX-XXXX-XXXX (24 символа)
 * Структура:
 *   - MPFH- (префикс, 5 символов)
 *   - XXXXXXXX (8 случайных символов)
 *   - XXXX (4 символа контрольной суммы CRC16)
 *   - XXXX (4 случайных символа)
 */

import crypto from 'crypto';

const PREFIX = 'MPFH-';
const CHARSET = '0123456789ABCDEFGHIJKLMNOPQRSTUVWXYZ';

/**
 * Генерация случайной строки из символов CHARSET
 */
function randomString(length) {
  let result = '';
  const randomBytes = crypto.randomBytes(length);
  for (let i = 0; i < length; i++) {
    result += CHARSET[randomBytes[i] % CHARSET.length];
  }
  return result;
}

/**
 * Вычисление CRC16 контрольной суммы
 */
function crc16(data) {
  let crc = 0xFFFF;
  const table = [];

  // Генерация таблицы CRC16 (полином 0x8005)
  for (let i = 0; i < 256; i++) {
    let c = i;
    for (let j = 0; j < 8; j++) {
      c = (c & 1) ? (0xA001 ^ (c >>> 1)) : (c >>> 1);
    }
    table[i] = c;
  }

  // Вычисление CRC
  for (let i = 0; i < data.length; i++) {
    crc = table[(crc ^ data.charCodeAt(i)) & 0xFF] ^ (crc >>> 8);
  }

  return crc & 0xFFFF;
}

/**
 * Преобразование CRC16 в 4-символьную строку (base36)
 */
function crcToChecksum(crc) {
  // CRC16 = 16 бит = 4 символа base36 (6 бит на символ = 24 бита, берём нижние)
  const hex = crc.toString(16).padStart(4, '0').toUpperCase();
  return hex;
}

/**
 * Проверка контрольной суммы
 */
function verifyChecksum(randomPart, checksum) {
  const computedCrc = crc16(randomPart);
  const computedChecksum = crcToChecksum(computedCrc);
  return computedChecksum === checksum.toUpperCase();
}

/**
 * Генерация лицензионного ключа
 */
function generateKey() {
  const randomPart = randomString(8);
  const crc = crc16(randomPart);
  const checksum = crcToChecksum(crc);
  const suffix = randomString(4);

  return `${PREFIX}${randomPart}-${checksum}-${suffix}`;
}

/**
 * Валидация лицензионного ключа
 */
function validateKey(key) {
  // Проверка формата
  const formatRegex = /^MPFH-[A-Z0-9]{8}-[A-Z0-9]{4}-[A-Z0-9]{4}$/;
  if (!formatRegex.test(key)) {
    return { valid: false, error: 'Неверный формат ключа' };
  }

  // Извлечение частей ключа
  const parts = key.split('-');
  const randomPart = parts[1]; // 8 символов
  const checksum = parts[2];   // 4 символа (контрольная сумма)

  // Проверка контрольной суммы
  if (!verifyChecksum(randomPart, checksum)) {
    return { valid: false, error: 'Неверная контрольная сумма' };
  }

  return { valid: true, error: null };
}

// Основной блок
const args = process.argv.slice(2);

if (args[0] === '--validate' && args[1]) {
  // Режим валидации
  const key = args[1].toUpperCase();
  const result = validateKey(key);
  if (result.valid) {
    console.log(`✓ Ключ валиден: ${key}`);
  } else {
    console.log(`✗ Ошибка: ${result.error}`);
    process.exit(1);
  }
} else if (args[0] === '--batch' && args[1]) {
  // Генерация нескольких ключей
  const count = parseInt(args[1], 10);
  console.log(`Генерация ${count} ключей:\n`);
  for (let i = 0; i < count; i++) {
    const key = generateKey();
    console.log(`${i + 1}. ${key}`);
  }
} else {
  // Генерация одного ключа
  const key = generateKey();
  console.log('Сгенерированный лицензионный ключ:');
  console.log(`\n${key}\n`);

  // Демонстрация валидации
  const validation = validateKey(key);
  console.log(`Проверка: ${validation.valid ? '✓ пройдена' : '✗ не пройдена'}`);
}

export { generateKey, validateKey, crc16 };
