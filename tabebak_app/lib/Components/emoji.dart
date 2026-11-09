import 'package:flutter/material.dart';

// Emoji are drawn from bundled Noto PNGs (assets/emoji/) instead of the
// platform emoji font, which some iOS versions fail to render in Flutter.

final RegExp _emojiPattern = RegExp(
  r'[\u{1F1E6}-\u{1F1FF}]{2}'
  r'|[\u{1F000}-\u{1FFFF}\u{2600}-\u{27BF}\u{2B00}-\u{2BFF}\u{2139}]\u{FE0F}?'
  r'(?:\u{200D}[\u{1F000}-\u{1FFFF}\u{2600}-\u{27BF}\u{2B00}-\u{2BFF}]\u{FE0F}?)*',
  unicode: true,
);

/// Asset path for an emoji sequence, e.g. '🩺' -> assets/emoji/emoji_u1fa7a.png.
String emojiAsset(String emoji) {
  final codes = emoji.runes
      .where((r) => r != 0xFE0F)
      .map((r) => r.toRadixString(16).padLeft(4, '0'))
      .join('_');
  return 'assets/emoji/emoji_u$codes.png';
}

/// A single emoji rendered as an image of [size] logical pixels.
class EmojiIcon extends StatelessWidget {
  final String emoji;
  final double size;

  const EmojiIcon(this.emoji, {super.key, this.size = 24});

  @override
  Widget build(BuildContext context) {
    return Image.asset(
      emojiAsset(emoji),
      width: size,
      height: size,
      fit: BoxFit.contain,
      filterQuality: FilterQuality.medium,
      errorBuilder: (_, __, ___) =>
          Text(emoji, style: TextStyle(fontSize: size * 0.85, height: 1)),
    );
  }
}

/// Drop-in replacement for [Text] that draws any emoji in [data] as images.
class EmojiText extends StatelessWidget {
  final String data;
  final TextStyle? style;
  final TextAlign? textAlign;
  final int? maxLines;
  final TextOverflow? overflow;
  final bool? softWrap;

  const EmojiText(
    this.data, {
    super.key,
    this.style,
    this.textAlign,
    this.maxLines,
    this.overflow,
    this.softWrap,
  });

  @override
  Widget build(BuildContext context) {
    final matches = _emojiPattern.allMatches(data).toList();
    final fontSize = style?.fontSize ??
        DefaultTextStyle.of(context).style.fontSize ??
        14;
    final emojiSize = fontSize * 1.15;

    // A lone emoji: just the image.
    if (matches.length == 1 && data.trim() == matches.first.group(0)) {
      return EmojiIcon(matches.first.group(0)!, size: emojiSize);
    }
    if (matches.isEmpty) {
      return Text(data,
          style: style,
          textAlign: textAlign,
          maxLines: maxLines,
          overflow: overflow,
          softWrap: softWrap);
    }

    final spans = <InlineSpan>[];
    var last = 0;
    for (final m in matches) {
      if (m.start > last) {
        spans.add(TextSpan(text: data.substring(last, m.start)));
      }
      spans.add(WidgetSpan(
        alignment: PlaceholderAlignment.middle,
        child: EmojiIcon(m.group(0)!, size: emojiSize),
      ));
      last = m.end;
    }
    if (last < data.length) spans.add(TextSpan(text: data.substring(last)));

    return Text.rich(
      TextSpan(children: spans),
      style: style,
      textAlign: textAlign,
      maxLines: maxLines,
      overflow: overflow,
      softWrap: softWrap,
    );
  }
}
