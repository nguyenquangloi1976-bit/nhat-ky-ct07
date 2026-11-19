export function useUploadDrive() {
  const uploading = ref(false)
  const uploadError = ref('')

  async function uploadFile(file: File): Promise<string | null> {
    uploading.value = true
    uploadError.value = ''

    try {
      const formData = new FormData()
      formData.append('file', file)

      const data = await $fetch<{ url: string }>('/api/upload-drive', {
        method: 'POST',
        body: formData,
      })

      return data.url
    } catch (err: any) {
      uploadError.value = err.data?.message || err.message || 'Lỗi upload'
      return null
    } finally {
      uploading.value = false
    }
  }

  return { uploadFile, uploading, uploadError }
}
