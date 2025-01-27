import 'dart:io';
import 'dart:math';

import 'package:audio_service/audio_service.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:audio_session/audio_session.dart' as asp;
import 'package:flutter/material.dart';
import 'package:flutter_radio/flutter_radio.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:mp3_music_converter/database/model/song.dart';
import 'package:mp3_music_converter/database/repository/song_repository.dart';
import 'package:mp3_music_converter/screens/world_radio/radio_class.dart';
import 'package:syncfusion_flutter_pdf/pdf.dart';
import '../../../utils/helper/instances.dart';

enum PlayerType { ALL, SHUFFLE, REPEAT }

void _entryPoint() {
  AudioServiceBackground.run(() => AudioPlayerTask());
}

//controls which background task is running (if music or pdf reader)
bool isPlayingMusic = true;

Future<dynamic> addActionToAudioService(Function callback) async {
  if (!AudioService.connected) await AudioService.connect();
  if (AudioService.running == null || !AudioService.running) {
    await AudioService.start(backgroundTaskEntrypoint: _entryPoint);
  }
  return callback();
}

class AudioPlayerTask extends BackgroundAudioTask {
  AudioPlayer audioPlayer;
  AudioPlayer musicPlayer;
  AudioPlayer vocalPlayer;
  FlutterTts flutterTts = FlutterTts();
  // PlayerFunction playerFunction = PlayerFunction.MUSIC;

  //audioplayer for playing the main songs
  static const POSITION_EVENT = 'POSITION_EVENT';
  static const DURATION_EVENT = 'DURATION_EVENT';
  static const STATE_CHANGE = 'STATE_CHANGE';
  static const STATE_CHANGE2 = 'STATE_CHANGE2';
  static const PLAY_ACTION = 'PLAY_ACTION';
  static const CHANGE_TYPE = 'CHANGE_TYPE';
  static const SEEK = 'SEEK';
  static const SET_VOLUME = 'SET_VOLUME';

//musicplayer for playing the instrumentals
  static const POSITION = 'POSITION';
  static const DURATION = 'DURATION';
  static const STATE = 'STATE';
  static const COMPLETION = 'COMPLETION';
  static const VOLUME = 'volume';
  static const PLAY = 'play';
  static const RESUME = 'resume';
  static const PAUSE = 'pause';
  static const STOP = 'stop';
  static const SEEK_TO = 'seek_to';

  //vocalplayer for playing vocals
  static const VOCAL_VOLUME = 'vocal_volume';

  //change from tts to music
  static const CHANGEPLAYERFUNCTION = 'change_player_function';

  //flutterTts for reading books
  static const TtsSPEAK = 'ttsSpeak';
  static const TtsSTOP = 'ttsStop';
  static const TtsIsPlaying = 'ttsIsPlaying';
  static const TtsCompletion = 'ttsCompletionHandler';
  static const TtsSetVoice = 'ttsSetVoice';
  static const TtsSetPitch = 'ttsSetPitch';
  static const TtsSetSpeechRate = 'ttsSetSpeechRate';
  static const TtsOnError = 'ttsOnError';

  static const SongIndex = 'songIndex';

  int index;
  PlayerType playerType = PlayerType.ALL;
  asp.AudioSession audioSession;
  asp.AudioSession audioSession2;
  String identity;
  bool playVocals = false;

