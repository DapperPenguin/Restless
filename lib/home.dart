import 'dart:collection';
import 'dart:core';
import 'dart:io';
import 'dart:typed_data';

import 'package:audioplayers/audioplayers.dart';
import 'package:dart_tags/dart_tags.dart';
import 'package:flutter/material.dart';
import 'package:restless/artist_data.dart';
import 'package:restless/Artists/artist_page.dart';
import 'package:restless/NowPlaying/now_playing_page.dart';
import 'package:restless/Artists/artists_page_provider.dart';


class Home extends StatefulWidget
{


  @override
  HomeState createState() {
    return new HomeState();
  }
}

class HomeState extends State<Home> {

  List<ArtistData> artists = List<ArtistData>();
  String _musicDirectoryPath = '/storage/emulated/0/Music';//'/storage/emulated/0/Music/TestMusic';
  String _path = '/storage/emulated/0/Music/Carousel Casualties/Madison/Bright Red Lights.mp3';
  double artistsListOffset = 0.0;
  Future _ftr;

  Future _getArtistsInfo(String directoryPath) async
  {
    for( Directory artist in Directory(directoryPath).listSync() )
    {
      if(artist is Directory)
        print('yes');
      
      print(Directory(directoryPath).listSync().length);
      print(artist.path);
      String artistName = artist.path.substring(artist.path.lastIndexOf('/')+1);
      artists.add(ArtistData(name: artistName, albums: [AlbumData(name: '')]));
      for( var album in artist.listSync())
      {
        print('adding ' + album.path.substring(album.path.lastIndexOf('/')+1, album.path.length));
        for( var file in Directory(album.path).listSync())
        {
          if(file.path.contains('.mp3')) {
            await _getAlbumInfo(artistName, file.path);
            break;
          }
        }
      }
    }
  }

  Future _getAlbumInfo(String artist, String path) async
  {
    TagProcessor tp = TagProcessor();
    File f = File(path);
    var img = await tp.getTagsFromByteArray(f.readAsBytes());
    // print(img.toString());
    if(img.last.tags['APIC'] == null)
    {
      print('Problems with: ' + artist);
      print('::: ' + path.toString());
      return;
    }

    artists.singleWhere( (a) => a.name == artist).albums.removeWhere( (a) => a.name == '' );

    ImageProvider albumArt;
    albumArt = Image.memory(Uint8List.fromList(img.last.tags['APIC'].imageData)).image;

    if(artists.singleWhere( (a) => a.name == artist).albums == null)
      artists.singleWhere( (a) => a.name == artist).albums = [
        AlbumData(
          name: path.split('/')[path.split('/').length-2],
          albumArt: albumArt,
        )
      ];
    else
      artists.singleWhere( (a) => a.name == artist).albums.add(
          AlbumData(
            name: path.split('/')[path.split('/').length-2],
            albumArt: albumArt,
          )
      );

    print('added ' + path.split('/')[path.split('/').length-3]);

  }

  @override
  void initState() {
    super.initState();
    artists = List<ArtistData>();
    _ftr = _getArtistsInfo('/storage/emulated/0/Music/');
    print('Initialized');   
  }

  AudioPlayer audioPlayer = new AudioPlayer();
  @override
  Widget build(BuildContext context)
  {
    
    audioPlayer.setUrl(_path, isLocal: true);
    audioPlayer.setReleaseMode(ReleaseMode.STOP);

    artists.sort( (a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()) );//sort artists

    for(int i = 0; i < artists.length ; i++)
    {
      artists[i].albums.sort( (a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()));// sort albums
    }

    ArtistsPageProvider.of(context).artists = artists;

    // print(ArtistsPageProvider.of(context).artists.length);

    return FutureBuilder(
      future: _ftr,
      builder: (BuildContext context, AsyncSnapshot snapshot) {
        print('building future');
        return PageView(
          pageSnapping: true,
          physics: BouncingScrollPhysics(),
          scrollDirection: Axis.horizontal,
          children: <Widget>[
            ArtistPage(
              getOffset: () => artistsListOffset,
              setOffset: (offset) => artistsListOffset = offset,
            ),
            NowPlaying(audioPlayer: audioPlayer, path: _path,),
          ],
        );
      },
    );
  }
}