import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:hm_shop/api/user.dart';
import 'package:hm_shop/components/common/app_error_view.dart';
import 'package:hm_shop/components/common/hm_bottom_bar.dart';
import 'package:hm_shop/constants/app_assets.dart';
import 'package:hm_shop/constants/app_theme.dart';
import 'package:hm_shop/models/user.dart';
import 'package:hm_shop/stores/token_manager.dart';
import 'package:hm_shop/stores/user_controller.dart';
import 'package:hm_shop/utils/api_exception.dart';
import 'package:hm_shop/utils/loading_dialog.dart';
import 'package:hm_shop/utils/toast_utils.dart';

/// 个人资料页：查看并修改昵称 / 性别 / 生日 / 职业
///
/// 数据来自 `GET /member/profile`，保存走 `PUT /member/profile`
/// （实测该接口按「传了才改」处理，只传 `nickname` 时其余字段保持不变，
/// 因此这里只提交被改过的字段，避免把没动过的字段覆盖成空值）。
///
/// 头像与所在地不提供修改：头像上传接口不存在（`POST /member/profile/avatar`
/// 返回 500），所在地也没有地区数据源，因此这两项只展示并给出说明。
class ProfilePage extends StatefulWidget {
  const ProfilePage({super.key});

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  /// 性别候选项（接口按字符串存，实测传任意值也不会报错）
  static const List<String> _genderOptions = ['男', '女'];

  /// 昵称长度上限，与登录后昵称的展示宽度相匹配
  static const int _nicknameMaxLength = 20;

  static const double _labelWidth = 72;
  static const double _avatarSize = 36;

  final UserController _userController = Get.find<UserController>();
  final TextEditingController _nicknameController = TextEditingController();
  final TextEditingController _professionController = TextEditingController();

  /// 拉取到的原始资料，用于「哪些字段真的改过」的判断
  UserInfo _original = UserInfo.empty();

