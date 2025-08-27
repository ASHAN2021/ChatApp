import '../Model/chat_model.dart';
import '../Model/message_model.dart';

class SampleData {
  static List<ChatModel> getSampleChats() {
    return [
      ChatModel(
        id: 'chat_1',
        name: 'Alex Johnson',
        lastMessage: 'Hey! How are you doing?',
        lastMessageTime: DateTime.now().subtract(Duration(minutes: 5)),
        isOnline: true,
        isGroup: false,
      ),
      ChatModel(
        id: 'chat_2',
        name: 'Sarah Wilson',
        lastMessage: 'Thanks for the help earlier!',
        lastMessageTime: DateTime.now().subtract(Duration(hours: 2)),
        isOnline: false,
        isGroup: false,
      ),
      ChatModel(
        id: 'chat_3',
        name: 'Mike Chen',
        lastMessage: 'See you tomorrow 👍',
        lastMessageTime: DateTime.now().subtract(Duration(days: 1)),
        isOnline: true,
        isGroup: false,
      ),
    ];
  }

  static List<MessageModel> getSampleMessages(String chatId) {
    return [
      MessageModel(
        id: 'msg_1',
        chatId: chatId,
        senderId: 'other_user',
        message: 'Hello! Nice to meet you through QR code!',
        timestamp: DateTime.now().subtract(Duration(minutes: 10)),
        isMe: false,
        path: '',
      ),
      MessageModel(
        id: 'msg_2',
        chatId: chatId,
        senderId: 'current_user',
        message: 'Hi there! This is pretty cool, isn\'t it?',
        timestamp: DateTime.now().subtract(Duration(minutes: 8)),
        isMe: true,
        path: '',
      ),
      MessageModel(
        id: 'msg_3',
        chatId: chatId,
        senderId: 'other_user',
        message: 'Yes! Very convenient way to connect.',
        timestamp: DateTime.now().subtract(Duration(minutes: 6)),
        isMe: false,
        path: '',
      ),
      MessageModel(
        id: 'msg_4',
        chatId: chatId,
        senderId: 'current_user',
        message: 'Exactly! No need to exchange phone numbers.',
        timestamp: DateTime.now().subtract(Duration(minutes: 5)),
        isMe: true,
        path: '',
      ),
    ];
  }
}