  void initPlayer() {
    audioPlayer = AudioPlayer();
    musicPlayer = AudioPlayer();
    vocalPlayer = AudioPlayer();

    audioPlayer.onPlayerCompletion.listen((event) async {
      List<MediaItem> mediaItems = AudioServiceBackground.queue;

      switch (playerType) {
        case PlayerType.ALL:
          if (index != null && index < mediaItems.length - 1) {
            index = index + 1;
            AudioServiceBackground.setMediaItem(mediaItems[index]);
            AudioService.customAction(PLAY_ACTION);
          } else {
            audioPlayer.state = AudioPlayerState.STOPPED;
          }
          break;
        case PlayerType.SHUFFLE:
          playRandom(mediaItems);
          break;
        case PlayerType.REPEAT:
          AudioService.customAction(PLAY_ACTION);
          break;
      }

      await _broadcastState();
    });

    audioPlayer.onPlayerStateChanged.listen((event) async {
      AudioServiceBackground.sendCustomEvent({STATE_CHANGE: event});
      await _broadcastState();
    });

    audioPlayer.onAudioPositionChanged.listen((position) async {
      AudioServiceBackground.sendCustomEvent(
          {POSITION_EVENT: position.inSeconds});
      await _broadcastState();
    });

    audioPlayer.onDurationChanged.listen((duration) async {
      AudioServiceBackground.sendCustomEvent(
          {DURATION_EVENT: duration.inSeconds});
      AudioServiceBackground.setMediaItem(
          AudioServiceBackground.mediaItem.copyWith(duration: duration));
      AudioServiceBackground.sendCustomEvent(
          {STATE_CHANGE2: audioPlayer.state});
      await _broadcastState();
    });

    musicPlayer.onPlayerCompletion.listen((event) async {
      musicPlayer.state = AudioPlayerState.STOPPED;
      if (playVocals) vocalPlayer.state = AudioPlayerState.STOPPED;
      AudioServiceBackground.sendCustomEvent(
          {COMPLETION: true, 'identity': identity});
      await _broadcastState();
    });

    musicPlayer.onPlayerStateChanged.listen((event) async {
      AudioServiceBackground.sendCustomEvent(
          {STATE: event, 'identity': identity});
      await _broadcastState();
    });

    musicPlayer.onAudioPositionChanged.listen((position) async {
      AudioServiceBackground.sendCustomEvent(
          {POSITION: position.inSeconds, 'identity': identity});
      await _broadcastState();
    });

    musicPlayer.onDurationChanged.listen((duration) async {
      AudioServiceBackground.sendCustomEvent(
          {DURATION: duration.inSeconds, 'identity': identity});

      await _broadcastState();
    });
  }

  AudioProcessingState _getProcessingState() {
    switch (audioPlayer.state) {
      case AudioPlayerState.STOPPED:
        return AudioProcessingState.stopped;
        break;
      case AudioPlayerState.PLAYING:
        return AudioProcessingState.ready;
        break;
      case AudioPlayerState.PAUSED:
        return AudioProcessingState.ready;
        break;
      case AudioPlayerState.COMPLETED:
        return AudioProcessingState.completed;
        break;
      default:
        return AudioProcessingState.ready;
    }
  }

  Future<void> _broadcastState() async {
    await AudioServiceBackground.setState(
      controls: [
        MediaControl.skipToPrevious,
        audioPlayer.state == AudioPlayerState.PLAYING
            ? MediaControl.pause
            : MediaControl.play,
        MediaControl.stop,
        MediaControl.skipToNext
      ],
      playing: audioPlayer.state == AudioPlayerState.PLAYING,
      processingState: _getProcessingState(),
    );
  }

  void handleInterruptions(
      asp.AudioSession audioSession, bool normalPlayer) async {
    bool interrupted = false;
    audioSession?.becomingNoisyEventStream?.listen((event) async {
      if (normalPlayer)
        await onPause();
      else
        AudioService.customAction(PAUSE);
    });

    if (normalPlayer) {
      audioPlayer.onPlayerStateChanged.listen((event) {
        interrupted = false;
        if (event == AudioPlayerState.PLAYING) {
          if (musicPlayer.state == AudioPlayerState.PLAYING)
            AudioService.customAction(PAUSE);
          audioSession.setActive(true);
        }
      });
    } else {
      musicPlayer.onPlayerStateChanged.listen((event) {
        interrupted = false;
        if (event == AudioPlayerState.PLAYING) {
          if (audioPlayer.state == AudioPlayerState.PLAYING) onPause();
          audioSession.setActive(true);
        }
      });
    }

    audioSession.interruptionEventStream.listen((event) async {
      if (event.begin) {
        if (audioPlayer.state == AudioPlayerState.PLAYING ||
            musicPlayer.state == AudioPlayerState.PLAYING) {
          switch (event.type) {
            case asp.AudioInterruptionType.duck:
              if (audioSession.androidAudioAttributes.usage ==
                  asp.AndroidAudioUsage.game) if (normalPlayer)
                await AudioService.customAction(SET_VOLUME, 0.3);
              else
                await AudioService.customAction(VOLUME, 0.3);
              interrupted = false;
              break;
            case asp.AudioInterruptionType.pause:
            case asp.AudioInterruptionType.unknown:
              if (normalPlayer)
                await onPause();
              else
                AudioService.customAction(PAUSE);
              interrupted = true;
              break;
          }
        }
      } else {
        switch (event.type) {
          case asp.AudioInterruptionType.duck:
            if (normalPlayer)
              await AudioService.customAction(SET_VOLUME, 1);
            else
              await AudioService.customAction(VOLUME, 1);
            interrupted = false;
            break;
          case asp.AudioInterruptionType.pause:
          case asp.AudioInterruptionType.unknown:
            if (interrupted) {
              if (normalPlayer) {
                if (musicPlayer.state == AudioPlayerState.PLAYING)
                  AudioService.customAction(PAUSE);
                await onPlay();
              } else {
                if (audioPlayer.state == AudioPlayerState.PLAYING)
                  await onPause();
                AudioService.customAction(RESUME);
              }
              interrupted = false;
            }
            break;
        }
      }
    });
  }

