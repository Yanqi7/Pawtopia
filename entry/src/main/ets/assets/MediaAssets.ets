export class MediaAssets {
  static readonly postCoverKeys: string[] = ['pet_cat_real_2', 'pet_dog_real_1', 'adopt_cat_real_1', 'adopt_dog_real_2', 'pet_dog_real_3'];

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

  static petCover(seed: number = 0): Resource {
    const covers: Resource[] = [
      $r('app.media.pet_dog_real_1'),
      $r('app.media.pet_dog_real_2'),
      $r('app.media.pet_dog_real_3'),
      $r('app.media.pet_cat_real_1'),
      $r('app.media.pet_cat_real_2'),
      $r('app.media.pet_cat_real_3')
    ];
    return covers[Math.abs(seed) % covers.length];
  }

  static postCover(seed: number = 0): Resource {
    const covers: Resource[] = [
      $r('app.media.pet_cat_real_2'),
      $r('app.media.pet_dog_real_1'),
      $r('app.media.adopt_cat_real_1'),
      $r('app.media.adopt_dog_real_2'),
      $r('app.media.pet_dog_real_3')
    ];
    return covers[Math.abs(seed) % covers.length];
  }

  static petImage(name?: string, seed: number = 0, species?: string): Resource {
    const mapped = MediaAssets.named(name);
    if (mapped) {
      return mapped;
    }
    const cats: Resource[] = [
      $r('app.media.pet_cat_real_1'),
      $r('app.media.pet_cat_real_2'),
      $r('app.media.pet_cat_real_3'),
      $r('app.media.adopt_cat_real_1'),
      $r('app.media.adopt_cat_real_2')
    ];
    const dogs: Resource[] = [
      $r('app.media.pet_dog_real_1'),
      $r('app.media.pet_dog_real_2'),
      $r('app.media.pet_dog_real_3'),
      $r('app.media.adopt_dog_real_1'),
      $r('app.media.adopt_dog_real_2')
    ];
    const pool = (species ?? '').indexOf('猫') >= 0 ? cats : dogs;
    return pool[Math.abs(seed) % pool.length];
  }

  static postImage(name?: string, seed: number = 0): Resource {
    const mapped = MediaAssets.named(name);
    if (mapped) {
      return mapped;
    }
    return MediaAssets.postCover(seed);
  }

  static productImage(name?: string, seed: number = 0, category?: string): Resource {
    const mapped = MediaAssets.named(name);
    if (mapped) {
      return mapped;
    }
    const common: Resource[] = [
      $r('app.media.shop_banner_real_1'),
      $r('app.media.shop_banner_real_2'),
      $r('app.media.pet_dog_real_1'),
      $r('app.media.pet_cat_real_1')
    ];
    const food: Resource[] = [
      $r('app.media.shop_banner_real_1'),
      $r('app.media.pet_dog_real_2'),
      $r('app.media.pet_cat_real_2')
    ];
    const toy: Resource[] = [
      $r('app.media.pet_cat_real_3'),
      $r('app.media.pet_dog_real_3'),
      $r('app.media.adopt_cat_real_2')
    ];
    const care: Resource[] = [
      $r('app.media.shop_banner_real_2'),
      $r('app.media.pet_cat_real_1'),
      $r('app.media.pet_dog_real_1')
    ];
    let pool = common;
    if (category === 'FOOD') {
      pool = food;
    } else if (category === 'TOY') {
      pool = toy;
    } else if (category === 'MEDICINE' || category === 'ACCESSORY') {
      pool = care;
    }
    return pool[Math.abs(seed) % pool.length];
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
      case 'pet_dog_real_1':
        return $r('app.media.pet_dog_real_1');
      case 'pet_dog_real_2':
        return $r('app.media.pet_dog_real_2');
      case 'pet_dog_real_3':
        return $r('app.media.pet_dog_real_3');
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
      default:
        return undefined;
    }
  }
}
