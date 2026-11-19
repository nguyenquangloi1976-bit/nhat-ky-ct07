export function useUploadDrive() {
  const uploading = ref(false)
  const uploadError = ref('')

  async function uploadFile(file: File): Promise<string | null> {
    uploading.value = true
    uploadError.value = ''

    try {
      // Bước 1: Lấy resumable upload URL từ server (request nhỏ, chỉ gửi metadata)
      const { uploadUrl } = await $fetch<{ uploadUrl: string }>('/api/upload-drive', {
        method: 'POST',
        body: { fileName: file.name, mimeType: file.type || 'application/octet-stream' },
      })

      // Bước 2: Upload file thẳng lên Google Drive (không qua Vercel, không giới hạn 4.5MB)
      const uploadResp = await fetch(uploadUrl, {
        method: 'PUT',
        headers: {
          'Content-Type': file.type || 'application/octet-stream',
        },
        body: file,
      })

      if (!uploadResp.ok) {
        const errText = await uploadResp.text()
        throw new Error(`Upload thất bại (${uploadResp.status}): ${errText}`)
      }

      const data = (await uploadResp.json()) as { id?: string }
      if (!data.id) {
        throw new Error('Không nhận được file ID từ Google Drive')
      }

      return `https://drive.google.com/file/d/${data.id}/view`
    } catch (err: any) {
      uploadError.value = err.data?.message || err.message || 'Lỗi upload'
      return null
    } finally {
      uploading.value = false
    }
  }

  return { uploadFile, uploading, uploadError }
}
