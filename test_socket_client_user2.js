const io = require('socket.io-client');

console.log('🧪 Testing Socket.io connection as user_002 (target user)...');

const socket = io('http://192.168.2.1:8000', {
    transports: ['websocket', 'polling'],
    forceNew: true,
    timeout: 10000
});

socket.on('connect', () => {
    console.log('✅ Connected to Socket.io with ID:', socket.id);
    
    console.log('📝 Testing signin with user_002...');
    socket.emit('signin', 'user_002');
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
    console.log('👂 Listening for incoming messages and notifications...');
});

socket.on('signinError', (data) => {
    console.log('❌ Signin error:', data);
});

socket.on('messageReceived', (msg) => {
    console.log('📨 INCOMING MESSAGE:', msg);
});

socket.on('messageSent', (data) => {
    console.log('✅ Message sent confirmation:', data);
});

socket.on('onlineUsers', (data) => {
    console.log('👥 Online users:', data);
});

// Listen for notification events
socket.on('newMessageNotification', (data) => {
    console.log('🔔 NEW MESSAGE NOTIFICATION (should trigger unread count update):', data);
});

socket.on('unreadCountUpdated', (data) => {
    console.log('📊 UNREAD COUNT UPDATED:', data);
});

// Stay connected for 30 seconds to listen for incoming messages
setTimeout(() => {
    console.log('⏰ Test complete, disconnecting...');
    socket.disconnect();
    process.exit(0);
}, 30000);
