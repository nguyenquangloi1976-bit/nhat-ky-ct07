import crypto from 'crypto'

export default defineEventHandler(async (event) => {
  const config = useRuntimeConfig()

  const formData = await readMultipartFormData(event)
  if (!formData || formData.length === 0) {
    throw createError({ statusCode: 400, message: 'Không có file nào được gửi' })
  }

  const file = formData.find((f) => f.name === 'file')
  if (!file || !file.data) {
    throw createError({ statusCode: 400, message: 'Không tìm thấy file trong form data' })
  }

  const email = config.googleServiceAccountEmail as string
  const privateKey = (config.googlePrivateKey as string).replace(/\\n/g, '\n')
  const folderId = config.googleDriveFolderId as string

  if (!email || !privateKey || !folderId) {
    throw createError({ statusCode: 500, message: 'Chưa cấu hình Google Drive credentials' })
  }

  // 1. Tạo JWT
  const jwt = createJWT(email, privateKey)

  // 2. Đổi JWT lấy access token
  const tokenResp = await fetch('https://oauth2.googleapis.com/token', {
    method: 'POST',
    headers: { 'Content-Type': 'application/x-www-form-urlencoded' },
    body: `grant_type=urn%3Aietf%3Aparams%3Aoauth%3Agrant-type%3Ajwt-bearer&assertion=${jwt}`,
  })
  const tokenData = (await tokenResp.json()) as { access_token?: string; error?: string }
  if (!tokenData.access_token) {
    throw createError({
      statusCode: 500,
      message: `Google auth thất bại: ${tokenData.error || 'unknown'}`,
    })
  }

  // 3. Upload lên Google Drive (multipart)
  const fileName = file.filename || 'upload'
  const mimeType = file.type || 'application/octet-stream'

  const metadata = JSON.stringify({
    name: fileName,
    parents: [folderId],
  })

  const boundary = 'nktc_boundary_' + Date.now()
  const metaPart = Buffer.from(
    `--${boundary}\r\nContent-Type: application/json; charset=UTF-8\r\n\r\n${metadata}\r\n`
  )
  const filePart = Buffer.from(`--${boundary}\r\nContent-Type: ${mimeType}\r\n\r\n`)
  const endPart = Buffer.from(`\r\n--${boundary}--`)

  const body = Buffer.concat([metaPart, filePart, file.data, endPart])

  const driveResp = await fetch(
    'https://www.googleapis.com/upload/drive/v3/files?uploadType=multipart&fields=id,webViewLink',
    {
      method: 'POST',
      headers: {
        Authorization: `Bearer ${tokenData.access_token}`,
        'Content-Type': `multipart/related; boundary=${boundary}`,
      },
      body,
    }
  )
  const driveData = (await driveResp.json()) as {
    id?: string
    webViewLink?: string
    error?: { message: string }
  }

  if (driveData.error) {
    throw createError({ statusCode: 500, message: `Drive upload lỗi: ${driveData.error.message}` })
  }

  return {
    id: driveData.id,
    url: driveData.webViewLink,
  }
})

function createJWT(email: string, privateKey: string): string {
  const header = Buffer.from(JSON.stringify({ alg: 'RS256', typ: 'JWT' })).toString('base64url')
  const now = Math.floor(Date.now() / 1000)
  const payload = Buffer.from(
    JSON.stringify({
      iss: email,
      scope: 'https://www.googleapis.com/auth/drive.file',
      aud: 'https://oauth2.googleapis.com/token',
      iat: now,
      exp: now + 3600,
    })
  ).toString('base64url')

  const signInput = `${header}.${payload}`
  const sign = crypto.createSign('RSA-SHA256')
  sign.update(signInput)
  const signature = sign.sign(privateKey, 'base64url')

  return `${signInput}.${signature}`
}
