const express = require("express");
const http = require("http");
const socketIo = require("socket.io");
const sqlite3 = require("sqlite3").verbose();
const path = require("path");

const app = express();
const server = http.createServer(app);

// Enable CORS and body parsing
app.use(express.json());
app.use(express.urlencoded({ extended: true }));
app.use(express.static(__dirname)); // Serve static files
app.use((req, res, next) => {
  res.header("Access-Control-Allow-Origin", "*");
  res.header("Access-Control-Allow-Headers", "Origin, X-Requested-With, Content-Type, Accept");
  res.header("Access-Control-Allow-Methods", "GET, POST, PUT, DELETE, OPTIONS");
  next();
});

// Enhanced Socket.io configuration for better connectivity
const io = socketIo(server, {
  cors: {
    origin: "*",
    methods: ["GET", "POST"],
    credentials: true
  },
  transports: ["websocket", "polling"],
  pingTimeout: 60000,
  pingInterval: 25000,
  upgradeTimeout: 30000,
  allowEIO3: true
});

// Initialize SQLite database
const dbPath = path.join(__dirname, "chat_server.db");
const db = new sqlite3.Database(dbPath);

// Create tables if they don't exist
db.serialize(() => {
  // Messages table
  db.run(`
    CREATE TABLE IF NOT EXISTS messages (
      id INTEGER PRIMARY KEY AUTOINCREMENT,
      sourceId TEXT NOT NULL,
      targetId TEXT NOT NULL,
      message TEXT NOT NULL,
      messageType TEXT DEFAULT 'text',
      path TEXT,
      timestamp DATETIME DEFAULT CURRENT_TIMESTAMP,
      isRead INTEGER DEFAULT 0
    )
  `);

  // Users table with Sri Lankan mobile numbers
  db.run(`
    CREATE TABLE IF NOT EXISTS users (
      id TEXT PRIMARY KEY,
      name TEXT NOT NULL,
      mobile TEXT NOT NULL,
      profileImage TEXT,
      socketId TEXT,
      isOnline INTEGER DEFAULT 0,
      lastSeen DATETIME DEFAULT CURRENT_TIMESTAMP
    )
  `);

  // Conversations table to track chat threads
  db.run(`
    CREATE TABLE IF NOT EXISTS conversations (
      id INTEGER PRIMARY KEY AUTOINCREMENT,
      user1Id TEXT NOT NULL,
      user2Id TEXT NOT NULL,
      lastMessage TEXT,
      lastMessageTime DATETIME DEFAULT CURRENT_TIMESTAMP,
      UNIQUE(user1Id, user2Id)
    )
  `);

  // Insert 5 Sri Lankan users with mobile numbers
  const sriLankanUsers = [
    {
      id: "user_001",
      name: "Kamal Perera",
      mobile: "+94771234567",
      profileImage: ""
    },
    {
      id: "user_002",
      name: "Nimal Silva",
      mobile: "+94701234567",
      profileImage: ""
    },
    {
      id: "user_003",
      name: "Sunil Fernando",
      mobile: "+94711234567",
      profileImage: ""
    },
    {
      id: "user_004",
      name: "Chaminda Jayasinghe",
      mobile: "+94761234567",
      profileImage: ""
    },
    {
      id: "user_005",
      name: "Ruwan Wickramasinghe",
      mobile: "+94781234567",
      profileImage: ""
    }
  ];

  // Clear existing users and insert fresh data
  db.run("DELETE FROM users", (err) => {
    if (err) {
      console.error("Error clearing users:", err);
    } else {
      // Insert users
      const stmt = db.prepare("INSERT OR REPLACE INTO users (id, name, mobile, profileImage) VALUES (?, ?, ?, ?)");
      
      sriLankanUsers.forEach((user) => {
        stmt.run([user.id, user.name, user.mobile, user.profileImage]);
      });
      
      stmt.finalize((err) => {
        if (err) {
          console.error("Error inserting users:", err);
        } else {
          console.log("🎉 Database initialized with Sri Lankan users!");
        }
      });
    }
  });
});

// Socket.io connection handling with enhanced features
const users = new Map(); // Store userId -> socketId mapping
const userSockets = new Map(); // Store socketId -> userId mapping

