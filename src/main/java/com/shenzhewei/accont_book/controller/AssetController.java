package com.shenzhewei.accont_book.controller;

import com.shenzhewei.accont_book.common.Result;
import com.shenzhewei.accont_book.model.entity.Asset;
import com.shenzhewei.accont_book.service.AssetService;
import lombok.RequiredArgsConstructor;
import org.springframework.web.bind.annotation.*;

import java.math.BigDecimal;
import java.time.LocalDateTime;
import java.util.List;

/**
 * 资产控制器
 */
@RestController
@RequestMapping("/api/assets")
@RequiredArgsConstructor
public class AssetController {

    private final AssetService assetService;

    /**
     * 查询资产详情
     */
    @GetMapping("/{id}")
    public Result<Asset> getById(@PathVariable Long id) {
        return assetService.findById(id)
                .map(Result::success)
                .orElse(Result.fail(404, "资产不存在"));
    }

    /**
     * 查询用户资产列表（从Token获取用户ID）
     */
    @GetMapping
    public Result<List<Asset>> listMyAssets(@RequestAttribute("userId") Long userId) {
        List<Asset> assets = assetService.findByUserId(userId);
        return Result.success(assets);
    }

    /**
     * 查询用户资产列表（通过用户ID参数）
     */
    @GetMapping("/user/{userId}")
    public Result<List<Asset>> listByUserId(@PathVariable Long userId) {
        List<Asset> assets = assetService.findByUserId(userId);
        return Result.success(assets);
    }

    /**
     * 创建资产账户
     */
    @PostMapping
    public Result<Asset> create(@RequestAttribute("userId") Long userId, @RequestBody CreateAssetRequest request) {
        Asset asset = Asset.builder()
                .userId(userId)
                .name(request.getName())
                .balance(request.getBalance() != null ? request.getBalance() : BigDecimal.ZERO)
                .build();
        Asset created = assetService.create(asset);
        return Result.success(created);
    }

    /**
     * 修改资产名称
     */
    @PutMapping("/{id}")
    public Result<Void> updateName(@PathVariable Long id, @RequestBody UpdateAssetRequest request) {
        assetService.updateName(id, request.getName());
        return Result.success();
    }

    /**
     * 删除资产（需无流水记录）
     */
    @DeleteMapping("/{id}")
    public Result<Void> delete(@PathVariable Long id) {
        assetService.delete(id);
        return Result.success();
    }

    /**
     * 创建资产请求
     */
    @lombok.Data
    public static class CreateAssetRequest {
        private String name;
        private BigDecimal balance;
    }

    /**
     * 修改资产请求
     */
    @lombok.Data
    public static class UpdateAssetRequest {
        private String name;
    }
}
