import 'package:flutter/material.dart';

class Login_Model {
  String message;
  int totalsong;
  List<Invoices> invoices;
  int totalsplitsongs;
  String storage;
  String token;
  String name;
  String background;
  String color;
  String profilepic;
  String about;
  int totalplayed;
  int followers;
  int following;

  Login_Model(
      {this.message,
      this.totalsong,
      this.invoices,
      this.totalsplitsongs,
      this.storage,
      this.token,
      this.name,
      this.background,
      this.color,
      this.profilepic,
      this.about,
      this.totalplayed,
      this.followers,
      this.following});

  Login_Model.fromJson(Map<String, dynamic> json) {
    message = json['message'];
    totalsong = json['totalsong'];
    if (json['invoices'] != null) {
      invoices = new List<Invoices>();
      json['invoices'].forEach((v) {
        invoices.add(new Invoices.fromJson(v));
      });
    }
    totalsplitsongs = json['totalsplitsongs'];
    storage = json['storage'];
    token = json['token'];
    name = json['name'];
    background = json['background'];
    color = json['color'];
    profilepic = json['profilepic'];
    about = json['about'];
    totalplayed = json['totalplayed'];
    followers = json['followers'];
    following = json['following'];
  }

  static Map<String, dynamic> toJson(
      {@required String email, @required String password}) {
    final Map<String, dynamic> data = new Map<String, dynamic>();
    data['email'] = email;
    data['password'] = password;
    return data;
  }
}

class Invoices {
  int id;
  String transactionId;
  String txRef;
  String userid;
  String amount;
  String createdAt;

  Invoices(
      {this.id,
      this.transactionId,
      this.txRef,
      this.userid,
      this.amount,
      this.createdAt});

  Invoices.fromJson(Map<String, dynamic> json) {
    id = json['id'];
    transactionId = json['transaction_id'];
    txRef = json['tx_ref'];
    userid = json['userid'];
    amount = json['amount'];
    createdAt = json['created_at'];
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = new Map<String, dynamic>();
    data['id'] = this.id;
    data['transaction_id'] = this.transactionId;
    data['tx_ref'] = this.txRef;
    data['userid'] = this.userid;
    data['amount'] = this.amount;
    data['created_at'] = this.createdAt;
    return data;
  }
}