  String _gender = '';
  String _birthday = '';
  bool _isLoading = true;
  bool _saving = false;
  String _errorMessage = '';

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _nicknameController.dispose();
    _professionController.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    setState(() {
      _isLoading = true;
      _errorMessage = '';
    });
    try {
      final user = await getUserInfoAPI();
      if (!mounted) return;
      setState(() {
        _applyUser(user);
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _isLoading = false;
        _errorMessage = resolveErrorMessage(e, fallback: '资料加载失败');
      });
    }
  }

  /// 把接口返回的资料回填到表单
  void _applyUser(UserInfo user) {
    _original = user;
    _nicknameController.text = user.nickname;
    _professionController.text = user.profession;
    _gender = user.gender;
    _birthday = user.birthday;
  }

  Future<void> _save() async {
    if (_saving) return;
    final nickname = _nicknameController.text.trim();
    if (nickname.isEmpty) {
      ToastUtils.showToast(context, '昵称不能为空');
      return;
    }
    if (nickname.length > _nicknameMaxLength) {
      ToastUtils.showToast(context, '昵称不能超过 $_nicknameMaxLength 个字符');
      return;
    }
    final profession = _professionController.text.trim();
    final data = <String, dynamic>{};
    if (nickname != _original.nickname) {
      data['nickname'] = nickname;
    }
    if (_gender.isNotEmpty && _gender != _original.gender) {
      data['gender'] = _gender;
    }
    if (_birthday.isNotEmpty && _birthday != _original.birthday) {
      data['birthday'] = _birthday;
    }
    if (profession != _original.profession) {
      data['profession'] = profession;
    }
    if (data.isEmpty) {
      ToastUtils.showToast(context, '资料没有改动');
      return;
    }

    setState(() => _saving = true);
    LoadingDialog.show(context, message: '正在保存');
    try {
      final updated = await updateProfileAPI(data);
      final merged = _merge(updated);
      // 接口会在返回体里带一个新 token，写回本地，避免旧 token 过期
      if (merged.token.isNotEmpty) {
        await tokenManager.setToken(merged.token);
      }
      _userController.updateUserInfo(merged);
      if (!mounted) return;
      LoadingDialog.hide();
      ToastUtils.showToast(context, '资料已保存');
      Navigator.pop(context, true);
    } catch (e) {
      if (!mounted) return;
      LoadingDialog.hide();
      setState(() => _saving = false);
      ToastUtils.showToast(context, resolveErrorMessage(e, fallback: '资料保存失败'));
    }
  }

  /// 合并更新结果与原始资料
  ///
  /// 更新接口返回体不一定带全字段（例如 `mobile`、`cityCode`），
  /// 直接整体替换会让用户在其它页面的展示丢信息，因此按字段非空覆盖。
  UserInfo _merge(UserInfo updated) {
    return UserInfo(
      id: updated.id.isNotEmpty ? updated.id : _original.id,
      account: updated.account.isNotEmpty ? updated.account : _original.account,
      mobile: updated.mobile.isNotEmpty ? updated.mobile : _original.mobile,
      token: updated.token.isNotEmpty ? updated.token : _original.token,
      avatar: updated.avatar.isNotEmpty ? updated.avatar : _original.avatar,
      nickname: updated.nickname.isNotEmpty
          ? updated.nickname
          : _original.nickname,
      gender: updated.gender.isNotEmpty ? updated.gender : _original.gender,
      birthday: updated.birthday.isNotEmpty
          ? updated.birthday
          : _original.birthday,
      cityCode: updated.cityCode.isNotEmpty
          ? updated.cityCode
          : _original.cityCode,
      provinceCode: updated.provinceCode.isNotEmpty
          ? updated.provinceCode
          : _original.provinceCode,
      profession: updated.profession.isNotEmpty
          ? updated.profession
          : _original.profession,
      fullLocation: updated.fullLocation.isNotEmpty
          ? updated.fullLocation
          : _original.fullLocation,
    );
  }

  Future<void> _pickGender() async {
    final selected = await showModalBottomSheet<String>(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(AppRadius.card),
        ),
      ),
      builder: (sheetContext) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 14),
              child: Text(
                '选择性别',
                style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
              ),
            ),
            const Divider(height: 1, color: AppColors.divider),
            for (final gender in _genderOptions)
              ListTile(
                title: Text(gender, style: const TextStyle(fontSize: 15)),
                trailing: gender == _gender
                    ? const Icon(
                        Icons.check,
                        color: AppColors.primary,
                        size: 20,
                      )
                    : null,
                onTap: () => Navigator.pop(sheetContext, gender),
              ),
            const SizedBox(height: 6),
          ],
        ),
      ),
    );
    if (selected == null || !mounted) return;
    setState(() => _gender = selected);
  }

  Future<void> _pickBirthday() async {
    final now = DateTime.now();
    final parsed = DateTime.tryParse(_birthday);
    final initial = parsed ?? DateTime(now.year - 18);
    final picked = await showDatePicker(
      context: context,
      initialDate: initial.isAfter(now) ? now : initial,
      firstDate: DateTime(1900),
      lastDate: now,
      helpText: '选择生日',
    );
    if (picked == null || !mounted) return;
    setState(() => _birthday = _formatDate(picked));
  }

  String _formatDate(DateTime date) {
    final month = date.month.toString().padLeft(2, '0');
    final day = date.day.toString().padLeft(2, '0');
    return '${date.year}-$month-$day';
  }

  void _showAvatarTip() {
    ToastUtils.showToast(context, '演示接口没有头像上传通道，暂不支持修改头像');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.pageBackground,
      appBar: AppBar(
        title: const Text('个人资料'),
        centerTitle: true,
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 0,
      ),
      bottomNavigationBar: _isLoading || _errorMessage.isNotEmpty
          ? null
          : HmBottomBar(
              child: HmBottomBarButton(
                text: '保存',
                primary: true,
                onPressed: _saving ? null : _save,
              ),
            ),
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }
    if (_errorMessage.isNotEmpty) {
      return Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(
            maxWidth: HmBottomBar.maxContentWidth,
          ),
          child: AppErrorView(message: _errorMessage, onRetry: _load),
        ),
      );
    }
    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(
          maxWidth: HmBottomBar.maxContentWidth,
        ),
        child: ListView(
          padding: const EdgeInsets.fromLTRB(12, 10, 12, 16),
          children: [
            _buildCard(
              children: [
                _buildAvatarRow(),
                _buildDivider(),
                _buildTextFieldRow(
                  label: '昵称',
                  controller: _nicknameController,
                  hintText: '请输入昵称',
                  maxLength: _nicknameMaxLength,
                ),
                _buildDivider(),
                _buildPickerRow(
                  label: '性别',
                  value: _gender.isEmpty ? '未设置' : _gender,
                  onTap: _pickGender,
                ),
                _buildDivider(),
                _buildPickerRow(
                  label: '生日',
                  value: _birthday.isEmpty ? '未设置' : _birthday,
                  onTap: _pickBirthday,
                ),
                _buildDivider(),
                _buildTextFieldRow(
                  label: '职业',
                  controller: _professionController,
                  hintText: '请输入职业',
                  maxLength: 20,
                ),
                _buildDivider(),
                _buildValueRow(
                  label: '所在地',
                  value: _original.fullLocation.isEmpty
                      ? '未设置'
                      : _original.fullLocation,
                ),
                _buildDivider(),
                _buildValueRow(
                  label: '账号',
                  value: _original.account.isEmpty ? '未设置' : _original.account,
                ),
              ],
            ),
            const SizedBox(height: 10),
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 4),
              child: Text(
                '头像与所在地由后台维护，暂不支持在这里修改；'
                '昵称、性别、生日、职业保存后立即生效。',
                style: TextStyle(
                  fontSize: 11,
                  height: 1.5,
                  color: AppColors.textSecondary,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCard({required List<Widget> children}) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(AppRadius.card),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 14),
      child: Column(children: children),
    );
  }

  Widget _buildDivider() {
    return const Divider(height: 1, thickness: 1, color: AppColors.divider);
  }

  Widget _buildLabel(String label) {
    return SizedBox(
      width: _labelWidth,
      child: Text(
        label,
        style: const TextStyle(fontSize: 13, color: AppColors.textSecondary),
      ),
    );
  }

  Widget _buildAvatarRow() {
    return InkWell(
      onTap: _showAvatarTip,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 12),
        child: Row(
          children: [
            _buildLabel('头像'),
            const Spacer(),
            CircleAvatar(
              radius: _avatarSize / 2,
              backgroundColor: AppColors.imagePlaceholder,
              // 头像按显示尺寸解码，避免把原图整张解进内存
              backgroundImage: _original.avatar.isEmpty
                  ? const AssetImage(AppAssets.goodsAvatar)
                  : ResizeImage(
                      NetworkImage(_original.avatar),
                      width: (_avatarSize * 3).round(),
                    ),
            ),
            const SizedBox(width: 4),
            const Icon(
              Icons.chevron_right_outlined,
              size: 18,
              color: AppColors.textSecondary,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTextFieldRow({
    required String label,
    required TextEditingController controller,
    required String hintText,
    required int maxLength,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          _buildLabel(label),
          Expanded(
            child: TextField(
              controller: controller,
              maxLength: maxLength,
              textAlign: TextAlign.end,
              style: const TextStyle(fontSize: 14),
              decoration: InputDecoration(
                hintText: hintText,
                counterText: '',
                isDense: true,
                border: InputBorder.none,
                hintStyle: const TextStyle(
                  fontSize: 14,
                  color: AppColors.textSecondary,
                ),
              ),
            ),
          ),
          const SizedBox(width: 4),
          // 与「性别 / 生日」的箭头区分：这两项是直接输入，不弹选择器
          const Icon(
            Icons.edit_outlined,
            size: 16,
            color: AppColors.textSecondary,
          ),
        ],
      ),
    );
  }

  Widget _buildPickerRow({
    required String label,
    required String value,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 14),
        child: Row(
          children: [
            _buildLabel(label),
            const Spacer(),
            Text(value, style: const TextStyle(fontSize: 14)),
            const SizedBox(width: 4),
            const Icon(
              Icons.chevron_right_outlined,
              size: 18,
              color: AppColors.textSecondary,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildValueRow({required String label, required String value}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 14),
      child: Row(
        children: [
          _buildLabel(label),
          const Spacer(),
          Flexible(
            child: Text(
              value,
              textAlign: TextAlign.end,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(fontSize: 14),
            ),
          ),
        ],
      ),
    );
  }
}
