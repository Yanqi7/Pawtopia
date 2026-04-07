import { Context } from '@kit.AbilityKit';

export function appContext(target: Object): Context {
  return getContext(target) as Context;
}
