import 'package:filesize/filesize.dart';
import 'package:flutter/material.dart';
import 'package:localsend_rs/core/rust/session/model.dart';
import 'package:mime/mime.dart';

import '../../core/rust/bridge.dart';

class FileIcon extends StatelessWidget {
  final String? extension;

  const FileIcon({super.key, this.extension});

  static const Map<String, IconData> _iconMap = {
    "image": Icons.image,
    "video": Icons.video_file,
    "audio": Icons.music_note,
    "pdf": Icons.picture_as_pdf,
    "text": Icons.text_snippet,
    "zip": Icons.folder_zip,
    "default": Icons.insert_drive_file,
  };

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(4.0),
      child: Container(
        decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.secondaryContainer,
            borderRadius: BorderRadius.circular(12)),
        height: 40,
        width: 40,
        child: Icon(
          extension == null
              ? _iconMap["default"]!
              : _iconMap[extension] ?? _iconMap["default"]!,
        ),
      ),
    );
  }
}

class FileWidget extends StatelessWidget {
  final String name;
  final dynamic size;
  final Widget? subTitle;
  final List<Widget>? actions;

  const FileWidget(
      {super.key, required this.name, this.size, this.subTitle, this.actions});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        const SizedBox(width: 8),
        FileIcon(extension: lookupMimeType(name)),
        Expanded(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.start,
            children: [
              const SizedBox(height: 4),
              Row(
                children: [
                  Expanded(
                    child: Text(
                      name,
                      maxLines: 1,
                      softWrap: false,
                      overflow: TextOverflow.fade,
                    ),
                  ),
                  Text("(${filesize(size)})"),
                ],
              ),
              if (subTitle != null) subTitle!,
            ],
          ),
        ),
        if (actions != null) ...actions!,
      ],
    );
  }
}
