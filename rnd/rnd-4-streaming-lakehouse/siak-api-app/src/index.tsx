import { Hono } from 'hono'
import { serve } from '@hono/node-server'
import { logger } from 'hono/logger'
import api from './routes/api.ts'
import ui from './routes/ui.ts'
import { initializeKafka, shutdownKafka } from './services/kafka.ts'

const app = new Hono()

// Add logger middleware
app.use('*', logger())

// Mount routes
app.route('/api', api) // API routes under /api/*
app.route('/', ui)     // UI routes under /*

const port = process.env.PORT || 3000

// Initialize Kafka before starting the server
try {
  await initializeKafka()
  console.log('Kafka initialized successfully')
} catch (error) {
  console.error('Failed to initialize Kafka:', error)
  // Continue starting the server even if Kafka fails
}

console.log(`Server is running on port ${port}`)
console.log(`
Available routes:
- UI Home: http://localhost:${port}/
- UI Dashboard: http://localhost:${port}/dashboard
- API Health: http://localhost:${port}/api/health
- API Users: http://localhost:${port}/api/users
- Kafka Test: POST http://localhost:${port}/api/kafka/test
`)

// Handle graceful shutdown
process.on('SIGTERM', async () => {
  console.log('SIGTERM received. Shutting down gracefully...')
  await shutdownKafka()
  process.exit(0)
})

process.on('SIGINT', async () => {
  console.log('SIGINT received. Shutting down gracefully...')
  await shutdownKafka()
  process.exit(0)
})

serve({
  fetch: app.fetch,
  port: Number(port)
})

export default app
