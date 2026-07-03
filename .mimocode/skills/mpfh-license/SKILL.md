---
name: mpfh-license
description: Use when generating or validating MPFH license keys
---

# MPFH License Key System

## Key Format

```
MPFH-YYYYMMDD-XXXX-XXXX
│     │        │    │
│     │        │    └── Random 4-char suffix
│     │        └─────── CRC16 checksum of date
│     └──────────────── Expiration date (YYYYMMDD)
└────────────────────── Prefix
```

## Example

```
MPFH-20261231-A1B2-C3D4
```

- Expires: December 31, 2026
- Checksum: A1B2 (CRC16 of "20261231")
- Suffix: C3D4 (random)

## Generate a Key

### JavaScript (Browser Console)

```javascript
// CRC16 function
function crc16(data) {
  let crc = 0xFFFF;
  const table = [];
  for (let i = 0; i < 256; i++) {
    let c = i;
    for (let j = 0; j < 8; j++) {
      c = (c & 1) ? (0xA001 ^ (c >>> 1)) : (c >>> 1);
    }
    table[i] = c;
  }
  for (let i = 0; i < data.length; i++) {
    crc = table[(crc ^ data.charCodeAt(i)) & 0xFF] ^ (crc >>> 8);
  }
  return crc & 0xFFFF;
}

// Generate key
function generateKey(expirationDate) {
  const dateStr = expirationDate.toISOString().slice(0, 10).replace(/-/g, '');
  const checksum = crc16(dateStr).toString(16).padStart(4, '0').toUpperCase();
  const suffix = Array.from({length: 4}, () => 
    '0123456789ABCDEF'[Math.floor(Math.random() * 16)]
  ).join('');
  return `MPFH-${dateStr}-${checksum}-${suffix}`;
}

// Example: expires 2026-12-31
console.log(generateKey(new Date('2026-12-31')));
```

### Python (Script)

```python
def crc16(data: str) -> int:
    crc = 0xFFFF
    for byte in data.encode('utf-8'):
        crc ^= byte
        for _ in range(8):
            if crc & 1:
                crc = (crc >> 1) ^ 0xA001
            else:
                crc >>= 1
    return crc & 0xFFFF

def generate_key(expiration_date: str) -> str:
    """expiration_date: YYYYMMDD"""
    checksum = format(crc16(expiration_date), '04X')
    import random
    suffix = ''.join(random.choices('0123456789ABCDEF', k=4))
    return f"MPFH-{expiration_date}-{checksum}-{suffix}"

# Example
print(generate_key("20261231"))
```

## Validate a Key

```javascript
function validateKey(key) {
  const regex = /^MPFH-(\d{8})-([A-F0-9]{4})-([A-F0-9]{4})$/;
  const match = key.toUpperCase().trim().match(regex);
  
  if (!match) return { valid: false, error: 'Invalid format' };
  
  const [, dateStr, checksum] = match;
  const computed = crc16(dateStr).toString(16).padStart(4, '0').toUpperCase();
  
  if (computed !== checksum) {
    return { valid: false, error: 'Invalid checksum' };
  }
  
  const expDate = new Date(
    parseInt(dateStr.slice(0, 4)),
    parseInt(dateStr.slice(4, 6)) - 1,
    parseInt(dateStr.slice(6, 8))
  );
  
  if (expDate < new Date()) {
    return { valid: false, error: 'Key expired', expires: dateStr };
  }
  
  return { valid: true, expires: dateStr };
}
```

## Batch Generation

```python
import random
from datetime import datetime, timedelta

def batch_generate(count: int, days_valid: int = 365) -> list:
    keys = []
    for _ in range(count):
        exp = datetime.now() + timedelta(days=days_valid)
        date_str = exp.strftime('%Y%m%d')
        keys.append(generate_key(date_str))
    return keys

# Generate 10 keys valid for 1 year
keys = batch_generate(10)
for k in keys:
    print(k)
```

## Security Notes

- CRC16 is for format validation, not cryptographic security
- Keys are validated client-side only
- For production, consider server-side validation with a secret salt
- Store generated keys securely; they cannot be recovered

## Troubleshooting

| Issue | Cause | Solution |
|-------|-------|----------|
| "Invalid checksum" | Wrong CRC16 implementation | Use the exact algorithm above |
| "Key expired" | Date passed | Generate new key with future date |
| "Invalid format" | Typos or wrong case | Use uppercase, check dashes |
