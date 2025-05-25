class ChatModel {
  String? name;
  String? icon;
  bool? isGroup;
  String? currentMessage;
  String? time;
  String? status;
  bool select;

  ChatModel({
    this.name,
    this.icon,
    this.isGroup,
    this.currentMessage,
    this.time,
    this.status,
    this.select = false,
  });
}
