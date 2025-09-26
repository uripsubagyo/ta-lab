import { Kafka, Producer, Consumer, Admin } from 'kafkajs'

// Create Kafka client
const kafka = new Kafka({
  clientId: 'siak-api-app',
  brokers: [process.env.KAFKA_BROKER || 'kafka-broker:29092'],
  retry: {
    initialRetryTime: 100,
    retries: 8
  }
})

// Create instances
let producer: Producer | null = null
let consumer: Consumer | null = null
let admin: Admin | null = null

// List of topics to create (deduplicated)
const TOPICS = Array.from(new Set([
  'test-topic',
  'faculty-topic',
  'program-topic',
  'student-topic',
  'class-topic',
  'course-topic',
  'lecturer-topic',
  'payment-topic',
  'registration-topic',
  'room-topic',
  'student-detail-topic',
  'student-enrollment-topic',
  'student-fee-topic'
]))

// Initialize Kafka connections
export async function initializeKafka(): Promise<void> {
  try {
    // Create new instances
    producer = kafka.producer()
    consumer = kafka.consumer({ groupId: 'siak-api-group' })
    admin = kafka.admin()

    // Connect admin, producer and consumer
    await admin.connect()
    await producer.connect()
    await consumer.connect()
    
    console.log('Successfully connected to Kafka')

    // Get list of existing topics
    const existingTopics = await admin.listTopics()
    
    // Create topics that don't exist
    const topicsToCreate = TOPICS.filter(topic => !existingTopics.includes(topic))
    
    if (topicsToCreate.length > 0) {
      await admin.createTopics({
        topics: topicsToCreate.map(topic => ({
          topic,
          numPartitions: 1,
          replicationFactor: 1
        }))
      })
      console.log('Created topics:', topicsToCreate)
    }
    
    // Subscribe to topics
    await consumer.subscribe({ 
      topics: TOPICS,
      fromBeginning: true 
    })

    // Start consuming messages
    await consumer.run({
      eachMessage: async ({ topic, partition, message }) => {
        console.log({
          topic,
          partition,
          value: message.value?.toString(),
          headers: message.headers,
        })
      },
    })

  } catch (error) {
    console.error('Error connecting to Kafka:', error)
    throw error
  }
}

// Ensure producer is connected
async function ensureProducerConnected(): Promise<Producer> {
  if (!producer) {
    producer = kafka.producer()
    await producer.connect()
  }
  return producer
}

// Send message to Kafka topic
export async function sendMessage(topic: string, message: string | Record<string, unknown>): Promise<boolean> {
  try {
    const connectedProducer = await ensureProducerConnected()
    
    await connectedProducer.send({
      topic,
      messages: [
        { 
          value: typeof message === 'string' ? message : JSON.stringify(message),
          timestamp: Date.now().toString()
        }
      ],
    })
    console.log(`Message sent to topic ${topic} successfully`)
    return true
  } catch (error) {
    console.error(`Error sending message to topic ${topic}:`, error)
    
    // If the error is due to disconnection, try to reconnect once
    if ((error as any).message === 'The producer is disconnected') {      try {
        producer = null // Reset the producer
        const reconnectedProducer = await ensureProducerConnected()
        
        await reconnectedProducer.send({
          topic,
          messages: [
            { 
              value: typeof message === 'string' ? message : JSON.stringify(message),
              timestamp: Date.now().toString()
            }
          ],
        })
        console.log(`Message sent to topic ${topic} successfully after reconnection`)
        return true
      } catch (retryError) {
        console.error(`Failed to send message after reconnection attempt:`, retryError)
        throw retryError
      }
    }
    
    throw error
  }
}

// Graceful shutdown
export async function shutdownKafka(): Promise<void> {
  try {
    if (producer) await producer.disconnect()
    if (consumer) await consumer.disconnect()
    if (admin) await admin.disconnect()
    
    producer = null
    consumer = null
    admin = null
    
    console.log('Disconnected from Kafka')
  } catch (error) {
    console.error('Error disconnecting from Kafka:', error)
    throw error
  }
} 