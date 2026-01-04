package com.shenzhewei.accont_book.model.dto;

import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Data;
import lombok.NoArgsConstructor;

/**
 * AI分析响应DTO
 */
@Data
@Builder
@NoArgsConstructor
@AllArgsConstructor
public class AIAnalysisResponse {

    /**
     * 分析内容
     */
    private String content;

    /**
     * 分析类型
     */
    private String type;

    /**
     * 生成时间
     */
    private String timestamp;
}
