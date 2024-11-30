import 'package:flutter/material.dart';
import 'package:tiler_app/data/contact.dart';
import 'package:tiler_app/data/request/NewTile.dart';
import 'package:tiler_app/data/request/clusterTemplateTileModel.dart';
import 'package:tiler_app/data/request/contactModel.dart';
import 'package:tiler_app/data/request/tileShareClusterModel.dart';
import 'package:tiler_app/data/tileShareTemplate.dart';
import 'package:tiler_app/data/tilerEvent.dart';
import 'package:tiler_app/data/userProfile.dart';
import 'package:tiler_app/util.dart';

class TileShareClusterData {
  String? id;
  String? name;
  UserProfile? creator;
  List<Contact>? contacts;
  List<NewTile>? newTileTemplates;
  List<TileShareTemplate>? tileShareTemplates;
  int? durationInMs;
  int? startTimeInMs;
  int? endTimeInMs;
  bool? isCompleted;
  bool? isDeleted;
  bool? isDismissed;
  bool? isMultiTilette;

  TilePriority priority = TilePriority.medium;
  TileShareClusterData();

  TileShareClusterData.fromJson(Map<String, dynamic> json) {
    this.id = '';
    if (json.containsKey('id')) {
      id = json['id'];
    }

    if (json.containsKey('name')) {
      name = json['name'];
    }

    if (json.containsKey('start')) {
      startTimeInMs = json['start'];
    }

    if (json.containsKey('end')) {
      endTimeInMs = json['end'];
    }

    if (json.containsKey('duration')) {
      durationInMs = json['duration'];
    }
    if (json.containsKey('isCompleted')) {
      isCompleted = json['isCompleted'];
    }
    if (json.containsKey('isCompleted')) {
      isCompleted = json['isCompleted'];
    }
    if (json.containsKey('isCompleted')) {
      isCompleted = json['isCompleted'];
    }
    if (json.containsKey('isMultiTilette')) {
      isMultiTilette = json['isMultiTilette'];
    }
    if (json.containsKey('tileShareTemplates') &&
        json['tileShareTemplates'] != null &&
        json['tileShareTemplates'] is Iterable) {
      tileShareTemplates = (json['tileShareTemplates'] as Iterable)
          .where((element) => element != null)
          .map<TileShareTemplate>((e) => TileShareTemplate.fromJson(e!))
          .toList();
    }
    if (json.containsKey('truncatedUser') && json['truncatedUser'] != null) {
      var trucatedUsers = json['truncatedUser'];
      if (json['truncatedUser'] is String) {
        trucatedUsers = json['truncatedUser'].split(",");
      }
      if (trucatedUsers is List) {
        contacts = <Contact>[];
        trucatedUsers.forEach((eachTruncatedUser) {
          if (Utility.isEmail(eachTruncatedUser)) {
            Contact contact = Contact();
            contact.email = eachTruncatedUser as String;
            contacts!.add(contact);
          } else if (Utility.isPhoneNumber(eachTruncatedUser)) {
            Contact contact = Contact();
            contact.phoneNumber = eachTruncatedUser as String;
            contacts!.add(contact);
          }
        });
      }
    }

    if (json.containsKey('creator') && json['creator'] != null) {
      creator = UserProfile.fromJson(json['creator']);
    }
  }

  TileShareClusterModel toTemplateClusterModel() {
    TileShareClusterModel templateClusterModel = TileShareClusterModel();
    templateClusterModel.Name = this.name;
    templateClusterModel.DurationInMs = durationInMs;
    templateClusterModel.StartTime = this.startTimeInMs;
    templateClusterModel.EndTime = this.endTimeInMs;
    templateClusterModel.IsMultiTilette = this.isMultiTilette;
    templateClusterModel.Contacts =
        this.contacts?.map<ContactModel>((e) => e.toContactModel()).toList();
    templateClusterModel.ClusterTemplateTileModels = this
        .newTileTemplates
        ?.map<ClusterTemplateTileModel>((e) => e.toClusterTemplateTileModel())
        .toList();

    return templateClusterModel;
  }
}
