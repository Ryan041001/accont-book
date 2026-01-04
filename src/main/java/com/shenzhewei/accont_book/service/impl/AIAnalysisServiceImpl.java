package com.shenzhewei.accont_book.service.impl;

import com.fasterxml.jackson.databind.JsonNode;
import com.fasterxml.jackson.databind.ObjectMapper;
import com.shenzhewei.accont_book.config.DeepSeekConfig;
import com.shenzhewei.accont_book.exception.BizException;
import com.shenzhewei.accont_book.common.ResultCode;
import com.shenzhewei.accont_book.model.dto.AIAnalysisResponse;
import com.shenzhewei.accont_book.model.entity.Asset;
import com.shenzhewei.accont_book.model.entity.Transaction;
import com.shenzhewei.accont_book.service.AIAnalysisService;
import com.shenzhewei.accont_book.service.AssetService;
import com.shenzhewei.accont_book.service.TransactionService;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import okhttp3.*;
import org.springframework.stereotype.Service;

import java.io.IOException;
import java.math.BigDecimal;
import java.time.LocalDateTime;
import java.time.format.DateTimeFormatter;
import java.util.HashMap;
import java.util.List;
import java.util.Map;
import java.util.concurrent.TimeUnit;
import java.util.stream.Collectors;

/**
 * AI分析服务实现
 */
@Slf4j
@Service
@RequiredArgsConstructor
public class AIAnalysisServiceImpl implements AIAnalysisService {

    private final DeepSeekConfig deepSeekConfig;
    private final AssetService assetService;
    private final TransactionService transactionService;
    private final ObjectMapper objectMapper = new ObjectMapper();

    @Override
    public AIAnalysisResponse analyzeUserData(Long userId, String type, String timeRange) {
        log.info("开始AI分析: userId={}, type={}, timeRange={}", userId, type, timeRange);

        // 获取用户数据
        List<Asset> assets = assetService.findByUserId(userId);
        List<Transaction> transactions = transactionService.listByUserId(userId);

        // 构建提示词
        String prompt = buildPrompt(assets, transactions, type, timeRange);

        // 调用DeepSeek API
        String aiResponse = callDeepSeekAPI(prompt);

        return AIAnalysisResponse.builder()
                .content(aiResponse)
                .type(type)
                .timestamp(LocalDateTime.now().format(DateTimeFormatter.ofPattern("yyyy-MM-dd HH:mm:ss")))
                .build();
    }

    /**
     * 构建提示词
     */
    private String buildPrompt(List<Asset> assets, List<Transaction> transactions, String type, String timeRange) {
        StringBuilder prompt = new StringBuilder();
        
        // 计算总资产
        BigDecimal totalBalance = assets.stream()
                .map(Asset::getBalance)
                .reduce(BigDecimal.ZERO, BigDecimal::add);

        // 计算收支情况
        BigDecimal totalIncome = transactions.stream()
                .filter(t -> t.getType() == 2)
                .map(Transaction::getAmount)
                .reduce(BigDecimal.ZERO, BigDecimal::add);

        BigDecimal totalExpense = transactions.stream()
                .filter(t -> t.getType() == 1)
                .map(Transaction::getAmount)
                .reduce(BigDecimal.ZERO, BigDecimal::add);

        // 分类统计
        Map<String, BigDecimal> categoryStats = transactions.stream()
                .filter(t -> t.getType() == 1)
                .collect(Collectors.groupingBy(
                        Transaction::getCategory,
                        Collectors.reducing(BigDecimal.ZERO, Transaction::getAmount, BigDecimal::add)
                ));

        prompt.append("我是一个个人记账助手，请根据以下数据进行分析：\n\n");
        prompt.append("【资产情况】\n");
        prompt.append("- 总资产：").append(totalBalance).append("元\n");
        prompt.append("- 资产账户数：").append(assets.size()).append("个\n");
        for (Asset asset : assets) {
            prompt.append("  * ").append(asset.getName()).append("：").append(asset.getBalance()).append("元\n");
        }

        prompt.append("\n【收支情况】\n");
        prompt.append("- 总收入：").append(totalIncome).append("元\n");
        prompt.append("- 总支出：").append(totalExpense).append("元\n");
        prompt.append("- 结余：").append(totalIncome.subtract(totalExpense)).append("元\n");
        prompt.append("- 交易记录数：").append(transactions.size()).append("笔\n");

        if (!categoryStats.isEmpty()) {
            prompt.append("\n【支出分类】\n");
            categoryStats.entrySet().stream()
                    .sorted((a, b) -> b.getValue().compareTo(a.getValue()))
                    .forEach(entry -> prompt.append("- ").append(entry.getKey())
                            .append("：").append(entry.getValue()).append("元\n"));
        }

        prompt.append("\n");

        // 根据分析类型添加具体要求
        switch (type) {
            case "summary":
                prompt.append("请用200字内总结财务状况：资产结构、收支平衡、主要开支。");
                break;
            case "advice":
                prompt.append("请给出3条理财建议，每条30字内，聚焦节流和资产配置。");
                break;
            case "forecast":
                prompt.append("请用150字内预测下月趋势并给建议。");
                break;
            default:
                prompt.append("请简要分析财务状况（150字内）。");
        }

        return prompt.toString();
    }

