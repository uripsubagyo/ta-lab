import { Hono } from 'hono'
import type { Context } from 'hono'

const ui = new Hono()

// Home page
ui.get('/', (c: Context) => {
  return c.html(`
    <!DOCTYPE html>
    <html>
      <head>
        <title>SIAK API App</title>
        <style>
          body {
            font-family: Arial, sans-serif;
            max-width: 800px;
            margin: 0 auto;
            padding: 20px;
          }
          .api-section {
            margin: 20px 0;
            padding: 20px;
            border: 1px solid #ddd;
            border-radius: 5px;
          }
          .form-group {
            margin: 10px 0;
          }
          .form-group label {
            display: block;
            margin-bottom: 5px;
          }
          .form-group input {
            width: 100%;
            padding: 8px;
            border: 1px solid #ddd;
            border-radius: 4px;
          }
          button {
            background: #007bff;
            color: white;
            border: none;
            padding: 10px 20px;
            border-radius: 4px;
            cursor: pointer;
          }
          button:hover {
            background: #0056b3;
          }
          #response {
            margin-top: 20px;
            padding: 10px;
            border: 1px solid #ddd;
            border-radius: 4px;
            display: none;
          }
        </style>
      </head>
      <body>
        <h1>Welcome to SIAK API App</h1>
        
        <div class="api-section">
          <h2>Available API Endpoints</h2>
          <ul>
            <li><code>GET /api/health</code> - Health check endpoint</li>
            <li><code>GET /api/users</code> - Get list of users</li>
            <li><code>POST /api/users</code> - Create a new user</li>
            <li><code>POST /api/kafka/test</code> - Send test message to Kafka</li>
          </ul>
        </div>

        <div class="api-section">
          <h2>Kafka Test</h2>
          <form id="kafkaForm">
            <div class="form-group">
              <label for="topic">Topic:</label>
              <input type="text" id="topic" name="topic" value="test-topic" required>
            </div>
            <div class="form-group">
              <label for="message">Message:</label>
              <input type="text" id="message" name="message" value="Hello Kafka!" required>
            </div>
            <button type="submit">Send Message</button>
          </form>
          <div id="response"></div>
        </div>

        <script>
          document.getElementById('kafkaForm').addEventListener('submit', async (e) => {
            e.preventDefault();
            const responseDiv = document.getElementById('response');
            responseDiv.style.display = 'block';
            responseDiv.innerHTML = 'Sending message...';

            try {
              const response = await fetch('/api/kafka/test', {
                method: 'POST',
                headers: {
                  'Content-Type': 'application/json',
                },
                body: JSON.stringify({
                  topic: document.getElementById('topic').value,
                  message: document.getElementById('message').value,
                }),
              });

              const data = await response.json();
              responseDiv.innerHTML = '<pre>' + JSON.stringify(data, null, 2) + '</pre>';
            } catch (error) {
              responseDiv.innerHTML = 'Error: ' + error.message;
            }
          });
        </script>
      </body>
    </html>
  `)
})

// Dashboard page
ui.get('/dashboard', (c: Context) => {
  return c.html(`
    <!DOCTYPE html>
    <html>
      <head>
        <title>Dashboard - SIAK API App</title>
        <style>
          body {
            font-family: Arial, sans-serif;
            max-width: 800px;
            margin: 0 auto;
            padding: 20px;
          }
        </style>
      </head>
      <body>
        <h1>Dashboard</h1>
        <p>Welcome to the dashboard!</p>
        <div id="api-data">Loading...</div>
        <script>
          fetch('/api/users')
            .then(res => res.json())
            .then(data => {
              document.getElementById('api-data').innerHTML = 
                '<h2>Users</h2>' + 
                '<pre>' + JSON.stringify(data, null, 2) + '</pre>';
            });
        </script>
      </body>
    </html>
  `)
})

export default ui 