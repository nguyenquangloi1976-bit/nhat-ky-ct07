import { getAccessToken } from '../utils/google-auth'

export default defineEventHandler(async (event) => {
  const body = await readBody(event)
  const { fileName, mimeType, fileSize, folderId: clientFolderId } = body

  if (!fileName) {
    throw createError({ statusCode: 400, statusMessage: 'Thiếu fileName' })
  }

  const config = useRuntimeConfig()
  const folderId = (clientFolderId as string) || (config.googleDriveFolderId as string)
  const accessToken = await getAccessToken()

  // Tạo resumable upload session
  const metadata: any = { name: fileName }
  if (folderId) metadata.parents = [folderId]

  const res = await fetch(
    'https://www.googleapis.com/upload/drive/v3/files?uploadType=resumable&supportsAllDrives=true',
    {
      method: 'POST',
      headers: {
        Authorization: `Bearer ${accessToken}`,
        'Content-Type': 'application/json; charset=UTF-8',
        'X-Upload-Content-Type': mimeType || 'application/octet-stream',
        ...(fileSize ? { 'X-Upload-Content-Length': String(fileSize) } : {}),
      },
      body: JSON.stringify(metadata),
    }
  )

  if (!res.ok) {
    const err = await res.text()
    throw createError({ statusCode: res.status, statusMessage: `Google Drive error: ${err}` })
  }

  const sessionUrl = res.headers.get('location')
  if (!sessionUrl) {
    throw createError({ statusCode: 500, statusMessage: 'Không nhận được session URL từ Google' })
  }

  return { sessionUrl }
})
