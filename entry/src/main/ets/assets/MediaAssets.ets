export class MediaAssets {
  static readonly postCoverKeys: string[] = ['pet_cat_real_2', 'pet_dog_real_1', 'pet_cat_real_4', 'pet_dog_real_4', 'pet_dog_real_3'];

  static isRemoteUrl(value?: string): boolean {
    const normalized = (value ?? '').trim().toLowerCase();
    return normalized.startsWith('http://') || normalized.startsWith('https://');
  }

  static splitImageValues(value?: string): string[] {
    return (value ?? '')
      .split(',')
      .map((item: string) => item.trim())
      .filter((item: string) => item.length > 0);
  }

  static heroDog(): Resource {
    return $r('app.media.pet_dog_real_2');
  }

  static heroCat(): Resource {
    return $r('app.media.pet_cat_real_2');
  }

  static adoptHero(): Resource {
    return $r('app.media.adopt_dog_real_1');
  }

  static mallHero(): Resource {
    return $r('app.media.shop_banner_real_1');
  }

  static profileHero(): Resource {
    return $r('app.media.pet_cat_real_3');
  }

  static loginBackground(): Resource {
    return $r('app.media.background');
  }

  static avatar(): Resource {
    return $r('app.media.people');
  }

  static placeholder(): Resource {
    return $r('app.media.media_placeholder');
  }

  static petImage(name?: string, _seed: number = 0, _species?: string): Resource | string {
    return MediaAssets.firstImage(name);
  }

  static postImage(name?: string, _seed: number = 0): Resource | string {
    return MediaAssets.firstImage(name);
  }

  static productGallery(name?: string, _seed: number = 0, _category?: string): Array<Resource | string> {
    return MediaAssets.resolveImages(name);
  }

  static productImage(name?: string, _seed: number = 0, _category?: string): Resource | string {
    const images = MediaAssets.resolveImages(name);
    if (images.length === 0) {
      return MediaAssets.placeholder();
    }
    const index = Math.abs(_seed) % images.length;
    return images[index];
  }

  private static firstImage(name?: string): Resource | string {
    const images = MediaAssets.resolveImages(name);
    return images.length > 0 ? images[0] : MediaAssets.placeholder();
  }

  private static resolveImages(name?: string): Array<Resource | string> {
    const normalized = MediaAssets.splitImageValues(name);
    const mapped: Array<Resource | string> = [];
    for (let i = 0; i < normalized.length; i++) {
      const current = normalized[i];
      if (MediaAssets.isRemoteUrl(current)) {
        mapped.push(current);
        continue;
      }
      const image = MediaAssets.named(current);
      if (image) {
        mapped.push(image);
      }
    }
    return mapped.length > 0 ? mapped : [MediaAssets.placeholder()];
  }

  private static named(name?: string): Resource | undefined {
    switch (name) {
      case 'cat_photo_1':
        return $r('app.media.cat_photo_1');
      case 'dog_photo_2':
        return $r('app.media.dog_photo_2');
      case 'cat_photo_3':
        return $r('app.media.cat_photo_3');
      case 'dog_photo_4':
        return $r('app.media.dog_photo_4');
      case 'dog_photo':
        return $r('app.media.dog_photo');
      case 'dog_photo_1':
        return $r('app.media.dog_photo_1');
      case 'dog_photo_3':
        return $r('app.media.dog_photo_3');
      case 'cat_photo':
        return $r('app.media.cat_photo');
      case 'cat_photo_2':
        return $r('app.media.cat_photo_2');
      case 'pet_cat_real_1':
        return $r('app.media.pet_cat_real_1');
      case 'pet_cat_real_2':
        return $r('app.media.pet_cat_real_2');
      case 'pet_cat_real_3':
        return $r('app.media.pet_cat_real_3');
      case 'pet_cat_real_4':
        return $r('app.media.pet_cat_real_4');
      case 'pet_dog_real_1':
        return $r('app.media.pet_dog_real_1');
      case 'pet_dog_real_2':
        return $r('app.media.pet_dog_real_2');
      case 'pet_dog_real_3':
        return $r('app.media.pet_dog_real_3');
      case 'pet_dog_real_4':
        return $r('app.media.pet_dog_real_4');
      case 'pet_dog_real_5':
        return $r('app.media.pet_dog_real_5');
      case 'adopt_cat_real_1':
        return $r('app.media.adopt_cat_real_1');
      case 'adopt_cat_real_2':
        return $r('app.media.adopt_cat_real_2');
      case 'adopt_dog_real_1':
        return $r('app.media.adopt_dog_real_1');
      case 'adopt_dog_real_2':
        return $r('app.media.adopt_dog_real_2');
      case 'shop_banner_real_1':
        return $r('app.media.shop_banner_real_1');
      case 'shop_banner_real_2':
        return $r('app.media.shop_banner_real_2');
      case 'shop_real_3':
        return $r('app.media.shop_real_3');
      case 'shop_real_4':
        return $r('app.media.shop_real_4');
      case 'shop_real_5':
        return $r('app.media.shop_real_5');
      case 'media_placeholder':
        return $r('app.media.media_placeholder');
      default:
        return undefined;
    }
  }
}
