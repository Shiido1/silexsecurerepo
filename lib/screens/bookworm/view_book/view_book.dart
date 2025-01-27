import 'package:audio_service/audio_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:mp3_music_converter/screens/bookworm/model/model.dart';
import 'package:mp3_music_converter/screens/bookworm/provider/bookworm_provider.dart';
import 'package:mp3_music_converter/screens/bookworm/view_book/voice_settings.dart';
import 'package:mp3_music_converter/screens/song/provider/music_provider.dart';
import 'package:mp3_music_converter/utils/color_assets/color.dart';
import 'package:mp3_music_converter/utils/helper/instances.dart';
import 'package:mp3_music_converter/widgets/text_view_widget.dart';
import 'package:page_transition/page_transition.dart';
import 'package:pdf_render/pdf_render_widgets2.dart';
import 'package:provider/provider.dart';
import 'package:syncfusion_flutter_pdf/pdf.dart';

class ViewBook extends StatefulWidget {
  final Book book;
  ViewBook(this.book);

  @override
  _ViewBookState createState() => _ViewBookState();
}

class _ViewBookState extends State<ViewBook> {
  PdfDocument doc;
  String text;
  PdfViewerController _controller;
  BookwormProvider provider;
  // FlutterTts flutterTts;

  int currentPage;
  int page;
  bool isPlaying = false;
  bool showGoTo = false;
  bool goToPageError = true;
  int goToPage;
  bool update = true;

  getStoredSettings() async {
    Map<String, String> voice = {
      'name': 'en-gb-x-rjs-network',
      'locale': 'en-GB'
    };
    bool pitchDataExists;
    bool speechRateDataExists;
    if (await preferencesHelper.doesExists(key: 'ttsVoice')) {
      Map data = await preferencesHelper.getCachedData(key: 'ttsVoice');
      voice = {'name': data['name'], 'locale': data['locale']};
    }
    pitchDataExists = await preferencesHelper.doesExists(key: 'ttsPitch');
    speechRateDataExists = await preferencesHelper.doesExists(key: 'ttsRate');

    provider.voice = voice;

    provider.pitch = pitchDataExists
        ? await preferencesHelper.getDoubleValues(key: 'ttsPitch')
        : 1.0;

    provider.rate = speechRateDataExists
        ? await preferencesHelper.getDoubleValues(key: 'ttsRate')
        : 1.0;
  }

  // startTts() async {
  //   setState(() {
  //     isPlaying = true;
  //   });
  //   page = _controller.currentPageNumber;
  //   doc = PdfDocument(inputBytes: File(widget.book.path).readAsBytesSync());
  //   text = PdfTextExtractor(doc)
  //       .extractText(startPageIndex: page - 1, endPageIndex: page - 1);
  //   if (text != null && text.isNotEmpty) {
  //     await flutterTts.awaitSpeakCompletion(true);
  //     flutterTts.speak(text);
  //   } else
  //     flutterTts.completionHandler();
  // }

  // completionHandler() async {
  //   if (page < _controller.pageCount) {
  //     page = page + 1;
  //     doc = PdfDocument(inputBytes: File(widget.book.path).readAsBytesSync());
  //     text = PdfTextExtractor(doc)
  //         .extractText(startPageIndex: page - 1, endPageIndex: page - 1);
  //     _controller.goToPage(pageNumber: page);
  //     if (text != null && text.trim().isNotEmpty) {
  //       await flutterTts.awaitSpeakCompletion(true);
  //       await flutterTts.speak(text);
  //     } else {
  //       flutterTts.completionHandler();
  //     }
  //   } else {
  //     setState(() {
  //       isPlaying = false;
  //     });
  //   }
  // }

  // stopTts() async {
  //   await flutterTts.stop();
  //   setState(() {
  //     isPlaying = false;
  //   });
  // }

  playNextPage() async {
    if (provider.currentPage != null &&
        provider.maxPage != null &&
        provider.currentPage < provider.maxPage &&
        provider.ttsCompleted) {
      provider.ttsCompleted = false;
      provider.currentPage = provider.currentPage + 1;
      _controller.goToPage(pageNumber: provider.currentPage);

      provider.startTts(widget.book);
    } else if (provider.currentPage == provider.maxPage &&
        provider.ttsCompleted) provider.stopTts();
  }

  // initTts() async {
  //   flutterTts = FlutterTts();
  //   flutterTts.setCompletionHandler(completionHandler);
  //   flutterTts.setCancelHandler(() {
  //     setState(() {
  //       isPlaying = false;
  //     });
  //   });
  //   flutterTts.setErrorHandler((message) async {
  //     showToast(context, message: 'An error occurred while reading book');
  //     await stopTts();
  //   });
  // }

  @override
  void initState() {
    provider = Provider.of<BookwormProvider>(context, listen: false);
    // initTts();
    getStoredSettings();
    _controller = PdfViewerController();
    provider.showModal = true;

    super.initState();
  }

  stopTtsAudioBackground() async {
    await provider.stopTts();
    isPlayingMusic = true;
  }

  @override
  void deactivate() {
    update = false;
    stopTtsAudioBackground();
    super.deactivate();
  }

