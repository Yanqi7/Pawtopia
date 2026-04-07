export class MediaAssets {
  static readonly postCoverKeys: string[] = ['cat_photo_1', 'dog_photo_2', 'cat_photo_3', 'dog_photo_4'];

  static heroDog(): Resource {
    return $r('app.media.dog_photo_2');
  }

  static heroCat(): Resource {
    return $r('app.media.cat_photo_1');
  }

  static loginBackground(): Resource {
    return $r('app.media.background');
  }

  static avatar(): Resource {
    return $r('app.media.people');
  }

  static petCover(seed: number = 0): Resource {
    const covers: Resource[] = [
      $r('app.media.dog_photo'),
      $r('app.media.dog_photo_1'),
      $r('app.media.dog_photo_3'),
      $r('app.media.cat_photo'),
      $r('app.media.cat_photo_2'),
      $r('app.media.cat_photo_3')
    ];
    return covers[Math.abs(seed) % covers.length];
  }

  static postCover(seed: number = 0): Resource {
    const covers: Resource[] = [
      $r('app.media.cat_photo_1'),
      $r('app.media.dog_photo_2'),
      $r('app.media.cat_photo_3'),
      $r('app.media.dog_photo_4')
    ];
    return covers[Math.abs(seed) % covers.length];
  }

  static postImage(name?: string, seed: number = 0): Resource {
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
      default:
        return MediaAssets.postCover(seed);
    }
  }
}
