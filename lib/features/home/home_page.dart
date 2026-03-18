      // Save checklist header to local and cloud
      await _checklistRepo.saveChecklist(checklist);

      AppLogger.info('保存 checklist 完成 - id: ${checklist.id}');
      AppLogger.info('即将保存 checklist items，items 数量: ${items.length}');

      // 打印第一个 item 的详细信息
      if (items.isNotEmpty) {
        AppLogger.info('items[0] - id: ${items[0].id}, checklistId: "${items[0].checklistId}", attractionId: ${items[0].attractionId}');
      }
      AppLogger.info('开始保存 checklist items...');

      // Save checklist items separately
      await _checklistRepo.saveChecklistItems(checklist.id, items);

      AppLogger.info('保存 checklist items 完成 - checklistId: ${checklist.id}, 数量: ${items.length}');

