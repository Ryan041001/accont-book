package com.shenzhewei.accont_book.service;

import com.shenzhewei.accont_book.model.dto.AIAnalysisResponse;

/**
 * AI分析服务接口
 */
public interface AIAnalysisService {

    /**
     * 分析用户账本数据
     *
     * @param userId 用户ID
     * @param type 分析类型
     * @param timeRange 时间范围
     * @return AI分析结果
     */
    AIAnalysisResponse analyzeUserData(Long userId, String type, String timeRange);
}
