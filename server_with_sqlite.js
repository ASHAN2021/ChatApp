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

const io = socketIo(server, {
  cors: {
    origin: "*",
    methods: ["GET", "POST"],
    credentials: true
  },
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
      profileImage: "" // Using local avatars instead
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

  // Insert users if they don't exist
  sriLankanUsers.forEach(user => {
    db.run(`
      INSERT OR IGNORE INTO users (id, name, mobile, profileImage, isOnline, lastSeen) 
      VALUES (?, ?, ?, ?, 0, CURRENT_TIMESTAMP)
    `, [user.id, user.name, user.mobile, user.profileImage]);
  });

  console.log("🎉 Database initialized with Sri Lankan users!");
});

// Store connected users
const users = new Map();

// Add connection logging middleware
app.use((req, res, next) => {
  console.log(`📡 ${req.method} ${req.url} from ${req.ip}`);
  next();
});

io.on("connection", (socket) => {
  console.log("🔌 User connected:", socket.id);

  // Handle user signin
  socket.on("signin", (userId) => {
    console.log("👤 User signed in:", userId, "Socket:", socket.id);
    users.set(userId, socket.id);
    socket.userId = userId;

    // Update user in database
    db.run(
      "UPDATE users SET socketId = ?, isOnline = 1, lastSeen = CURRENT_TIMESTAMP WHERE id = ?",
      [socket.id, userId],
      (err) => {
        if (err) {
          console.error("❌ Error updating user status:", err);
        } else {
          console.log("✅ User status updated:", userId);
          // Notify other users that this user is online
          socket.broadcast.emit("userOnline", userId);
        }
      }
    );
  });

  // Handle incoming messages
  socket.on("message", (data) => {
    console.log("📨 Message received:", data);

    const { message, sourceId, targetId, messageType = 'text', path } = data;

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
          
          // Update or create conversation
          updateConversation(sourceId, targetId, message);
          
          // Prepare message object with database ID
          const messageObj = {
            id: this.lastID,
            message: message,
            sourceId: sourceId,
            targetId: targetId,
            messageType: messageType,
            path: path || "",
            timestamp: new Date().toISOString(),
            isRead: 0
          };

          // Send confirmation to sender immediately
          socket.emit("messageSent", messageObj);
          console.log("✅ Sent confirmation to sender:", sourceId);

          // Find target user's socket and send message
          const targetSocketId = users.get(targetId);

          if (targetSocketId) {
            // Send message to target user in real-time
            io.to(targetSocketId).emit("message", messageObj);
            console.log("✅ Real-time message sent to:", targetId);
            
            // Also send delivery confirmation back to sender
            socket.emit("messageDelivered", {
              messageId: this.lastID,
              targetId: targetId,
              deliveredAt: new Date().toISOString()
            });
          } else {
            console.log("❌ Target user not online:", targetId);
            // Send offline notification to sender
            socket.emit("messagePending", {
              messageId: this.lastID,
              targetId: targetId,
              status: "offline"
            });
          }
        }
      }
    );
  });

  // Handle message read status
  socket.on("markAsRead", (data) => {
    const { messageId, userId } = data;
    db.run(
      "UPDATE messages SET isRead = 1 WHERE id = ? AND targetId = ?",
      [messageId, userId],
      (err) => {
        if (!err) {
          socket.emit("messageRead", { messageId });
        }
      }
    );
  });

  // Handle typing indicator
  socket.on("typing", (data) => {
    const { targetId, isTyping } = data;
    const targetSocketId = users.get(targetId);
    if (targetSocketId) {
      io.to(targetSocketId).emit("typing", {
        userId: socket.userId,
        isTyping: isTyping
      });
    }
  });

  // Handle real-time activity updates
  socket.on("activity", (data) => {
    const { targetId } = data;
    const targetSocketId = users.get(targetId);
    if (targetSocketId) {
      io.to(targetSocketId).emit("userActivity", {
        userId: socket.userId,
        activity: "active",
        timestamp: new Date().toISOString()
      });
    }
  });

  // Send periodic heartbeat to maintain connection
  const heartbeat = setInterval(() => {
    if (socket.connected && socket.userId) {
      socket.emit("heartbeat", {
        userId: socket.userId,
        timestamp: new Date().toISOString()
      });
    }
  }, 30000); // Every 30 seconds

  // Handle disconnection
  socket.on("disconnect", () => {
    console.log("🔌 User disconnected:", socket.id);
    if (socket.userId) {
      users.delete(socket.userId);

      // Update user last seen in database
      db.run(
        "UPDATE users SET socketId = NULL, isOnline = 0, lastSeen = CURRENT_TIMESTAMP WHERE id = ?",
        [socket.userId],
        (err) => {
          if (!err) {
            // Notify other users that this user is offline
            socket.broadcast.emit("userOffline", socket.userId);
          }
        }
      );

      console.log("👤 User removed from active users:", socket.userId);
    }

    clearInterval(heartbeat);
  });
});

