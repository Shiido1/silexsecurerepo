import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:mp3_music_converter/screens/bookworm/model/model.dart';
import 'package:mp3_music_converter/screens/bookworm/provider/bookworm_provider.dart';
import 'package:mp3_music_converter/screens/bookworm/services/book_services.dart';
import 'package:mp3_music_converter/utils/helper/helper.dart';
import 'package:mp3_music_converter/utils/helper/instances.dart';
import 'package:http/http.dart' as http;
import 'package:mp3_music_converter/widgets/progress_indicator.dart';
import 'package:provider/provider.dart';

Future<Widget> showFolderOptions(
    {@required BuildContext context, String folderName}) {
  Provider.of<BookwormProvider>(context, listen: false)
      .getFolderContents(folderName);
  return showDialog(
      context: context,
      builder: (context) {
        return Dialog(
          backgroundColor: Colors.grey[900],
          child: Padding(
            padding: EdgeInsets.symmetric(vertical: 30),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                InkWell(
                  onTap: () {
                    Navigator.pop(context);
                    showDialog(
                        context: context,
                        builder: (_) {
                          return RenameFolder(folderName);
                        });
                  },
                  child: Container(
                    padding: EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                    child: Row(
                      children: [
                        Icon(
                          Icons.edit,
                          color: Colors.white,
                        ),
                        SizedBox(width: 20),
                        Text(
                          'Rename Folder',
                          style: TextStyle(color: Colors.white, fontSize: 16),
                        )
                      ],
                    ),
                  ),
                ),
                SizedBox(height: 10),
                InkWell(
                  onTap: () {
                    Navigator.pop(context);
                    showDialog(
                      context: context,
                      builder: (_) {
                        return ShowConfirmDeleteDialog();
                      },
                    );
                  },
                  child: Container(
                    padding: EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                    child: Row(
                      children: [
                        Icon(
                          Icons.delete_forever,
                          color: Colors.white,
                        ),
                        SizedBox(width: 20),
                        Text(
                          'Delete Folder',
                          style: TextStyle(color: Colors.white, fontSize: 16),
                        )
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      });
}

class RenameFolder extends StatefulWidget {
  final String folderName;
  RenameFolder(this.folderName);

  @override
  _RenameFolderState createState() => _RenameFolderState();
}

class _RenameFolderState extends State<RenameFolder> {
  final _formKey = GlobalKey<FormState>();
  TextEditingController _textEditingController;
  List allFolders;
  String token;
  bool showError = false;
  String error = '';

  @override
  void initState() {
    _textEditingController = TextEditingController(text: widget.folderName);
    Provider.of<BookwormProvider>(context, listen: false).getFolders();
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    allFolders = Provider.of<BookwormProvider>(context).allFolders;

    return Dialog(
      backgroundColor: Colors.grey[500],
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Rename folder',
              style: TextStyle(color: Colors.black, fontSize: 16),
            ),
            SizedBox(height: 10),
            Form(
              key: _formKey,
              child: TextFormField(
                autovalidateMode: AutovalidateMode.onUserInteraction,
                autofocus: true,
                decoration: InputDecoration(
                    hintText: 'Rename folder',
                    hintStyle: TextStyle(color: Colors.black38),
                    counterText: ''),
                controller: _textEditingController,
                textCapitalization: TextCapitalization.words,
                maxLength: 20,
                validator: (val) {
                  return val.trim().isEmpty ? 'Please enter a name' : null;
                },
              ),
            ),
            if (showError) SizedBox(height: 10),
            if (showError)
              Text(
                error,
                style: TextStyle(color: Colors.red, fontSize: 15),
              ),
            SizedBox(height: 20),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                MaterialButton(
                  onPressed: () {
                    Navigator.pop(context);
                  },
                  child: Text(
                    'Cancel',
                    style: TextStyle(color: Colors.white, fontSize: 15),
                  ),
                  color: Colors.red,
                  elevation: 0,
                ),
                MaterialButton(
                  onPressed: () async {
                    setState(() {
                      showError = false;
                    });
                    if (allFolders.contains(_textEditingController.text)) {
                      error = 'Name already exists';
                      setState(() {
                        showError = true;
                      });
                    }
                    if (_textEditingController.text == widget.folderName)
                      Navigator.pop(context);

                    if (_formKey.currentState.validate() &&
                        !(allFolders.contains(_textEditingController.text))) {
                      {
                        await BookwormServices().renameFolder(
                            oldName: widget.folderName,
                            newName: _textEditingController.text);
                        Provider.of<BookwormProvider>(context, listen: false)
                            .getFolders();
                        Navigator.pop(context);
                      }
                    }
                  },
                  child: Text(
                    'Done',
                    style: TextStyle(color: Colors.white, fontSize: 16),
                  ),
                  color: Colors.blue,
                  elevation: 0,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class ShowConfirmDeleteDialog extends StatefulWidget {
  @override
  _ShowConfirmDeleteDialogState createState() =>
      _ShowConfirmDeleteDialogState();
}

class _ShowConfirmDeleteDialogState extends State<ShowConfirmDeleteDialog> {
  Folder folder;
  CustomProgressIndicator _progressIndicator;
  String token;

  getData() async {
    token = await preferencesHelper.getStringValues(key: 'token');
  }

  deleteFolder() async {
    String url = 'https://youtubeaudio.com/api/book/removefolder';

    try {
      _progressIndicator.show();
      final response = await http.post(url,
          headers: {'Content-Type': 'application/json'},
          body: jsonEncode({
            'token': token,
            'id': folder.id,
          }));
      _progressIndicator.dismiss();
      if (response.statusCode == 200) {
        Map data = jsonDecode(response.body);
        if (data['message'].toString().toLowerCase().contains('deleted')) {
          await BookwormServices().deleteFolder(folder.name);
          Provider.of<BookwormProvider>(context, listen: false).getFolders();
          showToast(context, message: 'Deleted', backgroundColor: Colors.green);
          Navigator.pop(context);
          return;
        } else {
          showToast(context,
              message: data['message'], backgroundColor: Colors.red);
          Navigator.pop(context);
        }
      } else {
        try {
          Map data = jsonDecode(response.body);
          showToast(context,
              message: data['message'], backgroundColor: Colors.red);
          Navigator.pop(context);
        } catch (e) {
          showToast(context,
              message: 'An error occurred', backgroundColor: Colors.red);
          Navigator.pop(context);
        }
      }
    } catch (e) {
      _progressIndicator.dismiss();
      showToast(context,
          message: 'Failed. Check internet connection',
          backgroundColor: Colors.red);
      Navigator.pop(context);
    }
  }

  @override
  void initState() {
    folder =
        Provider.of<BookwormProvider>(context, listen: false).currentFolder;
    _progressIndicator = CustomProgressIndicator(context);
    getData();
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: Colors.grey[900],
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            'This action will delete this folder and all its contents. Continue?',
            style: TextStyle(color: Colors.white, fontSize: 17),
          ),
        ],
      ),
      actions: [
        TextButton(
          child: Text('No',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w500)),
          onPressed: () {
            Navigator.pop(context);
          },
        ),
        TextButton(
          child: Text(
            'Yes',
            style: TextStyle(
                fontSize: 18, color: Colors.red, fontWeight: FontWeight.w500),
          ),
          onPressed: () {
            deleteFolder();
          },
        ),
      ],
    );
  }
}