  @override
  Future<void> onStart(Map<String, dynamic> params) async {
    initPlayer();
    await _broadcastState();
    return super.onStart(params);
  }

  @override
  Future<void> onTaskRemoved() async {
    await onStop();
    await super.onTaskRemoved();
  }

  @override
  Future<void> onStop() async {
    // if (playerFunction == PlayerFunction.MUSIC) {
    await audioPlayer.stop();
    await vocalPlayer.stop();
    await musicPlayer.stop();
    await super.onStop();
    // } else {
    //   await flutterTts.stop();
    //   AudioServiceBackground.sendCustomEvent({TtsIsPlaying: false});
    // }

    await _broadcastState();
  }

  @override
  Future<void> onClose() async {}

  @override
  Future<void> onPlay() async {
    await super.onPlay();
    if (musicPlayer.state == AudioPlayerState.PLAYING)
      await audioPlayer.pause();
    await audioPlayer.resume();
    await _broadcastState();
  }

  @override
  Future<void> onSkipToQueueItem(String mediaId) {
    List<MediaItem> mediaItems = AudioServiceBackground.queue;
    MediaItem mediaItem =
        mediaItems.firstWhere((element) => element.id == mediaId);
    AudioServiceBackground.setMediaItem(mediaItem);
    return super.onSkipToQueueItem(mediaId);
  }

  void playRandom(List<MediaItem> songs) {
    Random r = new Random();
    int songIndex = r.nextInt(songs.length);
    index = songIndex;
    AudioServiceBackground.setMediaItem(songs[index]);
    AudioService.customAction(PLAY_ACTION);
  }

  @override
  Future<void> onSkipToNext() async {
    List<MediaItem> mediaItems = AudioServiceBackground.queue;

    if (playerType == PlayerType.SHUFFLE) {
      Random r = new Random();
      int songIndex = r.nextInt(mediaItems.length);
      index = songIndex;
      AudioServiceBackground.setMediaItem(mediaItems[index]);
      AudioService.customAction(PLAY_ACTION);
    } else {
      if (index != null && index < mediaItems.length - 1) {
        index = index + 1;
        AudioServiceBackground.setMediaItem(mediaItems[index]);
        AudioService.customAction(PLAY_ACTION);
      }
    }
  }

  @override
  Future<void> onSkipToPrevious() async {
    List<MediaItem> mediaItems = AudioServiceBackground.queue;

    if (playerType == PlayerType.SHUFFLE) {
      Random r = new Random();
      int songIndex = r.nextInt(mediaItems.length);
      index = songIndex;
      AudioServiceBackground.setMediaItem(mediaItems[index]);
      AudioService.customAction(PLAY_ACTION);
    } else {
      if (index != null && index > 0) {
        index = index - 1;
        AudioServiceBackground.setMediaItem(mediaItems[index]);
        AudioService.customAction(PLAY_ACTION);
      }
    }
  }

  @override
  Future<void> onPause() async {
    await audioPlayer.pause();
    await super.onPause();
    await _broadcastState();
  }

