const express = require('express');
const cors = require('cors');

const app = express();
const PORT = process.env.PORT || 3000;

// Middleware
app.use(cors());
app.use(express.json());

// Routes
app.get('/', (req, res) => {
  res.json({
    message: 'Cache Test POC API',
    version: '1.0.0',
    timestamp: new Date().toISOString(),
    environment: process.env.NODE_ENV || 'development'
  });
});

app.get('/health', (req, res) => {
  res.status(200).json({
    status: 'healthy',
    uptime: process.uptime(),
    timestamp: new Date().toISOString()
  });
});

app.get('/cache-info', (req, res) => {
  res.json({
    message: 'Cette API démontre l\'utilisation du cache Docker dans les merge groups',
    features: [
      'Docker layer caching',
      'Registry cache mounting',
      'Multi-stage builds optimisés',
      'Cache partagé entre builds'
    ],
    build_info: {
      build_time: process.env.BUILD_TIME || 'unknown',
      commit_sha: process.env.COMMIT_SHA || 'unknown',
      branch: process.env.BRANCH || 'unknown'
    }
  });
});

// Error handling
app.use((err, req, res, next) => {
  console.error('Error:', err.message);
  res.status(500).json({
    error: 'Internal server error',
    message: err.message
  });
});

// Start server
app.listen(PORT, () => {
  console.log(`🚀 Server running on port ${PORT}`);
  console.log(`📊 Environment: ${process.env.NODE_ENV || 'development'}`);
  console.log(`🕐 Started at: ${new Date().toISOString()}`);
});

module.exports = app;
