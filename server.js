const express = require("express");
const http = require("http");
const socketIo = require("socket.io");

const app = express();
const server = http.createServer(app);
const io = socketIo(server, {
  cors: {
    origin: "*",
    methods: ["GET", "POST"],
  },
});

const users = new Map();
const rooms = new Map();

// Initialize public rooms
const publicRooms = [
  { id: "general_chat", name: "General Chat", users: new Set() },
  { id: "tech_talk", name: "Tech Talk", users: new Set() },
  { id: "random_chat", name: "Random Chat", users: new Set() },
  { id: "help_support", name: "Help & Support", users: new Set() },
];

publicRooms.forEach((room) => {
  rooms.set(room.id, room);
});

io.on("connection", (socket) => {
  console.log("🔌 User connected:", socket.id);

  // Handle user signin
  socket.on("signin", (userId) => {
    console.log("👤 User signed in:", userId, "Socket:", socket.id);
    console.log("📊 Users before signin:", Array.from(users.entries()));

    users.set(userId, socket.id);
    socket.userId = userId;

    console.log("📊 Users after signin:", Array.from(users.entries()));
    console.log("✅ User registration complete");

    // Send updated user list to all clients
    io.emit("users_update", Array.from(users.keys()));
    console.log("📢 User list broadcasted to all clients");
  });

  // Handle joining rooms
  socket.on("join_room", (roomId) => {
    if (rooms.has(roomId)) {
      socket.join(roomId);
      rooms.get(roomId).users.add(socket.userId);
      console.log(`👥 User ${socket.userId} joined room ${roomId}`);

      // Notify room members
      socket.to(roomId).emit("user_joined_room", {
        userId: socket.userId,
        roomId: roomId,
        message: `User ${socket.userId} joined the room`,
      });
    }
  });

  // Handle leaving rooms
  socket.on("leave_room", (roomId) => {
    if (rooms.has(roomId)) {
      socket.leave(roomId);
      rooms.get(roomId).users.delete(socket.userId);
      console.log(`👥 User ${socket.userId} left room ${roomId}`);

      // Notify room members
      socket.to(roomId).emit("user_left_room", {
        userId: socket.userId,
        roomId: roomId,
        message: `User ${socket.userId} left the room`,
      });
    }
  });

  // Handle incoming messages
  socket.on("message", (data) => {
    console.log("📨 Message received from client:", JSON.stringify(data));
    console.log("📊 Current users map:", Array.from(users.entries()));

    const { message, sourceId, targetId, path, isRoom } = data;

    if (isRoom) {
      // Handle room messages
      if (rooms.has(targetId)) {
        socket.to(targetId).emit("message", {
          message: message,
          sourceId: sourceId,
          targetId: targetId,
          path: path || "",
          timestamp: new Date().toISOString(),
          isRoom: true,
        });
        console.log("✅ Room message sent to:", targetId);
      } else {
        console.log("❌ Room not found:", targetId);
      }
    } else {
      // Handle direct messages
      console.log(`🔍 Looking for target user: ${targetId}`);
      const targetSocketId = users.get(targetId);
      console.log(`🎯 Target socket ID: ${targetSocketId}`);

      if (targetSocketId) {
        // Send message to target user
        const messagePayload = {
          message: message,
          sourceId: sourceId,
          targetId: targetId,
          path: path || "",
          timestamp: new Date().toISOString(),
          isRoom: false,
        };

        console.log(
          "📤 Sending message payload:",
          JSON.stringify(messagePayload)
        );
        io.to(targetSocketId).emit("message", messagePayload);
        console.log(
          "✅ Direct message sent to:",
          targetId,
          "via socket:",
          targetSocketId
        );
      } else {
        console.log("❌ Target user not found in users map:", targetId);
        console.log("📋 Available users:", Array.from(users.keys()));
      }
    }
  });

  // Handle user status updates
  socket.on("user_status", (status) => {
    if (socket.userId) {
      // Broadcast status to all connected users
      socket.broadcast.emit("user_status_update", {
        userId: socket.userId,
        status: status, // 'online', 'away', 'busy', 'offline'
        timestamp: new Date().toISOString(),
      });
    }
  });

  // Handle typing indicators
  socket.on("typing", (data) => {
    const { targetId, isTyping, isRoom } = data;

    if (isRoom) {
      socket.to(targetId).emit("typing_update", {
        userId: socket.userId,
        isTyping: isTyping,
        roomId: targetId,
      });
    } else {
      const targetSocketId = users.get(targetId);
      if (targetSocketId) {
        io.to(targetSocketId).emit("typing_update", {
          userId: socket.userId,
          isTyping: isTyping,
        });
      }
    }
  });

  // Handle disconnection
  socket.on("disconnect", () => {
    console.log("🔌 User disconnected:", socket.id);
    if (socket.userId) {
      users.delete(socket.userId);

      // Remove user from all rooms
      rooms.forEach((room, roomId) => {
        if (room.users.has(socket.userId)) {
          room.users.delete(socket.userId);
          socket.to(roomId).emit("user_left_room", {
            userId: socket.userId,
            roomId: roomId,
            message: `User ${socket.userId} disconnected`,
          });
        }
      });

      // Notify all users that this user went offline
      socket.broadcast.emit("user_status_update", {
        userId: socket.userId,
        status: "offline",
        timestamp: new Date().toISOString(),
      });

      // Send updated user list to all clients
      io.emit("users_update", Array.from(users.keys()));

      console.log("👤 User removed from active users:", socket.userId);
    }
  });

  // Send available rooms to new user
  socket.emit(
    "rooms_list",
    Array.from(rooms.values()).map((room) => ({
      id: room.id,
      name: room.name,
      userCount: room.users.size,
    }))
  );
});

const PORT = process.env.PORT || 8000;
server.listen(PORT, "0.0.0.0", () => {
  console.log("🚀 Chat server running on port", PORT);
  console.log(`📡 Server started at: ${new Date().toLocaleString()}`);
  console.log(`🌐 Server accessible at:`);
  console.log(`   📱 Android Emulator: http://10.0.2.2:${PORT}`);
  console.log(`   📲 Physical Device: http://192.168.8.123:${PORT}`);
  console.log(`   📲 Physical Device (Alt): http://192.168.56.1:${PORT}`);
  console.log(`   💻 Local Desktop: http://localhost:${PORT}`);
  console.log(`   💻 Local Desktop (Alt): http://127.0.0.1:${PORT}`);
  console.log(`📊 Connected users: ${users.size}`);
  console.log(`🏠 Active rooms: ${rooms.size}`);
  console.log(`⚡ Ready for connections!`);
});

// Add basic HTTP endpoint for testing
app.get("/", (req, res) => {
  res.send(`
    <h1>Socket.IO Chat Server</h1>
    <p>Server is running on port ${PORT}</p>
    <p>Time: ${new Date().toLocaleString()}</p>
    <p>Connected users: ${users.size}</p>
    <p>Active rooms: ${rooms.size}</p>
    <script src="/socket.io/socket.io.js"></script>
    <script>
      const socket = io();
      socket.on('connect', () => {
        console.log('Connected to server:', socket.id);
        document.body.innerHTML += '<p style="color: green;">Socket.IO Connected: ' + socket.id + '</p>';
      });
    </script>
  `);
});
