const express = require("express");
const http = require("http");
const socketIo = require("socket.io");
const sqlite3 = require("sqlite3").verbose();
const path = require("path");

const app = express();
const server = http.createServer(app);
const io = socketIo(server, {
  cors: {
    origin: "*",
    methods: ["GET", "POST"],
  },
});

// Initialize SQLite database
const dbPath = path.join(__dirname, "chat_server.db");
const db = new sqlite3.Database(dbPath);

// Create tables if they don't exist
db.serialize(() => {
  db.run(`
    CREATE TABLE IF NOT EXISTS messages (
      id INTEGER PRIMARY KEY AUTOINCREMENT,
      sourceId TEXT NOT NULL,
      targetId TEXT NOT NULL,
      message TEXT NOT NULL,
      path TEXT,
      timestamp DATETIME DEFAULT CURRENT_TIMESTAMP
    )
  `);

  db.run(`
    CREATE TABLE IF NOT EXISTS users (
      id TEXT PRIMARY KEY,
      socketId TEXT,
      lastSeen DATETIME DEFAULT CURRENT_TIMESTAMP
    )
  `);
});

// Store connected users
const users = new Map();

io.on("connection", (socket) => {
  console.log("🔌 User connected:", socket.id);

  // Handle user signin
  socket.on("signin", (userId) => {
    console.log("👤 User signed in:", userId, "Socket:", socket.id);
    users.set(userId, socket.id);
    socket.userId = userId;

    // Update user in database
    db.run(
      "INSERT OR REPLACE INTO users (id, socketId, lastSeen) VALUES (?, ?, CURRENT_TIMESTAMP)",
      [userId, socket.id]
    );
  });

  // Handle incoming messages
  socket.on("message", (data) => {
    console.log("📨 Message received:", data);

    const { message, sourceId, targetId, path } = data;

    // Save message to database
    db.run(
      "INSERT INTO messages (sourceId, targetId, message, path) VALUES (?, ?, ?, ?)",
      [sourceId, targetId, message, path || ""],
      function (err) {
        if (err) {
          console.error("❌ Database error:", err);
        } else {
          console.log("💾 Message saved to database, ID:", this.lastID);
        }
      }
    );

    // Find target user's socket
    const targetSocketId = users.get(targetId);

    if (targetSocketId) {
      // Send message to target user
      io.to(targetSocketId).emit("message", {
        message: message,
        sourceId: sourceId,
        targetId: targetId,
        path: path || "",
        timestamp: new Date().toISOString(),
      });
      console.log("✅ Message sent to:", targetId);
    } else {
      console.log("❌ Target user not found:", targetId);
    }
  });

  // Handle disconnection
  socket.on("disconnect", () => {
    console.log("🔌 User disconnected:", socket.id);
    if (socket.userId) {
      users.delete(socket.userId);

      // Update user last seen in database
      db.run(
        "UPDATE users SET socketId = NULL, lastSeen = CURRENT_TIMESTAMP WHERE id = ?",
        [socket.userId]
      );

      console.log("👤 User removed from active users:", socket.userId);
    }
  });
});

// API endpoint to get message history
app.get("/api/messages/:userId1/:userId2", (req, res) => {
  const { userId1, userId2 } = req.params;

  db.all(
    `SELECT * FROM messages 
     WHERE (sourceId = ? AND targetId = ?) OR (sourceId = ? AND targetId = ?)
     ORDER BY timestamp ASC`,
    [userId1, userId2, userId2, userId1],
    (err, rows) => {
      if (err) {
        res.status(500).json({ error: err.message });
      } else {
        res.json(rows);
      }
    }
  );
});

const PORT = process.env.PORT || 8000;
server.listen(PORT, () => {
  console.log("🚀 Chat server running on port", PORT);
  console.log("📱 Flutter app should connect to: http://10.0.2.2:8000");
  console.log("💾 Database: " + dbPath);
});

// Graceful shutdown
process.on("SIGINT", () => {
  console.log("⏹️ Shutting down server...");
  db.close();
  process.exit(0);
});
