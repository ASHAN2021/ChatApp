import 'package:chatapp/Model/chat_model.dart';
import 'package:emoji_picker_flutter/emoji_picker_flutter.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';

class IndividualPage extends StatefulWidget {
  const IndividualPage({super.key, this.chatModel});

  final ChatModel? chatModel;

  @override
  State<IndividualPage> createState() => _IndividualPageState();
}

class _IndividualPageState extends State<IndividualPage> {
  bool isEmojiVisible = false;
  FocusNode textFieldFocusNode = FocusNode();
  TextEditingController textFieldController = TextEditingController();
  @override
  void initState() {
    super.initState();
    textFieldFocusNode.addListener(() {
      if (textFieldFocusNode.hasFocus) {
        setState(() {
          isEmojiVisible = false;
        });
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.blueGrey,
      appBar: AppBar(
        titleSpacing: 0,
        backgroundColor: const Color(0xff075E54),
        leadingWidth: 100,
        leading: InkWell(
          onTap: () {
            Navigator.pop(context);
          },
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.arrow_back, color: Colors.white),
              CircleAvatar(
                radius: 24,
                backgroundColor: Colors.blueGrey,
                child: SvgPicture.asset(
                  (widget.chatModel?.isGroup ?? false)
                      ? 'assets/groups.svg'
                      : 'assets/person.svg',
                  width: 38,
                  height: 38,
                  color: Colors.white,
                ),
              ),
            ],
          ),
        ),
        title: InkWell(
          onTap: () {},
          child: Container(
            margin: EdgeInsets.all(5),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.start,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  widget.chatModel?.name ?? 'Unknown',
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                Text(
                  'last seen today at 12:00 PM',
                  style: TextStyle(
                    fontSize: 13,
                    color: Colors.white.withOpacity(0.7),
                  ),
                ),
              ],
            ),
          ),
        ),
        actions: [
          IconButton(icon: const Icon(Icons.video_call), onPressed: () {}),
          IconButton(icon: const Icon(Icons.call), onPressed: () {}),
          PopupMenuButton<String>(
            onSelected: (value) {
              print(value);
            },
            itemBuilder: (context) {
              return [
                PopupMenuItem(
                  child: Text('View Contact'),
                  value: "View Contact",
                ),
                PopupMenuItem(
                  child: Text('links, media, and docs'),
                  value: "links, media, and docs",
                ),
                PopupMenuItem(child: Text('Search'), value: "Search"),
                PopupMenuItem(
                  child: Text('Mute Notifications'),
                  value: "Mute Notifications",
                ),
                PopupMenuItem(child: Text('Wallpaper'), value: "Wallpaper"),
              ];
            },
          ),
        ],
      ),
      body: Container(
        height: MediaQuery.of(context).size.height,
        width: MediaQuery.of(context).size.width,
        child: WillPopScope(
          child: Stack(
            children: [
              ListView(),
              Align(
                alignment: Alignment.bottomCenter,
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    Row(
                      children: [
                        Container(
                          width: MediaQuery.of(context).size.width - 55,
                          child: Card(
                            margin: EdgeInsets.only(
                              left: 2,
                              right: 2,
                              bottom: 8,
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(30),
                            ),
                            child: TextFormField(
                              focusNode: textFieldFocusNode,
                              textAlignVertical: TextAlignVertical.center,
                              style: TextStyle(
                                fontSize: 16,
                                color: Colors.black,
                              ),
                              keyboardType: TextInputType.multiline,
                              maxLines: 5,
                              minLines: 1,
                              decoration: InputDecoration(
                                border: InputBorder.none,
                                hintText: 'Type a message',
                                contentPadding: EdgeInsets.symmetric(
                                  horizontal: 20,
                                  vertical: 10,
                                ),
                                prefixIcon: IconButton(
                                  onPressed: () {
                                    setState(() {
                                      textFieldFocusNode.unfocus();
                                      textFieldFocusNode.canRequestFocus =
                                          false;
                                      isEmojiVisible = !isEmojiVisible;
                                    });
                                  },
                                  icon: Icon(
                                    Icons.emoji_emotions,
                                    color: Colors.blueGrey,
                                  ),
                                ),
                                suffixIcon: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    IconButton(
                                      icon: Icon(
                                        Icons.attach_file,
                                        color: Colors.blueGrey,
                                      ),
                                      onPressed: () {
                                        showModalBottomSheet(
                                          backgroundColor: Colors.transparent,
                                          context: context,
                                          builder: (builder) => bottomSheet(),
                                        );
                                      },
                                    ),
                                    IconButton(
                                      icon: Icon(
                                        Icons.camera_alt,
                                        color: Colors.blueGrey,
                                      ),
                                      onPressed: () {
                                        // Handle camera action
                                      },
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ),
                        CircleAvatar(
                          radius: 25,
                          backgroundColor: const Color(0xff128C7E),
                          child: IconButton(
                            icon: const Icon(Icons.mic, color: Colors.white),
                            onPressed: () {
                              // Handle send action
                            },
                          ),
                        ),
                      ],
                    ),
                    isEmojiVisible
                        ? emojiPicker()
                        : Container(), // Emoji picker widget
                  ],
                ),
              ),
            ],
          ),
          onWillPop: () {
            if (isEmojiVisible) {
              setState(() {
                isEmojiVisible = false;
              });
            } else {
              Navigator.pop(context);
            }
            return Future.value(false);
          },
        ),
      ),
    );
  }

  Widget bottomSheet() {
    return Container(
      height: 278,
      width: MediaQuery.of(context).size.width,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(20),
          topRight: Radius.circular(20),
        ),
      ),
      child: Card(
        margin: EdgeInsets.all(18),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 20),
          child: Column(
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  SizedBox(width: 10),
                  increation(
                    icon: Icons.insert_drive_file,
                    color: Colors.indigo,
                    text: 'Document',
                  ),
                  SizedBox(width: 40),
                  increation(
                    icon: Icons.camera_alt,
                    color: Colors.red,
                    text: 'Camera',
                  ),
                  SizedBox(width: 40),
                  increation(
                    icon: Icons.photo_library,
                    color: Colors.purple,
                    text: 'Gallery',
                  ),
                ],
              ),
              SizedBox(height: 20),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  SizedBox(width: 10),
                  increation(
                    icon: Icons.headset,
                    color: Colors.orange,
                    text: 'Audio',
                  ),
                  SizedBox(width: 40),
                  increation(
                    icon: Icons.location_on,
                    color: Colors.pinkAccent,
                    text: 'Location',
                  ),
                  SizedBox(width: 40),
                  increation(
                    icon: Icons.person,
                    color: Colors.blue,
                    text: 'Contact',
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget increation({
    required icon,
    required Color color,
    required String text,
  }) {
    return InkWell(
      onTap: () {},
      child: Column(
        children: [
          CircleAvatar(
            radius: 30,
            backgroundColor: color,
            child: Icon(icon, size: 29, color: Colors.white),
          ),
          SizedBox(height: 5),
          Text(text),
        ],
      ),
    );
  }

  Widget emojiPicker() {
    return SizedBox(
      height: 250,
      width: MediaQuery.of(context).size.width,
      child: EmojiPicker(
        onEmojiSelected: (category, emoji) {
          print(emoji);
          setState(() {
            textFieldController.text += emoji.emoji;
          });
        },
      ),
    );
  }
}
