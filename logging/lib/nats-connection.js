// lib/nats-connection.js
import { connect } from 'nats';

class NATSConnection {
  constructor() {
    this.nc = null;
    this.isConnected = false;
  }

  async connect(servers = ['nats://localhost:4222']) {
    try {
      this.nc = await connect({ 
        servers,
        reconnect: true,
        maxReconnectAttempts: 10,
        reconnectTimeWait: 1000,
      });
      
      this.isConnected = true;
      console.log('✅ Connected to NATS server');
      
      // Handle connection events
      this.nc.closed().then(() => {
        console.log('📪 NATS connection closed');
        this.isConnected = false;
      });

      return this.nc;
    } catch (error) {
      console.error('❌ Failed to connect to NATS:', error.message);
      throw error;
    }
  }

  async publish(subject, data) {
    if (!this.isConnected || !this.nc) {
      throw new Error('NATS not connected');
    }
    
    const payload = JSON.stringify({
      timestamp: new Date().toISOString(),
      ...data
    });
    
    this.nc.publish(subject, payload);
    console.log(`📤 Published to ${subject}:`, payload);
  }

  async subscribe(subject, callback) {
    if (!this.isConnected || !this.nc) {
      throw new Error('NATS not connected');
    }

    const subscription = this.nc.subscribe(subject);
    console.log(`📥 Subscribed to ${subject}`);

    (async () => {
      for await (const msg of subscription) {
        try {
          const data = JSON.parse(msg.data);
          await callback(data, msg);
        } catch (error) {
          console.error(`Error processing message from ${subject}:`, error);
        }
      }
    })();

    return subscription;
  }

  async request(subject, data, timeout = 5000) {
    if (!this.isConnected || !this.nc) {
      throw new Error('NATS not connected');
    }

    const payload = JSON.stringify({
      timestamp: new Date().toISOString(),
      ...data
    });

    try {
      const response = await this.nc.request(subject, payload, { timeout });
      return JSON.parse(response.data);
    } catch (error) {
      console.error(`Request to ${subject} failed:`, error);
      throw error;
    }
  }

  async close() {
    if (this.nc) {
      await this.nc.drain();
      this.isConnected = false;
    }
  }
}

export default NATSConnection;
