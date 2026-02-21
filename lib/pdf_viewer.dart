import 'package:flutter/material.dart';
import 'package:flutter_pdfview/flutter_pdfview.dart';
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';
import 'dart:io';

class PdfViewer extends StatefulWidget {
  final String url;
  const PdfViewer({super.key, required this.url});

  @override
  State<PdfViewer> createState() => _PdfViewerState();
}

class _PdfViewerState extends State<PdfViewer> {
  String? localPath;
  bool isLoading = true;

  @override
  void initState() {
    // TODO: implement initState
    super.initState();
    loadPdf();
  }

  Future<void> loadPdf() async {
    try{
        final response = await http.get(Uri.parse(widget.url));

        if(response.statusCode == 200){
          final bytes = response.bodyBytes;
          final directory = await getApplicationDocumentsDirectory();
          final file = File('${directory.path}/temp.pdf');
          await file.writeAsBytes(bytes, flush: true);
          setState(() {
            localPath = file.path;
            isLoading = false;
          });
        }else{
          throw Exception("Failed to load PDF file.");
        }
    }catch (e){
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Failed to load PDF: $e")),
      );
      setState(() => isLoading = false);
    }
  }
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        iconTheme: IconThemeData(color: Colors.white),
        title: Text("Certificate", style: TextStyle(color: Colors.white),),
        backgroundColor: Colors.green[800],
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator(),)
          : localPath == null
              ? Center(child: Text("Failed to open PDF"))
              : PDFView(
                filePath: localPath!,
              ),
    );
  }
}
