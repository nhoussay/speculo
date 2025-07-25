#!/usr/bin/env python3
"""
WebSocket-to-TCP Bridge for Tendermint P2P over HTTPS
Allows P2P connections to work through Cloud Run's HTTPS-only environment
"""

import asyncio
import websockets
import socket
import logging
import json
import signal
import sys
from typing import Optional, Tuple, Set
from websockets.server import WebSocketServerProtocol

# Configuration
WS_HOST = "0.0.0.0"
WS_PORT = 8081
TARGET_HOST = "localhost"
TARGET_PORT = 26656  # Tendermint P2P port
BUFFER_SIZE = 4096
CONNECTION_TIMEOUT = 30

# Logging setup
logging.basicConfig(
    level=logging.INFO,
    format='%(asctime)s - %(name)s - %(levelname)s - %(message)s'
)
logger = logging.getLogger(__name__)

class P2PWebSocketBridge:
    def __init__(self):
        self.active_connections: Set[str] = set()
        self.server: Optional[websockets.WebSocketServer] = None
        self.running = False
        
    async def handle_websocket_connection(self, websocket: WebSocketServerProtocol, path: str):
        """Handle incoming WebSocket connection and bridge to TCP"""
        client_id = f"{websocket.remote_address[0]}:{websocket.remote_address[1]}"
        logger.info(f"New WebSocket connection from {client_id} (path: {path})")
        
        # Add to active connections
        self.active_connections.add(client_id)
        
        tcp_socket = None
        try:
            # Create TCP connection to local Tendermint P2P port
            tcp_socket = socket.socket(socket.AF_INET, socket.SOCK_STREAM)
            tcp_socket.settimeout(CONNECTION_TIMEOUT)
            tcp_socket.connect((TARGET_HOST, TARGET_PORT))
            logger.info(f"TCP connection established for {client_id}")
            
            # Start bidirectional data forwarding
            await asyncio.gather(
                self.forward_websocket_to_tcp(websocket, tcp_socket, client_id),
                self.forward_tcp_to_websocket(tcp_socket, websocket, client_id),
                return_exceptions=True
            )
            
        except socket.error as e:
            logger.error(f"TCP connection failed for {client_id}: {e}")
            await self.send_error_message(websocket, f"TCP connection failed: {e}")
        except Exception as e:
            logger.error(f"Unexpected error for {client_id}: {e}")
        finally:
            # Cleanup resources
            if tcp_socket:
                try:
                    tcp_socket.close()
                except:
                    pass
            
            self.active_connections.discard(client_id)
            logger.info(f"Connection {client_id} closed")
    
    async def forward_websocket_to_tcp(self, websocket: WebSocketServerProtocol, 
                                      tcp_socket: socket.socket, client_id: str):
        """Forward data from WebSocket to TCP socket"""
        try:
            async for message in websocket:
                if isinstance(message, bytes):
                    # Binary data - forward directly
                    tcp_socket.send(message)
                    logger.debug(f"WS->TCP {client_id}: {len(message)} bytes")
                elif isinstance(message, str):
                    # Text data - decode as hex or base64 if needed
                    try:
                        # Try to decode as JSON first
                        data = json.loads(message)
                        if 'data' in data:
                            # Extract binary data from JSON
                            import base64
                            binary_data = base64.b64decode(data['data'])
                            tcp_socket.send(binary_data)
                            logger.debug(f"WS->TCP {client_id}: {len(binary_data)} bytes (from JSON)")
                    except (json.JSONDecodeError, ValueError):
                        # Fallback: send as UTF-8
                        tcp_socket.send(message.encode('utf-8'))
                        logger.debug(f"WS->TCP {client_id}: {len(message)} chars")
                        
        except websockets.exceptions.ConnectionClosed:
            logger.info(f"WebSocket connection closed for {client_id}")
        except socket.error as e:
            logger.error(f"TCP send error for {client_id}: {e}")
        except Exception as e:
            logger.error(f"WS->TCP forwarding error for {client_id}: {e}")
    
    async def forward_tcp_to_websocket(self, tcp_socket: socket.socket,
                                      websocket: WebSocketServerProtocol, client_id: str):
        """Forward data from TCP socket to WebSocket"""
        loop = asyncio.get_event_loop()
        
        try:
            while True:
                # Read from TCP socket in a non-blocking way
                data = await loop.run_in_executor(
                    None, 
                    lambda: tcp_socket.recv(BUFFER_SIZE)
                )
                
                if not data:
                    logger.info(f"TCP connection closed for {client_id}")
                    break
                
                # Send binary data to WebSocket
                await websocket.send(data)
                logger.debug(f"TCP->WS {client_id}: {len(data)} bytes")
                
        except socket.error as e:
            logger.error(f"TCP receive error for {client_id}: {e}")
        except websockets.exceptions.ConnectionClosed:
            logger.info(f"WebSocket connection closed for {client_id}")
        except Exception as e:
            logger.error(f"TCP->WS forwarding error for {client_id}: {e}")
    
    async def send_error_message(self, websocket: WebSocketServerProtocol, error_msg: str):
        """Send error message to WebSocket client"""
        try:
            error_response = {
                "error": error_msg,
                "timestamp": asyncio.get_event_loop().time()
            }
            await websocket.send(json.dumps(error_response))
        except:
            pass  # Ignore errors when sending error messages
    
    async def start_server(self):
        """Start the WebSocket server"""
        logger.info(f"Starting WebSocket-to-TCP bridge on {WS_HOST}:{WS_PORT}")
        logger.info(f"Target TCP server: {TARGET_HOST}:{TARGET_PORT}")
        
        self.running = True
        self.server = await websockets.serve(
            self.handle_websocket_connection,
            WS_HOST,
            WS_PORT,
            # WebSocket server options
            max_size=1024*1024,  # 1MB max message size
            ping_interval=20,     # Ping every 20 seconds
            ping_timeout=10,      # Wait 10 seconds for pong
            close_timeout=10      # Wait 10 seconds for close
        )
        
        logger.info("WebSocket-to-TCP bridge started successfully")
        logger.info(f"Active connections: {len(self.active_connections)}")
        
        # Keep server running
        await self.server.wait_closed()
    
    async def stop_server(self):
        """Stop the WebSocket server"""
        logger.info("Stopping WebSocket-to-TCP bridge...")
        self.running = False
        
        if self.server:
            self.server.close()
            await self.server.wait_closed()
        
        logger.info("WebSocket-to-TCP bridge stopped")
    
    def get_status(self) -> dict:
        """Get current status of the bridge"""

