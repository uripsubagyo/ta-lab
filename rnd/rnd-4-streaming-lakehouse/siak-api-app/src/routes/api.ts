import { Hono } from 'hono'
import type { Context } from 'hono'
import { sendMessage } from '../services/kafka.ts'

const api = new Hono()

// Health check endpoint
api.get('/health', (c: Context) => {
  return c.json({
    status: 'ok',
    timestamp: new Date().toISOString()
  })
})

interface CreateFacultyBody {
    name: string;
    code: string;
}

api.post('/faculty/create', async (c: Context) => {
    try {
        const body = await c.req.json<CreateFacultyBody>()
        await sendMessage('faculty-topic',{
            action: 'create',
            data: body,
            timestamp: new Date().toISOString()
        })  

        return c.json({
            message: 'Faculty created and event published',
            data: body
        }, 201)

    } catch (error) {
        console.error('Error processing request:', error)
        return c.json({
            error: 'Failed to process request',
            message: error instanceof Error ? error.message : 'Unknown error'
        }, 500)
    }
})

interface UpdateFacultyBody {
    id: number;
    name: string;
    code: string;
}

api.post('/faculty/update', async (c: Context) => {

    try {
        const body = await c.req.json<UpdateFacultyBody>()

        await sendMessage('faculty-topic',{
            action: 'update',
            data: body,
            timestamp: new Date().toISOString()
        })

        return c.json({ 
            message: 'Faculty updated and event published',
            data: body
        }, 201)
    } catch (error) {
        console.error('Error processing request:', error)
        return c.json({
            error: 'Failed to process request',
            message: error instanceof Error ? error.message : 'Unknown error'
        }, 500)
    }
})



interface KafkaTestBody {
  topic?: string;
  message?: string;
}

// Kafka test endpoints
api.post('/kafka/test', async (c: Context) => {
  try {
    const body = await c.req.json<KafkaTestBody>()
    const message = body.message || 'Test message'
    const topic = body.topic || 'test-topic'

    await sendMessage(topic, message)

    return c.json({ 
      message: 'Test message sent to Kafka',
      topic,
      data: message
    })
  } catch (error) {
    console.error('Error sending test message:', error)
    return c.json({ 
      error: 'Failed to send message',
      message: error instanceof Error ? error.message : 'Unknown error'
    }, 500)
  }
})

export default api 