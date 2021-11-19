import 'dart:async';
import 'dart:io';

final HOME_DIR = Platform.environment['HOME'].toString();
var WALLS_DIR = Directory(Directory.current.path + '/.walls/');

void main(List<String>? args) async {
  final String argsUrl = (args ?? [])
      .firstWhere((key) => key.indexOf('http') == 0, orElse: () => '');

  var autoChangeFlag = (args ?? []).indexOf('-t');

  var url = argsUrl.isEmpty
      ? Uri.parse('https://source.unsplash.com/random')
      : Uri.parse(argsUrl);

  if (autoChangeFlag >= 0) {
    var timeout = 10;
    if ((args ?? []).length > autoChangeFlag + 1) {
      timeout = int.tryParse((args ?? [])[autoChangeFlag + 1]) ?? 10;
    }
    setWallpaper(url);
    Timer.periodic(Duration(minutes: timeout), (timer) {
      setWallpaper(url);
    });
  } else {
    setWallpaper(url);
    exit(0);
  }
}

Future<void> setWallpaper(Uri url) async {
  if ((await WALLS_DIR.exists())) {
    await WALLS_DIR.delete(recursive: true);
  }
  var originalUrl =
      Uri.parse(Uri.decodeComponent(await getRedirectedUrl(url.toString())));
  if (originalUrl.host.indexOf('unsplash') > 0) {
    originalUrl = Uri(
        scheme: originalUrl.scheme,
        userInfo: originalUrl.userInfo,
        host: originalUrl.host,
        port: originalUrl.port,
        path: originalUrl.path,
        queryParameters: {...originalUrl.queryParameters, 'force': 'true'}
          ..remove('w'),
        fragment: originalUrl.fragment);
  }
  var newImgPath = await saveImageFromUrl(originalUrl.toString());
  await wallsDbExec('insert into data values("${newImgPath}");');
  final newEntry = (await wallsDbExec('select max(rowid) from data;')).trim();
  final pictures =
      (await wallsDbExec('select rowid from pictures;')).split('\n').toList();
  var sql = 'delete from preferences; ';

  pictures.forEach((pic) {
    if (pic.isNotEmpty) {
      sql += 'insert into preferences (key, data_id, picture_id)';
      sql += 'values(1, ${newEntry}, ${pic}); ';
    }
  });
  await wallsDbExec(sql);
  await Process.run('killall', ['Dock']);
}

Future<String> saveImageFromUrl(String url) async {
  var wallsDir = WALLS_DIR;
  if (!(await wallsDir.exists())) {
    await wallsDir.create();
  }
  var wallName = 'pic_${DateTime.now().millisecondsSinceEpoch.toString()}.jpg';
  final wallFile = File('${wallsDir.path}${wallName}');
  final request = await HttpClient().getUrl(Uri.parse(url));
  final response = await request.close();

  var fileStream = wallFile.openWrite();
  await response.pipe(fileStream);
  await fileStream.close();

  return wallFile.path;
}

Future<String> wallsDbExec(String query) async {
  var dbFile = '${HOME_DIR}/Library/Application Support/Dock/desktoppicture.db';
  var result = await Process.run('sqlite3', [dbFile, query]);

  return result.stdout.toString();
}

Future<String> getRedirectedUrl(String url) async {
  var req = await HttpClient().getUrl(Uri.parse(url));
  req.followRedirects = false;
  var res = await req.close();
  var targetUrl = res.headers['location']?.first.toString() ?? '';
  targetUrl = targetUrl.isNotEmpty ? targetUrl : url;
  return targetUrl;
}