  @override
  Future onCustomAction(String name, arguments) async {
    if (name == PLAY_ACTION) {
      List<MediaItem> mediaItems = AudioServiceBackground.queue;
      MediaItem mediaItem = AudioServiceBackground.mediaItem;

      if (mediaItems != null && mediaItems.isNotEmpty)
        index = mediaItems.indexWhere((element) => element.id == mediaItem.id);
      AudioServiceBackground.sendCustomEvent({SongIndex: index});
      if (musicPlayer.state == AudioPlayerState.PLAYING) {
        await musicPlayer.stop();
        if (playVocals) await vocalPlayer.stop();
      }
      if (await FlutterRadio?.isPlaying()) await FlutterRadio.stop();

      audioSession = await asp.AudioSession.instance;
      audioSession
          .configure(asp.AudioSessionConfiguration.music())
          .then((value) async {
        handleInterruptions(audioSession, true);

        if (await audioSession.setActive(true)) {
          await audioPlayer.play(
            mediaItem.id,
            isLocal: true,
            position: Duration(seconds: 0),
          );
        } else {
          print('could not play');
        }
      });
    }
    if (name == CHANGE_TYPE) {
      if (arguments == 'ALL') playerType = PlayerType.ALL;
      if (arguments == 'SHUFFLE') playerType = PlayerType.SHUFFLE;
      if (arguments == 'REPEAT') playerType = PlayerType.REPEAT;
    }

    if (name == SET_VOLUME) {
      audioPlayer.setVolume(arguments);
    }
    if (name == SEEK) {
      Duration newDuration = Duration(seconds: arguments);
      audioPlayer.seek(newDuration);
    }
    if (name == PLAY) {
      identity = arguments['identity'];
      playVocals = arguments['playVocals'] ?? false;
      if (audioPlayer.state == AudioPlayerState.PLAYING)
        await audioPlayer.pause();
      if (await FlutterRadio?.isPlaying()) await FlutterRadio.stop();
      audioSession2 = await asp.AudioSession.instance;

      audioSession2.configure(asp.AudioSessionConfiguration.music()).then(
        (value) async {
          handleInterruptions(audioSession2, false);
          if (await audioSession2.setActive(true)) {
            await musicPlayer.play(arguments['url'],
                isLocal: true, position: Duration(seconds: 0));
            if (playVocals)
              await vocalPlayer.play(arguments['path'],
                  isLocal: true, position: Duration(seconds: 0));
          }
        },
      );
    }
    if (name == PAUSE) {
      await musicPlayer.pause();
      if (playVocals) await vocalPlayer.pause();
    }
    if (name == RESUME) {
      if (audioPlayer.state == AudioPlayerState.PLAYING)
        await audioPlayer.pause();
      await musicPlayer.resume();
      if (playVocals) await vocalPlayer.resume();
    }
    if (name == STOP) {
      await musicPlayer.stop();
      if (playVocals) await vocalPlayer.stop();
    }
    if (name == SEEK_TO) {
      Duration newDuration = Duration(seconds: arguments);
      musicPlayer.seek(newDuration);
      if (playVocals) vocalPlayer.seek(newDuration);
    }
    if (name == VOLUME) {
      await musicPlayer.setVolume(arguments);
      if (playVocals) await vocalPlayer.setVolume(arguments);
    }

    if (name == VOCAL_VOLUME) {
      await vocalPlayer.setVolume(arguments);
    }
    // if (name == CHANGEPLAYERFUNCTION) {
    //   if (arguments == 'TTS')
    //     playerFunction = PlayerFunction.TTS;
    //   else
    //     playerFunction = PlayerFunction.MUSIC;
    // }
    if (name == TtsSetVoice) {
      await flutterTts
          .setVoice({'name': arguments['name'], 'locale': arguments['locale']});
    }
    if (name == TtsSetPitch) {
      await flutterTts.setPitch(arguments);
    }
    if (name == TtsSetSpeechRate) {
      await flutterTts.setSpeechRate(arguments);
    }
    if (name == TtsSPEAK) {
      AudioServiceBackground.sendCustomEvent({TtsIsPlaying: true});
      AudioServiceBackground.sendCustomEvent({TtsCompletion: false});
      String text;
      PdfDocument doc;

      MediaItem mediaItem = MediaItem(
          id: 'whatever', album: '', title: arguments['title'] ?? 'Test');
      await AudioServiceBackground.setMediaItem(mediaItem);

      if (audioPlayer.state == AudioPlayerState.PLAYING)
        await audioPlayer.stop();
      if (musicPlayer.state == AudioPlayerState.PLAYING) {
        await musicPlayer.stop();
        if (playVocals) await vocalPlayer.stop();
      }
      if (await FlutterRadio?.isPlaying()) await FlutterRadio.stop();

      audioSession = await asp.AudioSession.instance;
      audioSession
          .configure(asp.AudioSessionConfiguration.music())
          .then((value) async {
        // handleInterruptions(audioSession, true);

        if (arguments['text'] == null) {
          doc = PdfDocument(
              inputBytes: File(arguments['path']).readAsBytesSync());
          text = PdfTextExtractor(doc).extractText(
              startPageIndex: arguments['page'] - 1,
              endPageIndex: arguments['page'] - 1);
        } else {
          text = arguments['text'];
        }

        if (await audioSession.setActive(true)) {
          if (text != null && text.isNotEmpty) {
            await flutterTts.awaitSpeakCompletion(true);
            flutterTts.speak(text);
          } else
            flutterTts.completionHandler();
        }
      });
    }
    if (name == TtsSTOP) {
      await flutterTts.stop();
      AudioServiceBackground.sendCustomEvent({TtsIsPlaying: false});
    }

    await _broadcastState();
    return super.onCustomAction(name, arguments);
  }

