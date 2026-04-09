import { Context } from '@kit.AbilityKit';
import { PreferencesStore } from './PreferencesStore';

export interface CartItem {
  productId: number;
  quantity: number;
}

type CartListener = (count: number) => void;

export class CartStore {
  private static readonly KEY = 'cart_items';
  private static initialized: boolean = false;
  private static items: Map<number, number> = new Map();
  private static listeners: CartListener[] = [];

  static async init(context: Context): Promise<void> {
    if (CartStore.initialized) {
      return;
    }
    await PreferencesStore.init(context);
    const raw = await PreferencesStore.getString(CartStore.KEY, '');
    if (raw) {
      try {
        const parsed = JSON.parse(raw) as CartItem[];
        parsed.forEach((it) => {
          const id = Number(it.productId);
          const qty = Number(it.quantity);
          if (id > 0 && qty > 0) {
            CartStore.items.set(id, qty);
          }
        });
      } catch (e) {
        CartStore.items.clear();
      }
    }
    CartStore.initialized = true;
    CartStore.emit();
  }

  static list(): CartItem[] {
    const result: CartItem[] = [];
    CartStore.items.forEach((quantity, productId) => result.push({ productId, quantity }));
    return result.sort((a, b) => a.productId - b.productId);
  }

  static getTotalCount(): number {
    let total = 0;
    CartStore.items.forEach((quantity) => total += quantity);
    return total;
  }

  static getQuantity(productId: number): number {
    return CartStore.items.get(productId) ?? 0;
  }

  static subscribe(listener: CartListener): void {
    if (CartStore.listeners.indexOf(listener) < 0) {
      CartStore.listeners.push(listener);
    }
  }

  static unsubscribe(listener: CartListener): void {
    CartStore.listeners = CartStore.listeners.filter((item: CartListener) => item !== listener);
  }

  static async add(productId: number, delta: number): Promise<void> {
    const next = Math.max(0, (CartStore.items.get(productId) ?? 0) + delta);
    if (next <= 0) {
      CartStore.items.delete(productId);
    } else {
      CartStore.items.set(productId, next);
    }
    await CartStore.persist();
  }

  static async setQuantity(productId: number, quantity: number): Promise<void> {
    const next = Math.max(0, quantity);
    if (next <= 0) {
      CartStore.items.delete(productId);
    } else {
      CartStore.items.set(productId, next);
    }
    await CartStore.persist();
  }

  static async clear(): Promise<void> {
    CartStore.items.clear();
    await CartStore.persist();
  }

  private static async persist(): Promise<void> {
    const arr: CartItem[] = [];
    CartStore.items.forEach((quantity, productId) => arr.push({ productId, quantity }));
    await PreferencesStore.setString(CartStore.KEY, JSON.stringify(arr));
    CartStore.emit();
  }

  private static emit(): void {
    const count = CartStore.getTotalCount();
    CartStore.listeners.forEach((listener: CartListener) => listener(count));
  }
}
