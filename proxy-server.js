const express = require('express');
const cors = require('cors');
const axios = require('axios');
const zlib = require('zlib');
const app = express();

// Enable CORS for all origins
app.use(cors());
app.use(express.json({ limit: '50mb' }));

const PORT = 3000;
const ANTHROPIC_API_URL = 'https://api.anthropic.com/v1';

// Proxy endpoint for Anthropic API
app.post('/messages', async (req, res) => {
  try {
    console.log('Proxying request to Anthropic API...');

    // Get API key from request headers
    const apiKey = req.headers['x-api-key'];
    if (!apiKey) {
      return res.status(401).json({ error: 'API key required' });
    }

    // Forward the request to Anthropic
    const response = await axios.post(
      `${ANTHROPIC_API_URL}/messages`,
      req.body,
      {
        headers: {
          'Content-Type': 'application/json',
          'x-api-key': apiKey,
          'anthropic-version': req.headers['anthropic-version'] || '2023-06-01',
          'anthropic-beta': req.headers['anthropic-beta'],
          'Accept-Encoding': 'gzip, deflate'
        },
        responseType: 'stream',
        decompress: false
      }
    );

    // Set headers for SSE
    res.setHeader('Content-Type', 'text/event-stream');
    res.setHeader('Cache-Control', 'no-cache');
    res.setHeader('Connection', 'keep-alive');
    res.setHeader('Access-Control-Allow-Origin', '*');

    // Handle compressed responses
    let stream = response.data;
    const contentEncoding = response.headers['content-encoding'];

    if (contentEncoding === 'gzip') {
      stream = stream.pipe(zlib.createGunzip());
    } else if (contentEncoding === 'deflate') {
      stream = stream.pipe(zlib.createInflate());
    }

    // Handle stream errors
    stream.on('error', (streamError) => {
      console.error('Stream error:', streamError);
      if (!res.headersSent) {
        res.status(500).json({ error: 'Stream processing error' });
      }
    });

    // Pipe the decompressed stream to client
    stream.pipe(res);

  } catch (error) {
    console.error('Proxy error:', error);

    // Handle axios errors properly
    if (error.response) {
      // Handle compressed error responses
      let errorData = error.response.data;
      const contentEncoding = error.response.headers['content-encoding'];

      if (contentEncoding === 'gzip' || contentEncoding === 'deflate') {
        try {
          const chunks = [];
          const decompressor = contentEncoding === 'gzip' ? zlib.createGunzip() : zlib.createInflate();

          if (typeof errorData === 'string') {
            errorData = Buffer.from(errorData);
          }

          decompressor.on('data', (chunk) => chunks.push(chunk));
          decompressor.on('end', () => {
            const decompressed = Buffer.concat(chunks).toString();
            try {
              const parsedError = JSON.parse(decompressed);
              res.status(error.response.status).json(parsedError);
            } catch (parseError) {
              res.status(error.response.status).json({ error: decompressed });
            }
          });
          decompressor.on('error', (decompError) => {
            console.error('Decompression error:', decompError);
            res.status(error.response.status).json({ error: 'Failed to decompress error response' });
          });

          if (errorData.pipe) {
            errorData.pipe(decompressor);
          } else {
            decompressor.write(errorData);
            decompressor.end();
          }
          return;
        } catch (decompError) {
          console.error('Error handling compressed response:', decompError);
        }
      }

      res.status(error.response.status).json({
        error: error.response.data || 'Unknown API error'
      });
    } else {
      res.status(500).json({
        error: error.message || 'Unknown proxy error'
      });
    }
  }
});

// Health check endpoint
app.get('/health', (req, res) => {
  res.json({ status: 'ok', message: 'Proxy server is running' });
});

app.listen(PORT, () => {
  console.log(`Anthropic proxy server running on http://localhost:${PORT}`);
  console.log('Use http://localhost:3000/messages for API calls');
});