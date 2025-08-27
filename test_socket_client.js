const io = require('socket.io-client');

console.log('🧪 Testing Socket.io connection with unread count notifications...');

const socket = io('http://192.168.2.1:8000', {
    transports: ['websocket', 'polling'],
    forceNew: true,
    timeout: 10000
});

socket.on('connect', () => {
    console.log('✅ Connected to Socket.io with ID:', socket.id);
    
    console.log('📝 Testing signin with user1...');
    socket.emit('signin', 'user_001');
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
        targetId: 'user_002',
        sourceId: 'user_001',
        message: 'Hello from Node.js test client for notification testing!',
        type: 'text'
    };
    
    console.log('📤 Sending test message:', testMessage);
    socket.emit('message', testMessage);
    
    // Test marking chat as read after 3 seconds
    setTimeout(() => {
        console.log('📖 Testing chat marked as read...');
        socket.emit('chatMarkedAsRead', {
            userId: 'user_001',
            otherUserId: 'user_002'
        });
    }, 3000);
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

// NEW: Listen for notification events
socket.on('newMessageNotification', (data) => {
    console.log('🔔 NEW MESSAGE NOTIFICATION:', data);
});

socket.on('unreadCountUpdated', (data) => {
    console.log('📊 UNREAD COUNT UPDATED:', data);
});

// Automatically disconnect after 10 seconds
setTimeout(() => {
    console.log('⏰ Test complete, disconnecting...');
    socket.disconnect();
    process.exit(0);
}, 10000);
