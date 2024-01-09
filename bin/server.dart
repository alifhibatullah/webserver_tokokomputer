import 'dart:io';
import 'package:shelf/shelf.dart';
import 'package:shelf/shelf_io.dart';
import 'package:shelf_router/shelf_router.dart';
import 'article.dart'; //modeling of entity article
import 'lib/controller.dart';

List<Article> articles = [];

Future<Response> postArticleHandler(Request request) async {
  String body = await request.readAsString();

  try {
    Article article = articleFromJson(body);
    articles.add(article);
    return Response.ok(articleToJson(article));
  } catch (e) {
    return Response(400);
  }
}

Response getArticlesHandler(Request request) {
  return Response.ok(articlesToJson(articles));
}

Response rootHandler(Request req) {
  return Response.ok(
      'Hello, World Im Learning code API Web Service By Dart !\n');
}

void main(List<String> args) async {
  // Use any available host or container IP (usually `0.0.0.0`).
  final ip = InternetAddress.anyIPv4;

  final Controller ctrl = Controller();
  await ctrl.connectSql();

  // Configure routes.
  final router = Router()
    ..get('/', rootHandler)
    ..get('/articles', getArticlesHandler)
    ..post('/articles', postArticleHandler)
    ..get('/produk', ctrl.getProdukData)
    ..post('/postProdukData', ctrl.postProdukData)
    ..get('/generate-api-key', ctrl.generateApiKeyHandler);

  // Configure a pipeline that logs requests.
  final handler = Pipeline().addMiddleware(logRequests()).addHandler(router);

  // For running in containers, we respect the PORT environment variable.
  final port = int.parse(Platform.environment['PORT'] ?? '8080');
  final server = await serve(handler, ip, port);
  print('Server listening on port ${server.port}');
}
