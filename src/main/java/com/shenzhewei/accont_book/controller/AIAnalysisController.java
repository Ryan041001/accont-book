package com.shenzhewei.accont_book.controller;

import com.shenzhewei.accont_book.common.Result;
import com.shenzhewei.accont_book.model.dto.AIAnalysisRequest;
import com.shenzhewei.accont_book.model.dto.AIAnalysisResponse;
import com.shenzhewei.accont_book.service.AIAnalysisService;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.web.bind.annotation.*;

/**
 * AI分析控制器
 */
@Slf4j
@RestController
@RequestMapping("/api/ai")
@RequiredArgsConstructor
public class AIAnalysisController {

    private final AIAnalysisService aiAnalysisService;

    /**
     * AI账本分析
     */
    @PostMapping("/analyze")
    public Result<AIAnalysisResponse> analyze(
            @RequestAttribute("userId") Long userId,
            @RequestBody AIAnalysisRequest request) {
        log.info("AI分析请求: userId={}, type={}, timeRange={}", 
                userId, request.getType(), request.getTimeRange());
        
        AIAnalysisResponse response = aiAnalysisService.analyzeUserData(
                userId, 
                request.getType(), 
                request.getTimeRange()
        );
        
        return Result.success(response);
    }
}
