import 'dart:convert';
import 'package:mysql1/mysql1.dart';
import 'package:shelf/shelf.dart';
import 'package:intl/intl.dart';
import 'produk.dart';

class Controller {
  /* Koneksi SQL */
  Future<MySqlConnection> connectSql() async {
    var pengaturan = ConnectionSettings(
        host: '127.0.0.1',
        port: 3306,
        user: 'dart3',
        password: 'password',
        db: 'toko_komputer');
    var koneksi = await MySqlConnection.connect(pengaturan);
    return koneksi;
  }

  /* USER -> CRUD */
  Future<Response> getProdukData(Request request) async {
    var koneksi = await connectSql();
    var sql = "SELECT * FROM Produk";
    var produk = await koneksi.query(sql, []);

    var respons = _responsPesanSukses(produk.toString());
    return Response.ok(respons.toString());
  }

  Future<Response> getProdukDataWithAuth(Request request) async {
    final isValidRequest = await _isValidRequestHeader(request);
    if (!isValidRequest) {
      var respons = _responsPesanError('Token Tidak Valid');
      return Response.forbidden(jsonEncode(respons));
    }

    var koneksi = await connectSql();
    var sql = "SELECT * FROM Produk";
    var data = await koneksi.query(sql, []);

    final List<Map<String, dynamic>> listProduk = [];

    for (var row in data) {
      var produk = {
        "id": row["id"],
        "nama": row["nama"],
        "harga": row["harga"],
        "stok": row["stok"],
        "kategori": row["kategori"],
        "supplier": row["supplier"],
        "created": row["created"],
      };
      listProduk.add(produk);
    }

    var respons = jsonEncode(_responsPesanSukses(listProduk));
    return Response.ok(respons.toString());
  }

  Future<Response> getUserDataFilter(Request request) async {
    String body = await request.readAsString();
    var obj = json.decode(body);
    var nama = "%" + obj['nama'] + "%";

    var koneksi = await connectSql();
    var sql = "SELECT * FROM USER WHERE nama like ?";
    var user = await koneksi.query(sql, [nama]);
    var respons = _responsPesanSukses(user.toString());
    return Response.ok(respons.toString());
  }

  Future<Response> postProdukData(Request request) async {
    String body = await request.readAsString();
    Produk produk = Produk.fromJson(json.decode(body) as Map<String, dynamic>);

    if (!_isValid(produk)) {
      return Response.badRequest(
          body: _responsPesanError('Error saat validasi data masukan'));
    }

    produk.created = getDateNow();
    produk.modified = getDateNow();

    var koneksi = await connectSql();
    var sqlExecute = """
      INSERT INTO produk (id, nama, harga, stok, kategori,
      supplier, created, modified)
      VALUES
      (
      '${produk.id}',
      '${produk.nama}','${produk.harga}','${produk.stok}','${produk.kategori}',
      '${produk.supplier}','${produk.created}','${produk.modified}'
      )
    """;

    await koneksi.query(sqlExecute, []);

    var sql = "SELECT * FROM PRODUK WHERE nama = ?";
    var responsProduk = await koneksi.query(sql, [produk.nama]);

    var respons = _responsPesanSukses(responsProduk.toString());
    return Response.ok(respons.toString());
  }

  Future<Response> putProdukData(Request request) async {
    String body = await request.readAsString();
    Produk produk = Produk.fromJson(json.decode(body) as Map<String, dynamic>);

    if (!_isValid(produk)) {
      return Response.badRequest(
          body: _responsPesanError('Error saat validasi data masukan'));
    }

    produk.modified = getDateNow();

    var koneksi = await connectSql();
    var sqlExecute = """
      UPDATE produk SET
      nama ='${produk.nama}', harga = '${produk.harga}',
      stok = '${produk.stok}', kategori = '${produk.kategori}',
      modified='${produk.modified}'
      WHERE id ='${produk.id}'
    """;

    await koneksi.query(sqlExecute, []);

    var sql = "SELECT * FROM PRODUK WHERE id = ?";
    var produkUpdate = await koneksi.query(sql, [produk.id]);

    var respons = _responsPesanSukses(produkUpdate.toString());
    return Response.ok(respons.toString());
  }

