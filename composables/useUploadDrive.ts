const CHUNK_SIZE = 3 * 1024 * 1024 // 3MB — dưới giới hạn 4.5MB của Vercel

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
      const initRes = await $fetch<{ sessionUrl: string }>('/api/upload-drive', {
        method: 'POST',
        body: {
          fileName: file.name,
          mimeType: file.type || 'application/octet-stream',
          fileSize: file.size,
        },
      })

      const { sessionUrl } = initRes
      const totalSize = file.size
      let offset = 0

      // Bước 2: Gửi từng chunk
      while (offset < totalSize) {
        const end = Math.min(offset + CHUNK_SIZE, totalSize)
        const chunk = file.slice(offset, end)

        const res = await $fetch<{ done: boolean; uploaded?: number; fileUrl?: string }>(
          '/api/upload-drive-chunk',
          {
            method: 'POST',
            params: {
              sessionUrl,
              offset,
              totalSize,
            },
            body: chunk,
            headers: {
              'Content-Type': 'application/octet-stream',
            },
          }
        )

        if (res.done && res.fileUrl) {
          uploadProgress.value = 100
          return res.fileUrl
        }

        offset = res.uploaded || end
        uploadProgress.value = Math.round((offset / totalSize) * 100)
      }

      uploadError.value = 'Upload không hoàn tất'
      return null
    } catch (err: any) {
      uploadError.value = err?.data?.message || err?.message || 'Lỗi upload'
      return null
    } finally {
      uploading.value = false
    }
  }

  return { uploadFile, uploading, uploadError, uploadProgress }
}
