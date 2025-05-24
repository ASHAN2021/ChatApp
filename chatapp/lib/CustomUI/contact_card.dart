import 'package:chatapp/Model/chat_model.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';

class ContactCard extends StatelessWidget {
  const ContactCard({super.key, this.contact});

  final ChatModel? contact;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: () {},
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: Colors.blueGrey,
          child: SvgPicture.asset(
            'assets/person.svg',
            width: 38,
            height: 38,
            color: Colors.white,
          ),
        ),
        title: Text(
          contact?.name ?? 'Unknown',
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
        ),
        subtitle: Text(
          contact?.status ?? 'No status',
          style: TextStyle(color: Colors.grey[600], fontSize: 16),
        ),
      ),
    );
  }
}