  @override
  void dispose() {
    _controller.removeListener(() {});
    _controller.dispose();
    // flutterTts.stop();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    BookwormProvider _bookwormProvider = Provider.of<BookwormProvider>(context);
    bool showModal = _bookwormProvider.showModal;
    playNextPage();

    return Scaffold(
      appBar: showModal
          ? AppBar(
              backgroundColor: AppColor.black,
              title: TextViewWidget(
                text: widget.book.name,
                color: AppColor.bottomRed,
                overflow: TextOverflow.ellipsis,
              ),
              leading: IconButton(
                onPressed: () {
                  Navigator.pop(context);
                },
                icon: Icon(
                  Icons.arrow_back_ios_sharp,
                  color: AppColor.bottomRed,
                ),
              ),
            )
          : PreferredSize(child: Container(), preferredSize: Size(0, 0)),
      body: Stack(
        children: [
          PdfDocumentLoader(
            filePath: widget.book.path,
            documentBuilder: (context, doc, pageCount) {
              return GestureDetector(
                onTap: () {
                  provider.updateShowModal(!provider.showModal);
                },
                child: PdfViewer(
                  filePath: widget.book.path,
                  viewerController: _controller,
                  onViewerControllerInitialized: (controller) {
                    _bookwormProvider.maxPage = _controller.pageCount;
                    _controller.addListener(() {
                      if (update) provider.updateShowModal(false);
                    });
                  },
                ),
              );
            },
          ),
          Consumer<BookwormProvider>(
            builder: (context, _provider, snapshot) {
              return _provider.showModal
                  ? Positioned(
                      bottom: 8,
                      left: 10,
                      right: 10,
                      child: Container(
                        height: 100,
                        // color: Colors.yellow,
                        decoration: BoxDecoration(
                          color: Colors.black,
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: showGoTo
                            ? goToWidget()
                            : controlButtonsWidget(_provider),
                      ),
                    )
                  : Container();
            },
          ),
        ],
      ),
    );
  }

  controlButtons(
      {@required String name,
      @required IconData icon,
      @required BookwormProvider bookProvider}) {
    return GestureDetector(
      onTap: () async {
        if (name.toLowerCase() == 'play' && !bookProvider.isPlaying) {
          if (AudioService.running != null && AudioService.running)
            await AudioService.stop();
          isPlayingMusic = false;
          bookProvider.currentPage = _controller.currentPageNumber;
          bookProvider.startTts(widget.book);
        }

        if (name.toLowerCase() == 'stop') await bookProvider.stopTts();

        if (name.toLowerCase() == 'goto')
          setState(() {
            showGoTo = true;
          });
        if (name.toLowerCase() == 'voices') {
          await bookProvider.stopTts();
          Navigator.push(
            context,
            PageTransition(
                child: VoiceSettings(), type: PageTransitionType.bottomToTop),
          );
        }
      },
      child: Container(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              color: (name.toLowerCase() == 'play' && bookProvider.isPlaying) ||
                      (name.toLowerCase() == 'stop' && !bookProvider.isPlaying)
                  ? Colors.white30
                  : Colors.white,
              size: 40,
            ),
            Text(
              name,
              style: TextStyle(
                  color: (name.toLowerCase() == 'play' &&
                              bookProvider.isPlaying) ||
                          (name.toLowerCase() == 'stop' &&
                              !bookProvider.isPlaying)
                      ? Colors.white30
                      : Colors.white,
                  fontSize: 15),
            )
          ],
        ),
      ),
    );
  }

  controlButtonsWidget(BookwormProvider bookProvider) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceAround,
      children: [
        controlButtons(
            name: 'Play',
            icon: Icons.play_arrow_rounded,
            bookProvider: bookProvider),
        controlButtons(
            name: 'Stop', icon: Icons.stop_rounded, bookProvider: bookProvider),
        controlButtons(
            name: 'GoTo',
            icon: Icons.pages_outlined,
            bookProvider: bookProvider),
        controlButtons(
            name: 'Voices',
            icon: Icons.people_outline_sharp,
            bookProvider: bookProvider)
      ],
    );
  }

  goToWidget() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        TextButton(
          onPressed: () {
            setState(() {
              showGoTo = false;
            });
          },
          child: Text(
            'Cancel',
            style: TextStyle(fontSize: 16),
          ),
        ),
        SizedBox(width: 5),
        Container(
          width: 60,
          height: 30,
          child: TextFormField(
            decoration: InputDecoration(
                hintText: 'Num',
                hintStyle: TextStyle(color: Colors.white30),
                filled: true,
                fillColor: Colors.white24,
                border: UnderlineInputBorder(),
                enabledBorder: UnderlineInputBorder(),
                focusedBorder: UnderlineInputBorder(),
                counterText: ''),
            style: TextStyle(color: Colors.white),
            keyboardType: TextInputType.number,
            autofocus: true,
            inputFormatters: [
              FilteringTextInputFormatter.digitsOnly,
            ],
            maxLength: 4,
            maxLengthEnforcement: MaxLengthEnforcement.enforced,
            onChanged: (val) {
              if (val == null ||
                  val.isEmpty ||
                  int.parse(val) > _controller.pageCount)
                setState(() {
                  goToPageError = true;
                });
              else if (val != null && val.isNotEmpty)
                setState(() {
                  goToPageError = false;
                  goToPage = int.parse(val);
                });
            },
          ),
        ),
        SizedBox(width: 5),
        Container(
          width: 40,
          child: TextFormField(
            readOnly: true,
            initialValue: '/  ' + _controller.pageCount.toString(),
            style: TextStyle(color: Colors.white, fontSize: 18),
          ),
        ),
        TextButton(
          onPressed: goToPageError
              ? null
              : () {
                  _controller.goToPage(pageNumber: goToPage);
                  setState(() {
                    showGoTo = false;
                  });
                },
          child: Text(
            'GoTo',
            style: TextStyle(
                fontSize: 17,
                color: goToPageError ? Colors.white30 : Colors.blue),
          ),
        ),
      ],
    );
  }
}