// Helper function to update conversation
function updateConversation(user1Id, user2Id, lastMessage) {
  // Ensure consistent ordering for conversation participants
  const [smallerId, largerId] = user1Id < user2Id ? [user1Id, user2Id] : [user2Id, user1Id];
  
  db.run(
    `INSERT OR REPLACE INTO conversations (user1Id, user2Id, lastMessage, lastMessageTime)
     VALUES (?, ?, ?, CURRENT_TIMESTAMP)`,
    [smallerId, largerId, lastMessage]
  );
}

// API endpoint to get all users
app.get("/api/users", (req, res) => {
  db.all(
    "SELECT id, name, mobile, profileImage, isOnline, lastSeen FROM users ORDER BY name ASC",
    [],
    (err, rows) => {
      if (err) {
        res.status(500).json({ error: err.message });
      } else {
        res.json(rows);
      }
    }
  );
});

// API endpoint to get user by ID
app.get("/api/users/:userId", (req, res) => {
  const { userId } = req.params;
  db.get(
    "SELECT id, name, mobile, profileImage, isOnline, lastSeen FROM users WHERE id = ?",
    [userId],
    (err, row) => {
      if (err) {
        res.status(500).json({ error: err.message });
      } else if (!row) {
        res.status(404).json({ error: "User not found" });
      } else {
        res.json(row);
      }
    }
  );
});

// API endpoint to get message history between two users
app.get("/api/messages/:userId1/:userId2", (req, res) => {
  const { userId1, userId2 } = req.params;
  const limit = req.query.limit || 100;
  const offset = req.query.offset || 0;

  db.all(
    `SELECT * FROM messages 
     WHERE (sourceId = ? AND targetId = ?) OR (sourceId = ? AND targetId = ?)
     ORDER BY timestamp ASC
     LIMIT ? OFFSET ?`,
    [userId1, userId2, userId2, userId1, limit, offset],
    (err, rows) => {
      if (err) {
        res.status(500).json({ error: err.message });
      } else {
        res.json(rows);
      }
    }
  );
});

// API endpoint to get user's conversations
app.get("/api/conversations/:userId", (req, res) => {
  const { userId } = req.params;

  db.all(
    `SELECT 
      c.id,
      c.lastMessage,
      c.lastMessageTime,
      CASE 
        WHEN c.user1Id = ? THEN u2.id
        ELSE u1.id
      END as otherUserId,
      CASE 
        WHEN c.user1Id = ? THEN u2.name
        ELSE u1.name
      END as otherUserName,
      CASE 
        WHEN c.user1Id = ? THEN u2.mobile
        ELSE u1.mobile
      END as otherUserMobile,
      CASE 
        WHEN c.user1Id = ? THEN u2.profileImage
        ELSE u1.profileImage
      END as otherUserProfileImage,
      CASE 
        WHEN c.user1Id = ? THEN u2.isOnline
        ELSE u1.isOnline
      END as otherUserIsOnline,
      (SELECT COUNT(*) FROM messages 
       WHERE targetId = ? AND sourceId = (
         CASE WHEN c.user1Id = ? THEN c.user2Id ELSE c.user1Id END
       ) AND isRead = 0) as unreadCount
    FROM conversations c
    JOIN users u1 ON c.user1Id = u1.id
    JOIN users u2 ON c.user2Id = u2.id
    WHERE c.user1Id = ? OR c.user2Id = ?
    ORDER BY c.lastMessageTime DESC`,
    [userId, userId, userId, userId, userId, userId, userId, userId, userId],
    (err, rows) => {
      if (err) {
        res.status(500).json({ error: err.message });
      } else {
        res.json(rows);
      }
    }
  );
});

// API endpoint to mark messages as read
app.post("/api/messages/markread", (req, res) => {
  const { userId, otherUserId } = req.body;

  db.run(
    "UPDATE messages SET isRead = 1 WHERE targetId = ? AND sourceId = ? AND isRead = 0",
    [userId, otherUserId],
    function (err) {
      if (err) {
        res.status(500).json({ error: err.message });
      } else {
        res.json({ 
          success: true, 
          updatedCount: this.changes 
        });
      }
    }
  );
});

const PORT = process.env.PORT || 8000;
server.listen(PORT, '0.0.0.0', () => {
  console.log("🚀 Chat server running on port", PORT);
  console.log("📱 Connection URLs:");
  console.log("   Android Emulator: http://10.0.2.2:8000");
  console.log("   iOS Simulator: http://localhost:8000");
  console.log("   Physical Device: http://192.168.1.5:8000");
  console.log("   Alternative: http://192.168.2.1:8000");
  console.log("💾 Database: " + dbPath);
});

// Graceful shutdown
process.on("SIGINT", () => {
  console.log("⏹️ Shutting down server...");
  db.close();
  process.exit(0);
});
