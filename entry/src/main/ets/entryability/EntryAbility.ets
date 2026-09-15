/*
 * Copyright (c) Huawei Technologies Co., Ltd. 2025. All rights reserved.
 */

import { UIAbility } from '@kit.AbilityKit';
import { hilog } from '@kit.PerformanceAnalysisKit';
import { window } from '@kit.ArkUI';

export default class EntryAbility extends UIAbility {
  private logTag: string = 'EntryAbility';
  private domainId: number = 0x0000;

  onCreate(): void {
    AppStorage.setOrCreate('tictocBackgroundEpoch', 0);
    hilog.info(this.domainId, this.logTag, 'onCreate');
  }

  onDestroy(): void {
    hilog.info(this.domainId, this.logTag, 'onDestroy');
  }

  async onWindowStageCreate(windowStage: window.WindowStage): Promise<void> {
    hilog.info(this.domainId, this.logTag, 'EntryAbility onWindowStageCreate');
    let windowClass: window.Window = await windowStage.getMainWindow()
    await windowClass.setWindowLayoutFullScreen(false)
    await windowClass.setWindowSystemBarEnable(['status', 'navigation'])
    windowClass.on('keyboardHeightChange', async data => {
      hilog.info(this.domainId, this.logTag, `testTag: ${data.toString()}`);
    })
    windowStage.loadContent('pages/HomePage', (err) => {
      if (err.code) {
        hilog.info(this.domainId, this.logTag, `failed to load the content. Cause: ${err.code}`);
        return;
      }
      hilog.info(this.domainId, this.logTag, 'succeeded in loading the content.');
    });
  }

  onWindowStageDestroy(): void {
    // Main window is destroyed, release UI related resources
    hilog.info(this.domainId, this.logTag, 'onWindowStageDestroy');
  }

  onForeground(): void {
    // Ability has brought to foreground
    hilog.info(this.domainId, this.logTag, 'onForeground');
  }

  onBackground(): void {
    AppStorage.set('tictocBackgroundEpoch', Date.now());
    hilog.info(this.domainId, this.logTag, 'onBackground');
  }
}
