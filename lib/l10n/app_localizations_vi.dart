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
  String get homeNav => 'Trang chủ';

  @override
  String get forYouNav => 'Đề xuất';

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
  String get contentSourceSetupTitle => 'Chưa cấu hình nguồn phim';

  @override
  String get contentSourceSetupDescription =>
      'ShortiGo không cài sẵn nguồn nội dung. Hãy thêm URL Content API của bạn để bắt đầu xem phim.';

  @override
  String get configureContentSource => 'Cấu hình nguồn phim';

  @override
  String get contentSourceSetupHint =>
      'Bạn có thể thay đổi nguồn bất cứ lúc nào trong Cài đặt.';

  @override
  String get popularCategories => 'Thể loại phổ biến';

  @override
  String get maybeYouLike => 'Có thể bạn thích';

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
  String get playbackError => 'Không thể phát nguồn video này lúc này.';

  @override
  String get watchHistory => 'Lịch sử xem';

  @override
  String get savedSeries => 'Phim đã lưu';

  @override
  String get noWatchHistory => 'Lịch sử xem của bạn sẽ xuất hiện ở đây.';

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
  String get sourceLockedShort => 'Bị khóa';

  @override
  String get sourceLockedDescription =>
      'Nguồn phát công khai chưa được cung cấp cho tập này.';

  @override
  String get sourceUnavailable => 'Nguồn phát không khả dụng';

  @override
  String get sourceUnavailableDescription =>
      'Tập này hiện chưa thể phát từ nguồn công khai.';

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
  String get trending => 'Thịnh hành';

  @override
  String get dubbed => 'Lồng tiếng Việt';

  @override
  String get vietsub => 'Vietsub';

  @override
  String get romance => 'Ngôn tình';

  @override
  String get ceo => 'Tổng tài';

  @override
  String get revenge => 'Báo thù';

  @override
  String get family => 'Gia đình';

  @override
  String get action => 'Hành động';

  @override
  String get fantasy => 'Huyền huyễn';

  @override
  String get recommended => 'Có thể bạn thích';

  @override
  String get rebirth => 'Tái sinh / Xuyên không';

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
  String get subscribeToVip => 'Đăng ký VIP';

  @override
  String get vipMembership => 'Thành viên VIP';

  @override
  String get vipBenefits =>
      'Không quảng cáo, chất lượng 1080p và nội dung VIP độc quyền.';

  @override
  String get noOfferingsAvailable => 'Hiện chưa có gói VIP khả dụng.';

  @override
  String get restorePurchases => 'Khôi phục giao dịch mua';

  @override
  String get subscriptionRestored => 'Đã khôi phục giao dịch mua VIP.';

  @override
  String get subscriptionPurchaseSuccess => 'VIP đã được kích hoạt.';

  @override
  String get vipTestModeNotice =>
      'Chế độ thử nghiệm — không phát sinh thanh toán thật.';

  @override
  String get resetVipTest => 'Đặt lại VIP thử nghiệm';

  @override
  String get testVipReset => 'Đã đặt lại quyền VIP thử nghiệm.';

  @override
  String get noActiveVipPurchase =>
      'Không tìm thấy giao dịch VIP đang hoạt động.';

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
      'Khám phá phim ngắn ngay cả khi chưa đăng nhập.';

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

  @override
  String get signInToSyncAccount =>
      'Đăng nhập khi bạn muốn đồng bộ danh sách, phần thưởng và tài khoản.';

  @override
  String watchOnShortiGo(Object episode, Object title) {
    return 'Xem $title trên ShortiGo · Tập $episode';
  }

  @override
  String get rewardedAdTransaction => 'Thưởng xem quảng cáo';

  @override
  String get purchaseTransaction => 'Mua hàng';

  @override
  String get episodeUnlockedTransaction => 'Mở khóa tập';

  @override
  String get refundTransaction => 'Hoàn tiền';

  @override
  String get invalidUrlError => 'URL máy chủ không hợp lệ.';

  @override
  String get notConfiguredError => 'Chưa cấu hình máy chủ API phim.';

  @override
  String get timeoutError => 'Máy chủ phản hồi quá lâu. Vui lòng thử lại.';

  @override
  String get networkError => 'Không thể kết nối tới máy chủ phim.';

  @override
  String get malformedJsonError => 'Máy chủ trả về dữ liệu không hợp lệ.';

  @override
  String get invalidSchemaError =>
      'Máy chủ không trả về đúng cấu trúc dữ liệu.';

  @override
  String get notFoundError => 'Không tìm thấy nội dung trên máy chủ.';

  @override
  String get sourceLockedError => 'Tập này hiện chưa có nguồn phát công khai.';

  @override
  String get genericContentApiError =>
      'Không thể tải nội dung lúc này. Vui lòng thử lại.';

  @override
  String get authInvalidEmail => 'Địa chỉ email không hợp lệ.';

  @override
  String get authInvalidCredential => 'Email hoặc mật khẩu không đúng.';

  @override
  String get authEmailInUse => 'Email này đã được đăng ký.';

  @override
  String get authWeakPassword => 'Mật khẩu quá yếu.';

  @override
  String get authTooManyRequests =>
      'Bạn đã thử quá nhiều lần. Vui lòng thử lại sau.';

  @override
  String get authNetwork => 'Không thể kết nối tới dịch vụ tài khoản.';

  @override
  String get authUserDisabled => 'Tài khoản này đã bị vô hiệu hóa.';

  @override
  String get authUnavailable => 'Tính năng đăng nhập hiện chưa khả dụng.';

  @override
  String get authUnknown => 'Không thể đăng nhập lúc này. Vui lòng thử lại.';

  @override
  String get somethingWentWrong => 'Đã xảy ra lỗi';

  @override
  String get unexpectedError =>
      'Ứng dụng gặp sự cố ngoài dự kiến. Vui lòng thử lại.';

  @override
  String get accountError => 'Lỗi tài khoản';

  @override
  String get subscriptionError => 'Lỗi đăng ký dịch vụ';

  @override
  String get subscriptionPurchaseFailed =>
      'Không thể hoàn tất giao dịch mua. Vui lòng thử lại.';

  @override
  String get subscriptionRestoreFailed =>
      'Không thể khôi phục giao dịch mua. Vui lòng thử lại.';

  @override
  String get subscriptionNotConfigured =>
      'Gói dịch vụ hiện chưa được cấu hình.';

  @override
  String get accountSignInRequired => 'Vui lòng đăng nhập lại để tiếp tục.';

  @override
  String get accountRecentLoginRequired =>
      'Vì lý do bảo mật, hãy đăng nhập lại trước khi xóa tài khoản.';

  @override
  String get accountDeletionFailed =>
      'Không thể xóa tài khoản. Vui lòng thử lại.';

  @override
  String get viewAll => 'Xem thêm';

  @override
  String get loadMore => 'Tải thêm';

  @override
  String get sortHot => 'Hot nhất';

  @override
  String get sortNew => 'Mới nhất';

  @override
  String get apiIncompatibleError =>
      'API nội dung không tương thích. Vui lòng cập nhật máy chủ.';

  @override
  String get watchAll => 'Xem toàn bộ';

  @override
  String get chooseEpisode => 'Chọn tập';

  @override
  String get intro => 'Giới thiệu';

  @override
  String get collapse => 'Thu gọn';

  @override
  String get ended => 'Đã hết phim';

  @override
  String episodeLabel(Object count) {
    return 'Tập $count';
  }

  @override
  String get share => 'Chia sẻ';

  @override
  String get like => 'Thích';

  @override
  String views(Object count) {
    return '$count lượt xem';
  }

  @override
  String get speed => 'Tốc độ';

  @override
  String get more => 'Thêm';

  @override
  String get hotTab => 'Hot';

  @override
  String get newTab => 'Phim mới';

  @override
  String get ranking => 'Xếp hạng';

  @override
  String get categories => 'Danh mục';

  @override
  String get similarContent => 'Thêm nội dung tương tự';

  @override
  String get noDescription => 'Chưa có mô tả.';

  @override
  String get lockedEpisode => 'Tập này đang bị khóa ở nguồn phát.';
}
