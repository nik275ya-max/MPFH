import { ref, computed } from 'vue'

const replies = ref<string[]>([])
const isRecording = ref(false)
const recognition = ref<SpeechRecognition | null>(null)

export function useRecording() {
  const initRecognition = () => {
    if (!('webkitSpeechRecognition' in window) && !('SpeechRecognition' in window)) {
      alert('Распознавание речи не поддерживается в вашем браузере')
      return false
    }

    const SpeechRecognitionAPI = (window as any).SpeechRecognition || (window as any).webkitSpeechRecognition
    const rec = new SpeechRecognitionAPI() as SpeechRecognition
    rec.continuous = true
    rec.interimResults = false
    rec.lang = 'ru-RU'

    rec.onresult = (event: SpeechRecognitionEvent) => {
      const transcript = event.results[event.results.length - 1][0].transcript
      replies.value.push(transcript.trim())
    }

    rec.onerror = (event: any) => {
      console.error('Speech recognition error:', event.error)
      isRecording.value = false
    }

    rec.onend = () => {
      isRecording.value = false
    }

    recognition.value = rec
    return true
  }

  const startRecording = () => {
    if (!recognition.value && !initRecognition()) {
      return
    }

    try {
      recognition.value?.start()
      isRecording.value = true
    } catch (error) {
      console.error('Failed to start recording:', error)
    }
  }

  const stopRecording = () => {
    try {
      recognition.value?.stop()
      isRecording.value = false
    } catch (error) {
      console.error('Failed to stop recording:', error)
    }
  }

  const clearReplies = () => {
    replies.value = []
  }

  const isComplete = computed(() => (maxReplies: number) => replies.value.length >= maxReplies)

  return {
    replies,
    isRecording,
    startRecording,
    stopRecording,
    clearReplies,
    isComplete
  }
}
