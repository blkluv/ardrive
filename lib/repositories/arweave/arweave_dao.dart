import 'dart:convert';
import 'dart:typed_data';

import 'package:arweave/arweave.dart';
import 'package:arweave/src/utils.dart' as utils;
import 'package:http/http.dart';
import 'package:mime/mime.dart';
import 'package:simple_gql/simple_gql.dart';

import '../entities/entities.dart';
import 'arweave_helpers.dart';

class ArweaveDao {
  Arweave _arweave;
  GQLClient _gql = GQLClient(
    url: 'https://arweave.dev/graphql',
  );

  ArweaveDao(this._arweave);

  Future<UpdatedEntities> getUpdatedEntities(
      String address, int latestBlockNumber) async {
    final newEntitiesQuery = await _gql.query(
      query: r'''
        query UpdatedEntities($address: String!, $latestBlockNumber: Int) {
          transactions(
            owners: [$address]
            tags: [{ name: "App-Name", values: ["drive"] }]
            block: { min: $latestBlockNumber }
          ) {
            edges {
              node {
                id
                tags {
                  name
                  value
                }
              }
            }
          }
        }
      ''',
      variables: {
        "address": address,
        "latestBlockNumber": latestBlockNumber,
      },
    );

    List<dynamic> entityMetadataMap = newEntitiesQuery.data['transactions']
            ['edges']
        .map((e) => EntityMetadata(e['node']['id'], e['node']['tags']))
        .toList();
    final entityData = (await Future.wait(entityMetadataMap
            .map((e) => _arweave.transactions.getData(e.id))
            .toList()))
        .map((e) => utils.decodeBase64ToString(e))
        .toList();

    final driveEntities = <String, DriveEntity>{};
    final folderEntitites = <String, FolderEntity>{};
    final fileEntities = <String, FileEntity>{};

    for (var i = 0; i < entityMetadataMap.length; i++) {
      final entityMetadata = entityMetadataMap[i];

      final driveId = _txGetTag(entityMetadata, 'Drive-Id');
      final folderId = _txGetTag(entityMetadata, 'Folder-Id');
      final parentFolderId = _txGetTag(entityMetadata, 'Parent-Folder-Id');
      final fileId = _txGetTag(entityMetadata, 'File-Id');

      if (fileId != null) {
        if (fileEntities.containsKey(fileId)) continue;

        final file = FileEntity.fromJson(json.decode(entityData[i]));
        file.id = fileId;
        file.driveId = driveId;
        file.parentFolderId = parentFolderId;
        fileEntities[fileId] = file;
      } else if (folderId != null) {
        if (folderEntitites.containsKey(folderId)) continue;

        final folder = FolderEntity.fromJson(json.decode(entityData[i]));
        folder.id = folderId;
        folder.driveId = driveId;
        folder.parentFolderId = parentFolderId;
        folderEntitites[folderId] = folder;
      } else if (driveId != null) {
        if (driveEntities.containsKey(driveId)) continue;

        final drive = DriveEntity.fromJson(json.decode(entityData[i]));
        drive.id = driveId;
        driveEntities[driveId] = drive;
      }
    }

    return UpdatedEntities(
        latestBlockNumber, driveEntities, folderEntitites, fileEntities);
  }

  String _txGetTag(EntityMetadata entity, String tagName) {
    final tag =
        entity.tags.firstWhere((t) => t['name'] == tagName, orElse: () => null);
    return tag != null ? tag['value'] : null;
  }

  Future<Transaction> prepareDriveEntity(
      String driveId, String rootFolderId, Wallet wallet) async {
    final driveEntity = DriveEntity(rootFolderId);

    final driveEntityTx = await _arweave.createTransaction(
      Transaction(data: json.encode(driveEntity.toJson())),
      wallet,
    );

    driveEntityTx.addApplicationTags();
    driveEntityTx.addJsonContentTypeTag();
    driveEntityTx.addTag('Drive-Id', driveId);

    await driveEntityTx.sign(wallet);

    return driveEntityTx;
  }

  Future<Transaction> prepareFolderEntity(
    String folderId,
    String driveId,
    String parentFolderId,
    String name,
    Wallet wallet,
  ) async {
    final folderEntity = FolderEntity(name);

    final folderEntityTx = await _arweave.createTransaction(
      Transaction(data: json.encode(folderEntity.toJson())),
      wallet,
    );

    folderEntityTx.addApplicationTags();
    folderEntityTx.addJsonContentTypeTag();
    folderEntityTx.addTag('Drive-Id', driveId);
    folderEntityTx.addTag('Folder-Id', folderId);

    if (parentFolderId != null)
      folderEntityTx.addTag('Parent-Folder-Id', parentFolderId);

    await folderEntityTx.sign(wallet);

    return folderEntityTx;
  }

  Future<UploadTransactions> prepareFileUpload(
    String fileId,
    String driveId,
    String parentFolderId,
    String name,
    int fileSize,
    Uint8List fileStream,
    Wallet wallet,
  ) async {
    final fileDataTx = await _arweave.createTransaction(
      Transaction(dataBytes: fileStream),
      wallet,
    );

    fileDataTx.addTag(
      'Content-Type',
      lookupMimeType(name),
    );

    await fileDataTx.sign(wallet);

    final fileEntity = FileEntity(name, fileSize, fileDataTx.id);

    final fileEntityTx = await _arweave.createTransaction(
      Transaction(data: json.encode(fileEntity.toJson())),
      wallet,
    );

    fileEntityTx.addApplicationTags();
    fileEntityTx.addJsonContentTypeTag();
    fileEntityTx.addTag('Drive-Id', driveId);
    fileEntityTx.addTag('Parent-Folder-Id', parentFolderId);
    fileEntityTx.addTag('File-Id', fileId);

    await fileEntityTx.sign(wallet);

    return UploadTransactions(fileEntityTx, fileDataTx);
  }

  Future<List<Response>> batchPostTxs(List<Transaction> transactions) =>
      Future.wait(transactions.map((tx) => _arweave.transactions.post(tx)));
}

class EntityMetadata {
  final String id;
  final List<dynamic> tags;

  EntityMetadata(this.id, this.tags);
}

class UpdatedEntities {
  final int latestBlockNumber;
  final Map<String, DriveEntity> drives;
  final Map<String, FolderEntity> folders;
  final Map<String, FileEntity> files;

  UpdatedEntities(
      this.latestBlockNumber, this.drives, this.folders, this.files);
}

class UploadTransactions {
  Transaction entityTx;
  Transaction dataTx;

  UploadTransactions(this.entityTx, this.dataTx);
}
