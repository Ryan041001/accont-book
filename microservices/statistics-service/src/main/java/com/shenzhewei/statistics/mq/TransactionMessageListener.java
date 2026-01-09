package com.shenzhewei.statistics.mq;

import com.fasterxml.jackson.databind.ObjectMapper;
import com.fasterxml.jackson.datatype.jsr310.JavaTimeModule;
import com.shenzhewei.statistics.mapper.StatisticsMapper;
import lombok.extern.slf4j.Slf4j;
import org.springframework.amqp.rabbit.annotation.RabbitListener;
import org.springframework.stereotype.Component;

import java.math.BigDecimal;
import java.time.LocalDate;
import java.time.LocalDateTime;
import java.time.format.DateTimeFormatter;
import java.util.Map;

/**
 * 交易消息监听器
 * 监听transaction-service发送的交易成功消息
 * 重构为直接更新预计算表，不再依赖 StatisticsService
 */
@Slf4j
@Component
public class TransactionMessageListener {

    private static final String QUEUE_TRANSACTION_SUCCESS = "transaction.success.queue";
    
    // 交易类型常量
    private static final int TYPE_EXPENSE = 1;  // 支出
    private static final int TYPE_INCOME = 2;   // 收入

    private final StatisticsMapper statisticsMapper;
    private final ObjectMapper objectMapper;

    public TransactionMessageListener(StatisticsMapper statisticsMapper) {
        this.statisticsMapper = statisticsMapper;
        this.objectMapper = new ObjectMapper();
        this.objectMapper.registerModule(new JavaTimeModule());
    }

    @RabbitListener(queues = QUEUE_TRANSACTION_SUCCESS)
    public void handleTransactionSuccess(String message) {
        try {
            log.info("收到交易成功消息: {}", message);
            
            // 解析消息
            Map<String, Object> transaction = objectMapper.readValue(message, Map.class);
            
            // 提取交易信息
            Long userId = ((Number) transaction.get("userId")).longValue();
            Integer type = ((Number) transaction.get("type")).intValue();
            BigDecimal amount = new BigDecimal(transaction.get("amount").toString());
            
            // 解析交易时间
            String transTimeStr = transaction.get("transTime").toString();
            LocalDate statDate = parseTransactionDate(transTimeStr);
            
            // 根据交易类型计算收入和支出
            BigDecimal incomeAmount = BigDecimal.ZERO;
            BigDecimal expenseAmount = BigDecimal.ZERO;
            
            if (type == TYPE_INCOME) {
                incomeAmount = amount;
            } else if (type == TYPE_EXPENSE) {
                expenseAmount = amount;
            }
            
            // 执行幂等的增量更新
            int result = statisticsMapper.insertOrUpdateDailyStat(
                userId, 
                statDate, 
                incomeAmount, 
                expenseAmount, 
                1  // 交易笔数增加1
            );
            
            // 新增：更新分类统计表
            String month = statDate.format(DateTimeFormatter.ofPattern("yyyy-MM")); // 从解析后的日期获取月份
            String category = transaction.get("category").toString();
            
            statisticsMapper.insertOrUpdateCategoryStat(userId, month, category, type, amount);

            log.info("统计数据预计算完成: userId={}, statDate={}, category={}, income={}, expense={}, result={}", 
                     userId, statDate, category, incomeAmount, expenseAmount, result);
        } catch (Exception e) {
            log.error("处理交易消息失败: {}", message, e);
            // 可以选择抛出异常让消息重试，或者记录到死信队列
        }
    }
    
    /**
     * 解析交易时间为日期
     * 支持多种时间格式
     */
    private LocalDate parseTransactionDate(String transTimeStr) {
        try {
            // 尝试解析为 LocalDateTime
            LocalDateTime dateTime = LocalDateTime.parse(transTimeStr, 
                    DateTimeFormatter.ISO_DATE_TIME);
            return dateTime.toLocalDate();
        } catch (Exception e1) {
            try {
                // 尝试直接解析为 LocalDate
                return LocalDate.parse(transTimeStr, DateTimeFormatter.ISO_DATE);
            } catch (Exception e2) {
                // 如果都失败，使用当前日期
                log.warn("无法解析交易时间: {}, 使用当前日期", transTimeStr);
                return LocalDate.now();
            }
        }
    }
}