async def main():
    """Main function to run the WebSocket-to-TCP bridge"""
    bridge = P2PWebSocketBridge()
    
    # Setup signal handlers for graceful shutdown
    def signal_handler(signum, frame):
        logger.info(f"Received signal {signum}, shutting down gracefully...")
        asyncio.create_task(bridge.stop_server())
        sys.exit(0)
    
    signal.signal(signal.SIGINT, signal_handler)
    signal.signal(signal.SIGTERM, signal_handler)
    
    try:
        # Check if target TCP server is available
        test_socket = socket.socket(socket.AF_INET, socket.SOCK_STREAM)
        test_socket.settimeout(5)
        result = test_socket.connect_ex((TARGET_HOST, TARGET_PORT))
        test_socket.close()
        
        if result != 0:
            logger.warning(f"Target TCP server {TARGET_HOST}:{TARGET_PORT} not available")
            logger.warning("Make sure Tendermint node is running before starting the bridge")
        else:
            logger.info(f"Target TCP server {TARGET_HOST}:{TARGET_PORT} is available")
        
        # Start the bridge server
        await bridge.start_server()
        
    except KeyboardInterrupt:
        logger.info("Received keyboard interrupt")
    except Exception as e:
        logger.error(f"Bridge error: {e}")
        raise
    finally:
        await bridge.stop_server()

if __name__ == "__main__":
    try:
        asyncio.run(main())
    except KeyboardInterrupt:
        logger.info("Bridge stopped by user")
    except Exception as e:
        logger.error(f"Fatal error: {e}")
        sys.exit(1)
            if client_id in self.active_connections:
                try:
                    tcp_socket.close()
                except:
                    pass
                del self.active_connections[client_id]
            logger.info(f"Closed connection {client_id}")
    
    async def forward_ws_to_tcp(self, websocket, tcp_socket, client_id):
        """Forward WebSocket messages to TCP socket"""
        try:
            async for message in websocket:
                if isinstance(message, bytes):
                    tcp_socket.send(message)
                else:
                    # Handle text messages (convert to bytes)
                    tcp_socket.send(message.encode('utf-8'))
        except websockets.exceptions.ConnectionClosed:
            logger.info(f"WebSocket connection closed for {client_id}")
        except Exception as e:
            logger.error(f"Error forwarding WS->TCP for {client_id}: {e}")
    
    async def forward_tcp_to_ws(self, tcp_socket, websocket, client_id):
        """Forward TCP socket data to WebSocket"""
        loop = asyncio.get_event_loop()
        
        def read_from_tcp():
            try:
                while True:
                    data = tcp_socket.recv(4096)
                    if not data:
                        break
                    return data
            except Exception as e:
                logger.error(f"Error reading from TCP for {client_id}: {e}")
                return None
        
        try:
            with ThreadPoolExecutor() as executor:
                while True:
                    # Read from TCP socket in thread to avoid blocking
                    data = await loop.run_in_executor(executor, read_from_tcp)
                    if not data:
                        break
                    
                    # Send to WebSocket
                    await websocket.send(data)
                    
        except websockets.exceptions.ConnectionClosed:
            logger.info(f"WebSocket connection closed for {client_id}")
        except Exception as e:
            logger.error(f"Error forwarding TCP->WS for {client_id}: {e}")
    
    async def start_server(self):
        """Start the WebSocket server"""
        logger.info(f"Starting WebSocket-to-TCP bridge on port {self.ws_port}")
        logger.info(f"Bridging to TCP {self.tcp_host}:{self.tcp_port}")
        
        async with websockets.serve(
            self.handle_websocket, 
            "0.0.0.0", 
            self.ws_port,
            ping_interval=20,
            ping_timeout=60,
            max_size=1024*1024,  # 1MB max message size
            compression=None     # Disable compression for better performance
        ):
            logger.info("WebSocket bridge server started")
            await asyncio.Future()  # Run forever

if __name__ == "__main__":
    bridge = WebSocketTCPBridge()
    asyncio.run(bridge.start_server())
