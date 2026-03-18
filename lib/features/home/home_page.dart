      // Save checklist header to local and cloud
      await _checklistRepo.saveChecklist(checklist);

      AppLogger.info('保存 checklist 完成 - id: ${checklist.id}');
      AppLogger.info('即将保存 checklist items，items 数量: $items.length');

      // Save checklist items separately
      await _checklistRepo.saveChecklistItems(checklist.id, items);

      AppLogger.info('保存 checklist items 完成 - checklistId: ${checklist.id}, 数量: ' + items.length.toString());