  Future<Response> deleteProduk(Request request) async {
    String body = await request.readAsString();
    Produk produk = Produk.fromJson(json.decode(body) as Map<String, dynamic>);

    var koneksi = await connectSql();
    var sqlExecute = "DELETE FROM PRODUK WHERE id ='${produk.id}'";

    await koneksi.query(sqlExecute, []);

    var sql = "SELECT * FROM PRODUK WHERE id = ?";
    var responsProduk = await koneksi.query(sql, [produk.id]);

    var respons = _responsPesanSukses(responsProduk.toString());
    return Response.ok(respons.toString());
  }

  Future<Response> signUp(Request request) async {
    String body = await request.readAsString();
    var obj = json.decode(body);
    var email = "%${obj['email']}%";

    var koneksi = await connectSql();
    var sql = "SELECT * FROM PRODUK WHERE harga like ?";
    var produk = await koneksi.query(sql, [email]);
    if (produk.isNotEmpty) {
      var strBase = "";

      for (var row in produk) {
        strBase =
            '{"id": ${row["id"]},"harga": "${row["harga"]}", "kategori": "${row["kategori"]}" }';
      }

      final bytes = utf8.encode(strBase.toString());
      final base64Str = base64.encode(bytes);
      final token = "Bearer-$base64Str";
      var respons = _responsPesanSukses(token);
      return Response.ok(jsonEncode(respons));
    } else {
      var respons = _responsPesanError('User Tidak Ditemukan');
      return Response.forbidden(jsonEncode(respons));
    }
  }

  /* Tanggal dan Waktu */
  String getDateNow() {
    final DateTime sekarang = DateTime.now();
    final DateFormat formatter = DateFormat('yyyy-MM-dd HH:mm:ss');
    final String tanggalSekarang = formatter.format(sekarang);
    return tanggalSekarang;
  }

  /*
    FUNGSI UNTUK OTENTIKASI
  */

  bool _isValid(Produk produk) {
    if (produk.nama == null ||
        produk.harga == null ||
        produk.kategori == null ||
        produk.stok == null) {
      return false;
    }

    return true;
  }

  Future<bool> _isValidRequestHeader(Request request) async {
    final authHeader =
        request.headers['Authorization'] ?? request.headers['authorization'];
    final bagian = authHeader?.split('-');

    if (bagian == null || bagian.length != 2 || !bagian[0].contains('Bearer')) {
      return false;
    }

    final token = bagian[1];
    var produkValid = await _isValidToken(token);
    return produkValid;
  }

  Future<Response> getCheckAuth(Request request) async {
    String hasil = "";
    final isValidRequest = await _isValidRequestHeader(request);
    if (isValidRequest) {
      hasil = '{"isValid": true}';
      return Response.ok(hasil.toString());
    } else {
      hasil = '{"isValid": false}';
      return Response.forbidden(hasil.toString());
    }
  }

  // verifikasi token
  Future<bool> _isValidToken(String token) async {
    final str = utf8.decode(base64.decode(token));
    var obj = json.decode(str);
    var idProduk = obj['id'];

    var conn = await connectSql();
    var sql = "SELECT * FROM PRODUK WHERE id = ?";
    var produk = await conn.query(sql, [idProduk]);

    return produk.isNotEmpty;
  }
   Future<Response> generateApiKeyHandler(Request request) async {
    var apiKey = generateApiKey();
    var response = _responsPesanSukses({'api_key': apiKey});
    return Response.ok(jsonEncode(response));
  }
  
  generateApiKey() {}
}


Map<String, dynamic> _responsPesanSukses(dynamic msg) {
  return {'status': 200, 'success': true, 'data': msg};
}

Map<String, dynamic> _responsPesanError(dynamic msg) {
  return {'status': 400, 'success': false, 'data': msg};
}
