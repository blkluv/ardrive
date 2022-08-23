import 'dart:async';

import 'package:ardrive/blocs/blocs.dart';
import 'package:ardrive/models/models.dart';
import 'package:ardrive/services/services.dart';
import 'package:arweave/arweave.dart';
import 'package:bloc_concurrency/bloc_concurrency.dart';
import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

part 'fs_entry_move_event.dart';
part 'fs_entry_move_state.dart';

class FsEntryMoveBloc extends Bloc<FsEntryMoveEvent, FsEntryMoveState> {
  final String driveId;
  final List<SelectedItem> selectedItems;

  final ArweaveService _arweave;
  final DriveDao _driveDao;
  final ProfileCubit _profileCubit;
  final SyncCubit _syncCubit;

  FsEntryMoveBloc({
    required this.driveId,
    required this.selectedItems,
    required ArweaveService arweave,
    required DriveDao driveDao,
    required ProfileCubit profileCubit,
    required SyncCubit syncCubit,
  })  : _arweave = arweave,
        _driveDao = driveDao,
        _profileCubit = profileCubit,
        _syncCubit = syncCubit,
        super(const FsEntryMoveLoadInProgress()) {
    final profile = _profileCubit.state as ProfileLoggedIn;

    on<FsEntryMoveEvent>(
      (event, emit) async {
        if (await _profileCubit.logoutIfWalletMismatch()) {
          emit(const FsEntryMoveWalletMismatch());
          return;
        }

        if (event is FsEntryMoveInitial) {
          final drive = await _driveDao.driveById(driveId: driveId).getSingle();
          await loadFolder(folderId: drive.rootFolderId, emit: emit);
        }

        if (event is FsEntryMoveSubmit) {
          final folderInView = event.folderInView;
          final conflictingItems = await checkForConflicts(
            parentFolder: folderInView,
            profile: profile,
          );
          if (conflictingItems.isEmpty) {
            moveEntities(
              conflictingItems: conflictingItems,
              profile: profile,
              parentFolder: folderInView,
            );
            emit(const FsEntryMoveSuccess());
          } else {
            final folderNames = conflictingItems
                .whereType<SelectedFolder>()
                .map((e) => e.item.name)
                .toList();
            final fileNames = conflictingItems
                .whereType<SelectedFile>()
                .map((e) => e.item.name)
                .toList();
            emit(
              FsEntryMoveNameConflict(
                folderNames: folderNames,
                fileNames: fileNames,
              ),
            );
          }
        }

        if (event is FsEntryMoveSkipConflicts) {
          final folderInView = event.folderInView;
          await moveEntities(
            parentFolder: folderInView,
            profile: profile,
          );
          emit(const FsEntryMoveSuccess());
        }

        if (event is FsEntryMoveUpdateTargetFolder) {
          await loadFolder(folderId: event.folderId, emit: emit);
        }

        if (event is FsEntryMoveGoBackToParent) {
          await loadParentFolder(folder: event.folderInView, emit: emit);
        }
      },
      transformer: restartable(),
    );
  }

  Future<void> loadParentFolder({
    required FolderEntry folder,
    required Emitter<FsEntryMoveState> emit,
  }) async {
    final parentFolder = folder.parentFolderId;
    if (parentFolder != null) {
      return loadFolder(folderId: parentFolder, emit: emit);
    }
  }

  Future<void> loadFolder({
    required String folderId,
    required Emitter<FsEntryMoveState> emit,
  }) async {
    final folderStream =
        _driveDao.watchFolderContents(driveId, folderId: folderId);
    await emit.forEach(
      folderStream,
      onData: (FolderWithContents folderWithContents) => FsEntryMoveLoadSuccess(
        viewingRootFolder: folderWithContents.folder.parentFolderId == null,
        viewingFolder: folderWithContents,
        itemsToMove: selectedItems,
      ),
    );
  }

  Future<List<SelectedItem>> checkForConflicts({
    required final FolderEntry parentFolder,
    required ProfileLoggedIn profile,
  }) async {
    final conflictingItems = <SelectedItem>[];
    try {
      for (var itemToMove in selectedItems) {
        final entityWithSameNameExists =
            await _driveDao.doesEntityWithNameExist(
          name: itemToMove.item.name,
          driveId: driveId,
          parentFolderId: parentFolder.id,
        );

        if (entityWithSameNameExists) {
          conflictingItems.add(itemToMove);
        }
      }
    } catch (err) {
      addError(err);
    }
    return conflictingItems;
  }

  Future<void> moveEntities({
    required FolderEntry parentFolder,
    List<SelectedItem> conflictingItems = const [],
    required ProfileLoggedIn profile,
  }) async {
    final driveKey = await _driveDao.getDriveKey(driveId, profile.cipherKey);
    final moveTxDataItems = <DataItem>[];

    final filesToMove = selectedItems
        .whereType<SelectedFile>()
        .where((file) => conflictingItems
            .where((conflictingFile) => conflictingFile.id == file.id)
            .isEmpty)
        .toList();

    final foldersToMove = selectedItems
        .whereType<SelectedFolder>()
        .where((folder) => conflictingItems
            .where((conflictingFolder) => conflictingFolder.id == folder.id)
            .isEmpty)
        .toList();

    final folderMap = <String, FolderEntriesCompanion>{};

    await _driveDao.transaction(() async {
      for (var fileToMove in filesToMove) {
        var file = await _driveDao
            .fileById(driveId: driveId, fileId: fileToMove.id)
            .getSingle();
        file = file.copyWith(
            parentFolderId: parentFolder.id,
            path: '${parentFolder.path}/${file.name}',
            lastUpdated: DateTime.now());
        final fileKey =
            driveKey != null ? await deriveFileKey(driveKey, file.id) : null;

        final fileEntity = file.asEntity();

        final fileDataItem = await _arweave.prepareEntityDataItem(
          fileEntity,
          profile.wallet,
          fileKey,
        );
        moveTxDataItems.add(fileDataItem);

        await _driveDao.writeToFile(file);
        fileEntity.txId = fileDataItem.id;

        await _driveDao.insertFileRevision(fileEntity.toRevisionCompanion(
          performedAction: RevisionAction.move,
        ));
      }
      for (var folderToMove in foldersToMove) {
        var folder = await _driveDao
            .folderById(driveId: driveId, folderId: folderToMove.id)
            .getSingle();
        folder = folder.copyWith(
          parentFolderId: parentFolder.id,
          path: '${parentFolder.path}/${folder.name}',
          lastUpdated: DateTime.now(),
        );

        final folderEntity = folder.asEntity();

        final folderDataItem = await _arweave.prepareEntityDataItem(
          folderEntity,
          profile.wallet,
          driveKey,
        );

        await _driveDao.writeToFolder(folder);
        folderEntity.txId = folderDataItem.id;
        await _driveDao.insertFolderRevision(folderEntity.toRevisionCompanion(
          performedAction: RevisionAction.move,
        ));
        folderMap.addAll({folder.id: folder.toCompanion(false)});
      }
    });

    final moveTx = await _arweave.prepareDataBundleTx(
      await DataBundle.fromDataItems(
        items: moveTxDataItems,
      ),
      profile.wallet,
    );
    await _arweave.postTx(moveTx);

    await _syncCubit.generateFsEntryPaths(driveId, folderMap, {});
  }

  @override
  Future<void> close() {
    return super.close();
  }

  @override
  void onError(Object error, StackTrace stackTrace) {
    super.onError(error, stackTrace);
  }
}
