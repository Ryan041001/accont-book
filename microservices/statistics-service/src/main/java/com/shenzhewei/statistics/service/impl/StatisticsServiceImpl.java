package com.shenzhewei.statistics.service.impl;


import com.shenzhewei.statistics.entity.CategoryStatistics;
import com.shenzhewei.statistics.entity.DailyStatistics;
import com.shenzhewei.statistics.entity.MonthlyStatistics;
import com.shenzhewei.statistics.mapper.StatisticsMapper;
import com.shenzhewei.statistics.service.StatisticsService;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.stereotype.Service;

import java.math.BigDecimal;
import java.math.RoundingMode;
import java.time.LocalDate;
import java.time.format.DateTimeFormatter;
import java.util.ArrayList;
import java.util.List;
import java.util.Map;
import java.util.stream.Collectors;

/**
 * 统计服务实现
 * 优化为使用预计算表查询，提升性能
 * 分类统计通过 Feign 调用 transaction-service
 */
@Slf4j
@Service
@RequiredArgsConstructor
public class StatisticsServiceImpl implements StatisticsService {

    private final StatisticsMapper statisticsMapper;

    private static final DateTimeFormatter MONTH_FORMATTER = DateTimeFormatter.ofPattern("yyyy-MM");

    @Override
    public void updateStatistics(Long userId, Long transactionId) {
        // 此方法已被消息驱动的预计算取代，保留接口兼容性
        log.info("统计数据更新触发（已迁移至消息驱动）: userId={}, transactionId={}", userId, transactionId);
    }

    @Override
    public List<MonthlyStatistics> getMonthlyStatistics(Long userId, int months) {
        // 计算查询的日期范围
        LocalDate endDate = LocalDate.now();
        LocalDate startDate = endDate.minusMonths(months);
        
        // 从预计算表查询
        List<DailyStatistics> dailyStats = statisticsMapper.findByDateRange(userId, startDate, endDate);
        
        // 按月聚合
        Map<String, List<DailyStatistics>> monthlyGroups = dailyStats.stream()
                .collect(Collectors.groupingBy(stat -> 
                    stat.getStatDate().format(MONTH_FORMATTER)));
        
        List<MonthlyStatistics> result = new ArrayList<>();
        for (Map.Entry<String, List<DailyStatistics>> entry : monthlyGroups.entrySet()) {
            String month = entry.getKey();
            List<DailyStatistics> stats = entry.getValue();
            
            BigDecimal totalIncome = stats.stream()
                    .map(DailyStatistics::getTotalIncome)
                    .reduce(BigDecimal.ZERO, BigDecimal::add);
            BigDecimal totalExpense = stats.stream()
                    .map(DailyStatistics::getTotalExpense)
                    .reduce(BigDecimal.ZERO, BigDecimal::add);
            int transCount = stats.stream()
                    .mapToInt(DailyStatistics::getTransCount)
                    .sum();
            
            result.add(MonthlyStatistics.builder()
                    .userId(userId)
                    .month(month)
                    .totalIncome(totalIncome)
                    .totalExpense(totalExpense)
                    .netAmount(totalIncome.subtract(totalExpense))
                    .transactionCount(transCount)
                    .build());
        }
        
        // 按月份降序排序
        result.sort((a, b) -> b.getMonth().compareTo(a.getMonth()));
        
        return result;
    }

    @Override
    public List<CategoryStatistics> getCategoryStatistics(Long userId, String month, Integer type) {
        // 修改后：直接查自己的 Mapper (解耦)
        log.info("查询本地分类统计数据: userId={}, month={}, type={}", userId, month, type);

        List<CategoryStatistics> statisticsList = statisticsMapper.selectCategoryStats(userId, month, type);
        
        // 计算总金额用于百分比
        BigDecimal totalSum = statisticsList.stream()
                .map(CategoryStatistics::getTotalAmount)
                .reduce(BigDecimal.ZERO, BigDecimal::add);

        // 计算百分比
        for (CategoryStatistics stat : statisticsList) {
            double percentage = totalSum.compareTo(BigDecimal.ZERO) > 0 
                    ? stat.getTotalAmount().divide(totalSum, 4, RoundingMode.HALF_UP).doubleValue() * 100 
                    : 0;
            stat.setPercentage(percentage);
        }
        
        return statisticsList;
    }

    @Override
    public MonthlyStatistics getCurrentMonthSummary(Long userId) {
        // 使用预计算表查询当月汇总
        LocalDate now = LocalDate.now();
        int year = now.getYear();
        int month = now.getMonthValue();
        String currentMonth = now.format(MONTH_FORMATTER);
        
        List<DailyStatistics> dailyStats = statisticsMapper.findByMonth(userId, year, month);
        
        BigDecimal totalIncome = dailyStats.stream()
                .map(DailyStatistics::getTotalIncome)
                .reduce(BigDecimal.ZERO, BigDecimal::add);
        BigDecimal totalExpense = dailyStats.stream()
                .map(DailyStatistics::getTotalExpense)
                .reduce(BigDecimal.ZERO, BigDecimal::add);
        int transCount = dailyStats.stream()
                .mapToInt(DailyStatistics::getTransCount)
                .sum();
        
        return MonthlyStatistics.builder()
                .userId(userId)
                .month(currentMonth)
                .totalIncome(totalIncome)
                .totalExpense(totalExpense)
                .netAmount(totalIncome.subtract(totalExpense))
                .transactionCount(transCount)
                .build();
    }
}
