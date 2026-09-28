import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import '../models/pdf_tool.dart';
import '../services/pdf_service.dart';
import 'processing_screen.dart';

class FilePickerScreen extends StatefulWidget {
  final PdfTool tool;

  const FilePickerScreen({super.key, required this.tool});

  @override
  State<FilePickerScreen> createState() => _FilePickerScreenState();
}

class _FilePickerScreenState extends State<FilePickerScreen> {
  final List<File> _files = [];
  CompressionQuality _quality = CompressionQuality.medium;
  int _fromPage = 0;
  int _toPage = 0;
  int? _pageCount;
  bool _loadingPageCount = false;

  bool get _isMultiFile =>
      widget.tool == PdfTool.merge || widget.tool == PdfTool.imagesToPdf;
  bool get _isImages => widget.tool == PdfTool.imagesToPdf;

  Future<void> _pickFiles() async {
    if (_isImages) {
      final picker = ImagePicker();
      final picked = await picker.pickMultiImage();
      if (picked.isEmpty) return;
      setState(() => _files.addAll(picked.map((x) => File(x.path))));
      return;
    }

    final List<PlatformFile> picked;
    if (_isMultiFile) {
      picked = await FilePicker.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['pdf'],
      );
    } else {
      final single = await FilePicker.pickFile(
        type: FileType.custom,
        allowedExtensions: ['pdf'],
      );
      picked = single == null ? [] : [single];
    }
    if (picked.isEmpty) return;

    setState(() {
      _files.addAll(
        picked.where((f) => f.path != null).map((f) => File(f.path!)),
      );
    });

    if (widget.tool == PdfTool.split && _files.isNotEmpty) {
      _loadPageCount();
    }
  }

  Future<void> _loadPageCount() async {
    setState(() => _loadingPageCount = true);
    final count = await PdfService.instance.getPageCount(_files.first);
    if (!mounted) return;
    setState(() {
      _pageCount = count;
      _toPage = count - 1;
      _loadingPageCount = false;
    });
  }

  void _removeAt(int index) => setState(() => _files.removeAt(index));

  void _reorder(int oldIndex, int newIndex) {
    setState(() {
      final item = _files.removeAt(oldIndex);
      _files.insert(newIndex, item);
    });
  }

  bool get _canContinue {
    if (widget.tool == PdfTool.merge) return _files.length >= 2;
    if (widget.tool == PdfTool.imagesToPdf) return _files.isNotEmpty;
    return _files.isNotEmpty;
  }

  void _continue() {
    final service = PdfService.instance;
    final Future<File> Function() task = switch (widget.tool) {
      PdfTool.compress => () => service.compressPdf(
        _files.first,
        quality: _quality,
      ),
      PdfTool.merge => () => service.mergePdfs(_files, quality: _quality),
      PdfTool.split => () => service.splitPdf(
        _files.first,
        fromPage: _fromPage,
        toPage: _toPage,
      ),
      PdfTool.imagesToPdf => () => service.imagesToPdf(_files),
    };

    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => ProcessingScreen(title: widget.tool.title, task: task),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(widget.tool.title)),
      body: SafeArea(
        top: false,
        child: Column(
          children: [
            Expanded(
              child: _files.isEmpty
                  ? Center(
                      child: TextButton.icon(
                        onPressed: _pickFiles,
                        icon: const Icon(Icons.add),
                        label: Text(
                          _isImages ? 'Choose photos' : 'Choose PDF file(s)',
                        ),
                      ),
                    )
                  : ReorderableListView.builder(
                      itemCount: _files.length,
                      onReorderItem: _reorder,
                      itemBuilder: (context, index) {
                        final file = _files[index];
                        return ListTile(
                          key: ValueKey(file.path + index.toString()),
                          leading: Icon(
                            _isImages ? Icons.image : Icons.picture_as_pdf,
                          ),
                          title: Text(
                            file.uri.pathSegments.last,
                            overflow: TextOverflow.ellipsis,
                          ),
                          trailing: IconButton(
                            icon: const Icon(Icons.close),
                            onPressed: () => _removeAt(index),
                          ),
                        );
                      },
                    ),
            ),
            if (_isMultiFile && _files.isNotEmpty)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: TextButton.icon(
                    onPressed: _pickFiles,
                    icon: const Icon(Icons.add),
                    label: const Text('Add more'),
                  ),
                ),
              ),
            if (widget.tool == PdfTool.compress || widget.tool == PdfTool.merge)
              Padding(
                padding: const EdgeInsets.all(16),
                child: SegmentedButton<CompressionQuality>(
                  segments: const [
                    ButtonSegment(
                      value: CompressionQuality.low,
                      label: Text('Low'),
                    ),
                    ButtonSegment(
                      value: CompressionQuality.medium,
                      label: Text('Medium'),
                    ),
                    ButtonSegment(
                      value: CompressionQuality.high,
                      label: Text('High'),
                    ),
                  ],
                  selected: {_quality},
                  onSelectionChanged: (s) => setState(() => _quality = s.first),
                ),
              ),
            if (widget.tool == PdfTool.split && _files.isNotEmpty)
              Padding(
                padding: const EdgeInsets.all(16),
                child: _loadingPageCount
                    ? const CircularProgressIndicator()
                    : _pageCount == null
                    ? const SizedBox.shrink()
                    : Column(
                        children: [
                          Text(
                            'Pages ${_fromPage + 1}–${_toPage + 1} of $_pageCount',
                          ),
                          RangeSlider(
                            min: 0,
                            max: (_pageCount! - 1).toDouble(),
                            divisions: _pageCount! > 1 ? _pageCount! - 1 : null,
                            values: RangeValues(
                              _fromPage.toDouble(),
                              _toPage.toDouble(),
                            ),
                            onChanged: (values) => setState(() {
                              _fromPage = values.start.round();
                              _toPage = values.end.round();
                            }),
                          ),
                        ],
                      ),
              ),
            Padding(
              padding: const EdgeInsets.all(16),
              child: SizedBox(
                width: double.infinity,
                child: FilledButton(
                  onPressed: _canContinue ? _continue : null,
                  child: const Text('Continue'),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
