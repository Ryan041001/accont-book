package com.shenzhewei.accont_book.service;

import com.shenzhewei.accont_book.model.dto.LoginRequest;
import com.shenzhewei.accont_book.model.dto.LoginResponse;
import com.shenzhewei.accont_book.model.dto.RegisterRequest;
import com.shenzhewei.accont_book.model.dto.UserDTO;

/**
 * 用户服务接口
 */
public interface UserService {

    /**
     * 用户注册
     *
     * @param request 注册请求
     * @return 用户信息
     */
    UserDTO register(RegisterRequest request);

    /**
     * 用户登录
     *
     * @param request 登录请求
     * @return 登录响应（包含Token）
     */
    LoginResponse login(LoginRequest request);

    /**
     * 根据ID获取用户信息
     *
     * @param userId 用户ID
     * @return 用户信息
     */
    UserDTO getUserById(Long userId);
}
