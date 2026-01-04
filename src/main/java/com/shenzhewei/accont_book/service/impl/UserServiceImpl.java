package com.shenzhewei.accont_book.service.impl;

import com.shenzhewei.accont_book.common.JwtUtil;
import com.shenzhewei.accont_book.common.PasswordUtil;
import com.shenzhewei.accont_book.common.ResultCode;
import com.shenzhewei.accont_book.exception.BizException;
import com.shenzhewei.accont_book.model.dto.LoginRequest;
import com.shenzhewei.accont_book.model.dto.LoginResponse;
import com.shenzhewei.accont_book.model.dto.RegisterRequest;
import com.shenzhewei.accont_book.model.dto.UserDTO;
import com.shenzhewei.accont_book.model.entity.User;
import com.shenzhewei.accont_book.repository.UserMapper;
import com.shenzhewei.accont_book.service.UserService;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.time.LocalDateTime;
import java.util.Optional;

/**
 * 用户服务实现
 */
@Slf4j
@Service
@RequiredArgsConstructor
public class UserServiceImpl implements UserService {

    private final UserMapper userMapper;
    private final JwtUtil jwtUtil;

    @Override
    @Transactional
    public UserDTO register(RegisterRequest request) {
        log.info("用户注册: username={}", request.getUsername());

        // 检查用户名是否已存在
        Optional<User> existingUser = userMapper.findByUsername(request.getUsername());
        if (existingUser.isPresent()) {
            throw new BizException(ResultCode.BIZ_ERROR, "用户名已存在");
        }

        // 加密密码
        String encodedPassword = PasswordUtil.encode(request.getPassword());

        // 创建用户
        User user = User.builder()
                .username(request.getUsername())
                .password(encodedPassword)
                .createTime(LocalDateTime.now())
                .build();

        int result = userMapper.insert(user);
        if (result != 1) {
            throw new BizException(ResultCode.BIZ_ERROR, "注册失败");
        }

        log.info("用户注册成功: userId={}, username={}", user.getId(), user.getUsername());

        return UserDTO.builder()
                .id(user.getId())
                .username(user.getUsername())
                .createTime(user.getCreateTime())
                .build();
    }

    @Override
    public LoginResponse login(LoginRequest request) {
        log.info("用户登录: username={}", request.getUsername());

        // 查询用户
        User user = userMapper.findByUsername(request.getUsername())
                .orElseThrow(() -> new BizException(ResultCode.BIZ_ERROR, "用户名或密码错误"));

        // 验证密码
        if (!PasswordUtil.matches(request.getPassword(), user.getPassword())) {
            throw new BizException(ResultCode.BIZ_ERROR, "用户名或密码错误");
        }

        // 生成Token
        String token = jwtUtil.generateToken(user.getId(), user.getUsername());

        log.info("用户登录成功: userId={}, username={}", user.getId(), user.getUsername());

        return LoginResponse.builder()
                .userId(user.getId())
                .username(user.getUsername())
                .token(token)
                .build();
    }

    @Override
    public UserDTO getUserById(Long userId) {
        log.debug("获取用户信息: userId={}", userId);

        User user = userMapper.findById(userId)
                .orElseThrow(() -> new BizException(ResultCode.NOT_FOUND, "用户不存在"));

        return UserDTO.builder()
                .id(user.getId())
                .username(user.getUsername())
                .createTime(user.getCreateTime())
                .build();
    }
}
