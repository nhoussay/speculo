#!/usr/bin/env node

/**
 * WebSocket-to-P2P Bridge for Single-Port Blockchain Node
 * 
 * This bridge allows P2P communication over WebSocket via the nginx proxy.
 * Clients can connect to ws://localhost:8080/p2p to communicate with the P2P layer.
 */

const WebSocket = require('ws');
const net = require('net');
const http = require('http');

// Configuration
const WS_PORT = 8081;
const P2P_HOST = '127.0.0.1';
const P2P_PORT = 26656;
const HEALTH_CHECK_PORT = 8082;

console.log('🌉 Starting WebSocket-to-P2P Bridge...');
console.log(`📡 WebSocket Server: localhost:${WS_PORT}`);
console.log(`🤝 P2P Target: ${P2P_HOST}:${P2P_PORT}`);

// Create WebSocket server
const wss = new WebSocket.Server({ 
    port: WS_PORT,
    perMessageDeflate: false 
});

console.log(`✅ WebSocket server listening on port ${WS_PORT}`);

// Track connections
let connectionCount = 0;
const connections = new Map();

wss.on('connection', function connection(ws, req) {
    const connectionId = ++connectionCount;
    console.log(`🔗 New WebSocket connection #${connectionId} from ${req.socket.remoteAddress}`);
    
    // Create TCP connection to P2P port
    const tcpSocket = new net.Socket();
    connections.set(connectionId, { ws, tcpSocket });
    
    // Connect to P2P port
    tcpSocket.connect(P2P_PORT, P2P_HOST, function() {
        console.log(`✅ TCP connection #${connectionId} established to P2P layer`);
    });
    
    // Forward WebSocket messages to TCP
    ws.on('message', function incoming(data) {
        try {
            if (tcpSocket.writable) {
                tcpSocket.write(data);
                console.log(`📤 WS→TCP #${connectionId}: ${data.length} bytes`);
            } else {
                console.log(`⚠️ TCP socket #${connectionId} not writable, dropping message`);
            }
        } catch (error) {
            console.error(`❌ Error forwarding WS→TCP #${connectionId}:`, error.message);
        }
    });
    
    // Forward TCP messages to WebSocket
    tcpSocket.on('data', function(data) {
        try {
            if (ws.readyState === WebSocket.OPEN) {
                ws.send(data);
                console.log(`📥 TCP→WS #${connectionId}: ${data.length} bytes`);
            } else {
                console.log(`⚠️ WebSocket #${connectionId} not open, dropping message`);
            }
        } catch (error) {
            console.error(`❌ Error forwarding TCP→WS #${connectionId}:`, error.message);
        }
    });
    
    // Handle WebSocket close
    ws.on('close', function() {
        console.log(`🔌 WebSocket connection #${connectionId} closed`);
        if (tcpSocket && !tcpSocket.destroyed) {
            tcpSocket.destroy();
        }
        connections.delete(connectionId);
    });
    
    // Handle WebSocket error
    ws.on('error', function(error) {
        console.error(`❌ WebSocket error #${connectionId}:`, error.message);
        if (tcpSocket && !tcpSocket.destroyed) {
            tcpSocket.destroy();
        }
        connections.delete(connectionId);
    });
    
    // Handle TCP close
    tcpSocket.on('close', function() {
        console.log(`🔌 TCP connection #${connectionId} closed`);
        if (ws.readyState === WebSocket.OPEN) {
            ws.close();
        }
        connections.delete(connectionId);
    });
    
    // Handle TCP error
    tcpSocket.on('error', function(error) {
        console.error(`❌ TCP error #${connectionId}:`, error.message);
        if (ws.readyState === WebSocket.OPEN) {
            ws.close();
        }
        connections.delete(connectionId);
    });
    
    // Handle TCP connection error
    tcpSocket.on('connect', function() {
        console.log(`🔗 TCP connection #${connectionId} ready`);
    });
});

// Handle WebSocket server errors
wss.on('error', function(error) {
    console.error('❌ WebSocket server error:', error.message);
});

// Create health check server
const healthServer = http.createServer((req, res) => {
    if (req.url === '/health') {
        const status = {
            status: 'healthy',
            timestamp: new Date().toISOString(),
            active_connections: connections.size,
            total_connections: connectionCount,
            target: `${P2P_HOST}:${P2P_PORT}`,
            websocket_port: WS_PORT
        };
        
        res.writeHead(200, { 'Content-Type': 'application/json' });
        res.end(JSON.stringify(status, null, 2));
    } else {
        res.writeHead(404, { 'Content-Type': 'text/plain' });
        res.end('Not Found');
    }
});

healthServer.listen(HEALTH_CHECK_PORT, () => {
    console.log(`🏥 Health check server listening on port ${HEALTH_CHECK_PORT}`);
});

// Graceful shutdown
process.on('SIGTERM', () => {
    console.log('🛑 Received SIGTERM, shutting down gracefully...');
    
    // Close all connections
    connections.forEach(({ ws, tcpSocket }, id) => {
        console.log(`🔌 Closing connection #${id}`);
        if (ws.readyState === WebSocket.OPEN) {
            ws.close();
        }
        if (tcpSocket && !tcpSocket.destroyed) {
            tcpSocket.destroy();
        }
    });
    
    // Close servers
    wss.close(() => {
        console.log('🔌 WebSocket server closed');
    });
    
    healthServer.close(() => {
        console.log('🔌 Health check server closed');
        process.exit(0);
    });
});

process.on('SIGINT', () => {
    console.log('🛑 Received SIGINT, shutting down gracefully...');
    process.emit('SIGTERM');
});

console.log('🚀 WebSocket-to-P2P Bridge is running');
console.log('🔗 Connect to ws://localhost:8080/p2p for P2P communication');
console.log('🏥 Health check available at http://localhost:8082/health');
