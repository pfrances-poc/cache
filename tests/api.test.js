const request = require('supertest');
const { app, server } = require('../src/index');

describe('Cache Test POC API', () => {
  // Close server after all tests
  afterAll((done) => {
    if (server) {
      server.close(done);
    } else {
      done();
    }
  });
  describe('GET /', () => {
    it('should return API information', async () => {
      const response = await request(app).get('/');

      expect(response.status).toBe(200);
      expect(response.body).toHaveProperty('message', 'Cache Test POC API');
      expect(response.body).toHaveProperty('version', '1.0.0');
      expect(response.body).toHaveProperty('timestamp');
      expect(response.body).toHaveProperty('environment');
    });
  });

  describe('GET /health', () => {
    it('should return health status', async () => {
      const response = await request(app).get('/health');

      expect(response.status).toBe(200);
      expect(response.body).toHaveProperty('status', 'healthy');
      expect(response.body).toHaveProperty('uptime');
      expect(response.body).toHaveProperty('timestamp');
    });
  });

  describe('GET /cache-info', () => {
    it('should return cache information', async () => {
      const response = await request(app).get('/cache-info');

      expect(response.status).toBe(200);
      expect(response.body).toHaveProperty('message');
      expect(response.body).toHaveProperty('features');
      expect(response.body).toHaveProperty('build_info');
      expect(response.body.features).toContain('Docker layer caching');
      expect(response.body.features).toContain('Registry cache mounting');
    });
  });

  describe('Error handling', () => {
    it('should handle non-existent routes', async () => {
      const response = await request(app).get('/non-existent');

      expect(response.status).toBe(404);
    });
  });
});
