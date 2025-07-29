import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import '../Model/user_model.dart';
import '../Model/chat_model.dart';
import '../Model/message_model.dart';

class DatabaseService {
  static final DatabaseService _instance = DatabaseService._internal();
  factory DatabaseService() => _instance;
  DatabaseService._internal();

  static Database? _database;

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDatabase();
    return _database!;
  }

  Future<Database> _initDatabase() async {
    String path = join(await getDatabasesPath(), 'chat_app.db');
    return await openDatabase(
      path,
      version: 4, // Force fresh database creation due to isRead column issue
      onCreate: _onCreate,
      onUpgrade: _onUpgrade,
    );
  }

  Future<void> _onCreate(Database db, int version) async {
    // Users table
    await db.execute('''
      CREATE TABLE users(
        id TEXT PRIMARY KEY,
        name TEXT NOT NULL,
        profileImage TEXT,
        qrCode TEXT NOT NULL,
        createdAt INTEGER NOT NULL
      )
    ''');

    // Chats table
    await db.execute('''
      CREATE TABLE chats(
        id TEXT PRIMARY KEY,
        name TEXT NOT NULL,
        lastMessage TEXT NOT NULL,
        lastMessageTime INTEGER NOT NULL,
        profileImage TEXT,
        isOnline INTEGER DEFAULT 0,
        isGroup INTEGER DEFAULT 0
      )
    ''');

    // Messages table
    await db.execute('''
      CREATE TABLE messages(
        id TEXT PRIMARY KEY,
        chatId TEXT NOT NULL,
        senderId TEXT NOT NULL,
        message TEXT NOT NULL,
        timestamp INTEGER NOT NULL,
        isMe INTEGER NOT NULL,
        isRead INTEGER DEFAULT 0,
        messageType TEXT DEFAULT 'text',
        path TEXT,
        FOREIGN KEY (chatId) REFERENCES chats (id)
      )
    ''');
  }

  Future<void> _onUpgrade(Database db, int oldVersion, int newVersion) async {
    print('Database upgrade from version $oldVersion to $newVersion');

    if (oldVersion < 2) {
      // Check if isGroup column already exists before adding it
      try {
        final result = await db.rawQuery("PRAGMA table_info(chats)");
        final columnExists = result.any(
          (column) => column['name'] == 'isGroup',
        );

        if (!columnExists) {
          await db.execute(
            'ALTER TABLE chats ADD COLUMN isGroup INTEGER DEFAULT 0',
          );
          print('Added isGroup column to chats table');
        } else {
          print('isGroup column already exists, skipping migration');
        }
      } catch (e) {
        print('Error during database migration: $e');
        // If there's any error, try to add the column anyway
        // This might fail if column exists, but we'll catch it
        try {
          await db.execute(
            'ALTER TABLE chats ADD COLUMN isGroup INTEGER DEFAULT 0',
          );
        } catch (alterError) {
          print('Column might already exist: $alterError');
        }
      }
    }

    if (oldVersion < 3) {
      // Check if isRead column already exists in messages table before adding it
      try {
        final result = await db.rawQuery("PRAGMA table_info(messages)");
        final columnExists = result.any((column) => column['name'] == 'isRead');

        if (!columnExists) {
          await db.execute(
            'ALTER TABLE messages ADD COLUMN isRead INTEGER DEFAULT 0',
          );
          print('Added isRead column to messages table');
        } else {
          print('isRead column already exists, skipping migration');
        }
      } catch (e) {
        print('Error during messages table migration: $e');
        // If there's any error, try to add the column anyway
        try {
          await db.execute(
            'ALTER TABLE messages ADD COLUMN isRead INTEGER DEFAULT 0',
          );
        } catch (alterError) {
          print('Column might already exist: $alterError');
        }
      }
    }

    if (oldVersion < 4) {
      // Force complete database recreation for version 4
      print('Forcing complete database recreation for version 4');

      // Drop all tables
      try {
        await db.execute('DROP TABLE IF EXISTS messages');
        await db.execute('DROP TABLE IF EXISTS chats');
        await db.execute('DROP TABLE IF EXISTS users');
        print('Dropped all existing tables');

        // Recreate all tables with correct schema
        await _onCreate(db, newVersion);
        print('Recreated all tables with version 4 schema');
      } catch (e) {
        print('Error during complete database recreation: $e');
      }
    }
  }

  // User operations
  Future<void> insertUser(UserModel user) async {
    final db = await database;
    await db.insert(
      'users',
      user.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<UserModel?> getCurrentUser() async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query('users', limit: 1);
    if (maps.isNotEmpty) {
      return UserModel.fromMap(maps.first);
    }
    return null;
  }

  // Chat operations
  Future<void> insertOrUpdateChat(ChatModel chat) async {
    final db = await database;
    await db.insert(
      'chats',
      chat.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<List<ChatModel>> getAllChats() async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      'chats',
      orderBy: 'lastMessageTime DESC',
    );
    return List.generate(maps.length, (i) => ChatModel.fromMap(maps[i]));
  }

  Future<ChatModel?> getChatById(String chatId) async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      'chats',
      where: 'id = ?',
      whereArgs: [chatId],
    );
    if (maps.isNotEmpty) {
      return ChatModel.fromMap(maps.first);
    }
    return null;
  }

  // Message operations
  Future<void> insertMessage(MessageModel message) async {
    final db = await database;
    await db.insert('messages', message.toMap());

    // Update chat's last message
    await db.update(
      'chats',
      {
        'lastMessage': message.message,
        'lastMessageTime': message.timestamp.millisecondsSinceEpoch,
      },
      where: 'id = ?',
      whereArgs: [message.chatId],
    );
  }

  Future<List<MessageModel>> getMessagesForChat(String chatId) async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      'messages',
      where: 'chatId = ?',
      whereArgs: [chatId],
      orderBy: 'timestamp ASC',
    );
    return List.generate(maps.length, (i) => MessageModel.fromMap(maps[i]));
  }

  Future<void> markMessagesAsRead(String chatId) async {
    final db = await database;
    await db.update(
      'messages',
      {'isRead': 1},
      where: 'chatId = ? AND isMe = 0',
      whereArgs: [chatId],
    );
  }

  Future<void> deleteChat(String chatId) async {
    final db = await database;
    await db.delete('messages', where: 'chatId = ?', whereArgs: [chatId]);
    await db.delete('chats', where: 'id = ?', whereArgs: [chatId]);
  }

  Future<void> clearAllData() async {
    final db = await database;
    await db.delete('messages');
    await db.delete('chats');
    await db.delete('users');
  }

  // Reset database by deleting the database file and recreating it
  Future<void> resetDatabase() async {
    try {
      final databasesPath = await getDatabasesPath();
      final path = join(databasesPath, 'chat_app.db');

      // Close current database connection
      if (_database != null) {
        await _database!.close();
        _database = null;
      }

      // Delete the database file
      await deleteDatabase(path);
      print('Database reset successfully');

      // Reinitialize database
      _database = await _initDatabase();
    } catch (e) {
      print('Error resetting database: $e');
    }
  }

  // Force complete database reset - more aggressive approach
  static Future<void> forceCompleteReset() async {
    try {
      final databasesPath = await getDatabasesPath();
      final path = join(databasesPath, 'chat_app.db');

      print('💥 Forcing complete database deletion...');

      // Always delete the database file regardless of its state
      if (await databaseExists(path)) {
        await deleteDatabase(path);
        print('✅ Database file deleted successfully');
      }

      // Clear any cached database instance
      if (_database != null) {
        await _database!.close();
        _database = null;
        print('✅ Database instance cleared');
      }

      print(
        '🆕 Database will be recreated with correct schema on first access',
      );
    } catch (e) {
      print('❌ Error in forceCompleteReset: $e');
    }
  }

  // Force reset database on app startup if schema issues detected
  static Future<void> forceResetIfNeeded() async {
    try {
      final databasesPath = await getDatabasesPath();
      final path = join(databasesPath, 'chat_app.db');

      // Check if database exists
      if (await databaseExists(path)) {
        // Try to open and check schema
        final db = await openDatabase(path, readOnly: true);
        try {
          // Try to check if isRead column exists
          final result = await db.rawQuery("PRAGMA table_info(messages)");
          final hasIsRead = result.any((column) => column['name'] == 'isRead');

          if (!hasIsRead) {
            print('⚠️ Database missing isRead column, forcing reset...');
            await db.close();
            await deleteDatabase(path);
            print('✅ Old database deleted, will recreate with correct schema');
          } else {
            await db.close();
            print('✅ Database schema is correct');
          }
        } catch (e) {
          print('⚠️ Error checking database schema: $e, forcing reset...');
          await db.close();
          await deleteDatabase(path);
        }
      }
    } catch (e) {
      print('Error in forceResetIfNeeded: $e');
    }
  }
}
