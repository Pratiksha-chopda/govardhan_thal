import { io } from 'socket.io-client';

const SOCKET_URL = process.env.NEXT_PUBLIC_API_URL || 'http://localhost:3000';

class SocketService {
  constructor() {
    this.socket = null;
  }

  connect() {
    if (!this.socket) {
      this.socket = io(SOCKET_URL, {
        transports: ['websocket'],
      });

      this.socket.on('connect', () => {
        console.log('🔗 Connected to Socket Server');
        this.socket.emit('join:admin');
      });

      this.socket.on('disconnect', () => {
        console.log('❌ Disconnected from Socket Server');
      });
    }
  }

  disconnect() {
    if (this.socket) {
      this.socket.disconnect();
      this.socket = null;
    }
  }

  on(eventName, callback) {
    if (!this.socket) return;
    this.socket.on(eventName, callback);
  }

  off(eventName, callback) {
    if (!this.socket) return;
    this.socket.off(eventName, callback);
  }

  emit(eventName, data) {
    if (!this.socket) return;
    this.socket.emit(eventName, data);
  }
}

const socketService = new SocketService();
export default socketService;
