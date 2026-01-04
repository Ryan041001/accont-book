package com.shenzhewei.accont_book.controller;

import com.shenzhewei.accont_book.common.Result;
import com.shenzhewei.accont_book.model.dto.LoginRequest;
import com.shenzhewei.accont_book.model.dto.LoginResponse;
import com.shenzhewei.accont_book.model.dto.RegisterRequest;
import com.shenzhewei.accont_book.model.dto.UserDTO;
import com.shenzhewei.accont_book.service.UserService;
import jakarta.validation.Valid;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.web.bind.annotation.*;

/**
 * 用户控制器
 */
@Slf4j
@RestController
@RequestMapping("/api/users")
@RequiredArgsConstructor
public class UserController {

    private final UserService userService;

    /**
     * 用户注册
     */
    @PostMapping("/register")
    public Result<UserDTO> register(@Valid @RequestBody RegisterRequest request) {
        log.info("用户注册请求: username={}", request.getUsername());
        UserDTO user = userService.register(request);
        return Result.success(user);
    }

    /**
     * 用户登录
     */
    @PostMapping("/login")
    public Result<LoginResponse> login(@Valid @RequestBody LoginRequest request) {
        log.info("用户登录请求: username={}", request.getUsername());
        LoginResponse response = userService.login(request);
        return Result.success(response);
    }

    /**
     * 获取当前用户信息
     */
    @GetMapping("/me")
    public Result<UserDTO> getCurrentUser(@RequestAttribute("userId") Long userId) {
        log.info("获取当前用户信息: userId={}", userId);
        UserDTO user = userService.getUserById(userId);
        return Result.success(user);
    }
}
