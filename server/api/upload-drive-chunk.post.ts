export default defineEventHandler(async (event) => {
  const contentType = getHeader(event, 'content-type') || ''

  // Đọc query params
  const query = getQuery(event)
  const sessionUrl = query.sessionUrl as string
  const offset = parseInt(query.offset as string, 10)
  const totalSize = parseInt(query.totalSize as string, 10)

  if (!sessionUrl || isNaN(offset) || isNaN(totalSize)) {
    throw createError({ statusCode: 400, statusMessage: 'Thiếu sessionUrl, offset hoặc totalSize' })
  }

  // Đọc raw body (binary)
  const chunk = await readRawBody(event, false)
  if (!chunk || chunk.length === 0) {
    throw createError({ statusCode: 400, statusMessage: 'Chunk rỗng' })
  }

  const chunkSize = chunk.length
  const rangeEnd = offset + chunkSize - 1
  const contentRange = `bytes ${offset}-${rangeEnd}/${totalSize}`

  // Gửi chunk lên Google
  const res = await fetch(sessionUrl, {
    method: 'PUT',
    headers: {
      'Content-Length': String(chunkSize),
      'Content-Range': contentRange,
    },
    body: chunk,
  })

  // 308 = cần chunk tiếp, 200/201 = hoàn tất
  if (res.status === 308) {
    return { done: false, uploaded: rangeEnd + 1 }
  }

  if (res.ok) {
    const fileData = await res.json()
    const fileId = fileData.id
    // Đặt quyền xem cho anyone
    try {
      const { getAccessToken } = await import('../utils/google-auth')
      const accessToken = await getAccessToken()
      await fetch(`https://www.googleapis.com/drive/v3/files/${fileId}/permissions`, {
        method: 'POST',
        headers: {
          Authorization: `Bearer ${accessToken}`,
          'Content-Type': 'application/json',
        },
        body: JSON.stringify({ role: 'reader', type: 'anyone' }),
      })
    } catch (_) {
      // Không set được permission thì bỏ qua
    }

    return {
      done: true,
      fileId,
      fileUrl: `https://drive.google.com/file/d/${fileId}/view`,
    }
  }

  const err = await res.text()
  throw createError({ statusCode: res.status, statusMessage: `Upload chunk lỗi: ${err}` })
})
