// File: product.dart

import 'dart:convert';

class Produk {
  final int id;
  final String? nama;
  final double? harga;
  final int? stok;
  final String? kategori;
  final String? supplier;
  late String created;
  late String modified;

  Produk({
    required this.id,
    required this.nama,
    required this.harga,
    required this.stok,
    required this.kategori,
    required this.supplier,
    required this.created,
    required this.modified,
  });

  Map<String, dynamic> toMap() => {
        'id': id,
        'nama': nama,
        'harga': harga,
        'stok': stok,
        'kategori': kategori,
        'supplier': supplier,
        'created': created,
        'modified': modified,
      };

  factory Produk.fromJson(Map<String, dynamic> json) => Produk(
        id: json['id'],
        nama: json['nama'],
        harga: json['harga'],
        stok: json['stok'],
        kategori: json['kategori'],
        supplier: json['supplier'],
        created: json['created'],
        modified: json['modified'],
      );
}

Produk userFromJson(String str) => Produk.fromJson(json.decode(str));
