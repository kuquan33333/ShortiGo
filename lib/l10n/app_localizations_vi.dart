// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Vietnamese (`vi`).
class AppLocalizationsVi extends AppLocalizations {
  AppLocalizationsVi([String locale = 'vi']) : super(locale);

  @override
  String get appTitle => 'ShortiGo';

  @override
  String get discover => 'Khám phá';

  @override
  String get shorts => 'Phim ngắn';

  @override
  String get rewards => 'Phần thưởng';

  @override
  String get myList => 'Danh sách của tôi';

  @override
  String get profile => 'Tài khoản';

  @override
  String get settings => 'Cài đặt';

  @override
  String get contentSource => 'Nguồn nội dung';

  @override
  String get contentApiServer => 'Máy chủ API phim';

  @override
  String get testConnection => 'Kiểm tra kết nối';

  @override
  String get save => 'Lưu';

  @override
  String get saved => 'Đã lưu';

  @override
  String get restoreDefault => 'Khôi phục mặc định';

  @override
  String get serverStatus => 'Trạng thái máy chủ';

  @override
  String get active => 'Hoạt động';

  @override
  String get unavailable => 'Không khả dụng';

  @override
  String get notConfigured => 'Chưa cấu hình';

  @override
  String get language => 'Ngôn ngữ';

  @override
  String get providers => 'Nguồn phim';

  @override
  String get search => 'Tìm kiếm';

  @override
  String get searchHint => 'Tìm phim ngắn';

  @override
  String get noResults => 'Không tìm thấy kết quả.';

  @override
  String get noShorts => 'Chưa có phim ngắn.';

  @override
  String get seriesNotFound => 'Không tìm thấy phim.';

  @override
  String get noSavedSeries => 'Bạn chưa lưu phim nào.';

  @override
  String get saveSeriesHint => 'Phim đã lưu sẽ xuất hiện ở đây.';

  @override
  String get signIn => 'Đăng nhập';

  @override
  String get createAccount => 'Đăng ký';

  @override
  String get createAccountOrSignIn => 'Đăng ký hoặc đăng nhập';

  @override
  String get continueWithGoogle => 'Tiếp tục với Google';

  @override
  String get guestMode => 'Chế độ Khách';

  @override
  String get guestMessage => 'Bạn đang dùng ShortiGo ở chế độ Khách.';

  @override
  String get signInToUse => 'Đăng nhập để sử dụng tính năng này.';

  @override
  String get accountServiceUnavailable =>
      'Dịch vụ tài khoản hiện chưa được cấu hình.';

  @override
  String get signOut => 'Đăng xuất';

  @override
  String get tryAgain => 'Thử lại';

  @override
  String get sourceLocked => 'Tập này hiện chưa có nguồn phát công khai.';

  @override
  String episodeCount(Object count) {
    return '$count tập';
  }

  @override
  String get forYou => 'Dành cho bạn';

  @override
  String get newUpdates => 'Mới cập nhật';

  @override
  String get hot => 'Thịnh hành';

  @override
  String get adventure => 'Phiêu lưu';

  @override
  String get scary => 'Kinh dị';

  @override
  String get anime => 'Hoạt hình';

  @override
  String get vip => 'VIP';

  @override
  String durationSeconds(Object seconds) {
    return '$seconds giây';
  }

  @override
  String get unknownDuration => '';

  @override
  String get accountAndSubscription => 'Tài khoản và gói dịch vụ';

  @override
  String get restorePurchases => 'Khôi phục giao dịch mua';

  @override
  String get deleteAccount => 'Xóa tài khoản';

  @override
  String get bonus => 'Điểm thưởng';

  @override
  String get coins => 'Xu';

  @override
  String get vipViewer => 'Thành viên VIP';

  @override
  String get freeViewer => 'Tài khoản thường';

  @override
  String get dailyCheckIn => 'Điểm danh hằng ngày';

  @override
  String get watchAnAd => 'Xem quảng cáo nhận thưởng';

  @override
  String get achievements => 'Thành tựu';

  @override
  String get done => 'Đã xong';

  @override
  String get claim => 'Nhận';

  @override
  String get retry => 'Thử lại';

