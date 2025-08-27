const io = require('socket.io-client');

console.log('🧪 Testing real-time message sending between users...');

// Connect as user1
const socket1 = io('http://192.168.2.1:8000', {
    transports: ['websocket', 'polling'],
    forceNew: true
});

socket1.on('connect', () => {
    console.log('✅ User1 connected with ID:', socket1.id);
    
    // Sign in as user1
    socket1.emit('signin', 'user1');
});

socket1.on('signinSuccess', (data) => {
    console.log('✅ User1 signed in successfully:', data);
    
    // Send a test message from user1 to user2
    const testMessage = {
        targetId: 'user2',
        sourceId: 'user1', 
        message: 'Hello from automated test! This should appear in chat list.',
        messageType: 'text'
    };
    
    console.log('📤 User1 sending message to user2...');
    socket1.emit('message', testMessage);
});

socket1.on('messageSent', (data) => {
    console.log('✅ Message sent confirmation:', data);
    console.log('📱 Check Flutter app chat list - this message should appear!');
    
    // Disconnect after 5 seconds
    setTimeout(() => {
        socket1.disconnect();
        console.log('✅ Test completed - disconnected');
        process.exit(0);
    }, 5000);
});

socket1.on('connect_error', (error) => {
    console.log('❌ Connection Error:', error.message);
});

socket1.on('disconnect', (reason) => {
    console.log('🔌 Disconnected:', reason);
});
