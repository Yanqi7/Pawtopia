export class MediaAssets {
  static heroDog() {
    return $r('app.media.dog_photo_2');
  }

  static heroCat() {
    return $r('app.media.cat_photo_1');
  }

  static loginBackground() {
    return $r('app.media.background');
  }

  static avatar() {
    return $r('app.media.people');
  }

  static petCover(seed: number = 0) {
    const covers = [
      $r('app.media.dog_photo'),
      $r('app.media.dog_photo_1'),
      $r('app.media.dog_photo_3'),
      $r('app.media.cat_photo'),
      $r('app.media.cat_photo_2'),
      $r('app.media.cat_photo_3')
    ];
    return covers[Math.abs(seed) % covers.length];
  }

  static postCover(seed: number = 0) {
    const covers = [
      $r('app.media.cat_photo_1'),
      $r('app.media.dog_photo_2'),
      $r('app.media.cat_photo_3'),
      $r('app.media.dog_photo_4')
    ];
    return covers[Math.abs(seed) % covers.length];
  }
}
