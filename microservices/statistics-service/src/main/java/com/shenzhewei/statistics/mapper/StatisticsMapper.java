package com.shenzhewei.statistics.mapper;

import com.shenzhewei.statistics.entity.CategoryStatistics;
import com.shenzhewei.statistics.entity.DailyStatistics;
import org.apache.ibatis.annotations.*;

import java.math.BigDecimal;
import java.time.LocalDate;
import java.util.List;

/**
 * 统计数据 Mapper
 * 使用 ON DUPLICATE KEY UPDATE 实现幂等的增量更新
 */
@Mapper
public interface StatisticsMapper {

    /**
     * 插入或更新日统计数据（幂等操作）
     * 如果记录存在（user_id + stat_date 唯一键冲突），则执行增量累加
     * 如果记录不存在，则新建记录
     * 
     * @param userId 用户ID
     * @param statDate 统计日期
     * @param incomeAmount 收入金额（如果本次交易是收入）
     * @param expenseAmount 支出金额（如果本次交易是支出）
     * @param transCount 交易笔数增量（通常为1）
     */
    @Insert("INSERT INTO tb_daily_statistics (user_id, stat_date, total_income, total_expense, trans_count) " +
            "VALUES (#{userId}, #{statDate}, #{incomeAmount}, #{expenseAmount}, #{transCount}) " +
            "ON DUPLICATE KEY UPDATE " +
            "total_income = total_income + #{incomeAmount}, " +
            "total_expense = total_expense + #{expenseAmount}, " +
            "trans_count = trans_count + #{transCount}")
    int insertOrUpdateDailyStat(@Param("userId") Long userId,
                                 @Param("statDate") LocalDate statDate,
                                 @Param("incomeAmount") BigDecimal incomeAmount,
                                 @Param("expenseAmount") BigDecimal expenseAmount,
                                 @Param("transCount") Integer transCount);

    /**
     * 按日期范围查询统计数据
     * 
     * @param userId 用户ID
     * @param startDate 开始日期
     * @param endDate 结束日期
     * @return 统计数据列表
     */
    @Select("SELECT id, user_id, stat_date, total_income, total_expense, trans_count, update_time " +
            "FROM tb_daily_statistics " +
            "WHERE user_id = #{userId} AND stat_date BETWEEN #{startDate} AND #{endDate} " +
            "ORDER BY stat_date")
    List<DailyStatistics> findByDateRange(@Param("userId") Long userId,
                                           @Param("startDate") LocalDate startDate,
                                           @Param("endDate") LocalDate endDate);

    /**
     * 按月份查询统计数据
     * 
     * @param userId 用户ID
     * @param year 年份
     * @param month 月份
     * @return 统计数据列表
     */
    @Select("SELECT id, user_id, stat_date, total_income, total_expense, trans_count, update_time " +
            "FROM tb_daily_statistics " +
            "WHERE user_id = #{userId} " +
            "AND YEAR(stat_date) = #{year} " +
            "AND MONTH(stat_date) = #{month} " +
            "ORDER BY stat_date")
    List<DailyStatistics> findByMonth(@Param("userId") Long userId,
                                       @Param("year") Integer year,
                                       @Param("month") Integer month);

    /**
     * 查询指定日期的统计数据
     * 
     * @param userId 用户ID
     * @param statDate 统计日期
     * @return 统计数据
     */
    @Select("SELECT id, user_id, stat_date, total_income, total_expense, trans_count, update_time " +
            "FROM tb_daily_statistics " +
            "WHERE user_id = #{userId} AND stat_date = #{statDate}")
    DailyStatistics findByDate(@Param("userId") Long userId,
                                @Param("statDate") LocalDate statDate);

    /**
     * 插入或更新分类统计数据（幂等操作）
     *
     * @param userId 用户ID
     * @param month 统计月份
     * @param category 分类名称
     * @param type 类型
     * @param amount 金额
     */
    @Insert("INSERT INTO tb_category_statistics (user_id, stat_month, category_name, type, total_amount, trans_count) " +
            "VALUES (#{userId}, #{month}, #{category}, #{type}, #{amount}, 1) " +
            "ON DUPLICATE KEY UPDATE " +
            "total_amount = total_amount + #{amount}, " +
            "trans_count = trans_count + 1")
    int insertOrUpdateCategoryStat(@Param("userId") Long userId,
                                   @Param("month") String month,
                                   @Param("category") String category,
                                   @Param("type") Integer type,
                                   @Param("amount") BigDecimal amount);

    /**
     * 查询分类统计数据
     *
     * @param userId 用户ID
     * @param month 统计月份
     * @param type 类型
     * @return 分类统计列表
     */
    @Select("SELECT user_id, category_name as category, type, total_amount, trans_count as transactionCount " +
            "FROM tb_category_statistics " +
            "WHERE user_id = #{userId} AND stat_month = #{month} AND type = #{type} " +
            "ORDER BY total_amount DESC")
    List<CategoryStatistics> selectCategoryStats(@Param("userId") Long userId,
                                                 @Param("month") String month,
                                                 @Param("type") Integer type);
}
