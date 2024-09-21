import 'package:flutter/scheduler.dart';
import 'package:tiler_app/data/contact.dart';
import 'package:tiler_app/data/request/NewTile.dart';
import 'package:tiler_app/data/request/clusterTemplateTileModel.dart';
import 'package:tiler_app/data/request/contactModel.dart';
import 'package:tiler_app/data/request/templateClusterModel.dart';
import 'package:tiler_app/data/tilerEvent.dart';

class TileClusterData {
  String? name;
  List<Contact>? contacts;
  List<NewTile>? tileTemplates;
  int? durationInMs;
  int? startTimeInMs;
  int? endTimeInMs;
  TilePriority priority = TilePriority.medium;
  TemplateClusterModel toTemplateClusterModel() {
    TemplateClusterModel templateClusterModel = TemplateClusterModel();
    templateClusterModel.Name = this.name;
    templateClusterModel.DurationInMs = durationInMs;
    templateClusterModel.StartTime = this.startTimeInMs;
    templateClusterModel.EndTime = this.endTimeInMs;
    templateClusterModel.Contacts =
        this.contacts?.map<ContactModel>((e) => e.toContactModel()).toList();
    templateClusterModel.ClusterTemplateTileModels = this
        .tileTemplates
        ?.map<ClusterTemplateTileModel>((e) => e.toClusterTemplateTileModel())
        .toList();

    return templateClusterModel;
  }
}
