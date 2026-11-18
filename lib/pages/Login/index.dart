import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:hm_shop/api/user.dart';
import 'package:hm_shop/stores/TokenManager.dart';
import 'package:hm_shop/stores/UserController.dart';
import 'package:hm_shop/utils/LoadingDialog.dart';
import 'package:hm_shop/utils/ToastUtils.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  bool _agreed = false;
  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _codeController = TextEditingController();
  final UserController _userController = Get.find<UserController>();

  @override
  void dispose() {
    _phoneController.dispose();
    _codeController.dispose();
    super.dispose();
  }

  Widget _buildHeader() {
    return Text(
      '账号密码登录',
      style: TextStyle(
        fontSize: 20,
        fontWeight: FontWeight.w600,
        color: Colors.black,
      ),
    );
  }

  Widget _buildPhoneTextField() {
    return TextFormField(
      validator: (value) {
        if (value == null || value.isEmpty) {
          return '请输入账号';
        }
        // 校验手机格式
        if (!RegExp(r'^1[3-9]\d{9}$').hasMatch(value)) {
          return '请输入正确的手机号';
        }
        return null;
      },
      controller: _phoneController,
      decoration: InputDecoration(
        hintText: '请输入账号',
        hintStyle: const TextStyle(color: Colors.grey),
        filled: true,
        fillColor: const Color(0xFFF5F5F5),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 20,
          vertical: 16,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(28),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(28),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(28),
          borderSide: BorderSide.none,
        ),
      ),
    );
  }

  Widget _buildCodeTextField() {
    return TextFormField(
      validator: (value) {
        if (value == null || value.isEmpty) {
          return '请输入密码';
        }
        // 校验密码格式，6-16位字母、数字、下划线
        if (!RegExp(r'^[a-zA-Z0-9_]{6,16}$').hasMatch(value)) {
          return '密码格式错误，6-16位字母、数字、下划线';
        }
        return null;
      },
      controller: _codeController,
      obscureText: true,
      decoration: InputDecoration(
        hintText: '请输入密码',
        hintStyle: const TextStyle(color: Colors.grey),
        filled: true,
        fillColor: const Color(0xFFF5F5F5),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 20,
          vertical: 16,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(28),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(28),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(28),
          borderSide: BorderSide.none,
        ),
      ),
    );
  }

  Widget _buildCheckBox() {
    return Row(
      children: [
        SizedBox(
          width: 22,
          height: 22,
          child: Checkbox(
            value: _agreed,
            activeColor: Colors.black,
            checkColor: Colors.white,
            onChanged: (value) {
              setState(() {
                _agreed = value ?? false;
              });
            },
            shape: const CircleBorder(),
            side: const BorderSide(color: Colors.grey),
            materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
            visualDensity: VisualDensity.compact,
          ),
        ),
        const SizedBox(width: 4),
        Expanded(
          child: Text.rich(
            TextSpan(
              text: '查看并同意',
              style: const TextStyle(fontSize: 12, color: Colors.grey),
              children: [
                TextSpan(
                  text: '《隐私条款》',
                  style: const TextStyle(color: Color(0xFF1E88E5)),
                ),
                const TextSpan(text: '和'),
                TextSpan(
                  text: '《用户协议》',
                  style: const TextStyle(color: Color(0xFF1E88E5)),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  // 登录
  Future<void> _login() async {
    LoadingDialog.show(context, message: "努力登录中");
    try {
      final res = await loginAPI({
        'account': _phoneController.text.trim(),
        'password': _codeController.text,
      });
      if (!mounted) {
        return;
      }
      _userController.updateUserInfo(res);
      await tokenManager.setToken(res.token);
      if (!mounted) {
        return;
      }
      LoadingDialog.hide(context); // 先关闭加载对话框
      ToastUtils.showToast(context, '登录成功，欢迎 ${res.nickname}');
      Navigator.pop(context); // 再返回上一页
    } catch (e) {
      if (!mounted) {
        return;
      }
      LoadingDialog.hide(context); // 登录失败时仅关闭加载弹窗，保留在登录页
      final errorMsg = e is DioException
          ? (e.message ?? '登录失败')
          : '网络或服务异常，请稍后重试';
      ToastUtils.showToast(context, errorMsg);
    }
  }

  Widget _buildLoginButton() {
    return SizedBox(
      width: double.infinity,
      height: 50,
      child: ElevatedButton(
        onPressed: () {
          if (_formKey.currentState?.validate() == true) {
            // 登录逻辑，需要判断勾选框逻辑
            if (!_agreed) {
              ToastUtils.showToast(context, '请勾选隐私条款和用户协议');
            } else {
              _login();
            }
          }
        },
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.black,
          foregroundColor: Colors.white,
          elevation: 0,
          shape: const StadiumBorder(),
        ),
        child: const Text(
          '登录',
          style: TextStyle(
            color: Colors.white,
            fontSize: 16,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }

  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text('登录'),
        centerTitle: true,
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 0,
      ),
      body: Form(
        key: _formKey,
        child: Container(
          padding: const EdgeInsets.all(20),
          color: Colors.white,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SizedBox(height: 20),
              _buildHeader(),
              const SizedBox(height: 20),
              _buildPhoneTextField(),
              const SizedBox(height: 20),
              _buildCodeTextField(),
              const SizedBox(height: 20),
              // 隐私条款 / 用户协议
              _buildCheckBox(),
              const SizedBox(height: 20),
              // 登录按钮
              _buildLoginButton(),
            ],
          ),
        ),
      ),
    );
  }
}
