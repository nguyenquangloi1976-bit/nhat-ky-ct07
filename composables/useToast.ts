interface ToastState {
  show: boolean
  message: string
  type: 'success' | 'error' | 'info'
}

const state = reactive<ToastState>({
  show: false,
  message: '',
  type: 'info',
})

let timer: ReturnType<typeof setTimeout> | null = null

export function useToast() {
  function showToast(message: string, type: ToastState['type'] = 'info', duration = 3000) {
    if (timer) clearTimeout(timer)
    state.message = message
    state.type = type
    state.show = true
    timer = setTimeout(() => { state.show = false }, duration)
  }

  return {
    toast: state,
    showToast,
    success: (msg: string) => showToast(msg, 'success'),
    error: (msg: string) => showToast(msg, 'error'),
    info: (msg: string) => showToast(msg, 'info'),
  }
}
