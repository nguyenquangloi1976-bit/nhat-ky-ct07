import crypto from 'crypto'

export default defineEventHandler(async (event) => {
  const config = useRuntimeConfig()
  const body = await readBody(event)
  const { fileName, mimeType, fileSize } = body

  const email = config.googleServiceAccountEmail as string
  const privateKey = (config.googlePrivateKey as string).replace(/\\n/g, '\n')
  const folderId = config.googleDriveFolderId as string

  if (!email || !privateKey || !folderId) {
    throw createError({ statusCode: 500, message: 'Chưa cấu hình Google Drive credentials' })
  }

  const jwt = createJWT(email, privateKey)

  const tokenResp = await fetch('https://oauth2.googleapis.com/token', {
    method: 'POST',
    headers: { 'Content-Type': 'application/x-www-form-urlencoded' },
    body: `grant_type=urn%3Aietf%3Aparams%3Aoauth%3Agrant-type%3Ajwt-bearer&assertion=${jwt}`,
  })
  const tokenData = (await tokenResp.json()) as { access_token?: string; error?: string }
  if (!tokenData.access_token) {
    throw createError({ statusCode: 500, message: `Google auth thất bại: ${tokenData.error || 'unknown'}` })
  }

  const initResp = await fetch(
    'https://www.googleapis.com/upload/drive/v3/files?uploadType=resumable',
    {
      method: 'POST',
      headers: {
        Authorization: `Bearer ${tokenData.access_token}`,
        'Content-Type': 'application/json; charset=UTF-8',
        'X-Upload-Content-Type': mimeType || 'application/octet-stream',
        'X-Upload-Content-Length': String(fileSize || 0),
      },
      body: JSON.stringify({ name: fileName, parents: [folderId] }),
    }
  )

  const sessionUrl = initResp.headers.get('location')
  if (!sessionUrl) {
    const err = (await initResp.json()) as { error?: { message: string } }
    throw createError({ statusCode: 500, message: `Drive init lỗi: ${err.error?.message || 'unknown'}` })
  }

  return { sessionUrl }
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