  @override
  String get info => 'Thông tin';

  @override
  String get readMore => 'Đọc thêm';

  @override
  String get email => 'Email';

  @override
  String get password => 'Mật khẩu';

  @override
  String get browseAsGuest => 'Tiếp tục với tư cách Khách';

  @override
  String get cancel => 'Hủy';

  @override
  String get earned => 'Đã nhận';

  @override
  String get unlocked => 'Đã mở khóa';

  @override
  String get recentActivity => 'Hoạt động gần đây';

  @override
  String get getVip => 'Nâng cấp VIP';

  @override
  String get yes => 'Có';

  @override
  String get no => 'Không';

  @override
  String get deleteAccountPrompt => 'Xóa tài khoản ShortiGo?';

  @override
  String get deleteAccountDescription =>
      'Hồ sơ, Danh sách của tôi và hoạt động xem phim sẽ bị xóa vĩnh viễn.';

  @override
  String get contentServerSlow => 'Máy chủ phim phản hồi quá lâu.';

  @override
  String get contentServerUnavailable => 'Không thể kết nối tới máy chủ phim.';

  @override
  String get keepStreakAlive => 'Duy trì chuỗi điểm danh';

  @override
  String get enoughToUnlock => 'Bạn đã đủ điểm để mở khóa một tập';

  @override
  String bonusUntilNext(Object count) {
    return 'Còn $count điểm để mở khóa tập tiếp theo';
  }

  @override
  String get claimedToday => 'Đã nhận hôm nay';

  @override
  String get bonusFive => '+5 điểm';

  @override
  String get watch => 'Xem';

  @override
  String get testAdReady => 'Quảng cáo thử nghiệm sẵn sàng · +12 điểm';

  @override
  String get bonusTwelve => '+12 điểm';

  @override
  String get preparingAd => 'Đang chuẩn bị quảng cáo...';

  @override
  String get adPlaying => 'Quảng cáo đang phát';

  @override
  String get confirmingReward => 'Đang xác nhận phần thưởng...';

  @override
  String get noAdAvailable => 'Chưa có quảng cáo';

  @override
  String get checkConnection => 'Kiểm tra kết nối';

  @override
  String get adSetupNeedsAttention => 'Cần kiểm tra cấu hình quảng cáo';

  @override
  String get adUnavailable => 'Quảng cáo hiện không khả dụng';

  @override
  String get activeToday => 'Đang hoạt động hôm nay';

  @override
  String get startToday => 'Bắt đầu hôm nay';

  @override
  String get firstSpark => 'Tia sáng đầu tiên';

  @override
  String get unlockReady => 'Sẵn sàng mở khóa';

  @override
  String get vipEpisode => 'Tập VIP';

  @override
  String get upgradeToWatch => 'Nâng cấp để xem short này.';

  @override
  String get goToRewards => 'Đến mục phần thưởng';

  @override
  String get unlockThisEpisode => 'Mở khóa tập này';

  @override
  String bonusBalance(Object balance, Object cost) {
    return '$cost điểm · Số dư của bạn: $balance';
  }

  @override
  String get earnBonus => 'Kiếm điểm';

  @override
  String get tapToRetry => 'Chạm để thử lại';

  @override
  String get previewShortiGo => 'Xem trước ShortiGo';

  @override
  String get shortDramasBeforeSignup => 'Xem drama ngắn trước khi đăng ký';

  @override
  String get browseCategoriesReady =>
      'Khám phá danh mục, rồi đăng nhập khi bạn sẵn sàng xem.';

  @override
  String get noPreviewsYet => 'Chưa có nội dung xem trước';

  @override
  String get checkBackFreshDramas =>
      'Hãy quay lại sau để xem các drama ngắn mới.';

  @override
  String get vipEpisodeOpen => 'Mọi tập VIP đều đã mở khóa';

  @override
  String get bonusSelectedEpisodes => 'Kiếm điểm để mở khóa các tập được chọn';

  @override
  String get adDiagnostics => 'Chẩn đoán quảng cáo';

  @override
  String get testMode => 'chế độ thử nghiệm';

  @override
  String get inspector => 'Trình kiểm tra';
}