  @override
  Future<void> onUpdateQueue(List<MediaItem> queue) async {
    await AudioServiceBackground.setQueue(queue);
    await _broadcastState();
    return super.onUpdateQueue(queue);
  }

  @override
  Future<void> onUpdateMediaItem(MediaItem mediaItem) async {
    await AudioServiceBackground.setMediaItem(mediaItem);
    await _broadcastState();
    return super.onUpdateMediaItem(mediaItem);
  }
}

class MusicProvider with ChangeNotifier {
  Duration totalDuration = Duration();
  Duration progress = Duration();
  Song currentSong;
  Song drawerItem;
  List<Song> songs = [];
  List<Song> allSongs = [];
  List playLists = [];
  List playListSongTitle = [];
  List<Song> favoriteSongs = [];
  bool shuffleSong = false;
  bool repeatSong = false;
  int _currentSongIndex = -1;
  int get length => songs.length;
  int get songNumber => _currentSongIndex + 1;
  String currentSongID = '';
  AudioPlayerState audioPlayerState;
  // String sharedText = '';
  BuildContext context;

  void setContext(BuildContext context) {
    this.context = context;
  }

  void openRadioPage(String search) {
    Navigator.push(
        context,
        MaterialPageRoute(
            builder: (_) => RadioClass(
                  search: search,
                )));
  }

  //this controls the navigation bar index
  int currentNavBarIndex = 0;

  //this function updates the currentIndex
  void updateCurrentIndex(int index) {
    this.currentNavBarIndex = index;
    notifyListeners();
  }

  // void updateSharedText(String shared) {
  //   sharedText = shared;
  // }

  Future<void> initProvider() async {
    SongRepository.init();
    await initPlayer();
  }

  savePlayingSong(Song song) async {
    preferencesHelper.saveValue(key: 'last_play', value: song.toJson());
  }

  savePlayingQueue() {
    List<String> data = [];
    for (int i = 0; i < songs.length; i++) {
      data.add(songs[i].musicid);
    }
    preferencesHelper.saveValue(key: 'last_play_queue', value: data);
    print('done');
  }

  Future<void> getSongs() async {
    allSongs = await SongRepository.getSongs();
    allSongs.sort(
        (a, b) => a.songName.toLowerCase().compareTo(b.songName.toLowerCase()));
    notifyListeners();
  }

  getPlayListNames() async {
    playLists = await SongRepository.getPlayListNames();
    notifyListeners();
  }

  getPlayListSongTitle(key) async {
    playListSongTitle = await SongRepository.getPlayListsSongs(key);
    notifyListeners();
  }

  getFavoriteSongs() async {
    favoriteSongs = await SongRepository.getFavoriteSongs();
    notifyListeners();
  }

  updateSong(Song song) {
    songs.forEach((element) {
      if (element.fileName == song.fileName) {
        element = song;
      }
    });
    SongRepository.addSong(song);
    notifyListeners();
  }

