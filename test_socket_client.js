const io = require('socket.io-client');

console.log('🧪 Testing Socket.io connection...');


const socket = io('http://192.168.2.1:8000', {
    transports: ['websocket', 'polling'],
    forceNew: true,
    timeout: 10000
});

socket.on('connect', () => {
    console.log('✅ Connected to Socket.io with ID:', socket.id);
    
    
    console.log('📝 Testing signin with user1...');
    socket.emit('signin', 'user1');
});

socket.on('connect_error', (error) => {
    console.log('❌ Connection Error:', error.message);
});

socket.on('disconnect', (reason) => {
    console.log('🔌 Disconnected:', reason);
});

socket.on('connected', (data) => {
    console.log('🎉 Connection acknowledged:', data);
});

socket.on('signinSuccess', (data) => {
    console.log('✅ Signin successful:', data);
    
    
    const testMessage = {
        targetId: 'user2',
        sourceId: 'user1',
        message: 'Hello from Node.js test client!',
        type: 'text'
    };
    
    console.log('📤 Sending test message:', testMessage);
    socket.emit('message', testMessage);
});

socket.on('signinError', (data) => {
    console.log('❌ Signin error:', data);
});

socket.on('messageReceived', (msg) => {
    console.log('📨 Message received:', msg);
});

socket.on('messageSent', (data) => {
    console.log('✅ Message sent confirmation:', data);
});

socket.on('onlineUsers', (data) => {
    console.log('👥 Online users:', data);
});

// Automatically disconnect after 10 seconds
setTimeout(() => {
    console.log('⏰ Test complete, disconnecting...');
    socket.disconnect();
    process.exit(0);
}, 10000);
