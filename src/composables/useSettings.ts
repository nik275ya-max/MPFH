import { ref, watch } from 'vue'

export interface Settings {
  instruction: string
  repliesCount: number
}

const STORAGE_KEY = 'master-prediction-settings'

const defaultSettings: Settings = {
  instruction: 'Инструкция к фокусу:',
  repliesCount: 4
}

const settings = ref<Settings>(loadSettings())

function loadSettings(): Settings {
  try {
    const stored = localStorage.getItem(STORAGE_KEY)
    if (stored) {
      return { ...defaultSettings, ...JSON.parse(stored) }
    }
  } catch (error) {
    console.error('Failed to load settings:', error)
  }
  return { ...defaultSettings }
}

function saveSettings() {
  try {
    localStorage.setItem(STORAGE_KEY, JSON.stringify(settings.value))
  } catch (error) {
    console.error('Failed to save settings:', error)
  }
}

watch(settings, saveSettings, { deep: true })

export function useSettings() {
  return {
    settings,
    updateSettings: (newSettings: Partial<Settings>) => {
      settings.value = { ...settings.value, ...newSettings }
    }
  }
}