  Future<void> initPlayer() async {
    await AudioService.start(
      backgroundTaskEntrypoint: _entryPoint,
      androidStopForegroundOnPause: true,
      androidShowNotificationBadge: true,
    );
    AudioService.customEventStream.listen((event) async {
      if (isPlayingMusic) {
        if (event[AudioPlayerTask.DURATION_EVENT] != null) {
          totalDuration =
              Duration(seconds: event[AudioPlayerTask.DURATION_EVENT]) ??
                  Duration();

          if (songs == null || songs.isEmpty)
            songs = convertMediaItemToSong(
                AudioService.queue ?? [AudioService.currentMediaItem]);
          if (currentSong == null) {
            currentSong = Song(
                artistName: AudioService.currentMediaItem.artist,
                fileName: AudioService.currentMediaItem.extras['fileName'],
                favorite: AudioService.currentMediaItem.extras['favourite'],
                filePath: AudioService.currentMediaItem.extras['filePath'],
                image: AudioService.currentMediaItem.extras['image'],
                size: AudioService.currentMediaItem.extras['size'],
                songName: AudioService.currentMediaItem.title,
                musicid: AudioService.currentMediaItem.extras['musicid']);
          }

          notifyListeners();
        }
        if (event[AudioPlayerTask.POSITION_EVENT] != null) {
          progress = Duration(seconds: event[AudioPlayerTask.POSITION_EVENT]) ??
              Duration();
          notifyListeners();
        }
        if (event[AudioPlayerTask.STATE_CHANGE] != null) {
          audioPlayerState = event[AudioPlayerTask.STATE_CHANGE];

          notifyListeners();
        }
        if (event[AudioPlayerTask.STATE_CHANGE2] != null) {
          audioPlayerState = event[AudioPlayerTask.STATE_CHANGE2];
          notifyListeners();
        }
        if (event[AudioPlayerTask.SongIndex] != null) {
          _currentSongIndex = event[AudioPlayerTask.SongIndex];
          notifyListeners();
        }
      }
    });

    AudioService.currentMediaItemStream.listen((event) {
      if (event != null && isPlayingMusic) {
        currentSongID = event.id;
        currentSong = songs.firstWhere((element) => element.file == event.id,
            orElse: () => Song(
                artistName: event.artist,
                fileName: event.extras['fileName'],
                favorite: event.extras['favourite'],
                filePath: event.extras['filePath'],
                image: event.extras['image'],
                size: event.extras['size'],
                songName: event.title,
                musicid: event.extras['musicid']));
        savePlayingSong(currentSong);
        updateDrawer(currentSong);
      }

      notifyListeners();
    });
  }

  void updateLocal(MediaItem song) async {
    if (audioPlayerState != AudioPlayerState.PLAYING &&
        audioPlayerState != AudioPlayerState.PAUSED) {
      progress = Duration();
      totalDuration = Duration();
      currentSong = songs.firstWhere((element) => element.file == song.id,
          orElse: () => Song(
                artistName: song.artist,
                fileName: song.extras['fileName'],
                favorite: song.extras['favourite'],
                filePath: song.extras['filePath'],
                image: song.extras['image'],
                musicid: song.extras['musicid'],
                size: song.extras['size'],
                songName: song.title,
              ));

      print(currentSong.songName);
      if (songs.isNotEmpty)
        await addActionToAudioService(() async =>
            await AudioService.updateQueue(convertSongToMediaItem(songs)));
      await addActionToAudioService(
          () async => await AudioService.updateMediaItem(song));
      notifyListeners();
    }
  }

  void updateDrawer(Song log) {
    drawerItem = log;
  }

  void seekToSecond(int second) {
    AudioService.customAction(AudioPlayerTask.SEEK, second);
  }

  List<MediaItem> convertSongToMediaItem(List<Song> songs) {
    List<MediaItem> item = [];
    for (int i = 0; i < songs.length; i++) {
      item.insert(
        i,
        MediaItem(
          artist: songs[i].artistName ?? 'Unknown artist',
          title: songs[i].songName ?? 'Unknown',
          id: songs[i].file,
          album: songs[i].songName ?? 'Unknown',
          extras: {
            'image': songs[i].image,
            'filePath': songs[i].filePath,
            'fileName': songs[i].fileName,
            'favourite': songs[i].favorite,
            'musicid': songs[i].musicid,
            'size': songs[i].size,
          },
        ),
      );
    }
    return item;
  }