io.on("connection", (socket) => {
  console.log("🔌 User connected:", socket.id);

  // Send connection acknowledgment
  socket.emit("connected", { 
    socketId: socket.id, 
    timestamp: new Date().toISOString(),
    message: "Successfully connected to chat server"
  });

  // Enhanced user signin with better validation
  socket.on("signin", (userId) => {
    console.log("👤 User signin attempt:", userId, "Socket:", socket.id);
    
    if (!userId) {
      socket.emit("signinError", { error: "Invalid user ID" });
      return;
    }

    // Store user mapping
    socket.userId = userId;
    users.set(userId, socket.id);
    userSockets.set(socket.id, userId);

    // Update user status in database
    db.run(
      "UPDATE users SET socketId = ?, isOnline = 1, lastSeen = CURRENT_TIMESTAMP WHERE id = ?",
      [socket.id, userId],
      (err) => {
        if (err) {
          console.error("❌ Database error updating user status:", err);
          socket.emit("signinError", { error: "Database error" });
        } else {
          console.log("✅ User signed in successfully:", userId);
          
          // Send signin success confirmation
          socket.emit("signinSuccess", { 
            userId: userId, 
            socketId: socket.id,
            timestamp: new Date().toISOString()
          });
          
          // Notify other users that this user is online
          socket.broadcast.emit("userOnline", { 
            userId: userId, 
            timestamp: new Date().toISOString() 
          });
          
          // Send current online users list
          const onlineUsers = Array.from(users.keys());
          socket.emit("onlineUsers", onlineUsers);
        }
      }
    );
  });

  // Enhanced message handling for real-time delivery
  socket.on("message", (data) => {
    console.log("📨 Message received:", data);

    const { message, sourceId, targetId, messageType = 'text', path } = data;

    // Validate message data
    if (!message || !sourceId || !targetId) {
      console.log("❌ Invalid message data:", data);
      socket.emit("messageError", { error: "Invalid message data" });
      return;
    }

    // Save message to database
    db.run(
      "INSERT INTO messages (sourceId, targetId, message, messageType, path) VALUES (?, ?, ?, ?, ?)",
      [sourceId, targetId, message, messageType, path || ""],
      function (err) {
        if (err) {
          console.error("❌ Database error:", err);
          socket.emit("messageError", { error: "Failed to save message" });
        } else {
          console.log("💾 Message saved to database, ID:", this.lastID);
          
          // Update conversation
          updateConversation(sourceId, targetId, message);
          
          // Prepare message object
          const messageObj = {
            id: this.lastID,
            message: message,
            sourceId: sourceId,
            targetId: targetId,
            messageType: messageType,
            path: path || "",
            timestamp: Date.now(),
            isRead: 0,
            isDelivered: false
          };

          // Send confirmation to sender immediately
          socket.emit("messageSent", {
            ...messageObj,
            status: "sent",
            sentAt: new Date().toISOString()
          });
          console.log("✅ Message sent confirmation to sender:", sourceId);

          // Find target user and deliver message in real-time
          const targetSocketId = users.get(targetId);

          if (targetSocketId && targetSocketId !== socket.id) {
            // Send message to target user in real-time
            io.to(targetSocketId).emit("messageReceived", {
              ...messageObj,
              status: "received",
              receivedAt: new Date().toISOString()
            });
            console.log("✅ Real-time message delivered to:", targetId);
            
            // Send delivery confirmation back to sender
            socket.emit("messageDelivered", {
              messageId: this.lastID,
              targetId: targetId,
              deliveredAt: new Date().toISOString(),
              status: "delivered"
            });
            
          } else {
            console.log("❌ Target user not online:", targetId);
            // Send offline notification to sender
            socket.emit("messagePending", {
              messageId: this.lastID,
              targetId: targetId,
              status: "pending",
              reason: "User offline"
            });
          }
        }
      }
    );
  });

  // Handle message read status
  socket.on("markAsRead", (data) => {
    console.log("📖 Mark as read:", data);
    const { messageId, userId } = data;
    
    db.run(
      "UPDATE messages SET isRead = 1 WHERE id = ? AND targetId = ?",
      [messageId, userId],
      (err) => {
        if (!err) {
          socket.emit("messageRead", { messageId });
          // Notify sender that message was read
          const senderSocketId = users.get(data.senderId);
          if (senderSocketId) {
            io.to(senderSocketId).emit("messageRead", { messageId, readBy: userId });
          }
        }
      }
    );
  });

  // Handle typing indicator
  socket.on("typing", (data) => {
    console.log("⌨️ Typing indicator:", data);
    const { targetId, isTyping, sourceId } = data;
    const targetSocketId = users.get(targetId);
    
    if (targetSocketId) {
      io.to(targetSocketId).emit("typing", {
        userId: sourceId || socket.userId,
        isTyping: isTyping,
        timestamp: new Date().toISOString()
      });
    }
  });

  // Handle user activity (online status)
  socket.on("activity", (data) => {
    const { targetId } = data;
    const targetSocketId = users.get(targetId);
    
    if (targetSocketId) {
      io.to(targetSocketId).emit("activity", {
        userId: socket.userId,
        lastSeen: new Date().toISOString()
      });
    }
  });

  // Handle heartbeat to maintain connection
  socket.on("heartbeat", () => {
    socket.emit("heartbeat", { timestamp: new Date().toISOString() });
  });

  // Handle user disconnect
  socket.on("disconnect", () => {
    console.log("🔌 User disconnected:", socket.id);
    
    const userId = userSockets.get(socket.id);
    if (userId) {
      // Update user status to offline
      db.run(
        "UPDATE users SET isOnline = 0, lastSeen = CURRENT_TIMESTAMP WHERE id = ?",
        [userId],
        (err) => {
          if (!err) {
            console.log("👤 User marked offline:", userId);
            // Notify other users
            socket.broadcast.emit("userOffline", { 
              userId: userId, 
              timestamp: new Date().toISOString() 
            });
          }
        }
      );

      // Remove from active users
      users.delete(userId);
      userSockets.delete(socket.id);
      console.log("👤 User removed from active users:", userId);
    }
  });
});

