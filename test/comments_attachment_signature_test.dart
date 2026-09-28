import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:tiler_app/bloc/comments/comments_state.dart';

void main() {
  late Directory tempDir;

  setUp(() async {
    tempDir = await Directory.systemTemp.createTemp('attachment_signature');
  });

  tearDown(() async {
    await tempDir.delete(recursive: true);
  });

  String write(String name, List<int> bytes) {
    final file = File('${tempDir.path}${Platform.pathSeparator}$name');
    file.writeAsBytesSync(bytes);
    return file.path;
  }

  group('CommentsBloc.validateSignature', () {
    test('accepts files whose header matches the extension', () async {
      expect(
          await CommentsBloc.validateSignature(
              write('ok.pdf', [0x25, 0x50, 0x44, 0x46, 1, 2, 3]),
              'ok.pdf'),
          isNull);
      expect(
          await CommentsBloc.validateSignature(
              write('ok.png',
                  [0x89, 0x50, 0x4E, 0x47, 0x0D, 0x0A, 0x1A, 0x0A, 1, 2]),
              'ok.png'),
          isNull);
      expect(
          await CommentsBloc.validateSignature(
              write('ok.jpg', [0xFF, 0xD8, 0xFF, 0xE0, 1]), 'ok.jpg'),
          isNull);
      expect(
          await CommentsBloc.validateSignature(
              write('ok.jpeg', [0xFF, 0xD8, 0xFF, 0xE1, 1]),
              'ok.jpeg'),
          isNull);
      expect(
          await CommentsBloc.validateSignature(
              write('ok.docx', [0x50, 0x4B, 0x03, 0x04, 0, 0, 0, 0]),
              'ok.docx'),
          isNull);
    });

    test('is case-insensitive on the extension', () async {
      expect(
          await CommentsBloc.validateSignature(
              write('UPPER.PDF', [0x25, 0x50, 0x44, 0x46, 1]),
              'UPPER.PDF'),
          isNull);
    });

    test('rejects disallowed content renamed to an allowed extension',
        () async {
      // Windows PE executable ("MZ") disguised as a PDF.
      expect(
          await CommentsBloc.validateSignature(
              write('evil.pdf', [0x4D, 0x5A, 0x90, 0x00]), 'evil.pdf'),
          'invalidType');
      // PDF header in a .docx name.
      expect(
          await CommentsBloc.validateSignature(
              write('renamed.docx',
                  [0x25, 0x50, 0x44, 0x46, 0x31, 0x2E, 0x34]),
              'renamed.docx'),
          'invalidType');
      // Shell script disguised as a PNG.
      expect(
          await CommentsBloc.validateSignature(
              write('script.png', [0x23, 0x21, 0x2F, 0x62, 0x69, 0x6E]),
              'script.png'),
          'invalidType');
      // JPEG content under a .jpg name is fine, but PDF content under a
      // .jpeg name is not.
      expect(
          await CommentsBloc.validateSignature(
              write('cross.jpeg', [0x25, 0x50, 0x44, 0x46]),
              'cross.jpeg'),
          'invalidType');
    });

    test('rejects unreadable, truncated and unknown-extension files',
        () async {
      expect(
          await CommentsBloc.validateSignature(
              '${tempDir.path}${Platform.pathSeparator}missing.pdf',
              'missing.pdf'),
          'invalidType');
      // Shorter than the JPEG signature.
      expect(
          await CommentsBloc.validateSignature(write('tiny.jpg', [0xFF]),
              'tiny.jpg'),
          'invalidType');
      // Known header bytes but an extension outside the allowlist.
      expect(
          await CommentsBloc.validateSignature(
              write('notes.txt', [0x25, 0x50, 0x44, 0x46, 1]),
              'notes.txt'),
          'invalidType');
      // No extension at all.
      expect(
          await CommentsBloc.validateSignature(
              write('noext', [0x25, 0x50, 0x44, 0x46, 1]), 'noext'),
          'invalidType');
    });
  });
}