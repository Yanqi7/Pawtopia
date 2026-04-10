@Component
export struct SectionTitle {
  title: string = '';

  build() {
    Text(this.title)
      .fontSize(16)
      .fontWeight(FontWeight.Medium)
      .margin({ top: 12, bottom: 6 })
  }
}

@Component
export struct PrimaryButton {
  text: string = '';
  action: () => void = () => {};
  disabled: boolean = false;

  build() {
    Button(this.text)
      .enabled(!this.disabled)
      .width('100%')
      .height(44)
      .backgroundColor(this.disabled ? '#D7D7D7' : '#2B7FFF')
      .fontColor(Color.White)
      .borderRadius(10)
      .onClick(() => this.action())
  }
}

@Component
export struct Field {
  label: string = '';
  placeholder: string = '';
  value: string = '';
  onChange: (v: string) => void = (v: string) => {};
  type: InputType = InputType.Normal;

  build() {
    Column({ space: 6 }) {
      Text(this.label).fontSize(13).fontColor('#444')
      TextInput({ placeholder: this.placeholder, text: this.value })
        .type(this.type)
        .height(44)
        .backgroundColor('#F6F7F9')
        .borderRadius(10)
        .padding({ left: 12, right: 12 })
        .onChange((v: string) => this.onChange(v))
    }.width('100%')
  }
}

@Component
export struct ErrorText {
  text: string = '';

  build() {
    if (this.text) {
      Text(this.text)
        .fontSize(13)
        .fontColor(Color.Red)
        .width('100%')
    }
  }
}

@Component
export struct OptionGroup {
  label: string = '';
  options: string[] = [];
  selected: string = '';
  onSelect: (v: string) => void = (v: string) => {};

  build() {
    Column({ space: 6 }) {
      Text(this.label).fontSize(13).fontColor('#444')
      Flex({ wrap: FlexWrap.Wrap }) {
        ForEach(this.options, (opt: string) => {
          Button(opt)
            .height(32)
            .margin({ right: 10, bottom: 10 })
            .borderRadius(16)
            .backgroundColor(opt === this.selected ? '#2B7FFF' : '#F0F2F5')
            .fontColor(opt === this.selected ? Color.White : '#333')
            .onClick(() => this.onSelect(opt))
        }, (opt: string) => opt)
      }
      .width('100%')
    }.width('100%')
  }
}

@Component
export struct OfflineBanner {
  text: string = '当前无法连接服务，请稍后重试。';
  action: () => void = () => {};

  build() {
    Row({ space: 8 }) {
      Image($r('app.media.hero_bell'))
        .width(18)
        .height(18)
      Text(this.text)
        .fontSize(12)
        .fontColor('#415A77')
        .layoutWeight(1)
      Text('重试')
        .fontSize(12)
        .fontColor('#2B7FFF')
        .fontWeight(FontWeight.Bold)
        .onClick(() => this.action())
    }
    .padding({ left: 12, right: 12, top: 10, bottom: 10 })
    .backgroundColor('#EEF5FF')
    .borderRadius(12)
    .border({ width: 1, color: '#D9E8FF' })
    .width('100%')
    .alignItems(VerticalAlign.Center)
  }
}

@Component
export struct EmptyState {
  title: string = '暂无内容';
  description: string = '';
  actionText: string = '';
  action: () => void = () => {};

  build() {
    Column({ space: 10 }) {
      Image($r('app.media.hero_follow'))
        .width(56)
        .height(56)
      Text(this.title)
        .fontSize(16)
        .fontWeight(FontWeight.Medium)
        .fontColor('#1F2937')
      if (this.description) {
        Text(this.description)
          .fontSize(12)
          .fontColor('#6B7280')
          .textAlign(TextAlign.Center)
      }
      if (this.actionText) {
        Button(this.actionText)
          .height(34)
          .padding({ left: 16, right: 16 })
          .fontSize(12)
          .backgroundColor('#E8F1FF')
          .fontColor('#2B7FFF')
          .borderRadius(17)
          .onClick(() => this.action())
      }
    }
    .width('100%')
    .padding(24)
    .alignItems(HorizontalAlign.Center)
  }
}