// Helper function to update conversations
function updateConversation(user1Id, user2Id, message) {
  const sortedUsers = [user1Id, user2Id].sort();
  
  db.run(
    `INSERT OR REPLACE INTO conversations (user1Id, user2Id, lastMessage, lastMessageTime) 
     VALUES (?, ?, ?, CURRENT_TIMESTAMP)`,
    [sortedUsers[0], sortedUsers[1], message],
    (err) => {
      if (err) {
        console.error("❌ Error updating conversation:", err);
      }
    }
  );
}

// REST API Routes
app.use((req, res, next) => {
  console.log(`📡 ${req.method} ${req.path} from ${req.ip}`);
  next();
});

// Get all users
app.get("/api/users", (req, res) => {
  db.all("SELECT * FROM users ORDER BY name", (err, rows) => {
    if (err) {
      res.status(500).json({ error: err.message });
    } else {
      res.json(rows);
    }
  });
});

// Get messages between two users
app.get("/api/messages/:userId/:targetId", (req, res) => {
  const { userId, targetId } = req.params;
  
  db.all(
    `SELECT * FROM messages 
     WHERE (sourceId = ? AND targetId = ?) OR (sourceId = ? AND targetId = ?)
     ORDER BY timestamp ASC`,
    [userId, targetId, targetId, userId],
    (err, rows) => {
      if (err) {
        res.status(500).json({ error: err.message });
      } else {
        res.json(rows);
      }
    }
  );
});

// Get conversations for a user
app.get("/api/conversations/:userId", (req, res) => {
  const { userId } = req.params;
  
  db.all(
    `SELECT 
       CASE 
         WHEN c.user1Id = ? THEN c.user2Id 
         ELSE c.user1Id 
       END as otherUserId,
       u.name as otherUserName,
       u.mobile as otherUserMobile,
       u.isOnline,
       u.lastSeen,
       c.lastMessage,
       c.lastMessageTime
     FROM conversations c
     JOIN users u ON (
       CASE 
         WHEN c.user1Id = ? THEN c.user2Id = u.id
         ELSE c.user1Id = u.id
       END
     )
     WHERE c.user1Id = ? OR c.user2Id = ?
     ORDER BY c.lastMessageTime DESC`,
    [userId, userId, userId, userId],
    (err, rows) => {
      if (err) {
        res.status(500).json({ error: err.message });
      } else {
        res.json(rows);
      }
    }
  );
});

// Get network interface IPs
function getLocalIPs() {
  const { networkInterfaces } = require('os');
  const nets = networkInterfaces();
  const ips = [];

  for (const name of Object.keys(nets)) {
    for (const net of nets[name]) {
      if (net.family === 'IPv4' && !net.internal) {
        ips.push(net.address);
      }
    }
  }
  return ips;
}

// Start server
const PORT = process.env.PORT || 8000;
server.listen(PORT, "0.0.0.0", () => {
  const localIPs = getLocalIPs();
  
  console.log("🚀 Chat server running on port", PORT);
  console.log("📱 Connection URLs:");
  console.log("   Android Emulator: http://10.0.2.2:" + PORT);
  console.log("   iOS Simulator: http://localhost:" + PORT);
  
  localIPs.forEach(ip => {
    console.log(`   Physical Device: http://${ip}:${PORT}`);
  });
  
  console.log("💾 Database:", dbPath);
});

// Graceful shutdown
process.on('SIGINT', () => {
  console.log('\n🛑 Shutting down server...');
  db.close((err) => {
    if (err) {
      console.error(err.message);
    } else {
      console.log('💾 Database connection closed.');
    }
    process.exit(0);
  });
});
