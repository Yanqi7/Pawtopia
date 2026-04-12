import { AppRouter } from '../common/AppRouter';
import { Api } from '../api/Api';
import { HealthRecord, Pet, UserRole } from '../model/Models';
import { SessionStore } from '../store/SessionStore';
import { AppStatus } from '../app/AppStatus';
import { EmptyState, OfflineBanner, PetCard, SectionHeader } from '../components/Ui';
import { Theme } from '../common/Theme';
import { MediaAssets } from '../assets/MediaAssets';
import { shortDate } from '../common/Formatters';

interface NewPetParams {
  mode?: string;
}

interface PetDetailParams {
  id?: number;
}

interface PetRouteParams {
  petId?: number;
}

@Component
export struct PetProfileTab {
  @State private loading: boolean = false;
  @State private errorText: string = '';
  @State private pets: Pet[] = [];
  @State private upcomingCount: number = 0;

  aboutToAppear(): void {
    AppRouter.bind(this);
    if (this.pets.length === 0) {
      this.reload();
    }
  }

  private role(): UserRole {
    return (SessionStore.getUser()?.role ?? 'USER') as UserRole;
  }

  private async reload(): Promise<void> {
    const user = SessionStore.getUser();
    if (!user || !user.id) {
      this.pets = [];
      return;
    }
    this.loading = true;
    this.errorText = '';
    try {
      if (this.role() === 'PET_HOSPITAL') {
        const allPets = await Api.getAllPets();
        this.pets = allPets.filter((pet: Pet) => pet.authorizedHospitalId === user.id);
        const today = new Date();
        const start = `${today.getFullYear()}-${String(today.getMonth() + 1).padStart(2, '0')}-${String(today.getDate()).padStart(2, '0')}`;
        const next = new Date(today.getTime() + 30 * 24 * 60 * 60 * 1000);
        const end = `${next.getFullYear()}-${String(next.getMonth() + 1).padStart(2, '0')}-${String(next.getDate()).padStart(2, '0')}`;
        const upcoming = await Api.getUpcomingAppointments(start, end).catch(() => [] as HealthRecord[]);
        this.upcomingCount = upcoming.length;
      } else {
        this.pets = await Api.getMyPets(user.id);
        this.upcomingCount = 0;
      }
    } catch (e) {
      this.errorText = e instanceof Error ? e.message : '加载失败';
    } finally {
      this.loading = false;
    }
  }

  build() {
    Column() {
      Stack({ alignContent: Alignment.BottomStart }) {
        Image(MediaAssets.profileHero())
          .width('100%')
          .height(186)
          .objectFit(ImageFit.Cover)
        Column()
          .width('100%')
          .height(186)
          .linearGradient({ angle: 180, colors: [['#0F172A08', 0], ['#0F172A54', 0.46], ['#F4F8FF', 1]] })
        Column({ space: 6 }) {
          Text(this.role() === 'PET_HOSPITAL' ? '健康档案工作台' : '宠物档案')
            .fontSize(22)
            .fontWeight(FontWeight.Bold)
            .fontColor(Color.White)
        }
        .padding({ left: 16, right: 16, bottom: 14 })
        .width('100%')
      }

      Scroll() {
        Column({ space: 14 }) {
          Row({ space: 10 }) {
            if (this.role() !== 'PET_HOSPITAL') {
              Button('新增')
                .height(34)
                .padding({ left: 14, right: 14 })
                .backgroundColor(Theme.primarySoft)
                .fontColor(Theme.primary)
                .borderRadius(17)
                .onClick(() => AppRouter.push('pages/NewPet', { mode: 'PROFILE' } as NewPetParams, this))
            }
            Button(this.role() === 'PET_HOSPITAL' ? `待提醒 ${this.upcomingCount}` : '健康记录')
              .height(34)
              .padding({ left: 14, right: 14 })
              .backgroundColor(Theme.surface)
              .fontColor(Theme.textPrimary)
              .borderRadius(17)
              .onClick(() => {
                const first = this.pets[0];
                if (this.role() === 'PET_HOSPITAL') {
                  AppRouter.push('pages/RoleWorkbench', undefined, this);
                } else if (first?.id) {
                  AppRouter.push('pages/HealthRecords', { petId: first.id } as PetRouteParams, this);
                }
              })
            if (this.role() !== 'PET_HOSPITAL') {
              Button('医院授权')
                .height(34)
                .padding({ left: 14, right: 14 })
                .backgroundColor(Theme.surface)
                .fontColor(Theme.textPrimary)
                .borderRadius(17)
                .onClick(() => {
                  const first = this.pets[0];
                  if (first?.id) {
                    AppRouter.push('pages/PetAuthorization', { petId: first.id } as PetRouteParams, this);
                  }
                })
            }
          }

          if (!AppStatus.isBackendOnline()) {
            OfflineBanner({ text: '当前无法连接服务，档案信息可能不是最新状态。', action: () => this.reload() })
          }

          if (this.errorText) {
            Text(this.errorText)
              .fontSize(13)
              .fontColor(Theme.danger)
              .width('100%')
          }

          SectionHeader({
            title: this.role() === 'PET_HOSPITAL' ? '授权宠物档案' : '我的宠物',
            actionText: this.role() === 'PET_HOSPITAL' ? '' : '新增',
            onAction: () => AppRouter.push('pages/NewPet', { mode: 'PROFILE' } as NewPetParams, this)
          })

          if (!this.loading && this.pets.length === 0) {
            EmptyState({
              title: this.role() === 'PET_HOSPITAL' ? '暂无授权宠物' : '还没有宠物档案',
              description: this.role() === 'PET_HOSPITAL' ? '等待宠物主人授权后，这里会显示可维护的宠物。' : '先添加一只宠物，后续可以维护详细资料与健康档案。',
              actionText: this.role() === 'PET_HOSPITAL' ? '查看工作台' : '添加宠物',
              action: () => this.role() === 'PET_HOSPITAL'
                ? AppRouter.push('pages/RoleWorkbench', undefined, this)
                : AppRouter.push('pages/NewPet', { mode: 'PROFILE' } as NewPetParams, this)
            })
          } else {
            ForEach(this.pets, (pet: Pet) => {
              PetCard({
                pet: pet,
                summary: `最近更新：${shortDate(pet.updatedAt ?? pet.createdAt)} · ${pet.description ?? '暂无描述'}`,
                actionText: '进入档案',
                badgeText: this.role() === 'PET_HOSPITAL' ? '已授权' : '',
                onTap: () => AppRouter.push('pages/PetDetail', { id: pet.id } as PetDetailParams, this)
              })
            }, (pet: Pet) => String(pet.id))

            if (this.loading) {
              Row({ space: 8 }) {
                LoadingProgress().width(20).height(20).color(Theme.primary)
                Text('正在同步宠物档案…').fontSize(12).fontColor(Theme.textMuted)
              }
              .width('100%')
              .justifyContent(FlexAlign.Center)
              .padding(16)
            }
          }
        }
        .padding({ left: 16, right: 16, top: 12, bottom: 24 })
        .width('100%')
      }
      .layoutWeight(1)
    }
    .height('100%')
    .width('100%')
    .backgroundColor(Theme.background)
  }
}
