const CHUNK_SIZE = 3 * 1024 * 1024 // 3MB mỗi phần (< 4.5MB limit Vercel)

export function useUploadDrive() {
  const uploading = ref(false)
  const uploadError = ref('')
  const uploadProgress = ref(0)

  async function uploadFile(file: File): Promise<string | null> {
    uploading.value = true
    uploadError.value = ''
    uploadProgress.value = 0

    try {
      // Bước 1: Khởi tạo upload session
      const { sessionUrl } = await $fetch<{ sessionUrl: string }>('/api/upload-drive', {
        method: 'POST',
        body: {
          fileName: file.name,
          mimeType: file.type || 'application/octet-stream',
          fileSize: file.size,
        },
      })

      // Bước 2: Upload từng chunk qua server
      let driveUrl: string | null = null
      const totalSize = file.size

      for (let start = 0; start < totalSize; start += CHUNK_SIZE) {
        const end = Math.min(start + CHUNK_SIZE, totalSize)
        const chunk = file.slice(start, end)

        const formData = new FormData()
        formData.append('chunk', chunk)
        formData.append('sessionUrl', sessionUrl)
        formData.append('start', String(start))
        formData.append('end', String(end - 1))
        formData.append('total', String(totalSize))

        const result = await $fetch<{ done: boolean; url?: string }>('/api/upload-drive-chunk', {
          method: 'POST',
          body: formData,
        })

        uploadProgress.value = Math.round((end / totalSize) * 100)

        if (result.done && result.url) {
          driveUrl = result.url
        }
      }

      if (!driveUrl) {
        throw new Error('Upload hoàn tất nhưng không nhận được link')
      }

      return driveUrl
    } catch (err: any) {
      uploadError.value = err.data?.message || err.message || 'Lỗi upload'
      return null
    } finally {
      uploading.value = false
      uploadProgress.value = 0
    }
  }

  return { uploadFile, uploading, uploadError, uploadProgress }
}
