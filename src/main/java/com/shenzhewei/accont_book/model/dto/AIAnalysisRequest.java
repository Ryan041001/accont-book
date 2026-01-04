package com.shenzhewei.accont_book.model.dto;

import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Data;
import lombok.NoArgsConstructor;

/**
 * AI分析请求DTO
 */
@Data
@Builder
@NoArgsConstructor
@AllArgsConstructor
public class AIAnalysisRequest {

    /**
     * 分析类型：summary-总结, advice-建议, forecast-预测
     */
    private String type;

    /**
     * 时间范围：week-本周, month-本月, year-本年
     */
    private String timeRange;
}