    /**
     * 调用DeepSeek API
     */
    private String callDeepSeekAPI(String prompt) {
        try {
            OkHttpClient client = new OkHttpClient.Builder()
                    .connectTimeout(deepSeekConfig.getTimeout(), TimeUnit.MILLISECONDS)
                    .readTimeout(deepSeekConfig.getTimeout(), TimeUnit.MILLISECONDS)
                    .writeTimeout(deepSeekConfig.getTimeout(), TimeUnit.MILLISECONDS)
                    .build();

            // 构建请求体
            Map<String, Object> requestBody = new HashMap<>();
            requestBody.put("model", deepSeekConfig.getModel());
            
            Map<String, String> message = new HashMap<>();
            message.put("role", "user");
            message.put("content", prompt);
            requestBody.put("messages", List.of(message));
            
            requestBody.put("temperature", 0.7);
            requestBody.put("max_tokens", 500); // 减少token限制，加快响应

            String jsonBody = objectMapper.writeValueAsString(requestBody);

            Request request = new Request.Builder()
                    .url(deepSeekConfig.getBaseUrl() + "/chat/completions")
                    .addHeader("Authorization", "Bearer " + deepSeekConfig.getKey())
                    .addHeader("Content-Type", "application/json")
                    .post(RequestBody.create(jsonBody, MediaType.parse("application/json")))
                    .build();

            try (Response response = client.newCall(request).execute()) {
                if (!response.isSuccessful()) {
                    String errorBody = response.body() != null ? response.body().string() : "";
                    log.error("DeepSeek API调用失败: code={}, message={}", response.code(), errorBody);
                    
                    String errorMessage;
                    switch (response.code()) {
                        case 401:
                            errorMessage = "AI服务认证失败，请检查API Key配置";
                            break;
                        case 402:
                            errorMessage = "AI服务余额不足，请充值后重试";
                            break;
                        case 429:
                            errorMessage = "AI服务请求过于频繁，请稍后重试";
                            break;
                        case 500:
                        case 503:
                            errorMessage = "AI服务暂时不可用，请稍后重试";
                            break;
                        default:
                            errorMessage = "AI分析服务暂时不可用";
                    }
                    throw new BizException(ResultCode.SYSTEM_ERROR, errorMessage);
                }

                String responseBody = response.body().string();
                log.info("DeepSeek API响应成功，响应长度: {}", responseBody.length());
                
                JsonNode jsonNode = objectMapper.readTree(responseBody);
                
                return jsonNode.path("choices")
                        .get(0)
                        .path("message")
                        .path("content")
                        .asText();
            }
        } catch (IOException e) {
            log.error("调用DeepSeek API异常: {}", e.getMessage(), e);
            if (e.getMessage() != null && e.getMessage().contains("timeout")) {
                throw new BizException(ResultCode.SYSTEM_ERROR, "AI分析请求超时，请稍后重试");
            }
            throw new BizException(ResultCode.SYSTEM_ERROR, "AI分析服务异常: " + e.getMessage());
        }
    }
}