  List<Song> convertMediaItemToSong(List<MediaItem> items) {
    List<Song> playingSongs = [];
    for (int i = 0; i < items.length; i++) {
      playingSongs.insert(
          i,
          Song(
              artistName: items[i].artist,
              songName: items[i].title,
              fileName: items[i].extras['fileName'],
              filePath: items[i].extras['filePath'],
              favorite: items[i].extras['favourite'],
              musicid: items[i].extras['musicid'],
              size: items[i].extras['size'],
              image: items[i].extras['image']));
    }
    return playingSongs;
  }

  void playAudio(Song song, {bool force = false}) async {
    if (song != null) {
      currentSong = song;
      savePlayingSong(song);
      savePlayingQueue();
      if (song.file == currentSongID && force == false) return;
      await addActionToAudioService(() async =>
          await AudioService.updateQueue(convertSongToMediaItem(songs)));
      await addActionToAudioService(
          () async => await AudioService.skipToQueueItem(song.file));
      await addActionToAudioService(() async =>
          await AudioService.customAction(AudioPlayerTask.PLAY_ACTION));
      notifyListeners();
    }
  }

  void resumeAudio() async {
    await addActionToAudioService(() async => await AudioService.play());
    notifyListeners();
  }

  void pauseAudio() async {
    await addActionToAudioService(() async => await AudioService.pause());
    notifyListeners();
  }

  Future next() async {
    await addActionToAudioService(() async => await AudioService.skipToNext());
    notifyListeners();
  }

  Future prev() async {
    await addActionToAudioService(
        () async => await AudioService.skipToPrevious());
    notifyListeners();
  }

  Future shuffle(bool force) async {
    shuffleSong = true;
    await addActionToAudioService(() async => await AudioService.customAction(
        AudioPlayerTask.CHANGE_TYPE, 'SHUFFLE'));
    if (force) {
      Random r = new Random();
      int songIndex = r.nextInt(songs.length);
      playAudio(songs[songIndex]);
    }
    notifyListeners();
  }

  Future stopShuffle() async {
    shuffleSong = false;
    await addActionToAudioService(
        () => AudioService.customAction(AudioPlayerTask.CHANGE_TYPE, 'ALL'));
    notifyListeners();
  }

  Future repeat(Song song) async {
    repeatSong = true;
    await addActionToAudioService(
        () => AudioService.customAction(AudioPlayerTask.CHANGE_TYPE, 'REPEAT'));
    notifyListeners();
  }

  Future undoRepeat() async {
    repeatSong = false;
    await addActionToAudioService(
        () => AudioService.customAction(AudioPlayerTask.CHANGE_TYPE, 'ALL'));
    notifyListeners();
  }

  handlePlaying() async {
    switch (audioPlayerState) {
      case AudioPlayerState.STOPPED:
        updateAndPlay();
        break;
      case AudioPlayerState.PAUSED:
        resumeAudio();
        break;
      case AudioPlayerState.PLAYING:
        pauseAudio();
        break;
      case AudioPlayerState.COMPLETED:
        updateAndPlay();
        break;
      default:
        updateAndPlay();
    }
  }

  updateAndPlay() async {
    if (currentSong != null && songs.isEmpty) {
      await addActionToAudioService(
        () async => await AudioService.updateMediaItem(
          MediaItem(
            artist: currentSong.artistName ?? 'Unknown artist',
            title: currentSong.songName ?? 'Unknown',
            id: currentSong.file,
            album: currentSong.songName ?? 'Unknown',
            extras: {
              'image': currentSong.image,
              'filePath': currentSong.filePath,
              'fileName': currentSong.fileName,
              'favourite': currentSong.favorite,
              'size': currentSong.size,
              'musicid': currentSong.musicid,
            },
          ),
        ),
      );
      await addActionToAudioService(
        () => AudioService.customAction(AudioPlayerTask.PLAY_ACTION),
      );
    }
    if (currentSong != null && songs.isNotEmpty) {
      await addActionToAudioService(
        () async => await AudioService.updateQueue(
          convertSongToMediaItem(songs),
        ),
      );
      await addActionToAudioService(
        () async => await AudioService.skipToQueueItem(currentSong.file),
      );
      await addActionToAudioService(
        () => AudioService.customAction(AudioPlayerTask.PLAY_ACTION),
      );
    }
  }

  setCurrentIndex(int index) {
    _currentSongIndex = index;
  }

  int get currentIndex => _currentSongIndex;

  bool get canNextSong => _currentSongIndex == length - 1;
  bool get canPrevSong => _currentSongIndex == 0;
}
